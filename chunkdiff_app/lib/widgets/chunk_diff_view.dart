import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chunkdiff_core/chunkdiff_core.dart';
import 'diff_lines_view.dart';
import 'package:path/path.dart' as p;

class ChunkDiffView extends StatelessWidget {
  const ChunkDiffView({
    super.key,
    required this.asyncChunks,
    required this.selectedIndex,
  });

  final AsyncValue<List<CodeChunk>> asyncChunks;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final List<CodeChunk> chunks = asyncChunks.value ?? const <CodeChunk>[];
    if (chunks.isEmpty) {
      return Center(
        child: Text(
          'No diff content to display.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[400]),
        ),
      );
    }
    final int clamped = selectedIndex.clamp(0, chunks.length - 1);
    final CodeChunk chunk = chunks[clamped];
    final String shortLeft = p.basename(chunk.filePath);
    final String shortRight = p.basename(chunk.filePath);
    return DiffLinesView(
      lines: chunk.lines,
      header:
          '${chunk.name} • ${chunk.filePath} (lines ${chunk.oldStart}-${chunk.oldEnd})',
      subtitle: chunk.ignored ? 'Ignored' : null,
      leftLabel: shortLeft,
      rightLabel: shortRight,
      scrollable: true,
    );
  }
}
