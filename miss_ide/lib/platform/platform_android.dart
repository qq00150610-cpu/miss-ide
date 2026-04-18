// lib/platform/platform_android.dart - Android 平台适配器
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'platform_adapter.dart';

/// Android 平台适配器
class AndroidPlatformAdapter implements PlatformAdapter {
  static const _channel = MethodChannel('com.misside/platform');
  static const _intentChannel = MethodChannel('com.misside/intent');

  @override
  PlatformType get platformType => PlatformType.android;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    try {
      final result = await _channel.invokeMethod('getPlatformInfo');
      return PlatformInfo(
        type: PlatformType.android,
        osVersion: result['osVersion'] ?? '',
        sdkVersion: result['sdkVersion'] ?? '',
        deviceModel: result['deviceModel'] ?? '',
        isEmulator: result['isEmulator'] ?? false,
        extraInfo: Map<String, dynamic>.from(result['extraInfo'] ?? {}),
      );
    } catch (e) {
      return PlatformInfo(
        type: PlatformType.android,
        osVersion: Platform.operatingSystemVersion,
        isEmulator: _checkIfEmulator(),
      );
    }
  }

  bool _checkIfEmulator() {
    return Platform.isAndroid &&
        (Platform.operatingSystem.contains('goldfish') ||
            Platform.operatingSystem.contains('ranchu') ||
            Platform.localHostname.contains('emu'));
  }

  @override
  Future<String> getAppDataDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<String> getCacheDirectory() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  @override
  Future<String?> getExternalStorageDirectory() async {
    if (Platform.isAndroid) {
      final directories = await getExternalStorageDirectories();
      if (directories != null && directories.isNotEmpty) {
        return directories.first.path;
      }
    }
    return null;
  }

  @override
  Future<String> getTempDirectory() async {
    return Directory.systemTemp.path;
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
  Future<bool> openExternalApp(String packageName, {Map<String, dynamic>? data}) async {
    try {
      final result = await _intentChannel.invokeMethod('openApp', {
        'package': packageName,
        'data': data,
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
        'package': packageName,
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
        'package': packageName,
      });
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ShellResult> executeShell(String command, {String? workDirectory}) async {
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
      final result = await _intentChannel.invokeMethod('shareFile', {
        'filePath': filePath,
        'mimeType': mimeType,
      });
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// iOS 平台适配器（占位实现）
class IosPlatformAdapter implements PlatformAdapter {
  @override
  PlatformType get platformType => PlatformType.ios;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    return PlatformInfo(
      type: PlatformType.ios,
      osVersion: Platform.operatingSystemVersion,
    );
  }

  @override
  Future<String> getAppDataDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<String> getCacheDirectory() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  @override
  Future<String?> getExternalStorageDirectory() async => null;

  @override
  Future<String> getTempDirectory() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<bool> hasStoragePermission() async => true;

  @override
  Future<bool> requestStoragePermission() async => true;

  @override
  Future<bool> openExternalApp(String packageName, {Map<String, dynamic>? data}) async {
    return false;
  }

  @override
  Future<bool> isAppInstalled(String packageName) async => false;

  @override
  Future<Map<String, dynamic>?> getAppInfo(String packageName) async => null;

  @override
  Future<ShellResult> executeShell(String command, {String? workDirectory}) async {
    return const ShellResult(exitCode: 1, stderr: 'Shell execution not supported on iOS');
  }

  @override
  Future<bool> shareFile(String filePath, {String? mimeType}) async => false;
}

/// 未知平台适配器
class UnknownPlatformAdapter implements PlatformAdapter {
  @override
  PlatformType get platformType => PlatformType.unknown;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    return PlatformInfo(type: PlatformType.unknown);
  }

  @override
  Future<String> getAppDataDirectory() async {
    return './data';
  }

  @override
  Future<String> getCacheDirectory() async {
    return './cache';
  }

  @override
  Future<String?> getExternalStorageDirectory() async => null;

  @override
  Future<String> getTempDirectory() async {
    return './temp';
  }

  @override
  Future<bool> hasStoragePermission() async => true;

  @override
  Future<bool> requestStoragePermission() async => true;

  @override
  Future<bool> openExternalApp(String packageName, {Map<String, dynamic>? data}) async {
    return false;
  }

  @override
  Future<bool> isAppInstalled(String packageName) async => false;

  @override
  Future<Map<String, dynamic>?> getAppInfo(String packageName) async => null;

  @override
  Future<ShellResult> executeShell(String command, {String? workDirectory}) async {
    return const ShellResult(exitCode: 1, stderr: 'Platform not supported');
  }

  @override
  Future<bool> shareFile(String filePath, {String? mimeType}) async => false;
}
