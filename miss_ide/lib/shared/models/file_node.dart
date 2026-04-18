// lib/shared/models/file_node.dart - 文件树节点模型
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// 文件树节点
class FileNode extends Equatable {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
  final FileType fileType;
  final int? size;
  final DateTime? modifiedTime;
  final bool isExpanded;
  final int level;
  
  const FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
    this.fileType = FileType.unknown,
    this.size,
    this.modifiedTime,
    this.isExpanded = false,
    this.level = 0,
  });
  
  /// 复制节点
  FileNode copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    List<FileNode>? children,
    FileType? fileType,
    int? size,
    DateTime? modifiedTime,
    bool? isExpanded,
    int? level,
  }) {
    return FileNode(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
      fileType: fileType ?? this.fileType,
      size: size ?? this.size,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      isExpanded: isExpanded ?? this.isExpanded,
      level: level ?? this.level,
    );
  }
  
  /// 切换展开状态
  FileNode toggleExpanded() {
    return copyWith(isExpanded: !isExpanded);
  }
  
  /// 获取显示图标
  String get iconName {
    if (isDirectory) {
      return isExpanded ? 'folder_open' : 'folder';
    }
    return fileType.extension;
  }
  
  @override
  List<Object?> get props => [name, path, isDirectory, children, fileType, isExpanded, level];
}

/// 文件树状态
class FileTreeState extends Equatable {
  final List<FileNode> rootNodes;
  final FileNode? selectedNode;
  final bool isLoading;
  final String? error;
  final String? basePath;
  
  const FileTreeState({
    this.rootNodes = const [],
    this.selectedNode,
    this.isLoading = false,
    this.error,
    this.basePath,
  });
  
  /// 复制状态
  FileTreeState copyWith({
    List<FileNode>? rootNodes,
    FileNode? selectedNode,
    bool? isLoading,
    String? error,
    String? basePath,
  }) {
    return FileTreeState(
      rootNodes: rootNodes ?? this.rootNodes,
      selectedNode: selectedNode ?? this.selectedNode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      basePath: basePath ?? this.basePath,
    );
  }
  
  @override
  List<Object?> get props => [rootNodes, selectedNode, isLoading, error, basePath];
}
