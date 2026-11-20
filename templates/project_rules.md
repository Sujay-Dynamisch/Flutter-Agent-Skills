## Flutter agent rules

{{profile}}

### How to work
- **Think first:** read `pubspec.yaml` and a similar existing feature before writing code. State your assumptions and ask when the request is ambiguous.
- **Simplicity:** use the minimum code that solves the request. Add no new dependencies, abstractions, or configurability without asking. Never add a second state-management or routing solution.
- **Real dependencies only:** before adding a package, confirm it exists on pub.dev and is maintained (`dart run flutter_agent_skills check <name>`). Never guess package names.
- **Surgical changes:** touch only what the task needs. Format only the files you changed. Never hand-edit generated files (`*.g.dart`, `*.freezed.dart`); rerun `build_runner` instead.
- **Goal-driven:** define done as a check: `flutter analyze` reports no new issues and the relevant tests pass. Write a failing test first for bugs. Don't silence lints with `// ignore:`.

### Verify before finishing
1. `dart run build_runner build --delete-conflicting-outputs` (only if annotated sources changed)
2. `dart format <changed files>`
3. `flutter analyze`
4. `flutter test <related tests>`, then `flutter test`

Report what ran and its real result.
