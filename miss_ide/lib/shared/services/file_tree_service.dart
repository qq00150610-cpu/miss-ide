// lib/shared/services/file_tree_service.dart - 文件树服务
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/file_utils.dart';
import '../models/file_node.dart';

/// 文件树服务
class FileTreeService {
  /// 构建文件树
  Future<List<FileNode>> buildFileTree(String rootPath) async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      return [];
    }
    
    final nodes = <FileNode>[];
    await _buildNodes(rootDir, nodes, 0);
    
    return nodes;
  }
  
  /// 递归构建节点
  Future<void> _buildNodes(Directory dir, List<FileNode> nodes, int level) async {
    try {
      final entities = await dir.list().toList();
      
      // 过滤和排序
      final filtered = FileUtils.filterFiles(
        entities,
        extensions: AppConstants.supportedFileExtensions,
      );
      final sorted = FileUtils.sortFiles(filtered);
      
      for (final entity in sorted) {
        final isDir = entity is Directory;
        final name = FileUtils.getFileName(entity.path);
        
        // 跳过隐藏文件和目录
        if (name.startsWith('.')) continue;
        
        FileStat? stat;
        try {
          stat = await entity.stat();
        } catch (e) {
          continue;
        }
        
        final node = FileNode(
          name: name,
          path: entity.path,
          isDirectory: isDir,
          fileType: isDir ? FileType.unknown : FileType.fromPath(entity.path),
          size: stat?.size,
          modifiedTime: stat?.modified,
          level: level,
        );
        
        nodes.add(node);
        
        // 递归处理目录
        if (isDir) {
          final children = <FileNode>[];
          await _buildNodes(entity as Directory, children, level + 1);
          // 不在这里设置children，由懒加载处理
        }
      }
    } catch (e) {
      // 忽略权限错误
    }
  }
  
  /// 加载子节点
  Future<List<FileNode>> loadChildren(String dirPath, int level) async {
    final nodes = <FileNode>[];
    
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return nodes;
      
      final entities = await dir.list().toList();
      final filtered = FileUtils.filterFiles(
        entities,
        extensions: AppConstants.supportedFileExtensions,
      );
      final sorted = FileUtils.sortFiles(filtered);
      
      for (final entity in sorted) {
        final isDir = entity is Directory;
        final name = FileUtils.getFileName(entity.path);
        
        if (name.startsWith('.')) continue;
        
        FileStat? stat;
        try {
          stat = await entity.stat();
        } catch (e) {
          continue;
        }
        
        final node = FileNode(
          name: name,
          path: entity.path,
          isDirectory: isDir,
          fileType: isDir ? FileType.unknown : FileType.fromPath(entity.path),
          size: stat?.size,
          modifiedTime: stat?.modified,
          level: level,
          children: isDir ? const [] : const [],
        );
        
        nodes.add(node);
      }
    } catch (e) {
      // 忽略错误
    }
    
    return nodes;
  }
  
  /// 搜索文件
  Future<List<FileNode>> searchFiles(
    String rootPath,
    String query, {
    bool recursive = true,
  }) async {
    final results = <FileNode>[];
    final lowerQuery = query.toLowerCase();
    
    await _searchInDirectory(Directory(rootPath), lowerQuery, results, recursive);
    
    return results;
  }
  
  /// 在目录中搜索
  Future<void> _searchInDirectory(
    Directory dir,
    String query,
    List<FileNode> results,
    bool recursive,
  ) async {
    try {
      final entities = await dir.list().toList();
      
      for (final entity in entities) {
        final name = FileUtils.getFileName(entity.path);
        
        if (name.startsWith('.')) continue;
        
        if (name.toLowerCase().contains(query)) {
          final isDir = entity is Directory;
          results.add(FileNode(
            name: name,
            path: entity.path,
            isDirectory: isDir,
            fileType: isDir ? FileType.unknown : FileType.fromPath(entity.path),
          ));
        }
        
        if (entity is Directory && recursive) {
          await _searchInDirectory(entity, query, results, recursive);
        }
      }
    } catch (e) {
      // 忽略权限错误
    }
  }
}

/// 文件树服务Provider
final fileTreeServiceProvider = Provider<FileTreeService>((ref) {
  return FileTreeService();
});
