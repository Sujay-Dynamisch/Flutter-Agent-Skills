import 'dart:convert';
import 'dart:io';

import 'package:flutter_agent_skills/flutter_agent_skills.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/bundle.dart' show generateBundle;

const _pubspec = '''
name: demo_app
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.0.0
  go_router: ^14.0.0
  dio: ^5.0.0
dev_dependencies:
  build_runner: any
  freezed: any
''';

void main() {
  test('bundle.g.dart is up to date with skills/ and templates/', () {
    final generated = File('lib/src/bundle.g.dart').readAsStringSync();
    expect(generated.replaceAll('\r\n', '\n'), generateBundle('.'),
        reason: 'Run: dart run tool/bundle.dart');
  });

  test('every skill has name/description frontmatter matching its folder', () {
    for (final name in skillNames) {
      final md = File('skills/$name/SKILL.md').readAsStringSync();
      expect(md, startsWith('---'));
      expect(md, contains('name: $name\n'));
      expect(md, contains('description: '));
    }
  });

  test('profile detects stack', () {
    final prof = ProjectProfile.fromPubspec(_pubspec);
    expect(prof.isFlutter, isTrue);
    expect(prof.stateManagement, ['Riverpod']);
    expect(prof.routing, ['go_router']);
    expect(prof.codegen, containsAll(['build_runner', 'freezed']));
    expect(prof.other, ['dio']);
  });

  test('upsertBlock appends once and replaces on rerun', () {
    final first = upsertBlock('# Mine\n', 'v1');
    expect(first, startsWith('# Mine\n\n'));
    final second = upsertBlock(first, 'v2');
    expect(second, contains('v2'));
    expect(second, isNot(contains('v1')));
    expect(second, startsWith('# Mine\n'));
  });

  group('Installer', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('fas_');
      File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync(_pubspec);
      File(p.join(dir.path, 'CLAUDE.md'))
          .writeAsStringSync('# Existing notes\n');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('installs skills and rules, keeps user content, is idempotent', () {
      Installer(dir).install(AgentTarget.values.toSet());
      for (final name in skillNames) {
        expect(
            File(p.join(dir.path, '.claude', 'skills', name, 'SKILL.md'))
                .existsSync(),
            isTrue);
      }
      final claude = File(p.join(dir.path, 'CLAUDE.md')).readAsStringSync();
      expect(claude, startsWith('# Existing notes'));
      expect(claude, contains('State management: Riverpod'));
      expect(File(p.join(dir.path, 'AGENTS.md')).readAsStringSync(),
          contains('Routing: go_router'));

      final rerun = Installer(dir).install(AgentTarget.values.toSet());
      expect(rerun.every((a) => a.startsWith('unchanged')), isTrue);
    });

    test('adds the hook to settings.json, keeping existing settings', () {
      final settings = File(p.join(dir.path, '.claude', 'settings.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode({
          'model': 'opus',
          'hooks': {
            'PreToolUse': [
              {
                'matcher': 'Read',
                'hooks': [
                  {'type': 'command', 'command': 'mine'}
                ]
              },
            ],
          },
        }));
      Installer(dir).install({AgentTarget.claude});
      Installer(dir).install({AgentTarget.claude}); // rerun must not duplicate
      final json = jsonDecode(settings.readAsStringSync()) as Map;
      expect(json['model'], 'opus');
      final pre = json['hooks']['PreToolUse'] as List;
      expect(pre, hasLength(2));
      expect(jsonEncode(pre),
          contains('dart pub global run flutter_agent_skills check --hook'));
    });

    test('--no-hooks leaves settings.json alone', () {
      Installer(dir, installHooks: false).install({AgentTarget.claude});
      expect(File(p.join(dir.path, '.claude', 'settings.json')).existsSync(),
          isFalse);
    });

    test('dry run writes nothing', () {
      Installer(dir, dryRun: true).install({AgentTarget.codex});
      expect(File(p.join(dir.path, 'AGENTS.md')).existsSync(), isFalse);
    });

    test('fails without pubspec', () {
      File(p.join(dir.path, 'pubspec.yaml')).deleteSync();
      expect(
          () => Installer(dir).install({AgentTarget.claude}), throwsStateError);
    });
  });
}
