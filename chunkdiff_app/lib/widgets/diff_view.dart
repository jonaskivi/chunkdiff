import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';

import '../providers.dart';

class DiffView extends ConsumerStatefulWidget {
  const DiffView({super.key});

  @override
  ConsumerState<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends ConsumerState<DiffView> {
  late final CodeController _leftController;
  late final CodeController _rightController;

  @override
  void initState() {
    super.initState();
    _leftController = CodeController(
      text: ref.read(leftDiffCodeProvider),
      language: dart,
    )..addListener(_onLeftChanged);
    _rightController = CodeController(
      text: ref.read(rightDiffCodeProvider),
      language: dart,
    )..addListener(_onRightChanged);
  }

  void _onLeftChanged() {
    ref.read(leftDiffCodeProvider.notifier).state = _leftController.text;
  }

  void _onRightChanged() {
    ref.read(rightDiffCodeProvider.notifier).state = _rightController.text;
  }

  @override
  void dispose() {
    _leftController.removeListener(_onLeftChanged);
    _rightController.removeListener(_onRightChanged);
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DiffPane(
            title: 'Left (old)',
            controller: _leftController,
            backgroundColor: const Color(0xFFFFF3F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DiffPane(
            title: 'Right (new)',
            controller: _rightController,
            backgroundColor: const Color(0xFFF2FFF4),
          ),
        ),
      ],
    );
  }
}

class _DiffPane extends StatelessWidget {
  const _DiffPane({
    required this.title,
    required this.controller,
    required this.backgroundColor,
  });

  final String title;
  final CodeController controller;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CodeTheme(
                data: CodeThemeData(styles: githubTheme),
                child: CodeField(
                  controller: controller,
                  textStyle: const TextStyle(
                    fontFamily: 'SourceCodePro',
                    fontSize: 13,
                  ),
                  expands: true,
                  lineNumberStyle: const LineNumberStyle(
                    width: 40,
                    textStyle: TextStyle(color: Color(0xFF8A8A8A)),
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
