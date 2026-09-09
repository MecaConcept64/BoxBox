import 'package:boxbox/Screens/home.dart';
import 'package:boxbox/api/rss.dart';
import 'package:boxbox/classes/event_tracker.dart';
import 'package:boxbox/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Motorsport source selection resolves once to the RSS endpoint', () {
    const url = 'https://fr.motorsport.com/rss/f1/news/';
    expect(RssFeeds.feedUrl('https://fr.motorsport.com'), url);
    expect(RssFeeds.feedUrl('https://fr.motorsport.com/'), url);
    expect(RssFeeds.feedUrl(url), url);
    expect(RssFeeds.feedUrl('https://example.com/feed'),
        'https://example.com/feed');
  });

  testWidgets(
      'Weekend displays all sprint sessions in date order on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final start = DateTime.now().add(const Duration(days: 30));
    Session session(String code, int hours) => Session(
        'scheduled',
        code,
        start.add(Duration(hours: hours + 1)),
        start.add(Duration(hours: hours)),
        '',
        0);
    final event = Event(
        'test',
        'Test Grand Prix',
        'FORMULA 1 TEST GRAND PRIX',
        'Test country',
        start,
        start.add(const Duration(days: 3)),
        '',
        [],
        false,
        [
          session('r', 48),
          session('s', 24),
          session('ss', 4),
          session('p1', 0),
          session('q', 28)
        ]);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!),
      home: Scaffold(
          body: SingleChildScrollView(child: PitwallWeekendCard(event))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('SS'), findsOneWidget);
    expect(tester.getTopLeft(find.text('P1')).dy,
        lessThan(tester.getTopLeft(find.text('SS')).dy));
    expect(tester.getTopLeft(find.text('S')).dy,
        lessThan(tester.getTopLeft(find.text('R')).dy));
    expect(find.text('Ouvrir le Race Center'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
