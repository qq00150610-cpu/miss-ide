// lib/core/errors/exceptions.dart - Miss IDE 异常定义

/// Miss IDE 基础异常
class MissIDEException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  
  MissIDEException(this.message, {this.code, this.details});
  
  @override
  String toString() => 'MissIDEException: $message${code != null ? ' ($code)' : ''}';
}

/// 文件操作异常
class FileException extends MissIDEException {
  final String? path;
  
  FileException(super.message, {super.code, this.path, super.details});
  
  @override
  String toString() => 'FileException: $message${path != null ? ' at $path' : ''}';
}

/// 项目异常
class ProjectException extends MissIDEException {
  final String? projectPath;
  
  ProjectException(super.message, {super.code, this.projectPath, super.details});
}

/// 反编译异常
class DecompileException extends MissIDEException {
  final String? sourcePath;
  
  DecompileException(super.message, {super.code, this.sourcePath, super.details});
}

/// Diff 异常
class DiffException extends MissIDEException {
  DiffException(super.message, {super.code, super.details});
}

/// 编辑器异常
class EditorException extends MissIDEException {
  final String? filePath;
  
  EditorException(super.message, {super.code, this.filePath, super.details});
}

/// 平台通道异常
class PlatformException extends MissIDEException {
  PlatformException(super.message, {super.code, super.details});
}
