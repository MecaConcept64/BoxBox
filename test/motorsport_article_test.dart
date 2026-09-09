import 'package:boxbox/api/motorsport_article.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:boxbox/Screens/MixedNews/native_news_reader.dart';
import 'package:boxbox/l10n/app_localizations.dart';

void main() {
  const url = 'https://fr.motorsport.com/f1/news/test/123/';
  const page = '''<meta property="og:title" content="Titre &amp; essai">
  <meta property="og:image" content="//cdn.motorsport.com/photo.jpg">
  <div class="ms-article-content"><p>Premier <a>paragraphe</a>.</p>
  <section class="relatedContent"><p>Suggestion à exclure</p></section>
  <div class="ms-apb"><p>Publicité à exclure</p></div>
  <h2>Intertitre</h2><p>Deuxième paragraphe.</p>
  <section data-widget="image" data-src="//cdn.motorsport.com/inline.jpg" data-title="Légende"></section></div>''';
  test('Extracts article text and images without recommendations or ads', () {
    final article = MotorsportArticle.parse(page, url);
    expect(article.title, 'Titre & essai');
    expect(article.blocks.map((b) => b.text), [
      'Premier paragraphe.',
      'Intertitre',
      'Deuxième paragraphe.',
      'Légende'
    ]);
    expect(article.blocks[1].heading, isTrue);
    expect(
        article.blocks.last.imageUrl, 'https://cdn.motorsport.com/inline.jpg');
  });
  test('Rejects unsupported hosts, missing content and restricted articles',
      () {
    expect(MotorsportArticle.supports(url), isTrue);
    expect(
        MotorsportArticle.supports(
            'https://fr.motorsport.com.evil.org/f1/news/a'),
        isFalse);
    expect(() => MotorsportArticle.parse('<html>Unavailable</html>', url),
        throwsFormatException);
    expect(
        () => MotorsportArticle.parse(
            '''<script type="application/ld+json">{"@type":"NewsArticle","isAccessibleForFree":false}</script>$page''',
            url),
        throwsFormatException);
  });
  testWidgets(
      'Native reader remains scrollable on a narrow phone with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final article = MotorsportArticle.parse(
        page.replaceAll('og:image', 'unused-image'), url);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!),
      home: Scaffold(
          body: NativeArticleContent(
              article: MotorsportArticle(
                  title: article.title,
                  description: 'Description de cet article pour la lecture.',
                  author: 'Auteur',
                  blocks:
                      article.blocks.where((b) => b.imageUrl == null).toList()),
              onOriginal: () {})),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Titre & essai'), findsOneWidget);
    expect(find.text('Premier paragraphe.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
