// lib/engine/plugin/builtin/tool_plugin.dart - 外部工具集成插件
import 'package:flutter/material.dart';
import '../plugin_system.dart';

/// 工具配置
class ToolConfig {
  final String id;
  final String name;
  final String executable;
  final String? arguments;
  final String? workDirectory;
  final String? description;
  final String? icon;
  final bool isBuiltIn;

  const ToolConfig({
    required this.id,
    required this.name,
    required this.executable,
    this.arguments,
    this.workDirectory,
    this.description,
    this.icon,
    this.isBuiltIn = false,
  });

  static const List<ToolConfig> builtInTools = [
    ToolConfig(
      id: 'jadx',
      name: 'Jadx',
      executable: 'jadx',
      arguments: '-d {output} {input}',
      description: 'DEX/Java 反编译工具',
      icon: 'code',
      isBuiltIn: true,
    ),
    ToolConfig(
      id: 'apktool',
      name: 'Apktool',
      executable: 'apktool',
      arguments: 'd {input} -o {output}',
      description: 'APK 反编译和打包工具',
      icon: 'archive',
      isBuiltIn: true,
    ),
    ToolConfig(
      id: 'adb',
      name: 'ADB',
      executable: 'adb',
      description: 'Android Debug Bridge',
      icon: 'android',
      isBuiltIn: true,
    ),
    ToolConfig(
      id: 'aapt',
      name: 'AAPT',
      executable: 'aapt',
      description: 'Android Asset Packaging Tool',
      icon: 'build',
      isBuiltIn: true,
    ),
  ];
}

/// 外部工具插件
class ToolPlugin implements MissPlugin {
  @override
  PluginMeta get meta => const PluginMeta(
    id: 'tool-plugin',
    name: '外部工具插件',
    version: '1.0.0',
    description: '集成外部反编译和分析工具',
    author: 'Miss IDE Team',
    tags: ['tool', 'external', 'jadx', 'apktool'],
    isBuiltIn: true,
  );

  PluginState _state = PluginState.unloaded;
  @override
  PluginState get state => _state;

  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> _config = {};
  final Map<String, ToolConfig> _tools = {};
  final Map<String, bool> _toolAvailability = {};

  @override
  List<String> get dependencies => [];

  @override
  Future<void> onInit() async {
    _state = PluginState.loading;
    
    // 加载内置工具
    for (final tool in ToolConfig.builtInTools) {
      _tools[tool.id] = tool;
    }
    
    // 检查工具可用性
    await _checkToolAvailability();
    
    _state = PluginState.loaded;
  }

  @override
  Future<void> onDispose() async {
    _state = PluginState.unloaded;
  }

  Future<void> _checkToolAvailability() async {
    // 检查每个工具是否可用
    for (final tool in _tools.values) {
      _toolAvailability[tool.id] = true; // 简化实现
    }
  }

  @override
  List<MenuItem> contributeMenuItems() => [
    const MenuItem(
      id: 'tools-menu',
      label: '工具',
      icon: 'build',
      sortOrder: 300,
    ),
  ];

  @override
  List<Command> contributeCommands() => [
    Command(
      id: 'tool.jadx',
      name: '使用 Jadx 反编译',
      description: '使用 Jadx 反编译 DEX/APK 文件',
      execute: () async {
        // 打开 Jadx 反编译对话框
      },
    ),
    Command(
      id: 'tool.apktool',
      name: '使用 Apktool 反编译',
      description: '使用 Apktool 反编译 APK 文件',
      execute: () async {
        // 打开 Apktool 反编译对话框
      },
    ),
    Command(
      id: 'tool.refresh',
      name: '刷新工具状态',
      description: '检查外部工具是否可用',
      execute: () async {
        await _checkToolAvailability();
      },
    ),
  ];

  @override
  Widget? contributePanel(String location) {
    if (location == 'settings:tools') {
      return _ToolSettingsPanel(
        tools: _tools,
        availability: _toolAvailability,
        onToolConfigure: (toolId) {
          // 打开工具配置对话框
        },
      );
    }
    return null;
  }

  @override
  List<SettingsItem> contributeSettings() => [
    const SettingsItem(
      key: 'tool.autoDetect',
      label: '自动检测工具',
      type: 'bool',
      defaultValue: true,
      description: '自动检测 PATH 中的外部工具',
    ),
    const SettingsItem(
      key: 'tool.defaultDecompiler',
      label: '默认反编译器',
      type: 'enum',
      defaultValue: 'jadx',
      options: {
        'jadx': 'Jadx',
        'apktool': 'Apktool',
      },
      description: '选择默认的反编译工具',
    ),
  ];

  @override
  Map<String, dynamic> getConfig() => _config;

  @override
  Future<void> setConfig(Map<String, dynamic> config) async {
    _config = config;
  }

  /// 获取所有工具
  List<ToolConfig> get allTools => _tools.values.toList();

  /// 获取可用的工具
  List<ToolConfig> get availableTools {
    return _tools.entries
        .where((e) => _toolAvailability[e.key] == true)
        .map((e) => e.value)
        .toList();
  }

  /// 获取工具配置
  ToolConfig? getTool(String toolId) => _tools[toolId];

  /// 检查工具是否可用
  bool isToolAvailable(String toolId) => _toolAvailability[toolId] ?? false;

  /// 添加自定义工具
  Future<void> addTool(ToolConfig tool) async {
    _tools[tool.id] = tool;
  }

  /// 移除工具
  Future<void> removeTool(String toolId) async {
    final tool = _tools[toolId];
    if (tool != null && !tool.isBuiltIn) {
      _tools.remove(toolId);
    }
  }

  /// 更新工具配置
  Future<void> updateTool(String toolId, ToolConfig tool) async {
    if (_tools.containsKey(toolId)) {
      _tools[toolId] = tool;
    }
  }
}

/// 工具设置面板
class _ToolSettingsPanel extends StatelessWidget {
  final Map<String, ToolConfig> tools;
  final Map<String, bool> availability;
  final Function(String) onToolConfigure;

  const _ToolSettingsPanel({
    required this.tools,
    required this.availability,
    required this.onToolConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '外部工具设置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: tools.length,
              itemBuilder: (context, index) {
                final tool = tools.values.elementAt(index);
                final isAvailable = availability[tool.id] ?? false;
                return ListTile(
                  leading: Icon(
                    isAvailable ? Icons.check_circle : Icons.error,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                  title: Text(tool.name),
                  subtitle: Text(tool.description ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => onToolConfigure(tool.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
