## 0.2.0

- **Dependency guard:** `init` adds a Claude Code `PreToolUse` hook that checks `flutter pub add` / `dart pub add` and `pubspec.yaml` edits against pub.dev. Non-existent (possibly hallucinated) packages are blocked; discontinued, unlisted, brand-new or unverified low-adoption packages ask for confirmation. Fails open when offline.
- New `check` command: `check <name>...` and `check --pubspec` for CI (exits 1 when a package does not exist).
- `init --no-hooks` to skip the hook.
- Project rules now tell agents to verify packages before adding them.

## 0.1.2

- Refreshed README with a banner and clearer getting-started steps.
- Publishing workflow uses the `pub.dev` GitHub environment.

## 0.1.1

- Add dartdoc comments to the public API.
- Add an example.

## 0.1.0

- `fas init`: detects the project stack and installs Claude Code skills, `CLAUDE.md` and `AGENTS.md` rules.
- Skills: `flutter-guidelines`, `flutter-feature`, `flutter-verify`.
- Claude Code plugin marketplace manifest.
