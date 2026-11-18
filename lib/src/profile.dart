import 'package:yaml/yaml.dart';

/// What we can learn about a project from its pubspec.yaml.
class ProjectProfile {
  /// Creates a profile from already-detected values.
  /// Most callers should use [ProjectProfile.fromPubspec] instead.
  ProjectProfile({
    required this.name,
    required this.isFlutter,
    required this.stateManagement,
    required this.routing,
    required this.codegen,
    required this.other,
  });

  /// The package name from `pubspec.yaml`.
  final String name;

  /// Whether the project depends on the Flutter SDK.
  final bool isFlutter;

  /// Detected state-management solutions, e.g. `Riverpod`, `Bloc`.
  final List<String> stateManagement;

  /// Detected routing packages, e.g. `go_router`.
  final List<String> routing;

  /// Detected code-generation packages, e.g. `freezed`, `build_runner`.
  final List<String> codegen;

  /// Other notable packages, e.g. `Firebase`, `dio`, `mocktail`.
  final List<String> other;

  static const _state = {
    'flutter_riverpod': 'Riverpod',
    'hooks_riverpod': 'Riverpod',
    'riverpod': 'Riverpod',
    'flutter_bloc': 'Bloc',
    'bloc': 'Bloc',
    'provider': 'Provider',
    'get': 'GetX',
    'mobx': 'MobX',
    'signals': 'Signals',
  };
  static const _routing = {
    'go_router': 'go_router',
    'auto_route': 'auto_route',
    'beamer': 'beamer',
  };
  static const _codegen = {
    'build_runner': 'build_runner',
    'freezed': 'freezed',
    'json_serializable': 'json_serializable',
    'riverpod_generator': 'riverpod_generator',
    'injectable_generator': 'injectable',
  };
  static const _other = {
    'firebase_core': 'Firebase',
    'dio': 'dio',
    'http': 'http',
    'drift': 'drift',
    'isar': 'isar',
    'hive': 'hive',
    'get_it': 'get_it',
    'mocktail': 'mocktail',
    'mockito': 'mockito',
    'flutter_hooks': 'flutter_hooks',
  };

  /// Parses the contents of a `pubspec.yaml` file and detects the stack from
  /// its `dependencies` and `dev_dependencies`.
  factory ProjectProfile.fromPubspec(String source) {
    final doc = loadYaml(source);
    final map = doc is YamlMap ? doc : YamlMap();
    final deps = <String>{
      for (final key in ['dependencies', 'dev_dependencies'])
        if (map[key] is YamlMap) ...(map[key] as YamlMap).keys.cast<String>(),
    };
    List<String> pick(Map<String, String> table) =>
        {for (final e in table.entries) if (deps.contains(e.key)) e.value}
            .toList();
    return ProjectProfile(
      name: map['name']?.toString() ?? 'unknown',
      isFlutter: deps.contains('flutter'),
      stateManagement: pick(_state),
      routing: pick(_routing),
      codegen: pick(_codegen),
      other: pick(_other),
    );
  }

  /// Markdown section describing the project for agents.
  String toMarkdown() {
    String list(List<String> v, String none) => v.isEmpty ? none : v.join(', ');
    return [
      '### Project profile (detected from pubspec.yaml)',
      '- Package: `$name` (${isFlutter ? 'Flutter app/package' : 'pure Dart'})',
      '- State management: ${list(stateManagement, 'none detected (use setState; do not add a library without asking)')}',
      '- Routing: ${list(routing, 'Navigator (none detected)')}',
      '- Code generation: ${list(codegen, 'none')}',
      if (other.isNotEmpty) '- Other key packages: ${other.join(', ')}',
    ].join('\n');
  }
}
