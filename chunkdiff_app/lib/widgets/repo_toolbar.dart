import 'package:chunkdiff_app/models/app_settings.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../services/git_service.dart';

class RepoToolbar extends ConsumerWidget {
  const RepoToolbar({super.key});

  Future<void> _selectFolder(WidgetRef ref) async {
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setRepoPath(directoryPath);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settings = ref.watch(settingsControllerProvider);
    final AsyncValue<GitValidationResult> validation =
        ref.watch(repoValidationProvider);

    final String repoPath = settings.maybeWhen(
      data: (AppSettings data) => data.repoPath ?? 'No repo selected',
      orElse: () => 'Loading...',
    );

    final String statusText = validation.maybeWhen(
      data: (GitValidationResult result) => result.message ?? '',
      loading: () => 'Validating repo...',
      orElse: () => 'No repository selected',
    );

    final bool isRepo = validation.maybeWhen(
      data: (GitValidationResult result) => result.isRepo,
      orElse: () => false,
    );

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _selectFolder(ref),
          icon: const Icon(Icons.folder_open),
          label: const Text('Open folder...'),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                repoPath,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isRepo ? Colors.green[700] : Colors.red[700],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(repoValidationProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Re-validate'),
        ),
      ],
    );
  }
}
