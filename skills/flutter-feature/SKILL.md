---
name: flutter-feature
description: Add a new feature, screen, or flow to a Flutter app following the project's existing architecture and state management (Riverpod, Bloc, Provider, GetX, or plain setState). Use when asked to build a screen, feature, page, form, or list.
license: MIT
---

# Flutter Feature

Build a feature that looks like the rest of the codebase wrote it.

## 1. Learn the shape

1. Read `pubspec.yaml` (or the project profile in `CLAUDE.md` / `AGENTS.md`) for state management, routing, and codegen.
2. Open the most similar existing feature. Note its folder layout (`features/x/{data,domain,presentation}` vs `screens/` + `models/`), file names, and how it gets dependencies.
3. If there is no existing feature to copy, propose a minimal layout in one or two lines and confirm before creating many files.

## 2. Build in this order

1. **Model**: immutable class. Use `freezed` / `json_serializable` only if the project already does.
2. **Data**: repository or service that matches existing ones. Keep I/O out of widgets.
3. **State**: follow the detected solution:
   - **Riverpod**: `Notifier` / `AsyncNotifier`. Use `@riverpod` codegen only if `riverpod_generator` is a dependency. Read with `ref.watch` in build and `ref.read` in callbacks.
   - **Bloc**: match the project's choice of `Cubit` or `Bloc`. Use sealed classes for states and events if the project does. One bloc per feature, provided where similar blocs are provided.
   - **Provider**: `ChangeNotifier` plus `ChangeNotifierProvider` placed where siblings are.
   - **GetX**: controller plus binding, following the existing pattern.
   - **None**: `StatefulWidget` / `setState`. Don't introduce a library.
4. **UI**: small widgets, `const` where possible, theme values from `Theme.of(context)` instead of hard-coded colors and sizes. Handle loading, empty, and error states the way existing screens do.
5. **Navigation**: register the route the same way as others (`go_router` route table, `auto_route` annotations, or `Navigator`).
6. **Tests**: at least one widget test for the screen's main states, plus unit tests for non-trivial logic. Mock the way existing tests do (`mocktail` / `mockito`).

## 3. Finish

- If codegen is used, run `dart run build_runner build --delete-conflicting-outputs`.
- Run the `flutter-verify` loop.
- Report the files you created and changed, and anything you assumed.
