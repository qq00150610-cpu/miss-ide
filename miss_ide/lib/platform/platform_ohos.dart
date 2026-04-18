// lib/platform/platform_ohos.dart - 鸿蒙 HarmonyOS 平台适配器
// 注意：此文件为条件编译目标，当检测到鸿蒙平台时使用
import 'dart:io';
import 'package:flutter/services.dart';
import 'platform_adapter.dart';

/// 鸿蒙平台适配器
/// 用于支持 HarmonyOS Next 设备运行 Miss IDE
class OhosPlatformAdapter implements PlatformAdapter {
  static const _channel = MethodChannel('com.misside/ohos');
  static const _faChannel = MethodChannel('com.misside/fa');

  @override
  PlatformType get platformType => PlatformType.ohos;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    try {
      final result = await _channel.invokeMethod('getPlatformInfo');
      return PlatformInfo(
        type: PlatformType.ohos,
        osVersion: result['osVersion'] ?? '',
        sdkVersion: result['sdkVersion'] ?? '',
        deviceModel: result['deviceModel'] ?? '',
        isEmulator: result['isEmulator'] ?? false,
        extraInfo: Map<String, dynamic>.from(result['extraInfo'] ?? {}),
      );
    } catch (e) {
      return PlatformInfo(
        type: PlatformType.ohos,
        osVersion: Platform.operatingSystemVersion,
      );
    }
  }

  @override
  Future<String> getAppDataDirectory() async {
    try {
      final result = await _channel.invokeMethod('getAppDataDirectory');
      return result as String;
    } catch (e) {
      // 鸿蒙应用数据目录
      return './data';
    }
  }

  @override
  Future<String> getCacheDirectory() async {
    try {
      final result = await _channel.invokeMethod('getCacheDirectory');
      return result as String;
    } catch (e) {
      return './cache';
    }
  }

  @override
  Future<String?> getExternalStorageDirectory() async {
    try {
      final result = await _channel.invokeMethod('getExternalStorageDirectory');
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> getTempDirectory() async {
    try {
      final result = await _channel.invokeMethod('getTempDirectory');
      return result as String;
    } catch (e) {
      return Directory.systemTemp.path;
    }
  }

  @override
  Future<bool> hasStoragePermission() async {
    try {
      final result = await _channel.invokeMethod('hasStoragePermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestStoragePermission() async {
    try {
      final result = await _channel.invokeMethod('requestStoragePermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> openExternalApp(
    String packageName, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final result = await _faChannel.invokeMethod('startAbility', {
        'bundleName': packageName,
        'abilityName': data?['abilityName'],
        'parameters': data,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod('isAppInstalled', {
        'bundleName': packageName,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getAppInfo(String packageName) async {
    try {
      final result = await _channel.invokeMethod('getAppInfo', {
        'bundleName': packageName,
      });
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ShellResult> executeShell(String command, {String? workDirectory}) async {
    // 鸿蒙平台通过 FA 模型执行命令
    try {
      final result = await _channel.invokeMethod('executeShell', {
        'command': command,
        'workDirectory': workDirectory,
      });
      return ShellResult(
        exitCode: result['exitCode'] ?? 1,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
      );
    } catch (e) {
      return ShellResult(
        exitCode: 1,
        stderr: e.toString(),
      );
    }
  }

  @override
  Future<bool> shareFile(String filePath, {String? mimeType}) async {
    try {
      final result = await _faChannel.invokeMethod('shareFile', {
        'filePath': filePath,
        'mimeType': mimeType,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // ===== 鸿蒙特有功能 =====

  /// 检查是否为鸿蒙系统
  static bool get isHarmonyOS {
    return Platform.operatingSystem.toLowerCase().contains('harmony') ||
        Platform.operatingSystem.toLowerCase().contains('ohos');
  }

  /// 获取鸿蒙 API 版本
  Future<int> getHarmonyApiVersion() async {
    try {
      final result = await _channel.invokeMethod('getHarmonyApiVersion');
      return result as int? ?? 9;
    } catch (e) {
      return 9; // 默认 HarmonyOS 2.0
    }
  }

  /// 检查是否为 ArkUI 应用
  Future<bool> isArkUIApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod('isArkUIApp', {
        'bundleName': packageName,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 获取已安装的鸿蒙应用列表
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      return List<Map<String, dynamic>>.from(
        (result as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      );
    } catch (e) {
      return [];
    }
  }
}
