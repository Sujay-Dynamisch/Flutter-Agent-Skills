import 'dart:convert';

import 'pub_check.dart';

/// Handles a Claude Code `PreToolUse` hook event (the JSON Claude Code sends
/// on stdin) and returns the JSON to print on stdout, or `null` to allow the
/// tool call without comment.
///
/// - Bash `flutter pub add` / `dart pub add` and edits to `pubspec.yaml` are
///   checked against pub.dev.
/// - Non-existent packages are denied; risky ones ask the user to confirm.
/// - Network failures never block the agent.
Future<String?> handlePreToolUse(String input, PubChecker checker) async {
  final Map<String, dynamic> event;
  try {
    event = jsonDecode(input) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }
  final tool = event['tool_name'];
  final args = (event['tool_input'] as Map?)?.cast<String, dynamic>() ?? {};

  final List<String> names;
  if (tool == 'Bash') {
    names = packagesFromCommand('${args['command'] ?? ''}');
  } else if ('${args['file_path'] ?? ''}'.endsWith('pubspec.yaml')) {
    final text = [
      args['content'],
      args['new_string'],
      for (final e in (args['edits'] as List? ?? const []))
        (e as Map)['new_string'],
    ].whereType<String>().join('\n');
    names = packagesFromPubspecText(text);
  } else {
    return null;
  }
  if (names.isEmpty) return null;

  final List<PackageReport> reports;
  try {
    reports = await checker.checkAll(names);
  } catch (_) {
    return null; // Fail open: pub.dev unreachable shouldn't stop work.
  }

  final blocked = reports.where((r) => r.verdict == Verdict.block).toList();
  final warned = reports.where((r) => r.verdict == Verdict.warn).toList();
  if (blocked.isEmpty && warned.isEmpty) return null;

  final decision = blocked.isNotEmpty ? 'deny' : 'ask';
  final reason = [
    'flutter_agent_skills dependency check:',
    ...blocked.map((r) => '- ${r.name}: ${r.reasons.join('; ')}'),
    ...warned.map((r) => '- ${r.name}: ${r.reasons.join('; ')}'),
    if (blocked.isNotEmpty)
      'Verify the package name on pub.dev or choose an existing package.',
  ].join('\n');

  return jsonEncode({
    'hookSpecificOutput': {
      'hookEventName': 'PreToolUse',
      'permissionDecision': decision,
      'permissionDecisionReason': reason,
    },
  });
}
