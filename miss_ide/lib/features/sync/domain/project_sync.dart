// lib/features/sync/domain/project_sync.dart - 项目同步模型
/// 项目同步模型
class ProjectSync {
  final String id;
  final String name;
  final String path;
  final DateTime lastModified;
  final DateTime? lastSyncedAt;
  final bool isSynced;
  final ProjectSyncStatus status;

  const ProjectSync({
    required this.id,
    required this.name,
    required this.path,
    required this.lastModified,
    this.lastSyncedAt,
    this.isSynced = false,
    this.status = ProjectSyncStatus.local,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'lastModified': lastModified.toIso8601String(),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'isSynced': isSynced,
    'status': status.name,
  };

  factory ProjectSync.fromJson(Map<String, dynamic> json) {
    return ProjectSync(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      isSynced: json['isSynced'] as bool? ?? false,
      status: ProjectSyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectSyncStatus.local,
      ),
    );
  }

  ProjectSync copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? lastModified,
    DateTime? lastSyncedAt,
    bool? isSynced,
    ProjectSyncStatus? status,
  }) {
    return ProjectSync(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      lastModified: lastModified ?? this.lastModified,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
      status: status ?? this.status,
    );
  }
}

/// 项目同步状态
enum ProjectSyncStatus {
  local,      // 仅本地
  syncing,    // 同步中
  synced,     // 已同步
  conflict,   // 冲突
  error,      // 错误
}
