/*
 *  This file is part of BoxBox (https://github.com/BrightDV/BoxBox).
 * 
 * BoxBox is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BoxBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BoxBox.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2022-2025, BrightDV
 */

import 'package:boxbox/Screens/schedule.dart';
import 'package:boxbox/theme/pitwall_theme.dart';
import 'package:boxbox/config/home_feed.dart';
import 'package:go_router/go_router.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:boxbox/helpers/drawer.dart';
import 'package:boxbox/providers/general/ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:boxbox/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({Key? key}) : super(key: key);

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _selectedIndex = 0;
  final ScrollController scrollController = ScrollController();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _homeSetState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int themeMode =
        Hive.box('settings').get('themeMode', defaultValue: 0) as int;

    final Brightness brightnessValue =
        MediaQuery.of(context).platformBrightness;
    bool isDark = brightnessValue == Brightness.dark;
    themeMode == 0
        ? Hive.box('settings').put('darkMode', isDark)
        : themeMode == 1
            ? Hive.box('settings').put('darkMode', false)
            : Hive.box('settings').put('darkMode', true);
    if (!kIsWeb) {
      FileDownloader().configureNotification(
        running: TaskNotification(
          AppLocalizations.of(context)!.downloadRunning,
          '{displayName}',
        ),
        complete: TaskNotification(
          AppLocalizations.of(context)!.downloadComplete,
          '{displayName}',
        ),
        error: TaskNotification(
          AppLocalizations.of(context)!.downloadFailed,
          '{displayName}',
        ),
        paused: TaskNotification(
          AppLocalizations.of(context)!.downloadPaused,
          '{displayName}',
        ),
        progressBar: true,
      );
    }

    List<Widget> screens =
        UIProvider().getBottomNavigationBarScreens(scrollController);
    bool disableBottomNavigationBarLabels = Hive.box('settings')
        .get('disableBottomNavigationBarLabels', defaultValue: false) as bool;

    final usePitwall = (_selectedIndex == 0 &&
            HomeFeedConfiguration(Hive.box('settings')).usePitwall) ||
        screens.elementAt(_selectedIndex) is ScheduleScreen;
    final activeTheme = Theme.of(context);
    final pitwallTheme = buildPitwallTheme(activeTheme.brightness);
    return Theme(
        data: usePitwall ? pitwallTheme : activeTheme,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            toolbarHeight: 76,
            titleSpacing: 0,
            title: usePitwall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: 'BoxBox',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 27)),
                          TextSpan(
                              text: ' ///',
                              style: TextStyle(
                                  color: pitwallTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 27)),
                        ])),
                        Text('P I T W A L L',
                            style: TextStyle(
                                fontSize: 10,
                                color:
                                    pitwallTheme.colorScheme.onSurfaceVariant,
                                letterSpacing: 2)),
                      ])
                : const Text('BoxBox',
                    style: TextStyle(fontWeight: FontWeight.w700)),
            foregroundColor:
                usePitwall ? pitwallTheme.colorScheme.onSurface : null,
            actions: [
              IconButton(
                tooltip: AppLocalizations.of(context)!.settings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context
                    .pushNamed('settings', extra: {'update': _homeSetState}),
              )
            ],
            backgroundColor:
                usePitwall ? pitwallTheme.scaffoldBackgroundColor : null,
            surfaceTintColor: Colors.transparent,
          ),
          drawer: MainDrawer(_homeSetState),
          drawerEdgeDragWidth: MediaQuery.of(context).size.width / 4,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            elevation: 0.0,
            destinations: UIProvider().getBottomNavigationBarButtons(context),
            onDestinationSelected: _onItemTapped,
            labelBehavior: disableBottomNavigationBarLabels
                ? NavigationDestinationLabelBehavior.alwaysHide
                : NavigationDestinationLabelBehavior.alwaysShow,
          ),
          body: screens.elementAt(_selectedIndex),
        ));
  }
}
