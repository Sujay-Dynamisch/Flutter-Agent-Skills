import 'dart:io';

import 'package:path/path.dart' as p;

import 'bundle.g.dart';
import 'profile.dart';

enum AgentTarget { claude, codex }

const blockStart = '<!-- flutter_agent_skills:start -->';
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

class Installer {
  Installer(this.root, {this.dryRun = false});

  final Directory root;
  final bool dryRun;

  /// Writes files for [targets]; returns a human-readable list of actions.
  List<String> install(Set<AgentTarget> targets) {
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError('No pubspec.yaml in ${root.path}. Run inside a Dart/Flutter project.');
    }
    final profile = ProjectProfile.fromPubspec(pubspec.readAsStringSync());
    final rules = bundledFiles['templates/project_rules.md']!
        .replaceAll('{{profile}}', profile.toMarkdown());

    final actions = <String>[];
    if (targets.contains(AgentTarget.claude)) {
      for (final entry in bundledFiles.entries) {
        if (!entry.key.startsWith('skills/')) continue;
        _write(p.join('.claude', p.joinAll(entry.key.split('/'))), entry.value, actions);
      }
      final skills = skillNames.map((s) => '`$s`').join(', ');
      _upsert('CLAUDE.md', '$rules\nSkills installed in `.claude/skills/`: $skills.', actions);
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

  void _upsert(String rel, String body, List<String> actions) {
    final file = File(p.join(root.path, rel));
    final existing = file.existsSync() ? file.readAsStringSync() : '';
    _write(rel, upsertBlock(existing, body), actions);
  }
}
