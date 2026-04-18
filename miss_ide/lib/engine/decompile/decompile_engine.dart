// lib/engine/decompile/decompile_engine.dart - 反编译引擎
import 'dart:io';
import 'package:archive/archive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// APK信息
class ApkInfo {
  final String path;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int minSdkVersion;
  final int targetSdkVersion;
  final List<String> activities;
  final List<String> services;
  final List<String> receivers;
  final List<String> providers;
  final List<String> permissions;
  final List<String> dexFiles;
  final List<String> resources;
  
  const ApkInfo({
    required this.path,
    this.packageName = '',
    this.versionName = '',
    this.versionCode = 0,
    this.minSdkVersion = 0,
    this.targetSdkVersion = 0,
    this.activities = const [],
    this.services = const [],
    this.receivers = const [],
    this.providers = const [],
    this.permissions = const [],
    this.dexFiles = const [],
    this.resources = const [],
  });
  
  factory ApkInfo.empty(String path) => ApkInfo(path: path);
  
  ApkInfo copyWith({
    String? path,
    String? packageName,
    String? versionName,
    int? versionCode,
    int? minSdkVersion,
    int? targetSdkVersion,
    List<String>? activities,
    List<String>? services,
    List<String>? receivers,
    List<String>? providers,
    List<String>? permissions,
    List<String>? dexFiles,
    List<String>? resources,
  }) {
    return ApkInfo(
      path: path ?? this.path,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      minSdkVersion: minSdkVersion ?? this.minSdkVersion,
      targetSdkVersion: targetSdkVersion ?? this.targetSdkVersion,
      activities: activities ?? this.activities,
      services: services ?? this.services,
      receivers: receivers ?? this.receivers,
      providers: providers ?? this.providers,
      permissions: permissions ?? this.permissions,
      dexFiles: dexFiles ?? this.dexFiles,
      resources: resources ?? this.resources,
    );
  }
}

/// 反编译结果
class DecompileResult {
  final bool success;
  final String outputPath;
  final ApkInfo? apkInfo;
  final String? error;
  final List<String> extractedFiles;
  
  const DecompileResult({
    required this.success,
    this.outputPath = '',
    this.apkInfo,
    this.error,
    this.extractedFiles = const [],
  });
  
  factory DecompileResult.failure(String error) {
    return DecompileResult(
      success: false,
      error: error,
    );
  }
}

/// 反编译引擎
class DecompileEngine {
  /// 解压APK文件
  Future<DecompileResult> extractApk(String apkPath, String outputPath) async {
    try {
      final file = File(apkPath);
      if (!await file.exists()) {
        return DecompileResult.failure('APK file not found');
      }
      
      // 创建输出目录
      final outputDir = Directory(outputPath);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // 读取APK文件
      final bytes = await file.readAsBytes();
      
      // 解码APK（ZIP格式）
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final extractedFiles = <String>[];
      
      // 解压所有文件
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final outputFile = File('$outputPath/$filename');
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
          extractedFiles.add(filename);
        } else {
          // 创建目录
          await Directory('$outputPath/$filename').create(recursive: true);
        }
      }
      
      // 解析APK信息
      final apkInfo = await _parseApkInfo(outputPath);
      
      return DecompileResult(
        success: true,
        outputPath: outputPath,
        apkInfo: apkInfo,
        extractedFiles: extractedFiles,
      );
    } catch (e) {
      return DecompileResult.failure('Failed to extract APK: $e');
    }
  }
  
  /// 解析APK信息
  Future<ApkInfo> _parseApkInfo(String extractedPath) async {
    var apkInfo = ApkInfo.empty(extractedPath);
    
    // 解析AndroidManifest.xml（简化版，实际需要解析二进制格式）
    final manifestFile = File('$extractedPath/AndroidManifest.xml');
    if (await manifestFile.exists()) {
      final manifestContent = await manifestFile.readAsString();
      apkInfo = _extractManifestInfo(manifestContent, apkInfo);
    }
    
    // 查找DEX文件
    final dexFiles = await _findDexFiles(extractedPath);
    apkInfo = apkInfo.copyWith(dexFiles: dexFiles);
    
    // 查找资源文件
    final resources = await _findResourceFiles(extractedPath);
    apkInfo = apkInfo.copyWith(resources: resources);
    
    return apkInfo;
  }
  
  /// 提取Manifest信息
  ApkInfo _extractManifestInfo(String manifestContent, ApkInfo info) {
    var apkInfo = info;
    
    // 简单的正则匹配（实际应该解析二进制XML）
    final packageMatch = RegExp(r'package="([^"]+)"').firstMatch(manifestContent);
    if (packageMatch != null) {
      apkInfo = apkInfo.copyWith(packageName: packageMatch.group(1));
    }
    
    final versionMatch = RegExp(r'versionName="([^"]+)"').firstMatch(manifestContent);
    if (versionMatch != null) {
      apkInfo = apkInfo.copyWith(versionName: versionMatch.group(1));
    }
    
    final versionCodeMatch = RegExp(r'versionCode="(\d+)"').firstMatch(manifestContent);
    if (versionCodeMatch != null) {
      apkInfo = apkInfo.copyWith(versionCode: int.tryParse(versionCodeMatch.group(1) ?? '0') ?? 0);
    }
    
    // 提取权限
    final permissionMatches = RegExp(r'<uses-permission[^>]+name="([^"]+)"').allMatches(manifestContent);
    final permissions = permissionMatches.map((m) => m.group(1) ?? '').toList();
    apkInfo = apkInfo.copyWith(permissions: permissions);
    
    // 提取Activity
    final activityMatches = RegExp(r'<activity[^>]+name="([^"]+)"').allMatches(manifestContent);
    final activities = activityMatches.map((m) => m.group(1) ?? '').toList();
    apkInfo = apkInfo.copyWith(activities: activities);
    
    return apkInfo;
  }
  
  /// 查找DEX文件
  Future<List<String>> _findDexFiles(String path) async {
    final dexFiles = <String>[];
    final dir = Directory(path);
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dex')) {
        dexFiles.add(entity.path.replaceFirst('$path/', ''));
      }
    }
    
    return dexFiles;
  }
  
  /// 查找资源文件
  Future<List<String>> _findResourceFiles(String path) async {
    final resources = <String>[];
    final dir = Directory(path);
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final ext = entity.path.split('.').last.toLowerCase();
        if (['xml', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(ext)) {
          resources.add(entity.path.replaceFirst('$path/', ''));
        }
      }
    }
    
    return resources;
  }
  
  /// 获取文件类型
  FileType getFileType(String filePath) {
    return FileType.fromPath(filePath);
  }
  
  /// 判断是否为APK文件
  bool isApkFile(String filePath) {
    return filePath.toLowerCase().endsWith('.apk');
  }
  
  /// 判断是否为DEX文件
  bool isDexFile(String filePath) {
    return filePath.toLowerCase().endsWith('.dex');
  }
}
