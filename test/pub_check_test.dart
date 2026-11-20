import 'dart:convert';

import 'package:flutter_agent_skills/flutter_agent_skills.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 20);

/// Fake pub.dev with three packages: a popular one, a brand-new unverified
/// one, and a discontinued one.
Future<Map<String, dynamic>?> _fakePub(String path) async {
  const db = {
    'http': (
      published: '2012-11-30T00:00:00Z',
      publisher: 'dart.dev',
      likes: 8000,
      dl: 15000000,
      disc: false
    ),
    'shiny_new': (
      published: '2026-11-15T00:00:00Z',
      publisher: null,
      likes: 0,
      dl: 12,
      disc: false
    ),
    'old_pkg': (
      published: '2019-01-01T00:00:00Z',
      publisher: 'x.dev',
      likes: 500,
      dl: 50000,
      disc: true
    ),
  };
  final parts = path.split('/');
  final pkg = db[parts[1]];
  if (pkg == null) return null;
  switch (parts.length == 3 ? parts[2] : '') {
    case 'options':
      return {
        'isDiscontinued': pkg.disc,
        'replacedBy': pkg.disc ? 'new_pkg' : null,
        'isUnlisted': false
      };
    case 'score':
      return {'likeCount': pkg.likes, 'downloadCount30Days': pkg.dl};
    case 'publisher':
      return {'publisherId': pkg.publisher};
    default:
      return {
        'versions': [
          {'published': pkg.published},
        ],
      };
  }
}

void main() {
  final checker = PubChecker(fetch: _fakePub, now: () => _now);

  group('packagesFromCommand', () {
    test('parses pub add variants', () {
      expect(packagesFromCommand('flutter pub add dio'), ['dio']);
      expect(
          packagesFromCommand(
              'cd app && dart pub add http:^1.2.0 dev:mocktail "override:path"'),
          ['http', 'mocktail', 'path']);
      expect(packagesFromCommand('flutter pub add --dev build_runner freezed'),
          ['build_runner', 'freezed']);
    });
    test('skips non-hosted sources and unrelated commands', () {
      expect(packagesFromCommand('flutter pub add foo --path ../foo'), isEmpty);
      expect(packagesFromCommand('flutter pub get && flutter test'), isEmpty);
    });
  });

  test('packagesFromPubspecText finds constrained deps, ignores SDK entries',
      () {
    const pubspec = '''
name: app
version: 1.0.0
environment:
  sdk: ^3.5.0
  flutter: ">=3.22.0"
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  local_pkg:
    path: ../local_pkg
dev_dependencies:
  mocktail: any
''';
    expect(packagesFromPubspecText(pubspec), ['dio', 'mocktail']);
  });

  group('PubChecker', () {
    test('ok for a healthy package', () async {
      expect((await checker.check('http')).verdict, Verdict.ok);
    });
    test('blocks a package that does not exist', () async {
      final r = await checker.check('flutter_magic_ai_sdk');
      expect(r.verdict, Verdict.block);
      expect(r.reasons.single, contains('does not exist'));
    });
    test('warns on new, unverified, low-adoption packages', () async {
      final r = await checker.check('shiny_new');
      expect(r.verdict, Verdict.warn);
      expect(r.reasons.join(),
          allOf(contains('5 days ago'), contains('unverified')));
    });
    test('warns on discontinued packages and names the replacement', () async {
      final r = await checker.check('old_pkg');
      expect(r.reasons.single, 'discontinued, replaced by new_pkg');
    });
    test('SDK packages are ok without a network call', () async {
      final c = PubChecker(fetch: (_) => throw StateError('no network'));
      expect((await c.check('flutter_test')).verdict, Verdict.ok);
    });
  });

  group('handlePreToolUse', () {
    Future<Map?> run(Map event, [PubChecker? c]) async {
      final out = await handlePreToolUse(jsonEncode(event), c ?? checker);
      return out == null
          ? null
          : (jsonDecode(out) as Map)['hookSpecificOutput'] as Map;
    }

    test('denies pub add of a hallucinated package', () async {
      final out = await run({
        'tool_name': 'Bash',
        'tool_input': {'command': 'flutter pub add http flutter_magic_ai_sdk'},
      });
      expect(out!['permissionDecision'], 'deny');
      expect(out['permissionDecisionReason'], contains('flutter_magic_ai_sdk'));
    });
    test('asks for risky pubspec edits', () async {
      final out = await run({
        'tool_name': 'Edit',
        'tool_input': {
          'file_path': '/app/pubspec.yaml',
          'new_string': '  shiny_new: ^0.0.1\n'
        },
      });
      expect(out!['permissionDecision'], 'ask');
    });
    test('stays silent for safe packages and unrelated tools', () async {
      expect(
          await run({
            'tool_name': 'Bash',
            'tool_input': {'command': 'flutter pub add http'}
          }),
          isNull);
      expect(
          await run({
            'tool_name': 'Bash',
            'tool_input': {'command': 'ls'}
          }),
          isNull);
      expect(
          await run({
            'tool_name': 'Edit',
            'tool_input': {
              'file_path': 'lib/main.dart',
              'new_string': '  dio: ^1.0.0'
            }
          }),
          isNull);
    });
    test('fails open when pub.dev is unreachable', () async {
      final offline = PubChecker(fetch: (_) => throw Exception('offline'));
      expect(
          await run({
            'tool_name': 'Bash',
            'tool_input': {'command': 'dart pub add zzz'}
          }, offline),
          isNull);
    });
  });
}
