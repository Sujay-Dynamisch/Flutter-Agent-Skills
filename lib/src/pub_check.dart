import 'dart:convert';
import 'dart:io';

/// How risky adding a package is.
enum Verdict {
  /// Looks safe to add.
  ok,

  /// Exists but has warning signs; a human should confirm.
  warn,

  /// Does not exist on pub.dev; likely a hallucinated name.
  block,
}

/// The result of checking one package against pub.dev.
class PackageReport {
  /// Creates a report for [name].
  PackageReport(this.name, this.verdict, this.reasons);

  /// The package name that was checked.
  final String name;

  /// The overall verdict.
  final Verdict verdict;

  /// Human-readable reasons behind the verdict; empty when [Verdict.ok].
  final List<String> reasons;

  @override
  String toString() => reasons.isEmpty
      ? '${verdict.name.padRight(5)}  $name'
      : '${verdict.name.padRight(5)}  $name: ${reasons.join('; ')}';
}

/// Fetches a pub.dev API path (e.g. `packages/http/score`) and returns the
/// decoded JSON, or `null` when the resource does not exist (HTTP 404).
typedef PubFetcher = Future<Map<String, dynamic>?> Function(String path);

/// SDK packages that live in the Flutter SDK rather than on pub.dev.
const sdkPackages = {
  'flutter',
  'flutter_test',
  'flutter_localizations',
  'flutter_driver',
  'flutter_web_plugins',
  'integration_test',
  'sky_engine',
};

/// Checks packages against pub.dev to catch hallucinated or risky names
/// before an AI agent adds them.
class PubChecker {
  /// Creates a checker. [fetch] defaults to live pub.dev requests;
  /// [now] is injectable for tests.
  PubChecker({PubFetcher? fetch, DateTime Function()? now})
      : _fetch = fetch ?? _httpFetch,
        _now = now ?? DateTime.now;

  final PubFetcher _fetch;
  final DateTime Function() _now;

  /// Packages first published within this window are flagged as new.
  static const newPackageAge = Duration(days: 30);

  /// Checks one package. Network errors propagate to the caller.
  Future<PackageReport> check(String name) async {
    if (sdkPackages.contains(name)) return PackageReport(name, Verdict.ok, []);
    final info = await _fetch('packages/$name');
    if (info == null) {
      return PackageReport(name, Verdict.block, [
        'does not exist on pub.dev (possibly a hallucinated name)',
      ]);
    }
    final results = await Future.wait([
      _fetch('packages/$name/options'),
      _fetch('packages/$name/score'),
      _fetch('packages/$name/publisher'),
    ]);
    final options = results[0] ?? const {};
    final score = results[1] ?? const {};
    final publisher = results[2]?['publisherId'] as String?;

    final reasons = <String>[];
    if (options['isDiscontinued'] == true) {
      final by = options['replacedBy'];
      reasons.add('discontinued${by != null ? ', replaced by $by' : ''}');
    }
    if (options['isUnlisted'] == true) reasons.add('unlisted');

    final versions = info['versions'] as List? ?? const [];
    final first = versions.isEmpty
        ? null
        : DateTime.tryParse('${(versions.first as Map)['published']}');
    if (first != null && _now().difference(first) < newPackageAge) {
      reasons
          .add('first published ${_now().difference(first).inDays} days ago');
    }

    final likes = (score['likeCount'] as num?)?.toInt() ?? 0;
    final downloads = (score['downloadCount30Days'] as num?)?.toInt() ?? 0;
    if (publisher == null && likes < 10 && downloads < 1000) {
      reasons.add('unverified publisher with low adoption '
          '($likes likes, $downloads downloads/30d)');
    }
    return PackageReport(
        name, reasons.isEmpty ? Verdict.ok : Verdict.warn, reasons);
  }

  /// Checks several packages concurrently.
  Future<List<PackageReport>> checkAll(Iterable<String> names) =>
      Future.wait(names.toSet().map(check));
}

final _client = HttpClient()
  ..connectionTimeout = const Duration(seconds: 5)
  ..userAgent = 'flutter_agent_skills';

Future<Map<String, dynamic>?> _httpFetch(String path) async {
  final req = await _client
      .getUrl(Uri.parse('https://pub.dev/api/$path'))
      .timeout(const Duration(seconds: 8));
  req.headers.set('accept', 'application/json');
  final res = await req.close().timeout(const Duration(seconds: 8));
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode == 404) return null;
  if (res.statusCode != 200) {
    throw HttpException('pub.dev returned ${res.statusCode} for $path');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

final _pubAdd = RegExp(r'(?:flutter|dart)\s+pub\s+add\s+([^;&|\n]+)');

/// Extracts hosted package names from `flutter pub add` / `dart pub add`
/// invocations in a shell [command]. Commands that add from a path, git or
/// SDK source are skipped because they don't come from pub.dev.
List<String> packagesFromCommand(String command) {
  final names = <String>[];
  for (final m in _pubAdd.allMatches(command)) {
    final args = m.group(1)!.trim().split(RegExp(r'\s+'));
    if (args.any((a) => RegExp(r'^--(path|git|sdk|hosted)').hasMatch(a))) {
      continue;
    }
    for (var a in args) {
      if (a.startsWith('-')) continue;
      a = a.replaceAll(RegExp(r'''^['"]|['"]$'''), '');
      a = a.replaceFirst(RegExp(r'^(dev|override):'), '');
      final name = a.split(':').first;
      if (RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) names.add(name);
    }
  }
  return names;
}

final _depLine = RegExp(r'''^\s+([a-z][a-z0-9_]*):\s*['"]?(\^|>=|<|any\b|\d)''',
    multiLine: true);

/// Extracts dependency names with version constraints from pubspec text
/// (a full file or an edited fragment). Path/git/SDK dependencies are ignored.
List<String> packagesFromPubspecText(String text) => [
      for (final m in _depLine.allMatches(text))
        if (!sdkPackages.contains(m.group(1)) && m.group(1) != 'sdk')
          m.group(1)!,
    ];
