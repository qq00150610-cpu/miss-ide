// lib/shared/services/project_service.dart - 项目服务
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/file_utils.dart';
import '../models/project_model.dart';

/// 项目服务
class ProjectService {
  static const String _recentProjectsKey = 'recent_projects';
  static const _uuid = Uuid();
  
  final SharedPreferences _prefs;
  
  ProjectService(this._prefs);
  
  /// 创建新项目
  Future<ProjectModel> createProject({
    required String name,
    required String path,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final project = ProjectModel(
      id: _uuid.v4(),
      name: name,
      path: path,
      createdAt: now,
      modifiedAt: now,
      status: ProjectStatus.ready,
      metadata: metadata,
    );
    
    // 保存项目配置
    await _saveProjectConfig(project);
    
    // 添加到最近项目
    await addToRecent(project);
    
    return project;
  }
  
  /// 打开项目
  Future<ProjectModel> openProject(String projectPath) async {
    final configPath = FileUtils.joinPath(projectPath, '.misside', 'config.json');
    
    if (await FileUtils.fileExists(configPath)) {
      // 读取已有配置
      final content = await FileUtils.readFileContent(configPath);
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ProjectModel.fromJson(json).copyWith(
        status: ProjectStatus.ready,
      );
    }
    
    // 创建新项目配置
    final name = FileUtils.getBaseName(projectPath);
    return createProject(name: name, path: projectPath);
  }
  
  /// 关闭项目
  Future<void> closeProject(ProjectModel project) async {
    // 保存项目状态
    await _saveProjectConfig(project);
  }
  
  /// 保存项目配置
  Future<void> _saveProjectConfig(ProjectModel project) async {
    final configDir = FileUtils.joinPath(project.path, '.misside');
    await FileUtils.createDirectory(configDir);
    
    final configPath = FileUtils.joinPath(configDir, 'config.json');
    final content = jsonEncode(project.toJson());
    await FileUtils.writeFileContent(configPath, content);
  }
  
  /// 获取最近项目列表
  Future<List<ProjectModel>> getRecentProjects() async {
    final jsonStr = _prefs.getString(_recentProjectsKey);
    if (jsonStr == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 添加到最近项目
  Future<void> addToRecent(ProjectModel project) async {
    final recentProjects = await getRecentProjects();
    
    // 移除已存在的相同项目
    recentProjects.removeWhere((p) => p.path == project.path);
    
    // 添加到列表开头
    recentProjects.insert(0, project);
    
    // 限制数量
    if (recentProjects.length > 10) {
      recentProjects.removeRange(10, recentProjects.length);
    }
    
    // 保存
    final jsonStr = jsonEncode(recentProjects.map((p) => p.toJson()).toList());
    await _prefs.setString(_recentProjectsKey, jsonStr);
  }
  
  /// 删除最近项目
  Future<void> removeFromRecent(String projectId) async {
    final recentProjects = await getRecentProjects();
    recentProjects.removeWhere((p) => p.id == projectId);
    
    final jsonStr = jsonEncode(recentProjects.map((p) => p.toJson()).toList());
    await _prefs.setString(_recentProjectsKey, jsonStr);
  }
  
  /// 检查项目是否存在
  Future<bool> projectExists(String projectPath) async {
    return FileUtils.directoryExists(projectPath);
  }
}

/// 项目服务Provider
final projectServiceProvider = Provider<ProjectService>((ref) {
  throw UnimplementedError('ProjectService must be initialized with SharedPreferences');
});

/// 初始化项目服务
final projectServiceInitializerProvider = FutureProvider<ProjectService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return ProjectService(prefs);
});
