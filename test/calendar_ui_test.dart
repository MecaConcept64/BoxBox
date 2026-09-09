import 'dart:typed_data';
import 'package:boxbox/api/race_components.dart';
import 'package:boxbox/classes/race.dart';
import 'package:boxbox/helpers/race_flag.dart';
import 'package:boxbox/l10n/app_localizations.dart';
import 'package:boxbox/theme/pitwall_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

void main() {
  late Box settings;
  setUp(() async {
    settings = await Hive.openBox('settings', bytes: Uint8List(0));
  });
  tearDown(() async => Hive.close());

  Race race({String date = '2026-09-13T15:00:00', bool hasTime = true}) => Race(
      '1',
      'madrid',
      'Spanish Grand Prix',
      date,
      '15:00:00',
      'madrid',
      'Madring',
      '',
      'Spain',
      [],
      hasRaceHour: hasTime,
      raceCoverUrl: 'none');

  Future<void> mount(WidgetTester tester, Race item,
      {Brightness brightness = Brightness.dark}) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: buildPitwallTheme(brightness),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!),
      home: Scaffold(
          body: Padding(
              padding: const EdgeInsets.all(16), child: RaceListItem(item, 0))),
    ));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        'Calendar keeps date, circuit, flag and time at 320px in $brightness',
        (tester) async {
      await mount(tester, race(), brightness: brightness);
      expect(find.text('Spain'), findsOneWidget);
      expect(find.text('Madring'), findsOneWidget);
      expect(find.text('13 sept.'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('🇪🇸'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Separate provider date and 12 hour preference remain supported',
      (tester) async {
    await settings.put('shouldUse12HourClock', true);
    await mount(tester, race(date: '2026-09-13'));
    // French locale still uses its normal locale-aware hour representation.
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('13 sept.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Unknown race time is omitted', (tester) async {
    await mount(tester, race(hasTime: false));
    expect(find.text('15:00'), findsNothing);
    expect(find.text('13 sept.'), findsOneWidget);
  });
  test('Flags cover event aliases and do not invent unknown countries', () {
    expect(raceCountryCode('Emilia-Romagna'), 'IT');
    expect(raceCountryCode('Miami'), 'US');
    expect(raceCountryCode('Las Vegas'), 'US');
    expect(raceCountryCode('Azerbaijan'), 'AZ');
    expect(raceCountryCode('unknown'), isNull);
  });
  testWidgets('Tapping a calendar race opens its existing details route',
      (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(body: RaceItem(race(), 0, true))),
      GoRoute(
          path: '/race/:meetingId',
          name: 'racing',
          builder: (_, state) => Text(state.pathParameters['meetingId']!)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spain'));
    await tester.pumpAndSettle();
    expect(find.text('madrid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
