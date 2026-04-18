// lib/features/project/presentation/bloc/project_bloc.dart - 项目状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/services/project_service.dart';
import '../../../../shared/services/file_tree_service.dart';
import '../../../../shared/models/file_node.dart';

// 项目状态
enum ProjectStateStatus {
  initial,
  loading,
  loaded,
  error,
}

// 项目状态模型
class ProjectState {
  final ProjectStateStatus status;
  final ProjectModel? currentProject;
  final List<ProjectModel> recentProjects;
  final FileTreeState fileTree;
  final String? error;
  
  const ProjectState({
    this.status = ProjectStateStatus.initial,
    this.currentProject,
    this.recentProjects = const [],
    this.fileTree = const FileTreeState(),
    this.error,
  });
  
  ProjectState copyWith({
    ProjectStateStatus? status,
    ProjectModel? currentProject,
    List<ProjectModel>? recentProjects,
    FileTreeState? fileTree,
    String? error,
  }) {
    return ProjectState(
      status: status ?? this.status,
      currentProject: currentProject ?? this.currentProject,
      recentProjects: recentProjects ?? this.recentProjects,
      fileTree: fileTree ?? this.fileTree,
      error: error ?? this.error,
    );
  }
}

// 项目Notifier
class ProjectNotifier extends StateNotifier<ProjectState> {
  final ProjectService _projectService;
  final FileTreeService _fileTreeService;
  
  ProjectNotifier(this._projectService, this._fileTreeService)
      : super(const ProjectState()) {
    _loadRecentProjects();
  }
  
  /// 加载最近项目
  Future<void> _loadRecentProjects() async {
    try {
      final recentProjects = await _projectService.getRecentProjects();
      state = state.copyWith(
        recentProjects: recentProjects,
        status: ProjectStateStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        status: ProjectStateStatus.error,
      );
    }
  }
  
  /// 创建新项目
  Future<void> createProject({
    required String name,
    required String path,
  }) async {
    state = state.copyWith(status: ProjectStateStatus.loading);
    
    try {
      final project = await _projectService.createProject(
        name: name,
        path: path,
      );
      
      state = state.copyWith(
        status: ProjectStateStatus.loaded,
        currentProject: project,
      );
      
      await _loadRecentProjects();
      await loadFileTree(path);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        status: ProjectStateStatus.error,
      );
    }
  }
  
  /// 打开项目
  Future<void> openProject(String projectPath) async {
    state = state.copyWith(status: ProjectStateStatus.loading);
    
    try {
      final project = await _projectService.openProject(projectPath);
      
      state = state.copyWith(
        status: ProjectStateStatus.loaded,
        currentProject: project,
      );
      
      await _loadRecentProjects();
      await loadFileTree(projectPath);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        status: ProjectStateStatus.error,
      );
    }
  }
  
  /// 关闭项目
  Future<void> closeProject() async {
    if (state.currentProject != null) {
      await _projectService.closeProject(state.currentProject!);
    }
    
    state = state.copyWith(
      currentProject: null,
      fileTree: const FileTreeState(),
    );
  }
  
  /// 加载文件树
  Future<void> loadFileTree(String path) async {
    state = state.copyWith(
      fileTree: state.fileTree.copyWith(isLoading: true),
    );
    
    try {
      final nodes = await _fileTreeService.buildFileTree(path);
      
      state = state.copyWith(
        fileTree: FileTreeState(
          rootNodes: nodes,
          isLoading: false,
          basePath: path,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        fileTree: state.fileTree.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }
  
  /// 加载子节点
  Future<void> loadChildren(FileNode node) async {
    if (!node.isDirectory) return;
    
    try {
      final children = await _fileTreeService.loadChildren(node.path, node.level + 1);
      
      // 更新节点
      final updatedNodes = _updateNodeWithChildren(state.fileTree.rootNodes, node, children);
      
      state = state.copyWith(
        fileTree: state.fileTree.copyWith(rootNodes: updatedNodes),
      );
    } catch (e) {
      // 忽略错误
    }
  }
  
  /// 展开/折叠节点
  void toggleNode(FileNode node) {
    final updatedNodes = _toggleNodeExpansion(state.fileTree.rootNodes, node);
    
    state = state.copyWith(
      fileTree: state.fileTree.copyWith(rootNodes: updatedNodes),
    );
  }
  
  /// 选择节点
  void selectNode(FileNode? node) {
    state = state.copyWith(
      fileTree: state.fileTree.copyWith(selectedNode: node),
    );
  }
  
  /// 更新节点的孩子
  List<FileNode> _updateNodeWithChildren(
    List<FileNode> nodes,
    FileNode target,
    List<FileNode> children,
  ) {
    return nodes.map((node) {
      if (node.path == target.path) {
        return node.copyWith(children: children);
      }
      if (node.children.isNotEmpty) {
        return node.copyWith(
          children: _updateNodeWithChildren(node.children, target, children),
        );
      }
      return node;
    }).toList();
  }
  
  /// 切换节点展开状态
  List<FileNode> _toggleNodeExpansion(List<FileNode> nodes, FileNode target) {
    return nodes.map((node) {
      if (node.path == target.path) {
        final newNode = node.toggleExpanded();
        if (newNode.isExpanded && node.children.isEmpty) {
          // 需要加载子节点
          loadChildren(node);
        }
        return newNode;
      }
      if (node.children.isNotEmpty) {
        return node.copyWith(
          children: _toggleNodeExpansion(node.children, target),
        );
      }
      return node;
    }).toList();
  }
  
  /// 搜索文件
  Future<List<FileNode>> searchFiles(String query) async {
    if (state.fileTree.basePath == null) return [];
    return _fileTreeService.searchFiles(state.fileTree.basePath!, query);
  }
}

// Provider
final projectBlocProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  throw UnimplementedError('projectBlocProvider requires initialization');
});
