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

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:boxbox/api/services/formula1.dart';
import 'package:boxbox/classes/race.dart';
import 'package:boxbox/helpers/race_flag.dart';
import 'package:boxbox/helpers/racetracks_url.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class RaceItem extends StatelessWidget {
  final Race item;
  final int index;
  final bool isUpNext;

  const RaceItem(this.item, this.index, this.isUpNext, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        'racing',
        pathParameters: {'meetingId': item.meetingId},
      ),
      child: index == 0 && isUpNext && (item.raceCoverUrl ?? '') != 'none'
          ? RaceListHeaderItem(item, index)
          : RaceListItem(item, index),
    );
  }
}

class RaceListHeaderItem extends StatelessWidget {
  final Race item;
  final int index;
  const RaceListHeaderItem(this.item, this.index, {super.key});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.raceCoverUrl ??
        RaceTracksUrls().getRaceCoverImageUrl(item.circuitId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 2,
            child: Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child:
                          const Center(child: Icon(Icons.landscape_outlined)),
                    )),
          ),
        ),
        RaceListItem(item, index),
      ],
    );
  }
}

class RaceListItem extends StatelessWidget {
  final Race item;
  final int index;

  const RaceListItem(this.item, this.index, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Hive.box('settings');
    final use12Hours =
        settings.get('shouldUse12HourClock', defaultValue: false) as bool;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Ergast supplies date and time separately; official providers supply ISO dates.
    final date = DateTime.parse(
            item.date.contains('T') || item.date.contains(' ')
                ? item.date
                : '${item.date} ${item.raceHour}')
        .toLocal();
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5)))),
      child: Row(children: [
        RaceFlag(item.country),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.country,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(item.circuitName,
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
          ],
        )),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(DateFormat.MMMd(locale).format(date),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (item.hasRaceHour ?? true) ...[
            const SizedBox(height: 3),
            Text(
                (use12Hours ? DateFormat.jm(locale) : DateFormat.Hm(locale))
                    .format(date),
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
          ],
        ]),
      ]),
    );
  }
}

class RacesList extends StatelessWidget {
  final List<Race> items;
  final bool isUpNext;
  final ScrollController? scrollController;
  final bool isCache;

  const RacesList(
    this.items,
    this.isUpNext, {
    Key? key,
    this.scrollController,
    this.isCache = false,
  }) : super(key: key);

  int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  // From https://stackoverflow.com/a/58711821
  String formattedTimeZoneOffset(DateTime time) {
    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    final duration = time.timeZoneOffset,
        hours = duration.inHours,
        minutes = duration.inMinutes.remainder(60).abs().toInt();

    return '${hours > 0 ? '+' : '-'}${twoDigits(hours.abs())}:${twoDigits(minutes)}';
  }

  Future<void> scheduledNotification(String meetingId) async {
    List<NotificationModel> notifications =
        await AwesomeNotifications().listScheduledNotifications();
    if (notifications.isNotEmpty &&
        notifications[0].content?.payload?['meetingId'] == meetingId) {
      return;
    }

    RaceDetails race = await Formula1().getCircuitDetails(meetingId);
    for (var session in race.sessions) {
      if (session.startTime.isAfter(DateTime.now())) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: createUniqueId(),
            channelKey: 'eventTracker',
            title: race.meetingCompleteName,
            body: "Be ready! ${session.sessionFullName} is starting soon!",
            payload: {
              'meetingId': meetingId,
              'session': session.sessionAbbreviation,
            },
          ),
          schedule: NotificationCalendar(
            allowWhileIdle: true,
            repeats: false,
            millisecond: 0,
            preciseAlarm: true,
            second: session.startTime.second,
            minute: session.startTime.minute,
            hour: session.startTime.hour,
            day: session.startTime.day,
            month: session.startTime.month,
            timeZone: 'GMT${formattedTimeZoneOffset(DateTime.now())}',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool notificationsEnabled = Hive.box('settings')
        .get('notificationsEnabled', defaultValue: false) as bool;
    if (items.isNotEmpty && isUpNext && !isCache && notificationsEnabled) {
      scheduledNotification(items[0].meetingId);
    }
    return isUpNext
        ? ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: items.length,
            controller: scrollController,
            itemBuilder: (context, index) => isUpNext
                ? RaceItem(
                    items[index],
                    index,
                    isUpNext,
                  )
                : RaceItem(
                    items[items.length - index - 1],
                    index,
                    isUpNext,
                  ),
            physics: const ClampingScrollPhysics(),
            //),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: items.length,
            controller: scrollController,
            itemBuilder: (context, index) => isUpNext
                ? RaceItem(
                    items[index],
                    index,
                    isUpNext,
                  )
                : RaceItem(
                    items[items.length - index - 1],
                    index,
                    isUpNext,
                  ),
            physics: const ClampingScrollPhysics(),
          );
  }
}
