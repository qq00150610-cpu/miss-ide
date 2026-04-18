// lib/platform/platform_adapter.dart - 平台适配层入口
// 使用条件编译支持多平台
export 'platform_android.dart' if (dart.library.ohos) 'platform_ohos.dart';

import 'dart:async';
import 'dart:io';

/// 平台类型枚举
enum PlatformType {
  android,
  ohos, // 鸿蒙 HarmonyOS
  ios,
  windows,
  macos,
  linux,
  unknown,
}

/// 平台信息
class PlatformInfo {
  final PlatformType type;
  final String osVersion;
  final String sdkVersion;
  final String deviceModel;
  final bool isEmulator;
  final Map<String, dynamic> extraInfo;

  const PlatformInfo({
    required this.type,
    this.osVersion = '',
    this.sdkVersion = '',
    this.deviceModel = '',
    this.isEmulator = false,
    this.extraInfo = const {},
  });
}

/// 平台适配器接口
abstract class PlatformAdapter {
  /// 获取当前平台信息
  Future<PlatformInfo> getPlatformInfo();

  /// 获取应用数据目录
  Future<String> getAppDataDirectory();

  /// 获取缓存目录
  Future<String> getCacheDirectory();

  /// 获取外部存储目录
  Future<String?> getExternalStorageDirectory();

  /// 获取临时文件目录
  Future<String> getTempDirectory();

  /// 检查是否有存储权限
  Future<bool> hasStoragePermission();

  /// 请求存储权限
  Future<bool> requestStoragePermission();

  /// 打开外部应用
  Future<bool> openExternalApp(String packageName, {Map<String, dynamic>? data});

  /// 检查应用是否已安装
  Future<bool> isAppInstalled(String packageName);

  /// 获取应用信息
  Future<Map<String, dynamic>?> getAppInfo(String packageName);

  /// 执行 Shell 命令（通过外部工具）
  Future<ShellResult> executeShell(String command, {String? workDirectory});

  /// 分享文件
  Future<bool> shareFile(String filePath, {String? mimeType});

  /// 获取平台类型
  PlatformType get platformType;
}

/// Shell 命令执行结果
class ShellResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ShellResult({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  bool get isSuccess => exitCode == 0;
}

/// 平台适配器工厂
class PlatformAdapterFactory {
  static PlatformAdapter? _instance;

  static PlatformAdapter get instance {
    _instance ??= _createAdapter();
    return _instance!;
  }

  static PlatformAdapter _createAdapter() {
    if (Platform.isAndroid) {
      return AndroidPlatformAdapter();
    } else if (Platform.isIOS) {
      return IosPlatformAdapter();
    } else {
      return UnknownPlatformAdapter();
    }
  }
}
