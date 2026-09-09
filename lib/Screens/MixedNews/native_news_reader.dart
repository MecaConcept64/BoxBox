import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:boxbox/api/motorsport_article.dart';
import 'package:boxbox/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

const _background = Color(0xFF101719);
const _coral = Color(0xFFFF7B68);
const _muted = Color(0xFFACBAC5);

class NativeNewsReader extends StatefulWidget {
  final String articleUrl;
  final Widget original;
  const NativeNewsReader(
      {super.key, required this.articleUrl, required this.original});

  @override
  State<NativeNewsReader> createState() => _NativeNewsReaderState();
}

class _NativeNewsReaderState extends State<NativeNewsReader> {
  late Future<MotorsportArticle> _article;
  HeadlessInAppWebView? _page;

  Future<MotorsportArticle> _loadArticle() async {
    try {
      return await MotorsportArticle.fetch(widget.articleUrl);
    } catch (_) {
      if (!mounted || kIsWeb) rethrow;
    }
    // Some publishers reject Dart HTTP requests. Load their public page with
    // the platform engine, then render only the article in native widgets.
    final result = Completer<MotorsportArticle>();
    final page = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.articleUrl)),
      initialSettings:
          InAppWebViewSettings(mediaPlaybackRequiresUserGesture: true),
      onLoadStop: (controller, url) async {
        if (result.isCompleted) return;
        try {
          final source = await controller.evaluateJavascript(
              source: 'document.documentElement.outerHTML');
          final article =
              MotorsportArticle.parse(source as String, widget.articleUrl);
          if (!result.isCompleted) result.complete(article);
        } catch (error, stack) {
          if (!result.isCompleted) result.completeError(error, stack);
        }
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame == true && !result.isCompleted) {
          result.completeError(const FormatException('Article unavailable'));
        }
      },
    );
    _page = page;
    try {
      // Attach the timeout/error handler before the platform callbacks run.
      final future = result.future.timeout(const Duration(seconds: 25));
      unawaited(page.run().catchError((Object error, StackTrace stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      }));
      return await future;
    } finally {
      if (identical(_page, page)) {
        _page = null;
        await page.dispose();
      }
    }
  }

  @override
  void dispose() {
    _page?.dispose();
    _page = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _article = _loadArticle();
  }

  void _openOriginal() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => widget.original));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Theme(
      data: ThemeData.dark().copyWith(scaffoldBackgroundColor: _background),
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: _background,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(l.readerTitle,
                style: const TextStyle(fontFamily: 'Formula1', fontSize: 15)),
            centerTitle: true,
            actions: [
              IconButton(
                  tooltip: l.readerOriginal,
                  onPressed: _openOriginal,
                  icon: const Icon(Icons.open_in_new_rounded, size: 21)),
              IconButton(
                  tooltip: MaterialLocalizations.of(context).shareButtonLabel,
                  onPressed: () => Share.share(widget.articleUrl),
                  icon: const Icon(Icons.ios_share_rounded, size: 21))
            ]),
        body: FutureBuilder<MotorsportArticle>(
            future: _article,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(28),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(l.readerUnavailable,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: _openOriginal,
                              child: Text(l.readerOriginal)),
                          TextButton(
                              onPressed: () => setState(() {
                                    _article = _loadArticle();
                                  }),
                              child: Text(l.pitwallRetry)),
                        ])));
              }
              if (!snapshot.hasData)
                return const Center(
                    child: CircularProgressIndicator(color: _coral));
              return NativeArticleContent(
                  article: snapshot.data!, onOriginal: _openOriginal);
            }),
      ),
    );
  }
}

class NativeArticleContent extends StatelessWidget {
  final MotorsportArticle article;
  final VoidCallback onOriginal;
  const NativeArticleContent(
      {super.key, required this.article, required this.onOriginal});

  Widget _image(String url) => ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(url,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink()));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final date = article.published == null
        ? ''
        : DateFormat('d MMMM yyyy · HH:mm',
                Localizations.localeOf(context).toLanguageTag())
            .format(article.published!.toLocal());
    return SingleChildScrollView(
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                              spacing: 20,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(
                                      width: 4, height: 14, color: _coral),
                                  const SizedBox(width: 8),
                                  Text(l.pitwallCategory,
                                      style: const TextStyle(
                                          color: _coral,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5)),
                                ]),
                                Text(l.readerSource,
                                    style: const TextStyle(
                                        color: _muted, fontSize: 12)),
                              ]),
                          const SizedBox(height: 18),
                          SelectableText(article.title,
                              style: const TextStyle(
                                  fontFamily: 'Formula1',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                  height: 1.3,
                                  color: Color(0xFFF3F5F6))),
                          const SizedBox(height: 16),
                          Text(
                              [article.author, date]
                                  .where((s) => s.isNotEmpty)
                                  .join('\n'),
                              style: const TextStyle(
                                  color: _muted, fontSize: 12, height: 1.7)),
                          if (article.imageUrl != null) ...[
                            const SizedBox(height: 22),
                            _image(article.imageUrl!)
                          ],
                          if (article.description.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                                padding: const EdgeInsets.only(left: 16),
                                decoration: const BoxDecoration(
                                    border: Border(
                                        left: BorderSide(
                                            color: _coral, width: 3))),
                                child: SelectableText(article.description,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFE7ECEF)))),
                          ],
                          const SizedBox(height: 24),
                          for (final block in article.blocks)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: block.imageUrl != null
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                            _image(block.imageUrl!),
                                            const SizedBox(height: 8),
                                            Text(block.text,
                                                style: const TextStyle(
                                                    color: _muted,
                                                    fontSize: 11,
                                                    height: 1.4))
                                          ])
                                    : SelectableText(block.text,
                                        style: TextStyle(
                                            fontSize: block.heading ? 22 : 17,
                                            height: 1.65,
                                            fontWeight: block.heading
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: const Color(0xFFD4DDE1)))),
                          const Divider(color: Color(0xFF2A373D)),
                          TextButton.icon(
                              onPressed: onOriginal,
                              icon: const Icon(Icons.open_in_new,
                                  size: 17, color: _coral),
                              label: Text(l.readerOriginal,
                                  style: const TextStyle(color: _coral))),
                        ])))));
  }
}
