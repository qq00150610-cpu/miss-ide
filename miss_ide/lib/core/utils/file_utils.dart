// lib/core/utils/file_utils.dart - 文件工具类

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

/// 文件工具类
class FileUtils {
  FileUtils._();
  
  /// 读取文件内容（支持大文件分页）
  static Future<List<String>> readFileLines(
    String filePath, {
    int? startLine,
    int? count,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    
    final lines = <String>[];
    await for (final line in file.openRead().transform(utf8.decoder).transform(const LineSplitter())) {
      lines.add(line);
    }
    
    if (startLine != null && count != null) {
      final endLine = (startLine + count).clamp(0, lines.length);
      return lines.sublist(startLine.clamp(0, lines.length), endLine);
    }
    
    return lines;
  }
  
  /// 读取文件全部内容
  static Future<String> readFileContent(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    return file.readAsString();
  }
  
  /// 写入文件内容
  static Future<void> writeFileContent(String filePath, String content) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
  
  /// 创建目录
  static Future<Directory> createDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
  
  /// 列出目录内容
  static Future<List<FileSystemEntity>> listDirectory(
    String dirPath, {
    bool recursive = false,
    bool followLinks = false,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      throw FileSystemException('Directory not found', dirPath);
    }
    return dir.list(
      recursive: recursive,
      followLinks: followLinks,
    ).toList();
  }
  
  /// 获取文件信息
  static Future<FileStat> getFileStat(String filePath) async {
    final file = File(filePath);
    return file.stat();
  }
  
  /// 判断文件是否存在
  static Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }
  
  /// 判断目录是否存在
  static Future<bool> directoryExists(String dirPath) async {
    return Directory(dirPath).exists();
  }
  
  /// 获取文件扩展名
  static String getExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }
  
  /// 获取文件名（不含扩展名）
  static String getBaseName(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }
  
  /// 获取文件名
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
  
  /// 获取父目录路径
  static String getParentPath(String filePath) {
    return path.dirname(filePath);
  }
  
  /// 获取相对路径
  static String getRelativePath(String filePath, String basePath) {
    return path.relative(filePath, from: basePath);
  }
  
  /// 合并路径
  static String joinPath(String base, String child) {
    return path.join(base, child);
  }
  
  /// 获取文件大小描述
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 获取文件类型图标名称
  static String getFileIconName(String filePath) {
    final ext = getExtension(filePath);
    switch (ext) {
      case '.apk':
        return 'apk';
      case '.dex':
        return 'dex';
      case '.jar':
        return 'jar';
      case '.smali':
        return 'smali';
      case '.java':
        return 'java';
      case '.xml':
        return 'xml';
      case '.json':
        return 'json';
      default:
        return 'file';
    }
  }
  
  /// 过滤文件列表
  static List<FileSystemEntity> filterFiles(
    List<FileSystemEntity> files, {
    List<String>? extensions,
    bool includeDirectories = true,
  }) {
    return files.where((file) {
      if (file is Directory) {
        return includeDirectories;
      }
      if (extensions != null && extensions.isNotEmpty) {
        final ext = getExtension(file.path).toLowerCase();
        return extensions.contains(ext);
      }
      return true;
    }).toList();
  }
  
  /// 排序文件列表（目录在前，文件在后，按名称排序）
  static List<FileSystemEntity> sortFiles(List<FileSystemEntity> files) {
    files.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return path.basename(a.path).toLowerCase().compareTo(
        path.basename(b.path).toLowerCase(),
      );
    });
    return files;
  }
}
