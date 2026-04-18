// lib/engine/plugin/plugin_manager.dart - 插件管理器
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'plugin_system.dart';
import 'builtin/theme_plugin.dart';
import 'builtin/language_plugin.dart';
import 'builtin/tool_plugin.dart';

/// 插件加载结果
class PluginLoadResult {
  final bool success;
  final String? error;

  const PluginLoadResult({
    required this.success,
    this.error,
  });
}

/// 插件管理器
class PluginManager {
  static PluginManager? _instance;
  static PluginManager get instance => _instance ??= PluginManager._();

  PluginManager._();

  final _plugins = <String, MissPlugin>{};
  final _stateController = StreamController<Map<String, PluginState>>.broadcast();
  final _config = <String, Map<String, dynamic>>{};

  /// 所有已加载的插件
  List<MissPlugin> get plugins => _plugins.values.toList();

  /// 插件状态流
  Stream<Map<String, PluginState>> get stateStream => _stateController.stream;

  /// 内置插件列表
  List<PluginMeta> get builtInPlugins => [
    ThemePlugin.meta,
    LanguagePlugin.meta,
    ToolPlugin.meta,
  ];

  /// 初始化插件系统
  Future<void> initialize() async {
    // 加载内置插件
    await _loadBuiltInPlugin(ThemePlugin());
    await _loadBuiltInPlugin(LanguagePlugin());
    await _loadBuiltInPlugin(ToolPlugin());
  }

  /// 加载内置插件
  Future<PluginLoadResult> _loadBuiltInPlugin(MissPlugin plugin) async {
    try {
      _plugins[plugin.meta.id] = plugin;
      await plugin.onInit();
      _notifyStateChange();
      return const PluginLoadResult(success: true);
    } catch (e) {
      debugPrint('Failed to load built-in plugin ${plugin.meta.id}: $e');
      return PluginLoadResult(success: false, error: e.toString());
    }
  }

  /// 安装插件
  Future<PluginLoadResult> installPlugin(String pluginId, Map<String, dynamic> config) async {
    // 检查是否已安装
    if (_plugins.containsKey(pluginId)) {
      return const PluginLoadResult(
        success: false,
        error: 'Plugin already installed',
      );
    }

    // 从配置文件创建插件实例
    final plugin = await _createPluginInstance(pluginId);
    if (plugin == null) {
      return const PluginLoadResult(
        success: false,
        error: 'Plugin not found',
      );
    }

    try {
      // 检查依赖
      for (final depId in plugin.dependencies) {
        if (!_plugins.containsKey(depId)) {
          return PluginLoadResult(
            success: false,
            error: 'Missing dependency: $depId',
          );
        }
      }

      _plugins[pluginId] = plugin;
      _config[pluginId] = config;
      await plugin.onInit();
      _notifyStateChange();
      
      return const PluginLoadResult(success: true);
    } catch (e) {
      _plugins.remove(pluginId);
      return PluginLoadResult(success: false, error: e.toString());
    }
  }

  /// 卸载插件
  Future<bool> uninstallPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;

    // 不能卸载内置插件
    if (plugin.meta.isBuiltIn) return false;

    try {
      await plugin.onDispose();
      _plugins.remove(pluginId);
      _config.remove(pluginId);
      _notifyStateChange();
      return true;
    } catch (e) {
      debugPrint('Failed to uninstall plugin $pluginId: $e');
      return false;
    }
  }

  /// 启用插件
  Future<bool> enablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;

    final updatedMeta = plugin.meta.copyWith(isEnabled: true);
    // 更新插件元数据
    await _plugins[pluginId]?.onInit();
    _notifyStateChange();
    return true;
  }

  /// 禁用插件
  Future<bool> disablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;

    if (plugin.meta.isBuiltIn) return false;

    try {
      await plugin.onDispose();
      final updatedMeta = plugin.meta.copyWith(isEnabled: false);
      _notifyStateChange();
      return true;
    } catch (e) {
      debugPrint('Failed to disable plugin $pluginId: $e');
      return false;
    }
  }

  /// 获取插件
  MissPlugin? getPlugin(String pluginId) => _plugins[pluginId];

  /// 获取插件配置
  Map<String, dynamic> getPluginConfig(String pluginId) {
    return _config[pluginId] ?? {};
  }

  /// 设置插件配置
  Future<void> setPluginConfig(String pluginId, Map<String, dynamic> config) async {
    _config[pluginId] = config;
    final plugin = _plugins[pluginId];
    if (plugin != null) {
      await plugin.setConfig(config);
    }
  }

  /// 获取所有菜单项
  List<MenuItem> getAllMenuItems() {
    final items = <MenuItem>[];
    for (final plugin in plugins) {
      if (plugin.meta.isEnabled) {
        items.addAll(plugin.contributeMenuItems());
      }
    }
    return items;
  }

  /// 获取所有命令
  List<Command> getAllCommands() {
    final commands = <Command>[];
    for (final plugin in plugins) {
      if (plugin.meta.isEnabled) {
        commands.addAll(plugin.contributeCommands());
      }
    }
    return commands;
  }

  /// 获取指定位置的面板
  List<Widget> getPanels(String location) {
    final panels = <Widget>[];
    for (final plugin in plugins) {
      if (plugin.meta.isEnabled) {
        final panel = plugin.contributePanel(location);
        if (panel != null) {
          panels.add(panel);
        }
      }
    }
    return panels;
  }

  /// 获取所有设置项
  List<SettingsItem> getAllSettings() {
    final settings = <SettingsItem>[];
    for (final plugin in plugins) {
      if (plugin.meta.isEnabled) {
        settings.addAll(plugin.contributeSettings());
      }
    }
    return settings;
  }

  /// 创庺插件实例（需要从插件市场获取）
  Future<MissPlugin?> _createPluginInstance(String pluginId) async {
    // 实际实现中会从插件市场下载并实例化
    return null;
  }

  void _notifyStateChange() {
    final states = <String, PluginState>{};
    for (final entry in _plugins.entries) {
      states[entry.key] = entry.value.state;
    }
    _stateController.add(states);
  }

  /// 释放资源
  Future<void> dispose() async {
    for (final plugin in plugins) {
      try {
        await plugin.onDispose();
      } catch (e) {
        debugPrint('Error disposing plugin ${plugin.meta.id}: $e');
      }
    }
    _plugins.clear();
    await _stateController.close();
  }
}
