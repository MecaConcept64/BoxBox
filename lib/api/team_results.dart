import 'dart:convert';
import 'package:boxbox/classes/driver.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

// Keep constructor IDs and profile slugs independent of display sponsors.
String _teamIdentity(String name) {
  final key = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  const aliases = {
    'haas': 'haasf1team',
    'haasferrari': 'haasf1team',
    'redbull': 'redbullracing',
    'rb': 'racingbulls',
    'sauber': 'kicksauber',
  };
  return aliases[key] ?? key;
}

/// Official season pages provide the current team and race URLs, including
/// renamed teams and new circuits, without hard-coded season identifiers.
class TeamResultsApi {
  final http.Client client;
  final Uri baseUrl;
  TeamResultsApi({http.Client? client, Uri? baseUrl})
      : client = client ?? http.Client(),
        baseUrl = baseUrl ?? Uri.parse('https://www.formula1.com');

  Future<String> _get(String path) async {
    final url =
        Uri.parse('${baseUrl.toString().replaceFirst(RegExp(r"/$"), "")}$path');
    final response = await client.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw http.ClientException(
          'F1 results: HTTP ${response.statusCode}', url);
    }
    final html = utf8.decode(response.bodyBytes);
    if (parser.parse(html).querySelector('table') == null) {
      throw http.ClientException('F1 results unavailable', url);
    }
    return html;
  }

  Future<List<List<DriverResult>>> getTeamResults(String team,
      {int? year, String? teamId}) async {
    final season = year ?? DateTime.now().year;
    final document = parser.parse(await _get('/en/results/$season/team'));
    final links = document.querySelectorAll('table a[href*="/team/"]');
    final identities = {
      _teamIdentity(team),
      if (teamId != null && teamId.isNotEmpty) _teamIdentity(teamId),
    };
    final matches = links.where((link) =>
        identities.contains(_teamIdentity(link.text)) ||
        identities.contains(_teamIdentity(
          Uri.parse(link.attributes['href']!).pathSegments.last,
        )));
    if (matches.isEmpty)
      throw http.ClientException('F1 team unavailable: $team');
    final teamName = matches.first.text.trim();
    final seasonPage =
        parser.parse(await _get(matches.first.attributes['href']!));
    final races = seasonPage.querySelectorAll('table a[href*="/race-result"]');
    final results = <List<DriverResult>>[];
    // Bound concurrency and preserve calendar order.
    for (var start = 0; start < races.length; start += 4) {
      final batch = races.skip(start).take(4);
      results.addAll(await Future.wait(batch.map((race) async {
        final path = race.attributes['href']!;
        for (final svg in race.querySelectorAll('svg')) {
          svg.remove();
        }
        final entries = await getRaceResults(path, race.text.trim());
        return entries
            .where(
                (entry) => _teamIdentity(entry.team) == _teamIdentity(teamName))
            .toList();
      })));
    }
    return results.where((race) => race.isNotEmpty).toList();
  }

  Future<List<DriverResult>> getRaceResults(String path, String name) async =>
      parseOfficialRaceResults(await _get(path), path, name);

  void close() => client.close();
}

List<DriverResult> parseOfficialRaceResults(
    String html, String path, String raceName) {
  final results = <DriverResult>[];
  for (final row in parser.parse(html).querySelectorAll('table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 7) continue;
    final givenName =
        cells[2].querySelector('[class="max-lg:hidden"]')?.text.trim() ?? '';
    final familyName =
        cells[2].querySelector('[class="max-md:hidden"]')?.text.trim() ?? '';
    final code = cells[2].querySelector('[class="md:hidden"]')?.text.trim() ??
        familyName;
    final color = RegExp(r'#[0-9a-fA-F]{6}')
        .firstMatch(
            cells[3].querySelector('[style]')?.attributes['style'] ?? '')
        ?.group(0)
        ?.substring(1);
    final driverSlug =
        '$givenName-$familyName'.toLowerCase().replaceAll(' ', '-');
    results.add(DriverResult(
      driverSlug,
      cells[0].text.trim(),
      cells[1].text.trim(),
      givenName,
      familyName,
      code,
      cells[3].text.trim(),
      cells[5].text.trim(),
      cells[5].text.trim(),
      false,
      '',
      '',
      lapsDone: cells[4].text.trim(),
      points: cells[6].text.trim(),
      raceId: path,
      raceName: raceName,
      status: cells[5].text.trim(),
      teamColor: color,
    ));
  }
  return results;
}
