import 'dart:io';
import 'package:boxbox/api/team_results.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String fixture(String name) =>
    File('test/fixtures/f1_results/$name.html').readAsStringSync();
void main() {
  test('official race preserves names, retirement, laps, points and race URL',
      () {
    final results = parseOfficialRaceResults(fixture('race'),
        '/en/results/2026/races/1293/italy/race-result', 'Italy');
    final ferrari =
        results.where((driver) => driver.team == 'Ferrari').toList();
    expect(ferrari.length, 2);
    final hamilton = ferrari.firstWhere((d) => d.code == 'HAM');
    expect(hamilton.familyName, 'Hamilton');
    expect(hamilton.givenName, 'Lewis');
    expect(hamilton.driverId, 'lewis-hamilton');
    expect(hamilton.position, '6');
    expect(hamilton.points, '8');
    expect(hamilton.lapsDone, '53');
    expect(hamilton.gap, '+24.655s');
    expect(hamilton.teamColor, 'e8002d');
    expect(ferrari.firstWhere((d) => d.code == 'LEC').sessionTime, 'DNF');
  });

  test('loads every race from official URLs and filters the selected team',
      () async {
    final urls = <Uri>[];
    final api = TeamResultsApi(client: MockClient((request) async {
      urls.add(request.url);
      final path = request.url.path;
      final file = path.endsWith('/team')
          ? 'teams'
          : path.endsWith('/Ferrari')
              ? 'team-results'
              : 'race';
      return http.Response(fixture(file), 200,
          headers: {'content-type': 'text/html; charset=utf-8'});
    }));
    addTearDown(api.close);
    final results = await api.getTeamResults('Ferrari', year: 2026);
    expect(results.length, 13);
    expect(
        results.every((race) =>
            race.length == 2 && race.every((d) => d.team == 'Ferrari')),
        isTrue);
    expect(results.last.first.raceName, 'Italy');
    expect(urls.every((url) => url.host == 'www.formula1.com'), isTrue);
    expect(urls.last.path, '/en/results/2026/races/1293/italy/race-result');
  });

  test('uses the published engine-qualified team URL', () async {
    final paths = <String>[];
    final api = TeamResultsApi(client: MockClient((request) async {
      paths.add(request.url.path);
      return http.Response(
          paths.length == 1
              ? fixture('teams')
              : '<table><tbody></tbody></table>',
          200);
    }));
    addTearDown(api.close);
    expect(await api.getTeamResults('Red Bull Racing', year: 2026), isEmpty);
    expect(paths.last, '/en/results/2026/team/Red-Bull-Racing-Red-Bull-Ford');
  });

  test('HTTP and non-table errors are reported without JSON decoding',
      () async {
    for (final status in [404, 200]) {
      final api = TeamResultsApi(
          client: MockClient(
              (_) async => http.Response('<html>Unavailable</html>', status)));
      addTearDown(api.close);
      await expectLater(
          api.getTeamResults('Ferrari'), throwsA(isA<http.ClientException>()));
    }
  });

  test('ignores incomplete rows', () {
    expect(
        parseOfficialRaceResults(
            '<table><tbody><tr><td>Pending</td></tr></tbody></table>',
            '/race',
            'Race'),
        isEmpty);
  });
}
