import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_agent_skills/flutter_agent_skills.dart';

const _usage = '''
Flutter-aware skills and rules for AI coding agents.

Usage: fas <command> [options]

Commands:
  init    Install skills and project rules into the current project
  list    List bundled skills

Run "fas init --help" for init options.''';

void main(List<String> args) {
  final init = ArgParser()
    ..addMultiOption('target',
        abbr: 't',
        allowed: AgentTarget.values.map((t) => t.name),
        defaultsTo: AgentTarget.values.map((t) => t.name),
        help: 'Agents to configure.')
    ..addOption('dir', abbr: 'd', defaultsTo: '.', help: 'Project directory.')
    ..addFlag('dry-run', negatable: false, help: 'Show changes without writing.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parser = ArgParser()
    ..addCommand('init', init)
    ..addCommand('list')
    ..addFlag('version', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults res;
  try {
    res = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n$_usage');
    exit(64);
  }

  if (res['version'] as bool) return stdout.writeln(packageVersion);
  final cmd = res.command;
  switch (cmd?.name) {
    case 'list':
      skillNames.forEach(stdout.writeln);
    case 'init':
      if (cmd!['help'] as bool) return stdout.writeln(init.usage);
      final targets = (cmd['target'] as List<String>)
          .map((n) => AgentTarget.values.byName(n))
          .toSet();
      final dryRun = cmd['dry-run'] as bool;
      try {
        final actions = Installer(Directory(cmd['dir'] as String), dryRun: dryRun)
            .install(targets);
        actions.forEach(stdout.writeln);
        stdout.writeln(dryRun ? '\nDry run: nothing written.' : '\nDone.');
      } on StateError catch (e) {
        stderr.writeln(e.message);
        exit(1);
      }
    default:
      stdout.writeln(_usage);
  }
}
