import 'dart:io';

enum SymbolKind { function, method, classType, enumType, other }

class SymbolChange {
  final String name;
  final SymbolKind kind;
  final String? beforePath;
  final String? afterPath;

  const SymbolChange({
    required this.name,
    required this.kind,
    this.beforePath,
    this.afterPath,
  });
}

class SymbolDiff {
  final SymbolChange change;
  final String leftSnippet;
  final String rightSnippet;

  const SymbolDiff({
    required this.change,
    required this.leftSnippet,
    required this.rightSnippet,
  });
}

List<SymbolChange> dummySymbolChanges() {
  return const <SymbolChange>[
    SymbolChange(
      name: 'ChunkDiffExample.greet',
      kind: SymbolKind.method,
      beforePath: 'lib/src/example.dart',
      afterPath: 'lib/src/example.dart',
    ),
    SymbolChange(
      name: 'ChunkDiffExample',
      kind: SymbolKind.classType,
      beforePath: 'lib/src/example.dart',
      afterPath: 'lib/src/example.dart',
    ),
    SymbolChange(
      name: 'main',
      kind: SymbolKind.function,
      beforePath: 'lib/main.dart',
      afterPath: 'lib/main.dart',
    ),
  ];
}

List<SymbolDiff> dummySymbolDiffs() {
  final List<SymbolChange> changes = dummySymbolChanges();
  return <SymbolDiff>[
    SymbolDiff(
      change: changes[0],
      leftSnippet: '''
class ChunkDiffExample {
  String greet(String name) {
    return 'Hello, \$name from v1';
  }
}

void main() {
  final ChunkDiffExample example = ChunkDiffExample();
  print(example.greet('Developer'));
}
''',
      rightSnippet: '''
class ChunkDiffExample {
  String greet(String name, {bool excited = false}) {
    final String base = 'Hello, \$name from v2';
    return excited ? '\$base!' : base;
  }
}

void main() {
  final ChunkDiffExample example = ChunkDiffExample();
  print(example.greet('Developer', excited: true));
}
''',
    ),
    SymbolDiff(
      change: changes[1],
      leftSnippet: '''
class ChunkDiffExample {
  final String name;

  const ChunkDiffExample(this.name);
}
''',
      rightSnippet: '''
class ChunkDiffExample {
  final String name;
  final int version;

  const ChunkDiffExample(this.name, {this.version = 2});
}
''',
    ),
    SymbolDiff(
      change: changes[2],
      leftSnippet: '''
void main() {
  final ChunkDiffExample example = ChunkDiffExample('Developer');
  print(example.name);
}
''',
      rightSnippet: '''
void main() {
  final ChunkDiffExample example = ChunkDiffExample('Developer', version: 2);
  print('\${example.name} v\${example.version}');
}
''',
    ),
  ];
}

Future<bool> isGitRepo(String path) async {
  try {
    final ProcessResult result = await Process.run(
      'git',
      <String>['rev-parse', '--is-inside-work-tree'],
      workingDirectory: path,
    );
    return result.exitCode == 0 &&
        (result.stdout as String?)?.trim().toLowerCase() == 'true';
  } catch (_) {
    // In sandboxed environments, process execution may be blocked.
    return false;
  }
}

Future<List<String>> listGitRefs(
  String path, {
  int limit = 20,
  bool strict = false,
}) async {
  try {
    final ProcessResult result = await Process.run(
      'git',
      <String>[
        'for-each-ref',
        '--format=%(refname:short)',
        '--count=$limit',
        'refs/heads',
        'refs/remotes',
      ],
      workingDirectory: path,
    );
    if (result.exitCode != 0) {
      if (strict) {
        throw ProcessException(
          'git',
          <String>['for-each-ref'],
          result.stderr,
          result.exitCode,
        );
      }
      return <String>[];
    }
    final String stdout = (result.stdout as String?) ?? '';
    return stdout
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();
  } catch (e) {
    if (strict) {
      rethrow;
    }
    // In sandboxed environments, process execution may be blocked.
    return <String>[];
  }
}
