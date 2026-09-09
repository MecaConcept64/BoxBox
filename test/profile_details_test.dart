import 'package:boxbox/scraping/profile_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driver stats use labels, not season grid order or CSS classes', () {
    final profile = parseDriverProfile('''
      <h1><span>Charles</span><span>Leclerc</span></h1>
      <dl><div><dt>Season Points</dt><dd>155</dd></div></dl>
      <dl><div><dt>World Championships</dt><dd>0</dd></div>
      <div><dt>Career Points</dt><dd>1827</dd></div>
      <div><dt>New statistic</dt><dd>999</dd></div>
      <div><dt>Grands Prix Entered</dt><dd>184</dd></div></dl>
      <div id="biography"><p>First paragraph.</p><p>Last paragraph.</p></div>
    ''');
    expect(profile[0], ['184', '1827', '—', '—', '—', '—', '0', '—']);
    expect(profile[2], ['First paragraph.', 'Last paragraph.']);
    expect(profile[3][0], isEmpty);
    expect(profile[4], ['Charles Leclerc']);
  });

  test('team supports a single driver and partial profile', () {
    final profile = parseTeamProfile('''
      <h1>Ferrari</h1>
      <div id="drivers"><a href="/en/drivers/charles-leclerc">
        <p>Charles</p><p>Leclerc</p><p>Ferrari</p>
      </a><a href="/en/drivers/incomplete"></a></div>
      <dl><div><dt>Full Team Name</dt><dd>Scuderia Ferrari HP</dd></div>
      <div><dt>Reserve Driver</dt><dd>Antonio Giovinazzi</dd></div>
      <div><dt>First Team Entry</dt><dd>1950</dd></div></dl>
      <div id="profile"><p>Team history.</p></div>
    ''');
    expect(profile['drivers']['names'], [
      ['', 'Charles', 'Leclerc']
    ]);
    expect(profile['drivers']['images'], ['']);
    expect(profile['teamStats'].length, 11);
    expect(profile['teamStats'][6], '1950');
    expect(profile['teamStats'][7], '—');
    expect(profile['information'], ['Team history.']);
    expect(profile['medias'], isEmpty);
  });

  test('empty optional sections and malformed articles are safe', () {
    const html =
        '<h1>Profile</h1><li class="ArticleListCard-module_articlecard">'
        '<a href="/en/latest/article/example.id">Title</a></li>';
    expect(parseDriverProfile(html)[1], isEmpty);
    expect(parseTeamProfile(html)['drivers']['names'], isEmpty);
  });

  test('legacy self-linking cards retain titles and article IDs', () {
    const html = '''<h1>Ferrari</h1>
      <a class="f1-driver-article-card" href="/en/latest/article/report.legacy-id">
        <img src="https://example.com/article.jpg">
        <div><span>News</span><h3>Legacy article title</h3></div>
      </a>
      <a class="f1-driver-article-card" href="/en/latest/article/other.other-id">
        <img src="https://example.com/other.jpg"><div>Other title</div>
      </a>
    ''';
    final articles = parseTeamProfile(html)['articles'];
    expect(articles, [
      [
        'legacy-id',
        'https://example.com/article.jpg',
        'Legacy article title',
        ''
      ],
      ['other-id', 'https://example.com/other.jpg', 'Other title', ''],
    ]);
    expect(parseDriverProfile(html)[1], articles);
  });

  test('non-profile responses produce a controlled error, not a RangeError',
      () {
    expect(() => parseDriverProfile(''), throwsFormatException);
    expect(() => parseTeamProfile('<html></html>'), throwsFormatException);
  });
}
