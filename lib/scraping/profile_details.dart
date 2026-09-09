import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

/// Profile values are matched by label: season and career grids can change
/// independently, so their DOM position must never determine the displayed stat.
Map<String, String> _statistics(Document document) {
  final values = <String, String>{};
  for (final label in document.querySelectorAll('dt')) {
    final value = label.nextElementSibling;
    if (value?.localName == 'dd') {
      values[label.text.trim().toLowerCase()] = value!.text.trim();
    }
  }
  return values;
}

List<String> _values(Document document, List<String> labels) {
  final statistics = _statistics(document);
  return labels.map((label) => statistics[label] ?? '—').toList();
}

String _name(Document document) {
  final heading = document.querySelector('h1');
  if (heading == null) throw const FormatException('F1 profile unavailable');
  return heading.children.isEmpty
      ? heading.text.trim()
      : heading.children.map((child) => child.text.trim()).join(' ');
}

List<String> _gallery(Document document, String section) => document
    .querySelectorAll(
        '$section figure img, dialog img, .f1-carousel__slide img')
    .map((image) => image.attributes['src'] ?? '')
    .where((url) => url.isNotEmpty)
    .toSet()
    .toList();

List<List<String>> _articles(Document document) {
  final articles = <List<String>>[];
  for (final card in document.querySelectorAll(
    '[class*="ArticleListCard-module_articlecard"], .f1-driver-article-card',
  )) {
    final link = card.querySelector('a[href*="/article/"]') ??
        card.querySelector('a[href]');
    final href = link?.attributes['href'] ?? card.attributes['href'];
    final image = card.querySelector('img')?.attributes['src'];
    final title =
        card.querySelector('[class*="ArticleListCard-module_title"]')?.text ??
            link?.text;
    if (href != null &&
        image != null &&
        title != null &&
        title.trim().isNotEmpty) {
      articles.add([href.split('.').last, image, title.trim(), '']);
    }
  }
  return articles;
}

List<List> parseDriverProfile(String html) {
  final document = parser.parse(html);
  final name = _name(document);
  return [
    _values(document, const [
      'grands prix entered',
      'career points',
      'highest race finish',
      'podiums',
      'highest grid position',
      'pole positions',
      'world championships',
      'dnfs',
    ]),
    _articles(document),
    document
        .querySelectorAll('#biography p')
        .map((p) => p.text.trim())
        .where((p) => p.isNotEmpty)
        .toList(),
    [_gallery(document, '#biography'), <String>[]],
    [name],
  ];
}

Map<String, dynamic> parseTeamProfile(String html) {
  final document = parser.parse(html);
  final name = _name(document);
  final images = <String>[];
  final names = <List<String>>[];
  for (final card
      in document.querySelectorAll('#drivers a[href*="/drivers/"]')) {
    final parts = card.querySelectorAll('p').map((p) => p.text.trim()).toList();
    if (parts.length < 2) continue;
    images.add(card.querySelector('img')?.attributes['src'] ?? '');
    names.add(['', parts.first, parts[1]]);
  }
  return {
    'teamName': name,
    'drivers': {'images': images, 'names': names},
    'teamStats': _values(document, const [
      'full team name',
      'base',
      'team chief',
      'technical chief',
      'chassis',
      'power unit',
      'first team entry',
      'world championships',
      'highest race finish',
      'pole positions',
      'fastest laps',
    ]),
    'information': document
        .querySelectorAll('#profile p, .f1-driver-bio p')
        .map((p) => p.text.trim())
        .where((p) => p.isNotEmpty)
        .toList(),
    'medias': _gallery(document, '#profile'),
    'articles': _articles(document),
  };
}
