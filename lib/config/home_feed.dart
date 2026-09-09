import 'package:boxbox/api/rss.dart';
import 'package:boxbox/helpers/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Applies the default only to installations without a saved feed preference.
Future<void> initializeHomeFeed(Box settings) async {
  if (!settings.containsKey('homeFeed')) {
    await settings.put('homeFeed', ['https://fr.motorsport.com', 'rss']);
  }
}

class HomeFeedConfiguration {
  final String championship;
  final List feed;
  final String server;
  final String officialServer;

  HomeFeedConfiguration(Box settings)
      : championship = settings.get('championship', defaultValue: 'Formula 1'),
        feed = settings.get('homeFeed',
            defaultValue: ['https://fr.motorsport.com', 'rss']) as List,
        officialServer = Constants().F1_API_URL,
        server = settings.get('server', defaultValue: Constants().F1_API_URL);

  bool get isFormula1 => championship == 'Formula 1';
  bool get usePitwall => isFormula1 && feed[1] == 'rss';

  // Other championships use the existing championship-aware news provider.
  List get effectiveFeed => isFormula1 ? feed : [officialServer, 'api'];

  String get rssUrl => RssFeeds.feedUrl(feed[0] as String,
      proxyServer: server == officialServer ? null : server);

  String get signature => [championship, ...feed, server].toString();
}
