import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:chunkdiff_core/chunkdiff_core.dart';
import '../providers.dart';
import 'files_list.dart';
import 'chunk_diff_view.dart';

class DiffView extends ConsumerStatefulWidget {
  const DiffView({super.key});

  @override
  ConsumerState<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends ConsumerState<DiffView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final FocusNode _filesFocus;
  late final FocusNode _hunksFocus;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _filesFocus = FocusNode(debugLabel: 'filesFocus');
    _hunksFocus = FocusNode(debugLabel: 'hunksFocus');
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _filesFocus.dispose();
    _hunksFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SymbolDiff>> asyncDiffs =
        ref.watch(symbolDiffsProvider);
    final AsyncValue<List<CodeHunk>> asyncHunks =
        ref.watch(hunkDiffsProvider);
    final AsyncValue<List<CodeChunk>> asyncChunks =
        ref.watch(chunkDiffsProvider);
    final List<SymbolChange> changes = ref.watch(symbolChangesProvider);
    final int selectedIndex = ref.watch(selectedChangeIndexProvider);
    final String leftRef = ref.watch(leftRefProvider);
    final String rightRef = ref.watch(rightRefProvider);
    final SymbolChange? selectedChange = ref.watch(selectedChangeProvider);
    final bool hasHunkData =
        asyncHunks.hasValue && (asyncHunks.value?.isNotEmpty ?? false);
    final bool hasChunkData =
        asyncChunks.hasValue && (asyncChunks.value?.isNotEmpty ?? false);
    final bool isLoading =
        (asyncDiffs.isLoading || asyncHunks.isLoading || asyncChunks.isLoading) &&
            (!hasHunkData && !hasChunkData && changes.isEmpty);
    final bool hasChanges =
        (changes.isNotEmpty && !isLoading) || hasHunkData || hasChunkData;
    final ChangesTab activeTab = ref.watch(changesTabProvider);
    final int selectedChunkIndex = ref.watch(selectedChunkIndexProvider);

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TabSwitcher(
                activeTab: activeTab,
                onChanged: (ChangesTab tab) =>
                    ref.read(changesTabProvider.notifier).state = tab,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _SkeletonListItem(animation: _shimmerController),
                          const SizedBox(height: 12),
                          _SkeletonListItem(animation: _shimmerController),
                          const SizedBox(height: 12),
                          _SkeletonListItem(animation: _shimmerController),
                        ],
                      )
                    : hasChanges
                        ? (activeTab == ChangesTab.files
                            ? FilesList(
                                changes: changes,
                                selectedIndex: selectedIndex,
                                onSelect: (int idx) => ref
                                    .read(
                                        selectedChangeIndexProvider.notifier)
                                    .state = idx,
                                onArrowUp: () {
                                  if (selectedIndex > 0) {
                                    ref
                                        .read(selectedChangeIndexProvider
                                            .notifier)
                                        .state = selectedIndex - 1;
                                  }
                                },
                                onArrowDown: () {
                                  if (selectedIndex < changes.length - 1) {
                                    ref
                                        .read(selectedChangeIndexProvider
                                            .notifier)
                                        .state = selectedIndex + 1;
                                  }
                                },
                                focusNode: _filesFocus,
                              )
                            : activeTab == ChangesTab.hunks
                                ? _HunkList(
                                    asyncHunks: asyncHunks,
                                    selectedIndex: selectedChunkIndex,
                                    onSelect: (int idx) {
                                      ref
                                          .read(selectedChunkIndexProvider
                                              .notifier)
                                          .state = idx;
                                      ref
                                          .read(settingsControllerProvider
                                              .notifier)
                                          .setSelectedChunkIndex(idx);
                                    },
                                    onArrowUp: () {
                                      if (selectedChunkIndex > 0) {
                                        ref
                                            .read(selectedChunkIndexProvider
                                                .notifier)
                                            .state = selectedChunkIndex - 1;
                                        ref
                                            .read(
                                                settingsControllerProvider
                                                    .notifier)
                                            .setSelectedChunkIndex(
                                                selectedChunkIndex - 1);
                                      }
                                    },
                                    onArrowDown: () {
                                      final int maxIndex =
                                          (asyncHunks.value?.length ?? 0) - 1;
                                      if (selectedChunkIndex < maxIndex) {
                                        ref
                                            .read(selectedChunkIndexProvider
                                                .notifier)
                                            .state = selectedChunkIndex + 1;
                                        ref
                                            .read(
                                                settingsControllerProvider
                                                    .notifier)
                                            .setSelectedChunkIndex(
                                                selectedChunkIndex + 1);
                                      }
                                    },
                                    focusNode: _hunksFocus,
                                  )
                                : _ChunksList(
                                    asyncChunks: asyncChunks,
                                    selectedIndex: selectedChunkIndex,
                                    onSelect: (int idx) {
                                      ref
                                          .read(selectedChunkIndexProvider
                                              .notifier)
                                          .state = idx;
                                      ref
                                          .read(settingsControllerProvider
                                              .notifier)
                                          .setSelectedChunkIndex(idx);
                                    },
                                  ))
                        : Center(
                            child: Text(
                              'No changes for $leftRef → $rightRef',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                            ),
                          ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _DiffMetaBar(
                change: selectedChange,
                leftRef: leftRef,
                rightRef: rightRef,
                onPrev: () {
                  if (activeTab == ChangesTab.files) {
                    if (selectedIndex > 0) {
                      ref
                          .read(selectedChangeIndexProvider.notifier)
                          .state = selectedIndex - 1;
                    }
                  } else if (activeTab == ChangesTab.hunks) {
                    if (selectedChunkIndex > 0) {
                      ref
                          .read(selectedChunkIndexProvider.notifier)
                          .state = selectedChunkIndex - 1;
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setSelectedChunkIndex(selectedChunkIndex - 1);
                    }
                  }
                },
                onNext: () {
                  if (activeTab == ChangesTab.files) {
                    if (selectedIndex < changes.length - 1) {
                      ref
                          .read(selectedChangeIndexProvider.notifier)
                          .state = selectedIndex + 1;
                    }
                  } else if (activeTab == ChangesTab.hunks) {
                    final int maxIndex =
                        (asyncHunks.value?.length ?? 0) - 1;
                    if (selectedChunkIndex < maxIndex) {
                      ref
                          .read(selectedChunkIndexProvider.notifier)
                          .state = selectedChunkIndex + 1;
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setSelectedChunkIndex(selectedChunkIndex + 1);
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? Row(
                        children: [
                          Expanded(
                            child: _SkeletonPane(
                              animation: _shimmerController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SkeletonPane(
                              animation: _shimmerController,
                            ),
                          ),
                        ],
                      )
                    : activeTab == ChangesTab.hunks
                        ? _HunkDiffView(
                            asyncHunks: asyncHunks,
                            selectedIndex: selectedChunkIndex,
                            selectedFileChange: selectedChange,
                            activeTab: activeTab,
                          )
                        : ChunkDiffView(
                            asyncChunks: asyncChunks,
                            selectedIndex: selectedChunkIndex,
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiffMetaBar extends StatelessWidget {
  const _DiffMetaBar({
    required this.change,
    required this.leftRef,
    required this.rightRef,
    this.onPrev,
    this.onNext,
    this.alignEnd = false,
  });

  final SymbolChange? change;
  final String leftRef;
  final String rightRef;
  final bool alignEnd;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]) ??
            const TextStyle(fontSize: 12, color: Colors.grey);
    final TextStyle valueStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600) ??
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous',
              icon: const Icon(Icons.arrow_upward),
              onPressed: onPrev,
            ),
            IconButton(
              tooltip: 'Next',
              icon: const Icon(Icons.arrow_downward),
              onPressed: onNext,
            ),
            const SizedBox(width: 8),
          ],
        ),
        if (change != null) ...[
          Text('Symbol: ', style: labelStyle),
          Text(change!.name, style: valueStyle),
          const SizedBox(width: 12),
          Text('Kind: ', style: labelStyle),
          Text(change!.kind.name, style: valueStyle),
          const SizedBox(width: 12),
        ],
        Text('Left: ', style: labelStyle),
        Text(leftRef, style: valueStyle),
        const SizedBox(width: 8),
        Text('Right: ', style: labelStyle),
        Text(rightRef, style: valueStyle),
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
    return Column(
      children: [
        DecoratedBox(
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
        ),
      ],
    );
  }
}

class _SkeletonPane extends StatelessWidget {
  const _SkeletonPane({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SkeletonBox(
        height: double.infinity,
        animation: animation,
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.activeTab,
    required this.onChanged,
  });

  final ChangesTab activeTab;
  final ValueChanged<ChangesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _TabChip(
          label: 'Files',
          selected: activeTab == ChangesTab.files,
          onTap: () => onChanged(ChangesTab.files),
        ),
        _TabChip(
          label: 'Hunks',
          selected: activeTab == ChangesTab.hunks,
          onTap: () => onChanged(ChangesTab.hunks),
        ),
        _TabChip(
          label: 'Chunks',
          selected: activeTab == ChangesTab.chunks,
          onTap: () => onChanged(ChangesTab.chunks),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.indigo.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? Colors.indigo[100] : Colors.grey[300],
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _HunkList extends StatelessWidget {
  const _HunkList({
    required this.asyncHunks,
    required this.selectedIndex,
    required this.onSelect,
    this.focusNode,
    this.onArrowUp,
    this.onArrowDown,
  });

  final AsyncValue<List<CodeHunk>> asyncHunks;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final FocusNode? focusNode;
  final VoidCallback? onArrowUp;
  final VoidCallback? onArrowDown;

  @override
  Widget build(BuildContext context) {
    final List<CodeHunk> chunks =
        asyncHunks.value ?? const <CodeHunk>[];

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

    return Focus(
      focusNode: focusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
        final LogicalKeyboardKey key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowUp) {
          onArrowUp?.call();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          onArrowDown?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: chunks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final CodeHunk chunk = chunks[index];
          final bool selected = index == selectedIndex;
          return ListTile(
            dense: true,
            selected: selected,
            title: Text(chunk.filePath),
            subtitle: Text(
              'Old ${chunk.oldStart}-${chunk.oldStart + chunk.oldCount - 1} → '
              'New ${chunk.newStart}-${chunk.newStart + chunk.newCount - 1}',
            ),
            onTap: () {
              focusNode?.requestFocus();
              onSelect(index);
            },
          );
        },
      ),
    );
  }
}

class _ChunksPlaceholder extends StatelessWidget {
  const _ChunksPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HunkLinesView extends StatelessWidget {
  const _HunkLinesView({required this.hunk, required this.scrollable});

  final CodeHunk hunk;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final List<DiffLine> lines = hunk.lines;
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final Widget header = Text(
      '${hunk.filePath}  (Old ${hunk.oldStart}-${hunk.oldStart + hunk.oldCount - 1} → '
      'New ${hunk.newStart}-${hunk.newStart + hunk.newCount - 1})',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Colors.grey[400]),
    );

    if (scrollable) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: lines.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: header,
            );
          }
          final DiffLine line = lines[index - 1];
          return _DiffLineRow(line: line);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 8),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lines.length,
          itemBuilder: (BuildContext context, int index) {
            final DiffLine line = lines[index];
            return _DiffLineRow(line: line);
          },
        ),
      ],
    );
  }
}

class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.line});

  final DiffLine line;

  Color _bgLeft() {
    switch (line.status) {
      case DiffLineStatus.removed:
        return const Color(0xFF3b1f1f);
      case DiffLineStatus.changed:
        return const Color(0xFF2f2424);
      default:
        return Colors.transparent;
    }
  }

  Color _bgRight() {
    switch (line.status) {
      case DiffLineStatus.added:
        return const Color(0xFF1f3b1f);
      case DiffLineStatus.changed:
        return const Color(0xFF243b24);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = const TextStyle(
      fontFamily: 'SourceCodePro',
      fontSize: 13,
      color: Colors.white,
    );
    final TextStyle numberStyle = TextStyle(
      fontFamily: 'SourceCodePro',
      fontSize: 12,
      color: Colors.grey[500],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              line.leftNumber?.toString() ?? '',
              textAlign: TextAlign.right,
              style: numberStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgLeft(),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
              child: SelectableText(
                line.leftText,
                style: textStyle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              line.rightNumber?.toString() ?? '',
              textAlign: TextAlign.right,
              style: numberStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgRight(),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
              child: SelectableText(
                line.rightText,
                style: textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HunkDiffView extends StatelessWidget {
  const _HunkDiffView({
    required this.asyncHunks,
    required this.selectedIndex,
    required this.selectedFileChange,
    required this.activeTab,
  });

  final AsyncValue<List<CodeHunk>> asyncHunks;
  final int selectedIndex;
  final SymbolChange? selectedFileChange;
  final ChangesTab activeTab;

  @override
  Widget build(BuildContext context) {
    final List<CodeHunk> all = asyncHunks.value ?? const <CodeHunk>[];
    if (all.isEmpty) {
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

    if (activeTab == ChangesTab.hunks) {
      final int clampedIndex = selectedIndex.clamp(0, all.length - 1);
      final CodeHunk hunk = all[clampedIndex];
      return _HunkLinesView(hunk: hunk, scrollable: true);
    }

    if (activeTab == ChangesTab.files) {
      final String? targetFile =
          selectedFileChange?.beforePath ?? selectedFileChange?.afterPath;
      final List<CodeHunk> filtered = targetFile == null
          ? all
          : all.where((CodeHunk h) => h.filePath == targetFile).toList();
      if (filtered.isEmpty) {
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
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final CodeHunk hunk = filtered[index];
          return _HunkLinesView(hunk: hunk, scrollable: false);
        },
      );
    }

    return const _ChunksPlaceholder();
  }
}

class _ChunksList extends StatelessWidget {
  const _ChunksList({
    required this.asyncChunks,
    required this.selectedIndex,
    required this.onSelect,
  });

  final AsyncValue<List<CodeChunk>> asyncChunks;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

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

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: chunks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final CodeChunk chunk = chunks[index];
        final bool selected = index == selectedIndex;
        return ListTile(
          dense: true,
          selected: selected,
          title: Text(chunk.name),
          subtitle: Text(
            '${chunk.filePath} | lines ${chunk.oldStart}-${chunk.oldEnd}',
          ),
          trailing: chunk.ignored
              ? Chip(
                  label: const Text('Ignored'),
                  backgroundColor: Colors.grey.shade800,
                  labelStyle: const TextStyle(color: Colors.white70),
                  visualDensity: VisualDensity.compact,
                )
              : null,
          onTap: () => onSelect(index),
        );
      },
    );
  }
}

class _SkeletonListItem extends StatelessWidget {
  const _SkeletonListItem({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        return SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(
                child: SkeletonBox(
                  height: 70,
                  animation: animation,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.height,
    required this.animation,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey.shade800;
    final Color highlightColor = Colors.grey.shade700;
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        final double t = animation.value;
        final double dx = (t * 2.0) - 1.0; // -1 to 1
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment(dx, 0),
              end: Alignment(dx + 1, 0),
              colors: <Color>[
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
          ),
        );
      },
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
