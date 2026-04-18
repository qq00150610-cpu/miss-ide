// lib/engine/jadx/jadx_wrapper.dart - Jadx 反编译引擎 Dart 封装层
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// 反编译引擎配置
class JadxConfig {
  /// 是否启用反混淆
  final bool deobfuscation;
  
  /// 是否显示-debug-info
  final bool debugInfo;
  
  /// 是否跳过资源解码
  final bool skipResources;
  
  /// 输出文件类型: java, smali
  final String outputType;
  
  /// 同时处理的最大类数量
  final int? classLimit;
  
  const JadxConfig({
    this.deobfuscation = false,
    this.debugInfo = false,
    this.skipResources = false,
    this.outputType = 'java',
    this.classLimit,
  });
  
  Map<String, dynamic> toMap() => {
    'deobfuscation': deobfuscation,
    'debugInfo': debugInfo,
    'skipResources': skipResources,
    'outputType': outputType,
    if (classLimit != null) 'classLimit': classLimit,
  };
}

/// 反编译进度信息
class DecompileProgress {
  final int current;
  final int total;
  final String currentClass;
  final double percent;
  
  const DecompileProgress({
    required this.current,
    required this.total,
    required this.currentClass,
    required this.percent,
  });
  
  factory DecompileProgress.fromMap(Map<dynamic, dynamic> map) {
    final total = map['total'] as int? ?? 1;
    final current = map['current'] as int? ?? 0;
    return DecompileProgress(
      current: current,
      total: total,
      currentClass: map['currentClass'] as String? ?? '',
      percent: total > 0 ? current / total : 0,
    );
  }
}

/// 反编译结果
class DecompileResult {
  final bool success;
  final String outputDir;
  final List<String> javaFiles;
  final List<String> smaliFiles;
  final List<String> resourceFiles;
  final String? error;
  final Duration duration;
  
  const DecompileResult({
    required this.success,
    required this.outputDir,
    this.javaFiles = const [],
    this.smaliFiles = const [],
    this.resourceFiles = const [],
    this.error,
    required this.duration,
  });
}

/// 单个类文件信息
class ClassFileInfo {
  final String name;
  final String path;
  final int methods;
  final int fields;
  final String? superClass;
  final List<String> interfaces;
  
  const ClassFileInfo({
    required this.name,
    required this.path,
    required this.methods,
    required this.fields,
    this.superClass,
    this.interfaces = const [],
  });
}

/// Jadx 引擎 Dart 封装
class JadxWrapper {
  static const _channel = MethodChannel('com.misside/jadx');
  static const _eventChannel = EventChannel('com.misside/jadx_progress');
  
  static JadxWrapper? _instance;
  static JadxWrapper get instance => _instance ??= JadxWrapper._();
  
  JadxWrapper._();
  
  /// 获取 Jadx 版本
  Future<String> getVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getVersion');
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      throw JadxException('获取版本失败: ${e.message}');
    }
  }
  
  /// 反编译 APK 文件
  Future<DecompileResult> decompileApk(
    String apkPath, {
    String? outputDir,
    JadxConfig config = const JadxConfig(),
    void Function(DecompileProgress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // 创建输出目录
      final output = outputDir ?? await _createOutputDir(apkPath);
      
      // 监听进度
      StreamSubscription<DecompileProgress>? progressSubscription;
      if (onProgress != null) {
        progressSubscription = _eventChannel
            .receiveBroadcastStream()
            .map((event) => DecompileProgress.fromMap(event as Map))
            .listen(onProgress);
      }
      
      // 执行反编译
      final result = await _channel.invokeMethod<Map>('decompileApk', {
        'apkPath': apkPath,
        'outputDir': output,
        ...config.toMap(),
      });
      
      await progressSubscription?.cancel();
      
      stopwatch.stop();
      
      if (result == null) {
        return DecompileResult(
          success: false,
          outputDir: output,
          error: '反编译返回结果为空',
          duration: stopwatch.elapsed,
        );
      }
      
      // 扫描输出目录获取文件列表
      final javaFiles = await _scanFiles(output, 'java');
      final smaliFiles = await _scanFiles(output, 'smali');
      final resourceFiles = await _scanFiles(output, 'xml');
      
      return DecompileResult(
        success: true,
        outputDir: output,
        javaFiles: javaFiles,
        smaliFiles: smaliFiles,
        resourceFiles: resourceFiles,
        duration: stopwatch.elapsed,
      );
    } on PlatformException catch (e) {
      stopwatch.stop();
      return DecompileResult(
        success: false,
        outputDir: '',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    }
  }
  
  /// 反编译 DEX 文件
  Future<DecompileResult> decompileDex(
    String dexPath, {
    String? outputDir,
    JadxConfig config = const JadxConfig(),
    void Function(DecompileProgress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final output = outputDir ?? await _createOutputDir(dexPath);
      
      StreamSubscription<DecompileProgress>? progressSubscription;
      if (onProgress != null) {
        progressSubscription = _eventChannel
            .receiveBroadcastStream()
            .map((event) => DecompileProgress.fromMap(event as Map))
            .listen(onProgress);
      }
      
      final result = await _channel.invokeMethod<Map>('decompileDex', {
        'dexPath': dexPath,
        'outputDir': output,
        ...config.toMap(),
      });
      
      await progressSubscription?.cancel();
      stopwatch.stop();
      
      final javaFiles = await _scanFiles(output, 'java');
      
      return DecompileResult(
        success: true,
        outputDir: output,
        javaFiles: javaFiles,
        duration: stopwatch.elapsed,
      );
    } on PlatformException catch (e) {
      stopwatch.stop();
      return DecompileResult(
        success: false,
        outputDir: '',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    }
  }
  
  /// 反编译 JAR 文件
  Future<DecompileResult> decompileJar(
    String jarPath, {
    String? outputDir,
    JadxConfig config = const JadxConfig(),
    void Function(DecompileProgress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final output = outputDir ?? await _createOutputDir(jarPath);
      
      StreamSubscription<DecompileProgress>? progressSubscription;
      if (onProgress != null) {
        progressSubscription = _eventChannel
            .receiveBroadcastStream()
            .map((event) => DecompileProgress.fromMap(event as Map))
            .listen(onProgress);
      }
      
      final result = await _channel.invokeMethod<Map>('decompileJar', {
        'jarPath': jarPath,
        'outputDir': output,
        ...config.toMap(),
      });
      
      await progressSubscription?.cancel();
      stopwatch.stop();
      
      final javaFiles = await _scanFiles(output, 'java');
      
      return DecompileResult(
        success: true,
        outputDir: output,
        javaFiles: javaFiles,
        duration: stopwatch.elapsed,
      );
    } on PlatformException catch (e) {
      stopwatch.stop();
      return DecompileResult(
        success: false,
        outputDir: '',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    }
  }
  
  /// 解码 APK 资源
  Future<List<String>> decodeResources(
    String apkPath, {
    String? outputDir,
  }) async {
    try {
      final output = outputDir ?? await _createOutputDir(apkPath);
      
      await _channel.invokeMethod<Map>('decodeResources', {
        'apkPath': apkPath,
        'outputDir': output,
      });
      
      return await _scanFiles(output, 'xml');
    } on PlatformException catch (e) {
      throw JadxException('解码资源失败: ${e.message}');
    }
  }
  
  /// 获取单个类的反编译结果
  Future<String> decompileSingleClass(
    String classPath, {
    bool toSmali = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('decompileSingleClass', {
        'classPath': classPath,
        'toSmali': toSmali,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw JadxException('反编译类失败: ${e.message}');
    }
  }
  
  /// 获取 APK 中的类列表
  Future<List<ClassFileInfo>> getClassList(String apkPath) async {
    try {
      final result = await _channel.invokeMethod<List>('getClassList', {
        'apkPath': apkPath,
      });
      
      if (result == null) return [];
      
      return result.map((item) {
        final map = item as Map;
        return ClassFileInfo(
          name: map['name'] as String? ?? '',
          path: map['path'] as String? ?? '',
          methods: map['methods'] as int? ?? 0,
          fields: map['fields'] as int? ?? 0,
          superClass: map['superClass'] as String?,
          interfaces: (map['interfaces'] as List?)?.cast() ?? [],
        );
      }).toList();
    } on PlatformException catch (e) {
      throw JadxException('获取类列表失败: ${e.message}');
    }
  }
  
  /// 创建临时输出目录
  Future<String> _createOutputDir(String inputPath) async {
    final tempDir = Directory.systemTemp;
    final appName = inputPath.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
    final outputDir = Directory('${tempDir.path}/miss_ide/$appName');
    
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);
    
    return outputDir.path;
  }
  
  /// 扫描目录获取特定扩展名的文件
  Future<List<String>> _scanFiles(String dirPath, String extension) async {
    final dir = Directory(dirPath);
    final files = <String>[];
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.$extension')) {
        files.add(entity.path);
      }
    }
    
    return files;
  }
  
  /// 取消当前反编译任务
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } on PlatformException {
      // 忽略取消错误
    }
  }
}

/// Jadx 异常
class JadxException implements Exception {
  final String message;
  JadxException(this.message);
  
  @override
  String toString() => 'JadxException: $message';
}
