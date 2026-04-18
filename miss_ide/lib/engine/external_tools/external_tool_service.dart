// lib/engine/external_tools/external_tool_service.dart - 外部工具集成服务
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 外部工具类型
enum ExternalToolType {
  /// MT Manager
  mtManager,
  /// APK Editor Pro
  apkEditor,
  /// Termux
  termux,
  /// Shizuku
  shizuku,
  /// ZArchiver
  zarchiver,
}

/// 外部工具信息
class ExternalToolInfo {
  final ExternalToolType type;
  final String name;
  final String packageName;
  final String? marketUrl;
  final String? websiteUrl;
  final bool isInstalled;
  final String? version;
  final List<String> supportedActions;
  
  const ExternalToolInfo({
    required this.type,
    required this.name,
    required this.packageName,
    this.marketUrl,
    this.websiteUrl,
    this.isInstalled = false,
    this.version,
    this.supportedActions = const [],
  });
  
  ExternalToolInfo copyWith({
    bool? isInstalled,
    String? version,
  }) {
    return ExternalToolInfo(
      type: type,
      name: name,
      packageName: packageName,
      marketUrl: marketUrl,
      websiteUrl: websiteUrl,
      isInstalled: isInstalled ?? this.isInstalled,
      version: version ?? this.version,
      supportedActions: supportedActions,
    );
  }
}

/// 工具调用结果
class ToolLaunchResult {
  final bool success;
  final String? error;
  final String? output;
  
  const ToolLaunchResult({
    required this.success,
    this.error,
    this.output,
  });
}

/// Shizuku 状态
enum ShizukuStatus {
  /// 未安装
  notInstalled,
  /// 未运行
  notRunning,
  /// 正在请求权限
  requesting,
  /// 已授权
  authorized,
  /// 拒绝
  denied,
}

/// 外部工具集成服务
class ExternalToolService {
  static ExternalToolService? _instance;
  static ExternalToolService get instance => 
      _instance ??= ExternalToolService._();
  
  ExternalToolService._() {
    _channel = const MethodChannel('com.misside/external_tools');
  }
  
  late final MethodChannel _channel;
  
  /// 预定义的外部工具信息
  static const Map<ExternalToolType, ExternalToolInfo> _tools = {
    ExternalToolType.mtManager: ExternalToolInfo(
      type: ExternalToolType.mtManager,
      name: 'MT Manager',
      packageName: 'bin.mt.plus',
      marketUrl: 'https://coolapk.com/apk/bin.mt.plus',
      websiteUrl: 'https://mt2.cn',
      supportedActions: [
        'view_apk',
        'edit_apk',
        'sign_apk',
        'multi_decode',
        'batch_operations',
      ],
    ),
    ExternalToolType.apkEditor: ExternalToolInfo(
      type: ExternalToolType.apkEditor,
      name: 'APK Editor Pro',
      packageName: 'com.mod.apt',
      marketUrl: 'https://coolapk.com/apk/com.mod.apt',
      supportedActions: [
        'edit_resources',
        'edit_dex',
        'sign_apk',
        'replace_files',
      ],
    ),
    ExternalToolType.termux: ExternalToolInfo(
      type: ExternalToolType.termux,
      name: 'Termux',
      packageName: 'com.termux',
      marketUrl: 'https://f-droid.org/packages/com.termux',
      supportedActions: [
        'execute_command',
        'run_script',
        'ssh',
        'file_operations',
      ],
    ),
    ExternalToolType.shizuku: ExternalToolInfo(
      type: ExternalToolType.shizuku,
      name: 'Shizuku',
      packageName: 'rikka.shizuku',
      marketUrl: 'https://play.google.com/store/apps/details?id=rikka.shizuku',
      websiteUrl: 'https://shizuku.rikka.app',
      supportedActions: [
        'request_permission',
        'run_as_root',
        'run_shell_command',
        'file_operations',
      ],
    ),
    ExternalToolType.zarchiver: ExternalToolInfo(
      type: ExternalToolType.zarchiver,
      name: 'ZArchiver',
      packageName: 'zdevs.archiver',
      marketUrl: 'https://play.google.com/store/apps/details?id=zdevs.archiver',
      supportedActions: [
        'extract_archive',
        'create_archive',
        'view_content',
      ],
    ),
  };
  
  /// 获取所有工具信息
  List<ExternalToolInfo> getAllTools() => _tools.values.toList();
  
  /// 获取指定类型的工具信息
  ExternalToolInfo? getTool(ExternalToolType type) => _tools[type];
  
  /// 检测工具是否已安装
  Future<ExternalToolInfo> checkToolInstalled(ExternalToolType type) async {
    final tool = _tools[type];
    if (tool == null) {
      throw ExternalToolException('未知工具类型: $type');
    }
    
    try {
      final result = await _channel.invokeMethod<Map>('checkPackage', {
        'packageName': tool.packageName,
      });
      
      final isInstalled = result?['installed'] as bool? ?? false;
      final version = result?['version'] as String?;
      
      return tool.copyWith(
        isInstalled: isInstalled,
        version: version,
      );
    } on PlatformException catch (e) {
      return tool.copyWith(isInstalled: false);
    }
  }
  
  /// 批量检测工具安装状态
  Future<List<ExternalToolInfo>> checkAllToolsInstalled() async {
    final results = <ExternalToolInfo>[];
    for (final type in _tools.keys) {
      results.add(await checkToolInstalled(type));
    }
    return results;
  }
  
  /// 启动外部工具
  Future<ToolLaunchResult> launchTool(
    ExternalToolType type, {
    String? filePath,
    String? action,
    Map<String, dynamic>? extras,
  }) async {
    final tool = _tools[type];
    if (tool == null) {
      return ToolLaunchResult(
        success: false,
        error: '未知工具类型',
      );
    }
    
    if (!tool.isInstalled) {
      return ToolLaunchResult(
        success: false,
        error: '${tool.name} 未安装',
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map>('launchApp', {
        'packageName': tool.packageName,
        if (filePath != null) 'filePath': filePath,
        if (action != null) 'action': action,
        if (extras != null) 'extras': extras,
      });
      
      return ToolLaunchResult(
        success: result?['success'] as bool? ?? true,
        output: result?['output'] as String?,
        error: result?['error'] as String?,
      );
    } on PlatformException catch (e) {
      return ToolLaunchResult(
        success: false,
        error: e.message,
      );
    }
  }
  
  /// 使用 MT Manager 打开文件
  Future<ToolLaunchResult> openWithMT(String filePath) async {
    return launchTool(
      ExternalToolType.mtManager,
      filePath: filePath,
      action: 'view',
    );
  }
  
  /// 使用 MT Manager 反编译 APK
  Future<ToolLaunchResult> decompileWithMT(String apkPath) async {
    return launchTool(
      ExternalToolType.mtManager,
      filePath: apkPath,
      action: 'decompile',
    );
  }
  
  /// 使用 APK Editor 打开文件
  Future<ToolLaunchResult> openWithAPKEditor(String apkPath) async {
    return launchTool(
      ExternalToolType.apkEditor,
      filePath: apkPath,
      action: 'edit',
    );
  }
  
  /// 在 Termux 中执行命令
  Future<ToolLaunchResult> executeInTermux(String command) async {
    return launchTool(
      ExternalToolType.termux,
      extras: {'command': command},
    );
  }
  
  /// 打开应用市场下载页面
  Future<bool> openMarketPage(ExternalToolType type) async {
    final tool = _tools[type];
    if (tool?.marketUrl == null) return false;
    
    final uri = Uri.parse(tool!.marketUrl!);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
  
  /// 打开应用商店 (通用)
  Future<bool> openAppStore(String packageName) async {
    try {
      final uri = Uri.parse('market://details?id=$packageName');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      
      // 尝试 Google Play
      final playUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName',
      );
      if (await canLaunchUrl(playUri)) {
        return await launchUrl(playUri, mode: LaunchMode.externalApplication);
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// ==================== Shizuku 集成 ====================
  
  /// 检查 Shizuku 状态
  Future<ShizukuStatus> checkShizukuStatus() async {
    try {
      final result = await _channel.invokeMethod<Map>('checkShizuku');
      final status = result?['status'] as String? ?? 'not_installed';
      
      switch (status) {
        case 'authorized':
          return ShizukuStatus.authorized;
        case 'requesting':
          return ShizukuStatus.requesting;
        case 'denied':
          return ShizukuStatus.denied;
        case 'running':
          return ShizukuStatus.notRunning;
        default:
          return ShizukuStatus.notInstalled;
      }
    } on PlatformException {
      return ShizukuStatus.notInstalled;
    }
  }
  
  /// 请求 Shizuku 权限
  Future<bool> requestShizukuPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestShizukuPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
  
  /// 使用 Shizuku 执行 shell 命令
  Future<String> executeWithShizuku(String command) async {
    final status = await checkShizukuStatus();
    if (status != ShizukuStatus.authorized) {
      throw ExternalToolException('Shizuku 未授权');
    }
    
    try {
      final result = await _channel.invokeMethod<String>('executeWithShizuku', {
        'command': command,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw ExternalToolException('Shizuku 执行失败: ${e.message}');
    }
  }
  
  /// 使用 Shizuku 复制文件
  Future<bool> shizukuCopy(String source, String dest) async {
    return executeWithShizuku('cp "$source" "$dest"').then((_) => true)
        .catchError((_) => false);
  }
  
  /// 使用 Shizuku 删除文件
  Future<bool> shizukuDelete(String path) async {
    return executeWithShizuku('rm -rf "$path"').then((_) => true)
        .catchError((_) => false);
  }
  
  /// 使用 Shizuku 创建目录
  Future<bool> shizukuMkdir(String path) async {
    return executeWithShizuku('mkdir -p "$path"').then((_) => true)
        .catchError((_) => false);
  }
  
  /// ==================== Android 11+ 包可见性适配 ====================
  
  /// 检查包是否可见 (Android 11+)
  Future<bool> isPackageVisible(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>('isPackageVisible', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
  
  /// 批量检查包可见性
  Future<Map<String, bool>> checkPackagesVisible(List<String> packages) async {
    final results = <String, bool>{};
    for (final pkg in packages) {
      results[pkg] = await isPackageVisible(pkg);
    }
    return results;
  }
  
  /// 打开应用详情页
  Future<bool> openAppSettings(String packageName) async {
    try {
      final uri = Uri.parse('package:$packageName');
      return await launchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}

/// 外部工具异常
class ExternalToolException implements Exception {
  final String message;
  ExternalToolException(this.message);
  
  @override
  String toString() => 'ExternalToolException: $message';
}
