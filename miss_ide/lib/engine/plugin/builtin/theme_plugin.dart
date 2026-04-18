// lib/engine/plugin/builtin/theme_plugin.dart - 主题插件
import 'package:flutter/material.dart';
import '../plugin_system.dart';

/// 主题插件 - 提供自定义主题功能
class ThemePlugin implements MissPlugin {
  @override
  PluginMeta get meta => const PluginMeta(
    id: 'theme-plugin',
    name: '主题插件',
    version: '1.0.0',
    description: '提供自定义编辑器主题和配色方案',
    author: 'Miss IDE Team',
    tags: ['theme', 'color-scheme', 'ui'],
    isBuiltIn: true,
  );

  PluginState _state = PluginState.unloaded;
  @override
  PluginState get state => _state;

  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> _config = {};
  Map<String, ColorScheme> _customThemes = {};

  @override
  List<String> get dependencies => [];

  @override
  Future<void> onInit() async {
    _state = PluginState.loading;
    await _loadCustomThemes();
    _state = PluginState.loaded;
  }

  @override
  Future<void> onDispose() async {
    _state = PluginState.unloaded;
  }

  Future<void> _loadCustomThemes() async {
    // 加载用户自定义主题
    _customThemes = {};
  }

  @override
  List<MenuItem> contributeMenuItems() => [
    const MenuItem(
      id: 'theme-menu',
      label: '主题',
      icon: 'palette',
      sortOrder: 200,
    ),
  ];

  @override
  List<Command> contributeCommands() => [
    Command(
      id: 'theme.switch',
      name: '切换主题',
      description: '切换编辑器主题',
      shortcut: 'Ctrl+T',
      execute: () async {
        // 切换主题逻辑
      },
    ),
    Command(
      id: 'theme.customize',
      name: '自定义主题',
      description: '创建自定义编辑器主题',
      execute: () async {
        // 打开主题自定义对话框
      },
    ),
  ];

  @override
  Widget? contributePanel(String location) {
    if (location == 'settings:appearance') {
      return _ThemeSettingsPanel(
        customThemes: _customThemes,
        onThemeSelected: (name) {
          // 应用主题
        },
      );
    }
    return null;
  }

  @override
  List<SettingsItem> contributeSettings() => [
    const SettingsItem(
      key: 'theme.editor',
      label: '编辑器主题',
      type: 'enum',
      defaultValue: 'monokai',
      options: {
        'monokai': 'Monokai',
        'dracula': 'Dracula',
        'github': 'GitHub',
        'oneDark': 'One Dark',
      },
      description: '选择编辑器语法高亮主题',
    ),
    const SettingsItem(
      key: 'theme.interface',
      label: '界面主题',
      type: 'enum',
      defaultValue: 'system',
      options: {
        'system': '跟随系统',
        'light': '浅色',
        'dark': '深色',
      },
      description: '选择应用界面主题',
    ),
    const SettingsItem(
      key: 'theme.fontSize',
      label: '代码字体大小',
      type: 'int',
      defaultValue: 14,
      description: '编辑器代码字体大小',
    ),
  ];

  @override
  Map<String, dynamic> getConfig() => _config;

  @override
  Future<void> setConfig(Map<String, dynamic> config) async {
    _config = config;
  }

  /// 获取所有可用主题
  List<String> get availableThemes => [
    'monokai',
    'dracula',
    'github',
    'oneDark',
    ..._customThemes.keys,
  ];

  /// 添加自定义主题
  Future<void> addCustomTheme(String name, ColorScheme scheme) async {
    _customThemes[name] = scheme;
  }
}

/// 主题设置面板
class _ThemeSettingsPanel extends StatelessWidget {
  final Map<String, ColorScheme> customThemes;
  final Function(String) onThemeSelected;

  const _ThemeSettingsPanel({
    required this.customThemes,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主题设置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ThemeCard(name: 'Monokai', onTap: () => onThemeSelected('monokai')),
              _ThemeCard(name: 'Dracula', onTap: () => onThemeSelected('dracula')),
              _ThemeCard(name: 'GitHub', onTap: () => onThemeSelected('github')),
              _ThemeCard(name: 'One Dark', onTap: () => onThemeSelected('oneDark')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(name),
        ),
      ),
    );
  }
}
