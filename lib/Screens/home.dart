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

import 'package:boxbox/Screens/MixedNews/rss_feed.dart';
import 'package:boxbox/Screens/MixedNews/rss_feed_article.dart';
import 'package:boxbox/api/rss.dart';
import 'package:boxbox/classes/event_tracker.dart';
import 'package:boxbox/helpers/news_feed_widget.dart';
import 'package:boxbox/l10n/app_localizations.dart';
import 'package:boxbox/providers/event_tracker/requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:webfeed/webfeed.dart';

const pitwallCoral = Color(0xFFFF7B68);
const pitwallBackground = Color(0xFF101719);
const pitwallSurface = Color(0xFF1B2529);
const pitwallMuted = Color(0xFFACBAC5);

class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;
  const HomeScreen(this.scrollController, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Event> _event;
  late Future<Map<String, dynamic>> _news;
  late String _feedUrl;
  String _selection = "";

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selection = Hive.box('settings').get('homeFeed',
        defaultValue: ['https://fr.motorsport.com', 'rss']).toString();
    if (selection != _selection) _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final feed = Hive.box('settings').get('homeFeed',
        defaultValue: ['https://fr.motorsport.com', 'rss']) as List;
    _selection = feed.toString();
    _feedUrl = RssFeeds.feedUrl(feed[0] as String);
    if (feed[1] != 'rss') return;
    _event = EventTrackerRequestsProvider()
        .parseEvent()
        .timeout(const Duration(seconds: 20));
    _news = RssFeeds().getFeedArticles(_feedUrl);
    // The news section may not be mounted until it scrolls into view.
    _news.then<void>((_) {}, onError: (Object _) {});
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([
      _event.then<void>((_) {}, onError: (Object _) {}),
      _news.then<void>((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final feed = Hive.box('settings').get('homeFeed',
        defaultValue: ['https://fr.motorsport.com', 'rss']) as List;
    if (feed[1] != 'rss') {
      return NewsFeed(scrollController: widget.scrollController);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: pitwallCoral,
      child: ListView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          FutureBuilder<Event>(
            future: _event,
            builder: (context, snapshot) {
              if (snapshot.hasData) return PitwallWeekendCard(snapshot.data!);
              if (snapshot.hasError) {
                return _message(l.pitwallScheduleUnavailable);
              }
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          const SizedBox(height: 26),
          Row(children: [
            Expanded(
                child: Text(l.pitwallNews,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w700))),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RssFeedScreen(l.news, _feedUrl))),
              child: Text(l.pitwallSeeAll),
            ),
          ]),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _news,
            builder: (context, snapshot) {
              if (snapshot.hasError) return _message(l.pitwallNewsUnavailable);
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data!['feedArticles'] as List<RssItem>;
              if (items.isEmpty) return _message(l.pitwallNewsUnavailable);
              return Column(
                  children: items
                      .take(12)
                      .map((item) => _article(item,
                          snapshot.data!['feedTitle'] as String? ?? l.news))
                      .toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _message(String message) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: pitwallSurface, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.pitwallRetry)),
        ]),
      );

  Widget _article(RssItem item, String source) {
    final image = item.enclosure?.url ??
        (item.media?.thumbnails?.isNotEmpty == true
            ? item.media!.thumbnails!.first.url
            : null) ??
        (item.media?.contents?.isNotEmpty == true
            ? item.media!.contents!.first.url
            : null);
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (Uri.parse(_feedUrl).host == 'fr.motorsport.com')
      source = 'Motorsport France';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.link == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    RssFeedArticleScreen(item.title ?? '', item.link!))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
                width: 112,
                height: 112,
                child: image == null
                    ? _imageFallback()
                    : Image.network(image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback())),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(AppLocalizations.of(context)!.pitwallCategory,
                    style: const TextStyle(
                        color: pitwallCoral,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(item.title ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: pitwallMuted, fontSize: 12)),
                if (item.pubDate != null)
                  Text(
                      DateFormat.MMMd(locale)
                          .add_Hm()
                          .format(item.pubDate!.toLocal()),
                      style:
                          const TextStyle(color: pitwallMuted, fontSize: 12)),
              ])),
        ]),
      ),
    );
  }

  Widget _imageFallback() => const ColoredBox(
      color: pitwallSurface,
      child: Center(child: Icon(Icons.newspaper, color: pitwallMuted)));
}

class PitwallWeekendCard extends StatelessWidget {
  final Event event;
  const PitwallWeekendCard(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final sessions = [...event.sessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final now = DateTime.now();
    final live = sessions
        .any((s) => !now.isBefore(s.startTime) && now.isBefore(s.endTime));
    final ended = sessions.isNotEmpty && now.isAfter(sessions.last.endTime);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF202D32), pitwallSurface]),
        border: Border.all(color: const Color(0xFF2A373C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sports_motorsports, color: pitwallCoral, size: 28),
          const SizedBox(width: 10),
          Expanded(
              child: Text(l.pitwallWeekend,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: live ? pitwallCoral : const Color(0xFF354249),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
                live
                    ? l.sessionRunning
                    : ended
                        ? l.pitwallFinished
                        : l.pitwallUpcoming,
                style: TextStyle(
                    fontSize: 12,
                    color: live ? pitwallBackground : Colors.white))),
        const SizedBox(height: 14),
        Text(event.meetingOfficialName,
            style: const TextStyle(
                color: pitwallMuted, fontSize: 11, letterSpacing: 1.3)),
        const SizedBox(height: 5),
        Text(event.meetingCountryName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        if (sessions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${DateFormat.MMMd(locale).format(sessions.first.startTime.toLocal())} – ${DateFormat.yMMMd(locale).format(sessions.last.startTime.toLocal())}',
              style: const TextStyle(color: pitwallMuted, fontSize: 13),
            ),
          ),
        if (event.circuitImage.isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1,
                    0,
                    0,
                    0,
                    255,
                    0,
                    -1,
                    0,
                    0,
                    255,
                    0,
                    0,
                    -1,
                    0,
                    255,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Image.network(event.circuitImage,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
        const SizedBox(height: 8),
        for (final session in sessions) ...[
          const Divider(color: Color(0xFF354249), height: 1),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(children: [
                SizedBox(
                    width: 34,
                    child: Text(session.sessionAbbreviation.toUpperCase(),
                        style: const TextStyle(
                            color: pitwallCoral, fontWeight: FontWeight.w700))),
                Expanded(
                    child: Text(_sessionName(session, l),
                        style: const TextStyle(fontSize: 14))),
                const SizedBox(width: 8),
                Text(
                    DateFormat.E(locale)
                        .add_Hm()
                        .format(session.startTime.toLocal()),
                    style: const TextStyle(color: pitwallMuted, fontSize: 13)),
              ])),
        ],
        if (sessions.isEmpty) Text(l.pitwallScheduleUnavailable),
        const SizedBox(height: 10),
        Text(l.pitwallLocalTime,
            style: const TextStyle(color: pitwallMuted, fontSize: 11)),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: () =>
                    context.pushNamed('race-hub', extra: {'event': event}),
                style: FilledButton.styleFrom(
                    backgroundColor: pitwallCoral,
                    foregroundColor: pitwallBackground,
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.sports_score),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(l.pitwallRaceCenter,
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ]))),
      ]),
    );
  }

  String _sessionName(Session session, AppLocalizations l) {
    switch (session.sessionAbbreviation.toLowerCase()) {
      case 'p1':
        return l.freePracticeOne;
      case 'p2':
        return l.freePracticeTwo;
      case 'p3':
        return l.freePracticeThree;
      case 'q':
        return l.qualifyings;
      case 'r':
        return l.race;
      case 's':
        return l.sprint;
      case 'ss':
        return l.sprintQualifyings;
      default:
        return session.sessionFullName ??
            session.sessionAbbreviation.toUpperCase();
    }
  }
}
