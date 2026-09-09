import 'dart:io';

import 'package:boxbox/config/home_feed.dart';
import 'package:boxbox/helpers/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory directory;
  late Box settings;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('boxbox-feed-test-');
    Hive.init(directory.path);
    settings = await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('A fresh installation receives the French feed', () async {
    await initializeHomeFeed(settings);
    expect(settings.get('homeFeed'), ['https://fr.motorsport.com', 'rss']);
  });

  for (final feed in [
    [Constants().F1_API_URL, 'api'],
    ['https://example.com/feed.xml', 'rss'],
    ['https://example.com', 'wp'],
  ]) {
    test('Upgrade and repeated startup preserve ${feed[1]} preference',
        () async {
      await settings.put('homeFeed', feed);
      await initializeHomeFeed(settings);
      await initializeHomeFeed(settings);
      expect(settings.get('homeFeed'), feed);
    });
  }

  test('A feed changed after the first launch is preserved', () async {
    await initializeHomeFeed(settings);
    await settings.put('pitwallFeedInitialized', true);
    await settings.put('homeFeed', ['https://example.com/custom', 'rss']);
    await initializeHomeFeed(settings);
    expect(settings.get('homeFeed'), ['https://example.com/custom', 'rss']);
  });

  test('Changing championships selects their news provider and reloads F1',
      () async {
    await initializeHomeFeed(settings);
    final f1 = HomeFeedConfiguration(settings);
    expect(f1.usePitwall, isTrue);
    for (final championship in [
      'Formula E',
      'Formula 2',
      'Formula 3',
      'F1 Academy'
    ]) {
      await settings.put('championship', championship);
      final other = HomeFeedConfiguration(settings);
      expect(other.usePitwall, isFalse);
      expect(other.effectiveFeed, [Constants().F1_API_URL, 'api']);
      expect(other.signature, isNot(f1.signature));
    }
    await settings.put('championship', 'Formula 1');
    expect(HomeFeedConfiguration(settings).signature, f1.signature);
    expect(HomeFeedConfiguration(settings).usePitwall, isTrue);
  });

  test(
      'Custom proxy handles base and full Motorsport URLs and invalidates loading',
      () async {
    await initializeHomeFeed(settings);
    final direct = HomeFeedConfiguration(settings);
    expect(direct.rssUrl, 'https://fr.motorsport.com/rss/f1/news/');
    await settings.put('server', 'https://proxy.example/api/');
    final proxy = HomeFeedConfiguration(settings);
    expect(proxy.rssUrl, 'https://proxy.example/api/rss/fr');
    expect(proxy.signature, isNot(direct.signature));
    await settings
        .put('homeFeed', ['https://fr.motorsport.com/rss/f1/news/', 'rss']);
    expect(HomeFeedConfiguration(settings).rssUrl, proxy.rssUrl);
    await settings.put('homeFeed', ['https://de.motorsport.com', 'rss']);
    expect(HomeFeedConfiguration(settings).rssUrl,
        'https://proxy.example/api/rss/de');
    await settings.put('homeFeed', ['https://example.com/feed.xml', 'rss']);
    expect(
        HomeFeedConfiguration(settings).rssUrl, 'https://example.com/feed.xml');
  });
}
