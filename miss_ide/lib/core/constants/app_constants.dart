// lib/core/constants/app_constants.dart - Miss IDE 常量定义

/// 应用常量
class AppConstants {
  AppConstants._();
  
  /// 应用名称
  static const String appName = 'Miss IDE';
  static const String appVersion = '1.0.0';
  
  /// 项目配置
  static const String projectExtension = '.missproj';
  static const String defaultProjectName = 'Untitled Project';
  
  /// 文件类型
  static const List<String> supportedFileExtensions = [
    '.apk',
    '.dex',
    '.jar',
    '.smali',
    '.java',
    '.xml',
    '.json',
  ];
  
  /// 文件大小限制 (字节)
  static const int maxFileSizeForFullLoad = 10 * 1024 * 1024; // 10MB
  static const int largeFileThreshold = 1024 * 1024; // 1MB
  static const int pageLoadSize = 1000; // 分页加载行数
  
  /// 编辑器配置
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
  static const String defaultFontFamily = 'monospace';
  
  /// Diff 配置
  static const int smallFileThreshold = 500; // 小文件行数
  static const int mediumFileThreshold = 5000; // 中文件行数
  static const double scrollSyncThreshold = 30.0; // 滑动同步阈值
  
  /// 缓存配置
  static const int maxCachedProjects = 10;
  static const int maxCachedFiles = 50;
  static const Duration cacheExpiration = Duration(hours: 24);
}

/// 文件类型枚举
enum FileType {
  apk('APK', 'apk', 'application/vnd.android.package-archive'),
  dex('DEX', 'dex', 'application/vnd.android.dex'),
  jar('JAR', 'jar', 'application/java-archive'),
  smali('Smali', 'smali', 'text/plain'),
  java('Java', 'java', 'text/x-java'),
  xml('XML', 'xml', 'application/xml'),
  json('JSON', 'json', 'application/json'),
  unknown('Unknown', '', 'application/octet-stream');
  
  const FileType(this.displayName, this.extension, this.mimeType);
  
  final String displayName;
  final String extension;
  final String mimeType;
  
  /// 根据路径获取文件类型
  static FileType fromPath(String path) {
    final lowerPath = path.toLowerCase();
    for (final type in FileType.values) {
      if (lowerPath.endsWith('.${type.extension}')) {
        return type;
      }
    }
    return FileType.unknown;
  }
  
  /// 是否为可编辑文件
  bool get isEditable {
    return this == FileType.smali || 
           this == FileType.java || 
           this == FileType.xml || 
           this == FileType.json;
  }
  
  /// 是否为可对比文件
  bool get isComparable {
    return this == FileType.smali || 
           this == FileType.java || 
           this == FileType.dex;
  }
}
