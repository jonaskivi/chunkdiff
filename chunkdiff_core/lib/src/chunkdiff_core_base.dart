import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

enum SymbolKind { function, method, classType, enumType, other }

/// Special ref string to indicate the working tree instead of a named ref.
const String kWorktreeRef = 'WORKTREE';

class CodeChunk {
  final String filePath;
  final int oldStart;
  final int oldEnd;
  final int newStart;
  final int newEnd;
  final String leftText;
  final String rightText;

  const CodeChunk({
    required this.filePath,
    required this.oldStart,
    required this.oldEnd,
    required this.newStart,
    required this.newEnd,
    required this.leftText,
    required this.rightText,
  });
}

class CodeHunk {
  final String filePath;
  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final String leftText;
  final String rightText;
  final List<DiffLine> lines;

  const CodeHunk({
    required this.filePath,
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.leftText,
    required this.rightText,
    required this.lines,
  });
}

enum DiffLineStatus { context, added, removed, changed }

class DiffLine {
  final int? leftNumber;
  final int? rightNumber;
  final String leftText;
  final String rightText;
  final DiffLineStatus status;

  const DiffLine({
    required this.leftNumber,
    required this.rightNumber,
    required this.leftText,
    required this.rightText,
    required this.status,
  });
}

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

List<CodeChunk> dummyCodeChunks() {
  return const <CodeChunk>[
    CodeChunk(
      filePath: 'lib/src/example.dart',
      oldStart: 3,
      oldEnd: 10,
      newStart: 3,
      newEnd: 12,
      leftText: r'''
class Greeter {
  String greet(String name) {
    return 'Hello, $name';
  }
}
''',
      rightText: r'''
class Greeter {
  String greet(String name, {bool excited = false}) {
    final String msg = 'Hello, $name';
    return excited ? '$msg!' : msg;
  }
}
''',
    ),
    CodeChunk(
      filePath: 'lib/main.dart',
      oldStart: 1,
      oldEnd: 6,
      newStart: 1,
      newEnd: 7,
      leftText: r'''
void main() {
  final Greeter greeter = Greeter();
  print(greeter.greet('World'));
}
''',
      rightText: r'''
void main() {
  final Greeter greeter = Greeter();
  print(greeter.greet('World', excited: true));
}
''',
    ),
  ];
}

List<CodeHunk> dummyCodeHunks() {
  return <CodeHunk>[
    CodeHunk(
      filePath: 'lib/src/example.dart',
      oldStart: 3,
      oldCount: 4,
      newStart: 3,
      newCount: 6,
      leftText: r'''
class Greeter {
  String greet(String name) {
    return 'Hello, $name';
  }
}''',
      rightText: r'''
class Greeter {
  String greet(String name, {bool excited = false}) {
    final String msg = 'Hello, $name';
    return excited ? '$msg!' : msg;
  }
}''',
      lines: <DiffLine>[
        const DiffLine(
          leftNumber: 3,
          rightNumber: 3,
          leftText: 'class Greeter {',
          rightText: 'class Greeter {',
          status: DiffLineStatus.context,
        ),
        const DiffLine(
          leftNumber: 4,
          rightNumber: 4,
          leftText: '  String greet(String name) {',
          rightText: '  String greet(String name, {bool excited = false}) {',
          status: DiffLineStatus.changed,
        ),
        const DiffLine(
          leftNumber: null,
          rightNumber: 5,
          leftText: '',
          rightText: "    final String msg = 'Hello, \$name';",
          status: DiffLineStatus.added,
        ),
        const DiffLine(
          leftNumber: 5,
          rightNumber: 6,
          leftText: "    return 'Hello, \$name';",
          rightText: "    return excited ? '\$msg!' : msg;",
          status: DiffLineStatus.changed,
        ),
        const DiffLine(
          leftNumber: 6,
          rightNumber: 7,
          leftText: '  }',
          rightText: '  }',
          status: DiffLineStatus.context,
        ),
        const DiffLine(
          leftNumber: 7,
          rightNumber: 8,
          leftText: '}',
          rightText: '}',
          status: DiffLineStatus.context,
        ),
      ],
    ),
    CodeHunk(
      filePath: 'lib/main.dart',
      oldStart: 1,
      oldCount: 5,
      newStart: 1,
      newCount: 6,
      leftText: r'''
void main() {
  final Greeter greeter = Greeter();
  print(greeter.greet('World'));
}''',
      rightText: r'''
void main() {
  final Greeter greeter = Greeter();
  print(greeter.greet('World', excited: true));
}''',
      lines: <DiffLine>[
        const DiffLine(
          leftNumber: 1,
          rightNumber: 1,
          leftText: 'void main() {',
          rightText: 'void main() {',
          status: DiffLineStatus.context,
        ),
        const DiffLine(
          leftNumber: 2,
          rightNumber: 2,
          leftText: '  final Greeter greeter = Greeter();',
          rightText: '  final Greeter greeter = Greeter();',
          status: DiffLineStatus.context,
        ),
        const DiffLine(
          leftNumber: 3,
          rightNumber: 3,
          leftText: "  print(greeter.greet('World'));",
          rightText: "  print(greeter.greet('World', excited: true));",
          status: DiffLineStatus.removed,
        ),
        const DiffLine(
          leftNumber: 4,
          rightNumber: 4,
          leftText: '}',
          rightText: '}',
          status: DiffLineStatus.context,
        ),
      ],
    ),
  ];
}

Future<bool> isGitRepo(String path) async {
  try {
    final ProcessResult result =
        await _runGit(path, <String>['rev-parse', '--is-inside-work-tree']);
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

Future<String?> gitRoot(String path) async {
  try {
    final ProcessResult result =
        await _runGit(path, <String>['rev-parse', '--show-toplevel']);
    if (result.exitCode != 0) {
      return null;
    }
    final String stdout = (result.stdout as String?) ?? '';
    return stdout.trim().isEmpty ? null : stdout.trim();
  } catch (_) {
    return null;
  }
}

Future<List<String>> listChangedFiles(
  String path,
  String leftRef,
  String rightRef,
) async {
  return listChangedFilesInScope(path, leftRef, rightRef, null);
}

Future<List<String>> listChangedFilesInScope(
  String path,
  String leftRef,
  String rightRef,
  String? pathSpec,
) async {
  try {
    final bool useWorktree = rightRef == kWorktreeRef;
    final ProcessResult result = await _runGit(path, <String>[
      'diff',
      '--name-only',
      leftRef,
      if (!useWorktree) rightRef,
      if (pathSpec != null) pathSpec,
    ]);
    if (result.exitCode != 0) {
      return <String>[];
    }
    final String stdout = (result.stdout as String?) ?? '';
    return stdout
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();
  } catch (_) {
    return <String>[];
  }
}

Future<String?> fileContentAtRef(
  String path,
  String ref,
  String filePath,
) async {
  if (ref == kWorktreeRef) {
    try {
      final File file = File(p.join(path, filePath));
      if (!await file.exists()) {
        return null;
      }
      final List<int> bytes = await file.readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
  try {
    final ProcessResult result =
        await _runGit(path, <String>['show', '$ref:$filePath'],
            logStdoutSnippet: false);
    if (result.exitCode != 0) {
      return null;
    }
    return _decodeOutput(result.stdout);
  } catch (_) {
    return null;
  }
}

Future<List<SymbolDiff>> loadSymbolDiffs(
  String repoPath,
  String leftRef,
  String rightRef, {
  bool dartOnly = true,
}) async {
  final bool repoOk = await isGitRepo(repoPath);
  if (!repoOk) {
    return <SymbolDiff>[];
  }

  final String? root = await gitRoot(repoPath);
  final String repoRoot = root ?? repoPath;
  final bool isSubdir = root != null && !p.equals(p.normalize(repoPath), root);
  final String? relativeScope =
      isSubdir ? p.relative(repoPath, from: repoRoot) : null;

  final List<String> files = await listChangedFilesInScope(
    repoRoot,
    leftRef,
    rightRef,
    relativeScope,
  );
  final Iterable<String> filtered = dartOnly
      ? files.where((String f) => f.endsWith('.dart'))
      : files;

  final List<SymbolDiff> diffs = <SymbolDiff>[];
  for (final String file in filtered) {
    final String? left = await fileContentAtRef(repoRoot, leftRef, file);
    final String? right = await fileContentAtRef(repoRoot, rightRef, file);
    diffs.add(
      SymbolDiff(
        change: SymbolChange(
          name: file,
          kind: SymbolKind.other,
          beforePath: file,
          afterPath: file,
        ),
        leftSnippet: left ?? '',
        rightSnippet: right ?? '',
      ),
    );
  }

  return diffs;
}

Future<List<CodeChunk>> loadChunkDiffs(
  String repoPath,
  String leftRef,
  String rightRef, {
  bool dartOnly = true,
}) async {
  final bool repoOk = await isGitRepo(repoPath);
  if (!repoOk) {
    return <CodeChunk>[];
  }

  final String? root = await gitRoot(repoPath);
  final String repoRoot = root ?? repoPath;
  final bool isSubdir = root != null && !p.equals(p.normalize(repoPath), root);
  final String? relativeScope =
      isSubdir ? p.relative(repoPath, from: repoRoot) : null;

  final List<String> files = await listChangedFilesInScope(
    repoRoot,
    leftRef,
    rightRef,
    relativeScope,
  );
  final Iterable<String> filtered = dartOnly
      ? files.where((String f) => f.endsWith('.dart'))
      : files;

  final List<CodeChunk> chunks = <CodeChunk>[];
  for (final String file in filtered) {
    final List<_Hunk> hunks =
        await _parseGitHunks(repoRoot, leftRef, rightRef, file);
    if (hunks.isEmpty) {
      continue;
    }
    final List<_Hunk> merged = _mergeHunks(hunks, gapThreshold: 6);

    final String? leftContent = await fileContentAtRef(repoRoot, leftRef, file);
    final String? rightContent =
        await fileContentAtRef(repoRoot, rightRef, file);
    if (leftContent == null || rightContent == null) {
      continue;
    }
    final List<String> leftLines = leftContent.split('\n');
    final List<String> rightLines = rightContent.split('\n');

    for (final _Hunk h in merged) {
      final int oldStart = h.oldStart;
      final int oldEnd = h.oldStart + h.oldCount - 1;
      final int newStart = h.newStart;
      final int newEnd = h.newStart + h.newCount - 1;

      final String leftSnippet =
          _sliceLines(leftLines, oldStart, oldEnd).join('\n');
      final String rightSnippet =
          _sliceLines(rightLines, newStart, newEnd).join('\n');

      chunks.add(
        CodeChunk(
          filePath: file,
          oldStart: oldStart,
          oldEnd: oldEnd,
          newStart: newStart,
          newEnd: newEnd,
          leftText: leftSnippet,
          rightText: rightSnippet,
        ),
      );
    }
  }

  return chunks;
}

Future<List<CodeHunk>> loadHunkDiffs(
  String repoPath,
  String leftRef,
  String rightRef, {
  bool dartOnly = true,
}) async {
  final bool repoOk = await isGitRepo(repoPath);
  if (!repoOk) {
    return <CodeHunk>[];
  }

  final String? root = await gitRoot(repoPath);
  final String repoRoot = root ?? repoPath;
  final bool isSubdir = root != null && !p.equals(p.normalize(repoPath), root);
  final String? relativeScope =
      isSubdir ? p.relative(repoPath, from: repoRoot) : null;

  final List<String> files = await listChangedFilesInScope(
    repoRoot,
    leftRef,
    rightRef,
    relativeScope,
  );
  final Iterable<String> filtered = dartOnly
      ? files.where((String f) => f.endsWith('.dart'))
      : files;

  final List<CodeHunk> hunks = <CodeHunk>[];
  for (final String file in filtered) {
    final String? leftContent = await fileContentAtRef(repoRoot, leftRef, file);
    final String? rightContent =
        await fileContentAtRef(repoRoot, rightRef, file);
    final List<String> leftLines =
        leftContent != null ? leftContent.split('\n') : <String>[];
    final List<String> rightLines =
        rightContent != null ? rightContent.split('\n') : <String>[];

    final List<_ParsedHunk> parsed =
        await _parseGitHunksWithLines(repoRoot, leftRef, rightRef, file);
    if (parsed.isEmpty) {
      // New file or removed file: treat whole file as one hunk.
      if (rightContent != null && leftContent == null) {
        final int newCount = rightLines.length;
        hunks.add(
          CodeHunk(
            filePath: file,
            oldStart: 0,
            oldCount: 0,
            newStart: 1,
            newCount: newCount,
            leftText: '',
            rightText: rightLines.join('\n'),
            lines: List<DiffLine>.generate(
              newCount,
              (int i) => DiffLine(
                leftNumber: null,
                rightNumber: i + 1,
                leftText: '',
                rightText: rightLines[i],
                status: DiffLineStatus.added,
              ),
            ),
          ),
        );
      } else if (leftContent != null && rightContent == null) {
        final int oldCount = leftLines.length;
        hunks.add(
          CodeHunk(
            filePath: file,
            oldStart: 1,
            oldCount: oldCount,
            newStart: 0,
            newCount: 0,
            leftText: leftLines.join('\n'),
            rightText: '',
            lines: List<DiffLine>.generate(
              oldCount,
              (int i) => DiffLine(
                leftNumber: i + 1,
                rightNumber: null,
                leftText: leftLines[i],
                rightText: '',
                status: DiffLineStatus.removed,
              ),
            ),
          ),
        );
      }
      continue;
    }

    for (final _ParsedHunk h in parsed) {
      final int oldStart = h.header.oldStart;
      final int oldEnd = h.header.oldStart + h.header.oldCount - 1;
      final int newStart = h.header.newStart;
      final int newEnd = h.header.newStart + h.header.newCount - 1;

      final String leftSnippet =
          _sliceLines(leftLines, oldStart, oldEnd).join('\n');
      final String rightSnippet =
          _sliceLines(rightLines, newStart, newEnd).join('\n');

      hunks.add(
        CodeHunk(
          filePath: file,
          oldStart: oldStart,
          oldCount: h.header.oldCount,
          newStart: newStart,
          newCount: h.header.newCount,
          leftText: leftSnippet,
          rightText: rightSnippet,
          lines: h.lines,
        ),
      );
    }
  }

  return hunks;
}

class _Hunk {
  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;

  const _Hunk({
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
  });
}

Future<List<_Hunk>> _parseGitHunks(
  String repoPath,
  String leftRef,
  String rightRef,
  String file,
) async {
  try {
    final bool useWorktree = rightRef == kWorktreeRef;
    final List<String> args = <String>[
      'diff',
      '-U3',
      leftRef,
      if (!useWorktree) rightRef,
      '--',
      file,
    ];
    final ProcessResult result = await _runGit(
      repoPath,
      args,
      logStdoutSnippet: false,
    );
    if (result.exitCode != 0) {
      return <_Hunk>[];
    }
    final String output = _decodeOutput(result.stdout);
    final RegExp header =
        RegExp(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@');
    final List<_Hunk> hunks = <_Hunk>[];
    for (final String line in output.split('\n')) {
      final RegExpMatch? m = header.firstMatch(line);
      if (m != null) {
        final int oldStart = int.parse(m.group(1)!);
        final int oldCount = m.group(2) != null ? int.parse(m.group(2)!) : 1;
        final int newStart = int.parse(m.group(3)!);
        final int newCount = m.group(4) != null ? int.parse(m.group(4)!) : 1;
        hunks.add(_Hunk(
          oldStart: oldStart,
          oldCount: oldCount,
          newStart: newStart,
          newCount: newCount,
        ));
      }
    }
    return hunks;
  } catch (_) {
    return <_Hunk>[];
  }
}

class _ParsedHunk {
  final _Hunk header;
  final List<DiffLine> lines;

  const _ParsedHunk({required this.header, required this.lines});
}

Future<List<_ParsedHunk>> _parseGitHunksWithLines(
  String repoPath,
  String leftRef,
  String rightRef,
  String file,
) async {
  try {
    final bool useWorktree = rightRef == kWorktreeRef;
    final List<String> args = <String>[
      'diff',
      '-U3',
      leftRef,
      if (!useWorktree) rightRef,
      '--',
      file,
    ];
    final ProcessResult result = await _runGit(
      repoPath,
      args,
      logStdoutSnippet: false,
    );
    if (result.exitCode != 0) {
      return <_ParsedHunk>[];
    }
    final String output = _decodeOutput(result.stdout);
    final RegExp header =
        RegExp(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@');
    final List<_ParsedHunk> parsed = <_ParsedHunk>[];
    _Hunk? currentHeader;
    List<DiffLine> currentLines = <DiffLine>[];
    int currentOld = 0;
    int currentNew = 0;

    void flush() {
      if (currentHeader != null) {
        parsed.add(_ParsedHunk(header: currentHeader!, lines: currentLines));
      }
    }

    for (final String raw in output.split('\n')) {
      final RegExpMatch? m = header.firstMatch(raw);
      if (m != null) {
        flush();
        final int oldStart = int.parse(m.group(1)!);
        final int oldCount = m.group(2) != null ? int.parse(m.group(2)!) : 1;
        final int newStart = int.parse(m.group(3)!);
        final int newCount = m.group(4) != null ? int.parse(m.group(4)!) : 1;
        currentHeader = _Hunk(
          oldStart: oldStart,
          oldCount: oldCount,
          newStart: newStart,
          newCount: newCount,
        );
        currentLines = <DiffLine>[];
        currentOld = oldStart;
        currentNew = newStart;
        continue;
      }

      if (currentHeader == null) {
        continue;
      }

      if (raw.startsWith('+')) {
        final String text = raw.substring(1);
        currentLines.add(DiffLine(
          leftNumber: null,
          rightNumber: currentNew,
          leftText: '',
          rightText: text,
          status: DiffLineStatus.added,
        ));
        currentNew++;
      } else if (raw.startsWith('-')) {
        final String text = raw.substring(1);
        currentLines.add(DiffLine(
          leftNumber: currentOld,
          rightNumber: null,
          leftText: text,
          rightText: '',
          status: DiffLineStatus.removed,
        ));
        currentOld++;
      } else if (raw.startsWith(' ')) {
        final String text = raw.substring(1);
        currentLines.add(DiffLine(
          leftNumber: currentOld,
          rightNumber: currentNew,
          leftText: text,
          rightText: text,
          status: DiffLineStatus.context,
        ));
        currentOld++;
        currentNew++;
      } else {
        // Skip other markers (e.g., \ No newline at end of file).
      }
    }
    flush();
    return parsed;
  } catch (_) {
    return <_ParsedHunk>[];
  }
}

List<_Hunk> _mergeHunks(List<_Hunk> hunks, {int gapThreshold = 6}) {
  if (hunks.isEmpty) return hunks;
  final List<_Hunk> sorted = List<_Hunk>.from(hunks)
    ..sort((a, b) => a.oldStart.compareTo(b.oldStart));
  final List<_Hunk> merged = <_Hunk>[];
  _Hunk current = sorted.first;
  for (int i = 1; i < sorted.length; i++) {
    final _Hunk next = sorted[i];
    final int currentOldEnd = current.oldStart + current.oldCount - 1;
    final int nextOldStart = next.oldStart;
    final int gap = nextOldStart - currentOldEnd - 1;
    if (gap <= gapThreshold) {
      final int newOldStart = current.oldStart;
      final int newOldEnd = next.oldStart + next.oldCount - 1;
      final int newNewStart = current.newStart;
      final int newNewEnd = next.newStart + next.newCount - 1;
      current = _Hunk(
        oldStart: newOldStart,
        oldCount: (newOldEnd - newOldStart) + 1,
        newStart: newNewStart,
        newCount: (newNewEnd - newNewStart) + 1,
      );
    } else {
      merged.add(current);
      current = next;
    }
  }
  merged.add(current);
  return merged;
}

List<String> _sliceLines(List<String> lines, int start, int end) {
  if (start <= 0) start = 1;
  if (end < start) return <String>[];
  final int startIdx = start - 1;
  final int endIdx = end.clamp(0, lines.length);
  return lines.sublist(startIdx, endIdx);
}

  List<DiffLine> _buildAlignedLines(
  List<String> leftLines,
  int leftStart,
  List<String> rightLines,
  int rightStart,
) {
  final List<DiffLine> result = <DiffLine>[];
  final int leftLen = leftLines.length;
  final int rightLen = rightLines.length;
  final int maxLen = leftLen > rightLen ? leftLen : rightLen;
  for (int i = 0; i < maxLen; i++) {
    final String leftText = i < leftLen ? leftLines[i] : '';
    final String rightText = i < rightLen ? rightLines[i] : '';
    final int? leftNum = i < leftLen ? leftStart + i : null;
    final int? rightNum = i < rightLen ? rightStart + i : null;
    DiffLineStatus status = DiffLineStatus.context;
    if (leftNum == null && rightNum != null) {
      status = DiffLineStatus.added;
    } else if (leftNum != null && rightNum == null) {
      status = DiffLineStatus.removed;
    } else if (leftText != rightText) {
      status = DiffLineStatus.changed;
    }
    result.add(DiffLine(
      leftNumber: leftNum,
      rightNumber: rightNum,
      leftText: leftText,
      rightText: rightText,
      status: status,
    ));
  }
  return result;
}

// Logging helpers for external commands
const bool kLogExternalCommands = true;
const bool kLogFullStdout = false;

Future<ProcessResult> _runGit(
  String workingDirectory,
  List<String> args, {
  bool? logStdoutSnippet,
}) async {
  final String commandDescription =
      'git ${args.join(' ')} (cwd: $workingDirectory)';
  if (kLogExternalCommands) {
    stdout.writeln('[chunkdiff_core] RUN $commandDescription');
  }
  final ProcessResult result = await Process.run(
    'git',
    args,
    workingDirectory: workingDirectory,
  );
  if (kLogExternalCommands) {
    stdout.writeln(
        '[chunkdiff_core] EXIT ${result.exitCode} for $commandDescription');
    final String out = _decodeOutput(result.stdout).trim();
    if (out.isNotEmpty) {
      final bool useSnippet = logStdoutSnippet ?? !kLogFullStdout;
      if (useSnippet) {
        stdout.writeln(
          '[chunkdiff_core] STDOUT (${out.length} chars): ${_snippet(out)}',
        );
      } else {
        stdout.writeln(
          '[chunkdiff_core] STDOUT (${out.length} chars): $out',
        );
      }
    }
    final String err = (result.stderr as String? ?? '').trim();
    if (err.isNotEmpty) {
      stdout.writeln('[chunkdiff_core] STDERR: ${_snippet(err)}');
    }
  }
  return result;
}

String _snippet(String text, {int max = 200}) {
  if (text.length <= max) {
    return text;
  }
  return '${text.substring(0, max)}... (truncated)';
}

String _decodeOutput(Object? data) {
  if (data == null) return '';
  if (data is String) return data;
  if (data is List<int>) {
    try {
      return utf8.decode(data, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(<int>[]);
    }
  }
  return data.toString();
}
