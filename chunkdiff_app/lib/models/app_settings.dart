class AppSettings {
  final String? gitFolder;
  final int selectedChunkIndex;

  const AppSettings({
    this.gitFolder,
    this.selectedChunkIndex = 0,
  });

  AppSettings copyWith({
    String? gitFolder,
    int? selectedChunkIndex,
  }) {
    return AppSettings(
      gitFolder: gitFolder ?? this.gitFolder,
      selectedChunkIndex: selectedChunkIndex ?? this.selectedChunkIndex,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'gitFolder': gitFolder,
        'selectedChunkIndex': selectedChunkIndex,
      };

  static AppSettings fromJson(Map<String, Object?> json) {
    final Object? pathValue = json['gitFolder'];
    final Object? chunkIndex = json['selectedChunkIndex'];
    return AppSettings(
      gitFolder: pathValue as String?,
      selectedChunkIndex: chunkIndex is int ? chunkIndex : 0,
    );
  }
}
