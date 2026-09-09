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

import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

class RssFeeds {
  static String feedUrl(String source, {String? proxyServer}) {
    final uri = Uri.parse(source);
    final motorsport =
        uri.host == 'motorsport.com' || uri.host.endsWith('.motorsport.com');
    if (!motorsport) return source;
    if (proxyServer != null) {
      final base = proxyServer.replaceFirst(RegExp(r'/+$'), '');
      return '$base/rss/${uri.host.split('.').first}';
    }
    return uri.path.isEmpty || uri.path == '/'
        ? uri.replace(path: '/rss/f1/news/').toString()
        : source;
  }

  Future<Map<String, dynamic>> getFeedArticles(String feedUrl,
      {int? max}) async {
    var url = Uri.parse(feedUrl);
    var response = await http.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('RSS HTTP ${response.statusCode}');
    }
    RssFeed rssFeed = RssFeed.parse(response.body);
    List<RssItem> rssItems = rssFeed.items ?? <RssItem>[];
    if (max != null) {
      rssItems = rssItems.take(max).toList();
    }
    Map<String, dynamic> resultsFormated = {
      'feedTitle': rssFeed.title,
      'feedArticles': rssItems,
    };

    return resultsFormated;
  }
}
