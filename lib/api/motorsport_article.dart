import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

class ReaderBlock {
  final String text;
  final String? imageUrl;
  final bool heading;
  const ReaderBlock(this.text, {this.imageUrl, this.heading = false});
}

class MotorsportArticle {
  final String title;
  final String description;
  final String? imageUrl;
  final String author;
  final DateTime? published;
  final List<ReaderBlock> blocks;
  const MotorsportArticle(
      {required this.title,
      required this.description,
      this.imageUrl,
      required this.author,
      this.published,
      required this.blocks});

  static bool supports(String url) {
    final uri = Uri.tryParse(url);
    return uri?.scheme == 'https' &&
        uri?.host == 'fr.motorsport.com' &&
        uri!.path.startsWith('/f1/news/');
  }

  static Future<MotorsportArticle> fetch(String url) async {
    if (!supports(url)) throw const FormatException('Unsupported source');
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200)
      throw const FormatException('Article unavailable');
    return parse(utf8.decode(response.bodyBytes), url);
  }

  static MotorsportArticle parse(String source, String url) {
    final document = html.parse(source);
    String meta(String key) =>
        document
            .querySelector('meta[property="$key"], meta[name="$key"]')
            ?.attributes['content']
            ?.trim() ??
        '';
    Map<String, dynamic> metadata = {};
    for (final script
        in document.querySelectorAll('script[type="application/ld+json"]')) {
      try {
        final value = jsonDecode(script.text);
        if (value is Map<String, dynamic> && value['@type'] == 'NewsArticle')
          metadata = value;
      } on FormatException {/* Other structured data is optional. */}
    }
    if (metadata['isAccessibleForFree'] == false ||
        metadata['isAccessibleForFree'] == 'false') {
      throw const FormatException('Subscriber article');
    }
    final body = document.querySelector('.ms-article-content');
    if (body == null) throw const FormatException('Missing article body');
    for (final unwanted in body.querySelectorAll(
        '.relatedContent, .ms-apb, script, style, [hidden]')) {
      unwanted.remove();
    }
    String? image(String? value) {
      if (value == null || value.isEmpty) return null;
      final uri = Uri.parse(url).resolve(value);
      return uri.scheme == 'https' ? uri.toString() : null;
    }

    final blocks = <ReaderBlock>[];
    for (final element
        in body.querySelectorAll('p, h2, h3, section[data-widget="image"]')) {
      if (element.localName == 'section') {
        final src = image(element.attributes['data-src']);
        if (src != null)
          blocks.add(ReaderBlock(
              [
                element.attributes['data-title'],
                element.attributes['data-author']
              ].whereType<String>().where((s) => s.isNotEmpty).join(' — '),
              imageUrl: src));
      } else if (element.text.trim().isNotEmpty) {
        blocks.add(ReaderBlock(element.text.trim(),
            heading: element.localName != 'p'));
      }
    }
    if (blocks.where((b) => b.imageUrl == null).length < 2 ||
        meta('og:title').isEmpty) {
      throw const FormatException('Incomplete article');
    }
    final authorData = metadata['author'];
    final author =
        authorData is Map ? authorData['name']?.toString() ?? '' : '';
    return MotorsportArticle(
        title: meta('og:title'),
        description: meta('og:description'),
        imageUrl: image(meta('og:image')),
        author: html.parseFragment(author).text ?? '',
        published: DateTime.tryParse(meta('datePublished')),
        blocks: blocks);
  }
}
