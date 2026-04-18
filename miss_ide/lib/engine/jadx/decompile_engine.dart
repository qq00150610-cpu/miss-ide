// lib/engine/jadx/decompile_engine.dart - 反编译引擎调度中心
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'jadx_wrapper.dart';

/// 反编译引擎类型
enum DecompilerType {
  /// 内置 Jadx 引擎
  jadx,
  /// 外部工具 MT Manager
  mtManager,
  /// 外部工具 APK Editor Pro
  apkEditor,
  /// Apktool
  apktool,
}

/// 支持的文件类型
enum FileType {
  apk,
  dex,
  jar,
  zip,
  unknown,
}

/// 反编译任务状态
enum DecompileTaskState {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// 反编译任务信息
class DecompileTask {
  final String id;
  final String inputPath;
  final FileType fileType;
  final DecompilerType decompiler;
  final DecompileTaskState state;
  final DateTime createdAt;
  final DecompileProgress? progress;
  final DecompileResult? result;
  final String? error;
  
  const DecompileTask({
    required this.id,
    required this.inputPath,
    required this.fileType,
    required this.decompiler,
    this.state = DecompileTaskState.pending,
    required this.createdAt,
    this.progress,
    this.result,
    this.error,
  });
  
  DecompileTask copyWith({
    DecompileTaskState? state,
    DecompileProgress? progress,
    DecompileResult? result,
    String? error,
  }) {
    return DecompileTask(
      id: id,
      inputPath: inputPath,
      fileType: fileType,
      decompiler: decompiler,
      state: state ?? this.state,
      createdAt: createdAt,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// 反编译引擎调度中心
class DecompileEngineCenter {
  static DecompileEngineCenter? _instance;
  static DecompileEngineCenter get instance => 
      _instance ??= DecompileEngineCenter._();
  
  DecompileEngineCenter._() {
    _jadx = JadxWrapper.instance;
  }
  
  late final JadxWrapper _jadx;
  
  // 任务队列
  final _tasks = <String, DecompileTask>{};
  final _taskController = StreamController<Map<String, DecompileTask>>.broadcast();
  
  // 进度流
  final _progressController = StreamController<DecompileProgress>.broadcast();
  
  /// 任务状态流
  Stream<Map<String, DecompileTask>> get taskStream => _taskController.stream;
  
  /// 进度流
  Stream<DecompileProgress> get progressStream => _progressController.stream;
  
  /// 所有任务
  List<DecompileTask> get tasks => _tasks.values.toList();
  
  /// 获取支持的文件类型
  static FileType getFileType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.apk':
        return FileType.apk;
      case '.dex':
        return FileType.dex;
      case '.jar':
        return FileType.jar;
      case '.zip':
        return FileType.zip;
      default:
        return FileType.unknown;
    }
  }
  
  /// 检测最佳反编译器
  DecompilerType suggestDecompiler(FileType fileType) {
    switch (fileType) {
      case FileType.apk:
      case FileType.dex:
      case FileType.jar:
        return DecompilerType.jadx;
      case FileType.zip:
        return DecompilerType.apktool;
      case FileType.unknown:
        return DecompilerType.jadx;
    }
  }
  
  /// 创建反编译任务
  String createTask({
    required String inputPath,
    FileType? fileType,
    DecompilerType? decompiler,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final type = fileType ?? getFileType(inputPath);
    final engine = decompiler ?? suggestDecompiler(type);
    
    final task = DecompileTask(
      id: id,
      inputPath: inputPath,
      fileType: type,
      decompiler: engine,
      createdAt: DateTime.now(),
    );
    
    _tasks[id] = task;
    _notifyTasksChanged();
    
    return id;
  }
  
  /// 开始反编译任务
  Future<DecompileResult> startTask(String taskId, {JadxConfig? config}) async {
    final task = _tasks[taskId];
    if (task == null) {
      throw DecompileEngineException('任务不存在: $taskId');
    }
    
    _updateTask(task.copyWith(state: DecompileTaskState.running));
    
    try {
      DecompileResult result;
      
      switch (task.fileType) {
        case FileType.apk:
          result = await _jadx.decompileApk(
            task.inputPath,
            config: config,
            onProgress: (progress) {
              _updateTask(task.copyWith(progress: progress));
              _progressController.add(progress);
            },
          );
          break;
          
        case FileType.dex:
          result = await _jadx.decompileDex(
            task.inputPath,
            config: config,
            onProgress: (progress) {
              _updateTask(task.copyWith(progress: progress));
              _progressController.add(progress);
            },
          );
          break;
          
        case FileType.jar:
          result = await _jadx.decompileJar(
            task.inputPath,
            config: config,
            onProgress: (progress) {
              _updateTask(task.copyWith(progress: progress));
              _progressController.add(progress);
            },
          );
          break;
          
        case FileType.zip:
          // ZIP 文件使用 APKTool
          result = await _decompileZipWithApktool(task.inputPath);
          break;
          
        case FileType.unknown:
          throw DecompileEngineException('不支持的文件类型');
      }
      
      _updateTask(task.copyWith(
        state: DecompileTaskState.completed,
        result: result,
      ));
      
      return result;
    } catch (e) {
      _updateTask(task.copyWith(
        state: DecompileTaskState.failed,
        error: e.toString(),
      ));
      rethrow;
    }
  }
  
  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    
    await _jadx.cancel();
    _updateTask(task.copyWith(state: DecompileTaskState.cancelled));
  }
  
  /// 移除任务
  void removeTask(String taskId) {
    _tasks.remove(taskId);
    _notifyTasksChanged();
  }
  
  /// 获取任务
  DecompileTask? getTask(String taskId) => _tasks[taskId];
  
  /// 使用 APKTool 解压 ZIP
  Future<DecompileResult> _decompileZipWithApktool(String zipPath) async {
    final stopwatch = Stopwatch()..start();
    final outputDir = p.join(
      Directory.systemTemp.path,
      'miss_ide',
      p.basenameWithoutExtension(zipPath),
    );
    
    try {
      // 使用 Android 原生 APKTool
      // 这里简化实现，实际应通过 MethodChannel 调用
      await Directory(outputDir).create(recursive: true);
      
      return DecompileResult(
        success: true,
        outputDir: outputDir,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return DecompileResult(
        success: false,
        outputDir: '',
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }
  
  void _updateTask(DecompileTask task) {
    _tasks[task.id] = task;
    _notifyTasksChanged();
  }
  
  void _notifyTasksChanged() {
    _taskController.add(Map.from(_tasks));
  }
  
  /// 释放资源
  void dispose() {
    _taskController.close();
    _progressController.close();
  }
}

/// 反编译引擎异常
class DecompileEngineException implements Exception {
  final String message;
  DecompileEngineException(this.message);
  
  @override
  String toString() => 'DecompileEngineException: $message';
}
