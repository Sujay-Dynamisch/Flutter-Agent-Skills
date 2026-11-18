// Most users run the CLI instead:
//   dart pub global activate flutter_agent_skills
//   fas init
//
// This example uses the library API directly.
import 'dart:io';

import 'package:flutter_agent_skills/flutter_agent_skills.dart';

void main() {
  // Detect a project's stack from its pubspec.yaml.
  final profile = ProjectProfile.fromPubspec('''
name: my_app
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.0
  go_router: ^14.0.0
dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
''');
  print(profile.toMarkdown());

  // List bundled skills.
  print('\nSkills: ${skillNames.join(', ')}');

  // Preview what `fas init` would write to the current project.
  if (File('pubspec.yaml').existsSync()) {
    final actions = Installer(Directory.current, dryRun: true)
        .install(AgentTarget.values.toSet());
    print('\nDry run:');
    actions.forEach(print);
  }
}
