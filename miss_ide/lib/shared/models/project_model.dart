// lib/shared/models/project_model.dart - 项目模型
import 'package:equatable/equatable.dart';

/// 项目状态
enum ProjectStatus {
  idle,
  loading,
  ready,
  error,
}

/// 项目模型
class ProjectModel extends Equatable {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final ProjectStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  
  const ProjectModel({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.modifiedAt,
    this.status = ProjectStatus.idle,
    this.errorMessage,
    this.metadata,
  });
  
  /// 创建空项目
  factory ProjectModel.empty() {
    final now = DateTime.now();
    return ProjectModel(
      id: '',
      name: 'Untitled',
      path: '',
      createdAt: now,
      modifiedAt: now,
    );
  }
  
  /// 复制项目
  ProjectModel copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    DateTime? modifiedAt,
    ProjectStatus? status,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }
  
  /// 从JSON创建
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.idle,
      ),
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }
  
  @override
  List<Object?> get props => [id, name, path, createdAt, modifiedAt, status, errorMessage];
}
