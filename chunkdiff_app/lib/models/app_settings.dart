class AppSettings {
  final String? gitFolder;
  final int selectedChunkIndex;
  final bool showDebugInfo;
  final String debugSearch;

  const AppSettings({
    this.gitFolder,
    this.selectedChunkIndex = 0,
    this.showDebugInfo = false,
    this.debugSearch = '',
  });

  AppSettings copyWith({
    String? gitFolder,
    int? selectedChunkIndex,
    bool? showDebugInfo,
    String? debugSearch,
  }) {
    return AppSettings(
      gitFolder: gitFolder ?? this.gitFolder,
      selectedChunkIndex: selectedChunkIndex ?? this.selectedChunkIndex,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      debugSearch: debugSearch ?? this.debugSearch,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'gitFolder': gitFolder,
        'selectedChunkIndex': selectedChunkIndex,
        'showDebugInfo': showDebugInfo,
        'debugSearch': debugSearch,
      };

  static AppSettings fromJson(Map<String, Object?> json) {
    final Object? pathValue = json['gitFolder'];
    final Object? chunkIndex = json['selectedChunkIndex'];
    final Object? showDebugValue = json['showDebugInfo'];
    final Object? debugSearchValue = json['debugSearch'];
    return AppSettings(
      gitFolder: pathValue as String?,
      selectedChunkIndex: chunkIndex is int ? chunkIndex : 0,
      showDebugInfo: showDebugValue is bool ? showDebugValue : false,
      debugSearch: debugSearchValue is String ? debugSearchValue : '',
    );
  }
}
