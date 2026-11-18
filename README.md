<div align="center">

# 🧠 flutter_agent_skills

### Make AI coding agents write Flutter code the way *your* project does.

One command teaches **Claude Code** and **Codex** your stack, your architecture,<br>
and your rules — so they stop guessing and start shipping clean, verified code.

[![pub package](https://img.shields.io/pub/v/flutter_agent_skills.svg?label=pub&color=0175C2)](https://pub.dev/packages/flutter_agent_skills)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-ready-D97757?logo=anthropic&logoColor=white)](#-claude-code-plugin)
[![Codex](https://img.shields.io/badge/Codex-AGENTS.md-412991?logo=openai&logoColor=white)](#-what-it-writes)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)

```bash
dart pub global activate flutter_agent_skills && fas init
```

</div>

---

## 😩 The problem

You ask an AI agent to *"add a settings screen"* and you get:

- ❌ A **new state-management library** in your Riverpod app
- ❌ Hand-edited `*.g.dart` files that break on the next `build_runner`
- ❌ **Your whole project reformatted** in a 40-file diff
- ❌ *"Done! ✅"* — while `flutter analyze` shows 12 errors

## ✨ The fix

`flutter_agent_skills` reads your `pubspec.yaml`, detects your stack, and installs **Flutter-specific skills and rules** your agent follows on every task.

<table>
<tr>
<th>🤖 Without</th>
<th>🚀 With <code>flutter_agent_skills</code></th>
</tr>
<tr>
<td>

```text
> add a settings screen

+ adds provider package
+ creates SettingsController
+ edits settings.g.dart by hand
+ reformats 38 files
"Done!"
```

</td>
<td>

```text
> add a settings screen

✓ detected Riverpod + go_router
✓ mirrors features/profile/ layout
✓ AsyncNotifier + widget test
✓ runs build_runner, formats 4 files
✓ flutter analyze: no issues
✓ flutter test: 18 passed
```

</td>
</tr>
</table>

---

## ⚡ Quick start

```bash
# 1. Install the CLI
dart pub global activate flutter_agent_skills

# 2. Run it inside your Flutter project
cd my_flutter_app
fas init
```

```text
created    .claude/skills/flutter-feature/SKILL.md
created    .claude/skills/flutter-guidelines/SKILL.md
created    .claude/skills/flutter-verify/SKILL.md
updated    CLAUDE.md
created    AGENTS.md

Done.
```

That's it. Open Claude Code or Codex and start building. 🎉

### Options

| Command | What it does |
|---|---|
| `fas init` | Set up Claude Code **and** Codex |
| `fas init -t claude` | Claude Code only |
| `fas init -t codex` | Codex only (`AGENTS.md`) |
| `fas init --dry-run` | Preview changes, write nothing |
| `fas init -d path/to/app` | Run on another directory |
| `fas list` | List bundled skills |

---

## 🧩 Skills

| | Skill | What your agent learns |
|:-:|---|---|
| 🧭 | **`flutter-guidelines`** | Think before coding · Simplicity first · Surgical changes · Goal-driven execution — tuned for Flutter: no surprise dependencies, never hand-edit generated files, format only what changed. |
| 🏗️ | **`flutter-feature`** | Builds screens and features that look like *your team* wrote them: model → data → state → UI → route → tests, using your existing Riverpod / Bloc / Provider / GetX patterns. |
| ✅ | **`flutter-verify`** | A real verification loop — `build_runner` → `dart format` → `flutter analyze` → `flutter test` — fix, repeat, and report honest results. |

---

## 🔍 Stack detection

`fas init` writes a project profile your agent reads before every task:

```markdown
### Project profile (detected from pubspec.yaml)
- Package: `my_app` (Flutter app/package)
- State management: Riverpod
- Routing: go_router
- Code generation: build_runner, freezed, riverpod_generator
- Other key packages: Firebase, dio, mocktail
```

| Category | Detected |
|---|---|
| 🔄 State management | Riverpod · Bloc · Provider · GetX · MobX · Signals |
| 🧭 Routing | go_router · auto_route · beamer |
| ⚙️ Code generation | build_runner · freezed · json_serializable · riverpod_generator · injectable |
| 📦 Others | Firebase · dio · http · drift · isar · hive · get_it · mocktail · mockito · flutter_hooks |

---

## 📁 What it writes

| File | Used by |
|---|---|
| `.claude/skills/*/SKILL.md` | 🟠 Claude Code skills |
| `CLAUDE.md` | 🟠 Claude Code project rules + stack profile |
| `AGENTS.md` | 🟣 Codex and other `AGENTS.md`-aware agents |

> [!TIP]
> **Safe to rerun.** Rules live inside a managed block (`<!-- flutter_agent_skills:start/end -->`). Your own `CLAUDE.md` / `AGENTS.md` content is never touched, and running `fas init` again only refreshes that block.

---

## 🔌 Claude Code plugin

Prefer plugins? Install the skills straight from GitHub:

```text
/plugin marketplace add Sujay-Dynamisch/Flutter-Agent-Skills
/plugin install flutter-agent-skills@flutter-agent-skills
```

> The plugin installs the skills only. Use `fas init` to also get the stack profile in `CLAUDE.md` / `AGENTS.md`.

---

## 🗺️ Roadmap

- [x] Claude Code skills + `CLAUDE.md`
- [x] Codex via `AGENTS.md`
- [x] Claude Code plugin marketplace
- [ ] Cursor rules & GitHub Copilot instructions
- [ ] Hooks: auto `dart format` + `flutter analyze` after edits
- [ ] Skills: golden tests, performance audit, accessibility audit
- [ ] Skills: Flutter version migrations, pub.dev release prep
- [ ] Eval suite: every skill tested against sample apps

Have an idea? [Open an issue](https://github.com/Sujay-Dynamisch/Flutter-Agent-Skills/issues) 💡

---

## 🤝 Contributing

Skills live in [`skills/`](skills/) and the rules template in [`templates/`](templates/).

```bash
dart run tool/bundle.dart   # rebuild the bundled content
dart test                   # make sure everything passes
```

PRs for new skills are very welcome — keep them short, Flutter-specific, and verifiable.

## 🙏 Credits

`flutter-guidelines` is adapted from the excellent [Karpathy guidelines](https://github.com/forrestchang/andrej-karpathy-skills) (MIT), inspired by [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

<div align="center">

---

**If this saves you from one bad AI diff, give it a ⭐ — it helps other Flutter devs find it.**

MIT © flutter_agent_skills contributors

</div>
