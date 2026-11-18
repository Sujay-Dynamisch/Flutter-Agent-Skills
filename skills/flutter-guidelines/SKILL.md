---
name: flutter-guidelines
description: Behavioral guidelines for writing, reviewing, or refactoring Flutter/Dart code. Use on any Flutter coding task to avoid overcomplication, unrequested dependencies, and noisy diffs, and to finish with a verified, analyzer-clean result.
license: MIT
---

# Flutter Guidelines

Behavioral guidelines that reduce common LLM mistakes in Flutter projects. Adapted for Flutter from the
[Karpathy guidelines](https://github.com/forrestchang/andrej-karpathy-skills) (MIT).

**Tradeoff:** these bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Read the project before writing to it.**

- Check `pubspec.yaml` first: state management, routing, codegen (`freezed`, `json_serializable`, `riverpod_generator`), and lint rules in `analysis_options.yaml`.
- Find an existing feature that is similar and follow its structure. The project's conventions beat your defaults.
- State your assumptions. If the request has more than one reasonable reading (e.g. "add caching": memory or disk?), ask instead of picking silently.
- Never introduce a second state-management or routing solution next to the existing one.

## 2. Simplicity First

**Minimum code that solves the problem.**

- No new dependencies unless the user agrees. Say which package and why before adding it.
- Prefer a `StatelessWidget` plus existing state over a new controller, service, or base class.
- No abstractions, interfaces, or generic widgets for code used once.
- Use `const` constructors where possible; don't add `Key`s, mixins, or theme extensions nobody asked for.
- If you wrote 200 lines and 50 would do, rewrite it.

## 3. Surgical Changes

**Every changed line traces to the request.**

- Format only the files you touched (`dart format <files>`), not the whole project.
- Never hand-edit generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.mocks.dart`). Change the source and run `dart run build_runner build --delete-conflicting-outputs`.
- Don't bump dependency versions, change `analysis_options.yaml`, or touch platform folders (`android/`, `ios/`, ...) unless the task needs it.
- Match existing naming, file layout, and import style (relative vs `package:`).
- Mention unrelated problems you notice; don't fix them. Remove only the imports and code that your own change made unused.

## 4. Goal-Driven Execution

**Define done as something you can check.**

- "Add a screen" → it builds, is reachable from the router, and has a widget test.
- "Fix the bug" → write a test that reproduces it, then make it pass.
- "Refactor" → tests pass before and after, and public behavior is unchanged.

Done means `flutter analyze` reports no new issues and the relevant tests pass (see the `flutter-verify` skill).
Never silence a lint with `// ignore:` to get there unless the user agrees.
