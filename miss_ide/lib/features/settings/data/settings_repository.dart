// lib/features/settings/data/settings_repository.dart - 设置数据仓库
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/settings_model.dart';

/// 设置持久化服务
class SettingsRepository {
  static const String _settingsFileName = 'miss_ide_settings.json';
  static const String _backupFileName = 'miss_ide_settings_backup.json';
  
  String? _settingsPath;
  
  /// 初始化设置仓库
  Future<void> initialize() async {
    final appDir = _getAppDirectory();
    _settingsPath = p.join(appDir, _settingsFileName);
  }
  
  /// 获取应用数据目录
  String _getAppDirectory() {
    if (Platform.isAndroid) {
      return '/data/data/com.misside/files';
    } else if (Platform.isIOS) {
      return p.join(Directory.current.path, 'Documents');
    }
    return Directory.current.path;
  }
  
  /// 获取设置文件路径
  String get settingsPath => _settingsPath ?? 
      p.join(_getAppDirectory(), _settingsFileName);
  
  /// 加载设置
  Future<AppSettings> loadSettings() async {
    try {
      await initialize();
      final file = File(settingsPath);
      
      if (!await file.exists()) {
        return const AppSettings();
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // 尝试从备份恢复
      try {
        final backupFile = File(
            settingsPath.replaceAll(_settingsFileName, _backupFileName));
        if (await backupFile.exists()) {
          final content = await backupFile.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          return AppSettings.fromJson(json);
        }
      } catch (_) {}
      
      return const AppSettings();
    }
  }
  
  /// 保存设置
  Future<void> saveSettings(AppSettings settings) async {
    try {
      await initialize();
      final file = File(settingsPath);
      
      // 先创建备份
      if (await file.exists()) {
        await file.copy(
          settingsPath.replaceAll(_settingsFileName, _backupFileName),
        );
      }
      
      // 保存新设置
      final json = jsonEncode(settings.toJson());
      await file.writeAsString(json);
    } catch (e) {
      rethrow;
    }
  }
  
  /// 重置为默认设置
  Future<void> resetSettings() async {
    await saveSettings(const AppSettings());
  }
  
  /// 导出设置到文件
  Future<void> exportSettings(String exportPath) async {
    final settings = await loadSettings();
    final json = jsonEncode(settings.toJson());
    await File(exportPath).writeAsString(json);
  }
  
  /// 从文件导入设置
  Future<AppSettings> importSettings(String importPath) async {
    final file = File(importPath);
    if (!await file.exists()) {
      throw SettingsException('导入文件不存在');
    }
    
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final settings = AppSettings.fromJson(json);
    await saveSettings(settings);
    return settings;
  }
  
  /// 获取编辑器设置
  Future<EditorSettings> getEditorSettings() async {
    final settings = await loadSettings();
    return settings.editorSettings;
  }
  
  /// 保存编辑器设置
  Future<void> saveEditorSettings(EditorSettings editorSettings) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(editorSettings: editorSettings));
  }
  
  /// 获取主题设置
  Future<({AppThemeMode mode, CodeHighlightTheme codeTheme})> 
      getThemeSettings() async {
    final settings = await loadSettings();
    return (mode: settings.themeMode, codeTheme: settings.codeHighlightTheme);
  }
  
  /// 保存主题设置
  Future<void> saveThemeSettings({
    AppThemeMode? themeMode,
    CodeHighlightTheme? codeHighlightTheme,
  }) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(
      themeMode: themeMode,
      codeHighlightTheme: codeHighlightTheme,
    ));
  }
  
  /// 清除所有缓存
  Future<void> clearCache() async {
    // 清除应用缓存目录
    final cacheDir = _getCacheDirectory();
    if (await Directory(cacheDir).exists()) {
      await Directory(cacheDir).delete(recursive: true);
    }
  }
  
  /// 获取缓存目录
  String _getCacheDirectory() {
    if (Platform.isAndroid) {
      return '/data/data/com.misside/cache';
    }
    return p.join(Directory.current.path, 'cache');
  }
  
  /// 获取缓存大小
  Future<int> getCacheSize() async {
    final cacheDir = Directory(_getCacheDirectory());
    if (!await cacheDir.exists()) return 0;
    
    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
  
  /// 格式化缓存大小
  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 设置异常
class SettingsException implements Exception {
  final String message;
  SettingsException(this.message);
  
  @override
  String toString() => 'SettingsException: $message';
}
