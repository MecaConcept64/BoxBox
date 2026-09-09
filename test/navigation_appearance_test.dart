import 'package:boxbox/helpers/bottom_navigation_bar.dart';
import 'package:boxbox/helpers/constants.dart';
import 'package:boxbox/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Box settings;

  Future<void> prepare(WidgetTester tester) async {
    settings = await Hive.openBox('settings', bytes: Uint8List(0));
    await Hive.openBox('requests', bytes: Uint8List(0));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/connectivity'),
            (_) async => ['wifi']);
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await Hive.close();
  }

  Future<void> mount(WidgetTester tester, ThemeMode mode) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: mode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainBottomNavigationBar(),
    ));
    await tester.pump(const Duration(milliseconds: 100));
  }

  void expectShell(WidgetTester tester, Brightness brightness) {
    for (final type in [AppBar, NavigationBar]) {
      final element = tester.element(find.byType(type).first);
      expect(Theme.of(element).brightness, brightness);
    }
    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffold).brightness, brightness);
    if (brightness == Brightness.light) {
      expect(tester.widget<AppBar>(find.byType(AppBar).first).backgroundColor,
          isNull);
      expect(tester.widget<AppBar>(find.byType(AppBar).first).foregroundColor,
          isNull);
    }
  }

  for (final mode in [ThemeMode.light, ThemeMode.system, ThemeMode.dark]) {
    testWidgets('Classic F1 feed respects $mode throughout the shell',
        (tester) async {
      await prepare(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await settings.put('homeFeed', [Constants().F1_API_URL, 'api']);
      await mount(tester, mode);
      expectShell(
          tester, mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
      expect(find.text('P I T W A L L'), findsNothing);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
  }

  testWidgets('Another championship keeps the selected light appearance',
      (tester) async {
    await prepare(tester);
    await settings.put('championship', 'Formula 2');
    await settings.put('homeFeed', ['https://fr.motorsport.com', 'rss']);
    await mount(tester, ThemeMode.light);
    expectShell(tester, Brightness.light);
    expect(find.text('P I T W A L L'), findsNothing);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });

  testWidgets(
      'Leaving Pitwall restores light appearance and returning restores Pitwall',
      (tester) async {
    await prepare(tester);
    await settings.put('homeFeed', ['https://fr.motorsport.com', 'rss']);
    await mount(tester, ThemeMode.light);
    expectShell(tester, Brightness.dark);
    expect(find.text('P I T W A L L'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pump(const Duration(milliseconds: 400));
    expectShell(tester, Brightness.light);
    expect(find.text('P I T W A L L'), findsNothing);
    await tester.tap(find.byType(NavigationDestination).first);
    await tester.pump(const Duration(milliseconds: 400));
    expectShell(tester, Brightness.dark);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
}
