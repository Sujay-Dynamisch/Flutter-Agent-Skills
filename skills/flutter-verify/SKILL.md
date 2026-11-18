---
name: flutter-verify
description: Verification loop for Flutter/Dart changes - format, analyze, codegen, and test, then fix and repeat until clean. Use before declaring any Flutter coding task done, or when asked to check, validate, or fix analyzer errors and failing tests.
license: MIT
---

# Flutter Verify

Don't call a task done until it passes this loop.

## The loop

1. **Codegen**, only if you changed annotated sources (`@freezed`, `@JsonSerializable`, `@riverpod`, ...):
   `dart run build_runner build --delete-conflicting-outputs`
2. **Format** only the files you changed: `dart format <changed files>`
3. **Analyze**: `flutter analyze` (use `dart analyze` for pure Dart packages).
   - Fix every issue your change introduced. Leave existing issues alone, but mention them.
   - Don't add `// ignore:` comments or change `analysis_options.yaml` to get a clean result.
4. **Test**, narrowest first:
   - The tests for what you touched: `flutter test test/path/to/feature_test.dart`
   - Then the full suite: `flutter test`
5. If anything fails, read the **first** error, fix the cause (not the symptom), and go back to step 2.

## Reading failures

- A `pumpAndSettle` timeout usually means an infinite animation or a progress indicator. Use `pump(duration)` instead.
- "No MaterialLocalizations found" or missing providers: wrap the widget under test the way other tests do (`MaterialApp`, `ProviderScope`, `BlocProvider`).
- Golden mismatches: never update goldens (`--update-goldens`) unless the visual change was intended and the user agrees.
- `Undefined name` after editing a model: generated code is stale. Rerun step 1.

## Reporting

Say exactly what ran and what it returned, for example "`flutter analyze`: no issues. `flutter test`: 42 passed." If something still fails, say so with the error. Never claim a check passed if you didn't run it.
