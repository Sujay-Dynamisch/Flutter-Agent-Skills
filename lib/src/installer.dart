import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bundle.g.dart';
import 'profile.dart';

/// An AI coding agent that `fas init` can configure.
enum AgentTarget {
  /// Claude Code: installs `.claude/skills/` and a rules block in `CLAUDE.md`.
  claude,

  /// Codex (and other `AGENTS.md`-aware agents): a rules block in `AGENTS.md`.
  codex,
}

/// Marker that opens the managed block in `CLAUDE.md` / `AGENTS.md`.
const blockStart = '<!-- flutter_agent_skills:start -->';

/// CLI arguments the Claude Code hook runs; also identifies our hook entry.
const hookCommand = 'check --hook';

/// Marker that closes the managed block in `CLAUDE.md` / `AGENTS.md`.
const blockEnd = '<!-- flutter_agent_skills:end -->';

/// Names of the bundled skills, e.g. `flutter-verify`.
List<String> get skillNames => {
      for (final k in bundledFiles.keys)
        if (k.startsWith('skills/')) k.split('/')[1],
    }.toList()
      ..sort();

/// Inserts [body] between managed markers, replacing a previous block if present.
String upsertBlock(String existing, String body) {
  final block = '$blockStart\n${body.trim()}\n$blockEnd';
  final start = existing.indexOf(blockStart);
  final end = existing.indexOf(blockEnd);
  if (start != -1 && end > start) {
    return existing.replaceRange(start, end + blockEnd.length, block);
  }
  if (existing.trim().isEmpty) return '$block\n';
  return '${existing.trimRight()}\n\n$block\n';
}

/// Installs bundled skills and project rules into a Dart/Flutter project.
///
/// ```dart
/// final actions = Installer(Directory('my_app')).install({AgentTarget.claude});
/// actions.forEach(print); // e.g. "created    CLAUDE.md"
/// ```
class Installer {
  /// Creates an installer for the project at [root].
  ///
  /// When [dryRun] is true, [install] reports what it would do without
  /// writing any files.
  Installer(this.root, {this.dryRun = false, this.installHooks = true});

  /// The project directory; must contain a `pubspec.yaml`.
  final Directory root;

  /// Whether to only report changes instead of writing them.
  final bool dryRun;

  /// Whether to add the Claude Code dependency-check hook to
  /// `.claude/settings.json`.
  final bool installHooks;

  /// Writes files for [targets] and returns one line per file, prefixed with
  /// `created`, `updated`, or `unchanged`.
  ///
  /// Throws a [StateError] if [root] has no `pubspec.yaml`.
  List<String> install(Set<AgentTarget> targets) {
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError(
          'No pubspec.yaml in ${root.path}. Run inside a Dart/Flutter project.');
    }
    final profile = ProjectProfile.fromPubspec(pubspec.readAsStringSync());
    final rules = bundledFiles['templates/project_rules.md']!
        .replaceAll('{{profile}}', profile.toMarkdown());

    final actions = <String>[];
    if (targets.contains(AgentTarget.claude)) {
      for (final entry in bundledFiles.entries) {
        if (!entry.key.startsWith('skills/')) continue;
        _write(p.join('.claude', p.joinAll(entry.key.split('/'))), entry.value,
            actions);
      }
      final skills = skillNames.map((s) => '`$s`').join(', ');
      _upsert('CLAUDE.md',
          '$rules\nSkills installed in `.claude/skills/`: $skills.', actions);
      if (installHooks) _installHook(pubspec.readAsStringSync(), actions);
    }
    if (targets.contains(AgentTarget.codex)) {
      _upsert('AGENTS.md', rules, actions);
    }
    return actions;
  }

  void _write(String rel, String content, List<String> actions) {
    final file = File(p.join(root.path, rel));
    final existed = file.existsSync();
    if (existed && file.readAsStringSync() == content) {
      actions.add('unchanged  $rel');
      return;
    }
    actions.add('${existed ? 'updated' : 'created'}    $rel');
    if (dryRun) return;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  /// Adds (or refreshes) the PreToolUse hook that checks new dependencies,
  /// keeping every other setting and hook intact.
  void _installHook(String pubspec, List<String> actions) {
    const rel = '.claude/settings.json';
    final file = File(p.join(root.path, rel));
    Map<String, dynamic> settings = {};
    if (file.existsSync() && file.readAsStringSync().trim().isNotEmpty) {
      try {
        settings = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      } on FormatException {
        actions.add('skipped    $rel (invalid JSON; add the hook manually)');
        return;
      }
    }
    final asDevDep =
        RegExp(r'^\s+flutter_agent_skills:', multiLine: true).hasMatch(pubspec);
    final run = asDevDep
        ? 'dart run flutter_agent_skills $hookCommand'
        : 'dart pub global run flutter_agent_skills $hookCommand';
    // Starting Dart takes seconds, so a shell pre-filter skips every tool call
    // that can't add a dependency.
    final command = "sh -c 'i=\$(cat); case \"\$i\" in "
        "*\"pub add\"*|*pubspec.yaml*) printf \"%s\" \"\$i\" | $run;; esac'";

    final hooks = (settings['hooks'] as Map?)?.cast<String, dynamic>() ?? {};
    final pre = [...(hooks['PreToolUse'] as List? ?? const [])]
      ..removeWhere((e) => jsonEncode(e).contains(hookCommand));
    pre.add({
      'matcher': 'Bash|Edit|MultiEdit|Write',
      'hooks': [
        {'type': 'command', 'command': command, 'timeout': 20},
      ],
    });
    settings['hooks'] = {...hooks, 'PreToolUse': pre};
    _write(rel, '${const JsonEncoder.withIndent('  ').convert(settings)}\n',
        actions);
  }

  void _upsert(String rel, String body, List<String> actions) {
    final file = File(p.join(root.path, rel));
    final existing = file.existsSync() ? file.readAsStringSync() : '';
    _write(rel, upsertBlock(existing, body), actions);
  }
}
