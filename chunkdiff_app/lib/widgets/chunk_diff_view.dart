import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chunkdiff_core/chunkdiff_core.dart';

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
    final String leftText = _sanitizeText(chunk.leftText);
    final String rightText = _sanitizeText(chunk.rightText);
    return Row(
      children: [
        Expanded(
          child: _DiffPane(
            text: leftText,
            backgroundColor: const Color(0xFF272822),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DiffPane(
            text: rightText,
            backgroundColor: const Color(0xFF272822),
          ),
        ),
      ],
    );
  }
}

class _DiffPane extends StatelessWidget {
  const _DiffPane({
    required this.text,
    required this.backgroundColor,
  });

  final String text;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: 240,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'SourceCodePro',
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _sanitizeText(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in input.runes) {
    if (rune >= 0 && rune <= 0x10FFFF) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
