class AppSettings {
  final String? repoPath;

  const AppSettings({this.repoPath});

  AppSettings copyWith({String? repoPath}) {
    return AppSettings(repoPath: repoPath ?? this.repoPath);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'repoPath': repoPath,
      };

  static AppSettings fromJson(Map<String, Object?> json) {
    final Object? pathValue = json['repoPath'];
    return AppSettings(repoPath: pathValue as String?);
  }
}
