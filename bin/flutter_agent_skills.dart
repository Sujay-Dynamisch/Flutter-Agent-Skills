import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_agent_skills/flutter_agent_skills.dart';

const _usage = '''
Flutter-aware skills and rules for AI coding agents.

Usage: fas <command> [options]

Commands:
  init    Install skills, project rules and the dependency-check hook
  check   Check packages on pub.dev before adding them (fas check <name>...)
  list    List bundled skills

Run "fas <command> --help" for options.''';

Future<void> main(List<String> args) async {
  final init = ArgParser()
    ..addMultiOption('target',
        abbr: 't',
        allowed: AgentTarget.values.map((t) => t.name),
        defaultsTo: AgentTarget.values.map((t) => t.name),
        help: 'Agents to configure.')
    ..addOption('dir', abbr: 'd', defaultsTo: '.', help: 'Project directory.')
    ..addFlag('dry-run',
        negatable: false, help: 'Show changes without writing.')
    ..addFlag('hooks',
        defaultsTo: true,
        help:
            'Add the Claude Code hook that checks new dependencies on pub.dev.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final check = ArgParser()
    ..addFlag('pubspec',
        negatable: false, help: 'Check every dependency in ./pubspec.yaml.')
    ..addFlag('hook',
        negatable: false,
        help: 'Run as a Claude Code PreToolUse hook (reads stdin).')
    ..addFlag('help', abbr: 'h', negatable: false);
  final parser = ArgParser()
    ..addCommand('init', init)
    ..addCommand('check', check)
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
        final actions = Installer(Directory(cmd['dir'] as String),
                dryRun: dryRun, installHooks: cmd['hooks'] as bool)
            .install(targets);
        actions.forEach(stdout.writeln);
        stdout.writeln(dryRun ? '\nDry run: nothing written.' : '\nDone.');
      } on StateError catch (e) {
        stderr.writeln(e.message);
        exit(1);
      }
    case 'check':
      if (cmd!['help'] as bool) return stdout.writeln(check.usage);
      final checker = PubChecker();
      if (cmd['hook'] as bool) {
        final out = await handlePreToolUse(
            await stdin.transform(utf8.decoder).join(), checker);
        if (out != null) stdout.writeln(out);
        exit(0);
      }
      final names = [
        ...cmd.rest,
        if (cmd['pubspec'] as bool) ...packagesFromPubspecText(_readPubspec()),
      ];
      if (names.isEmpty) return stdout.writeln(check.usage);
      final List<PackageReport> reports;
      try {
        reports = await checker.checkAll(names);
      } on Exception catch (e) {
        stderr.writeln('Could not reach pub.dev: $e');
        exit(2);
      }
      reports.forEach(stdout.writeln);
      exit(reports.any((r) => r.verdict == Verdict.block) ? 1 : 0);
    default:
      stdout.writeln(_usage);
  }
}

String _readPubspec() {
  final f = File('pubspec.yaml');
  if (!f.existsSync()) {
    stderr.writeln('No pubspec.yaml in the current directory.');
    exit(64);
  }
  return f.readAsStringSync();
}
