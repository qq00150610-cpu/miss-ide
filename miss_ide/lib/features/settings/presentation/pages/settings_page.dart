// lib/features/settings/presentation/pages/settings_page.dart - 设置页面
import 'package:flutter/material.dart';
import '../domain/settings_model.dart';
import '../data/settings_repository.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _repository = SettingsRepository();
  late Future<AppSettings> _settingsFuture;
  
  AppSettings? _currentSettings;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  void _loadSettings() {
    _settingsFuture = _repository.loadSettings().then((settings) {
      _currentSettings = settings;
      return settings;
    });
  }
  
  Future<void> _saveSettings(AppSettings settings) async {
    await _repository.saveSettings(settings);
    setState(() {
      _currentSettings = settings;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '恢复默认',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('恢复默认设置'),
                  content: const Text('确定要恢复所有设置为默认值吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _repository.resetSettings();
                _loadSettings();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<AppSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final settings = _currentSettings;
          if (settings == null) {
            return const Center(child: Text('加载设置失败'));
          }
          
          return ListView(
            children: [
              _buildSection(
                '外观',
                [
                  _buildThemeTile(settings),
                  _buildCodeThemeTile(settings),
                  _buildMaterial3Tile(settings),
                ],
              ),
              _buildSection(
                '编辑器',
                [
                  _buildFontSizeTile(settings),
                  _buildFontFamilyTile(settings),
                  _buildTabSizeTile(settings),
                  _buildSwitchTile(
                    '显示行号',
                    settings.editorSettings.showLineNumbers,
                    (value) => _saveSettings(settings.copyWith(
                      editorSettings: settings.editorSettings.copyWith(
                        showLineNumbers: value,
                      ),
                    )),
                  ),
                  _buildSwitchTile(
                    '高亮当前行',
                    settings.editorSettings.highlightCurrentLine,
                    (value) => _saveSettings(settings.copyWith(
                      editorSettings: settings.editorSettings.copyWith(
                        highlightCurrentLine: value,
                      ),
                    )),
                  ),
                  _buildSwitchTile(
                    '自动换行',
                    settings.editorSettings.wordWrap,
                    (value) => _saveSettings(settings.copyWith(
                      editorSettings: settings.editorSettings.copyWith(
                        wordWrap: value,
                      ),
                    )),
                  ),
                  _buildSwitchTile(
                    '代码折叠',
                    settings.editorSettings.enableCodeFolding,
                    (value) => _saveSettings(settings.copyWith(
                      editorSettings: settings.editorSettings.copyWith(
                        enableCodeFolding: value,
                      ),
                    )),
                  ),
                ],
              ),
              _buildSection(
                '反编译',
                [
                  _buildSwitchTile(
                    '启用反混淆',
                    settings.decompileSettings.deobfuscationEnabled,
                    (value) => _saveSettings(settings.copyWith(
                      decompileSettings: settings.decompileSettings.copyWith(
                        deobfuscationEnabled: value,
                      ),
                    )),
                  ),
                  _buildSwitchTile(
                    '跳过资源文件',
                    settings.decompileSettings.skipResources,
                    (value) => _saveSettings(settings.copyWith(
                      decompileSettings: settings.decompileSettings.copyWith(
                        skipResources: value,
                      ),
                    )),
                  ),
                  _buildOutputFormatTile(settings),
                  _buildMaxThreadsTile(settings),
                ],
              ),
              _buildSection(
                '外部工具',
                [
                  _buildSwitchTile(
                    '优先使用外部工具',
                    settings.externalToolSettings.preferExternalTools,
                    (value) => _saveSettings(settings.copyWith(
                      externalToolSettings: settings.externalToolSettings.copyWith(
                        preferExternalTools: value,
                      ),
                    )),
                  ),
                  _buildPreferredDecompilerTile(settings),
                ],
              ),
              _buildSection(
                '存储',
                [
                  _buildCacheSizeTile(),
                  _buildClearCacheTile(),
                ],
              ),
              _buildSection(
                '关于',
                [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('版本'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Miss IDE'),
                    subtitle: const Text('Android APK 反编译与分析工具'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
  
  Widget _buildThemeTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('主题模式'),
      subtitle: Text(_getThemeModeText(settings.themeMode)),
      onTap: () async {
        final result = await showDialog<AppThemeMode>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择主题模式'),
            children: [
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.system,
                groupValue: settings.themeMode,
                title: const Text('跟随系统'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.light,
                groupValue: settings.themeMode,
                title: const Text('浅色'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.dark,
                groupValue: settings.themeMode,
                title: const Text('深色'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(themeMode: result));
        }
      },
    );
  }
  
  String _getThemeModeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return '跟随系统';
      case AppThemeMode.light:
        return '浅色';
      case AppThemeMode.dark:
        return '深色';
    }
  }
  
  Widget _buildCodeThemeTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.color_lens),
      title: const Text('代码高亮主题'),
      subtitle: Text(_getCodeThemeText(settings.codeHighlightTheme)),
      onTap: () async {
        final result = await showDialog<CodeHighlightTheme>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择代码高亮主题'),
            children: CodeHighlightTheme.values.map((theme) {
              return RadioListTile<CodeHighlightTheme>(
                value: theme,
                groupValue: settings.codeHighlightTheme,
                title: Text(_getCodeThemeText(theme)),
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(codeHighlightTheme: result));
        }
      },
    );
  }
  
  String _getCodeThemeText(CodeHighlightTheme theme) {
    switch (theme) {
      case CodeHighlightTheme.monokai:
        return 'Monokai';
      case CodeHighlightTheme.dracula:
        return 'Dracula';
      case CodeHighlightTheme.github:
        return 'GitHub';
      case CodeHighlightTheme.solarizedDark:
        return 'Solarized Dark';
      case CodeHighlightTheme.solarizedLight:
        return 'Solarized Light';
      case CodeHighlightTheme.nord:
        return 'Nord';
      case CodeHighlightTheme.oneDark:
        return 'One Dark';
      case CodeHighlightTheme.material:
        return 'Material';
      case CodeHighlightTheme.defaultLight:
        return '浅色默认';
    }
  }
  
  Widget _buildMaterial3Tile(AppSettings settings) {
    return _buildSwitchTile(
      '使用 Material 3',
      settings.useMaterial3,
      (value) => _saveSettings(settings.copyWith(useMaterial3: value)),
    );
  }
  
  Widget _buildFontSizeTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: const Text('字体大小'),
      subtitle: Text('${settings.editorSettings.fontSize.toInt()} px'),
      onTap: () async {
        final result = await showDialog<double>(
          context: context,
          builder: (context) => _FontSizeDialog(
            currentSize: settings.editorSettings.fontSize,
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(
            editorSettings: settings.editorSettings.copyWith(fontSize: result),
          ));
        }
      },
    );
  }
  
  Widget _buildFontFamilyTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.font_download),
      title: const Text('字体'),
      subtitle: Text(settings.editorSettings.fontFamily),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择字体'),
            children: ['monospace', 'Roboto Mono', 'Source Code Pro', 'JetBrains Mono']
                .map((font) => RadioListTile<String>(
                      value: font,
                      groupValue: settings.editorSettings.fontFamily,
                      title: Text(font),
                      onChanged: (value) => Navigator.pop(context, value),
                    ))
                .toList(),
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(
            editorSettings: settings.editorSettings.copyWith(fontFamily: result),
          ));
        }
      },
    );
  }
  
  Widget _buildTabSizeTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.keyboard_tab),
      title: const Text('Tab 大小'),
      subtitle: Text('${settings.editorSettings.tabSize} 个空格'),
      onTap: () async {
        final result = await showDialog<int>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择 Tab 大小'),
            children: [2, 4, 8].map((size) {
              return RadioListTile<int>(
                value: size,
                groupValue: settings.editorSettings.tabSize,
                title: Text('$size 个空格'),
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(
            editorSettings: settings.editorSettings.copyWith(tabSize: result),
          ));
        }
      },
    );
  }
  
  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
  
  Widget _buildOutputFormatTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.code),
      title: const Text('输出格式'),
      subtitle: Text(settings.decompileSettings.outputFormat.toUpperCase()),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择输出格式'),
            children: ['java', 'smali', 'both'].map((format) {
              return RadioListTile<String>(
                value: format,
                groupValue: settings.decompileSettings.outputFormat,
                title: Text(format.toUpperCase()),
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(
            decompileSettings: settings.decompileSettings.copyWith(
              outputFormat: result,
            ),
          ));
        }
      },
    );
  }
  
  Widget _buildMaxThreadsTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.memory),
      title: const Text('最大线程数'),
      subtitle: Text('${settings.decompileSettings.maxThreads}'),
      onTap: () async {
        final result = await showDialog<int>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择线程数'),
            children: [1, 2, 4, 8].map((threads) {
              return RadioListTile<int>(
                value: threads,
                groupValue: settings.decompileSettings.maxThreads,
                title: Text('$threads'),
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(
            decompileSettings: settings.decompileSettings.copyWith(
              maxThreads: result,
            ),
          ));
        }
      },
    );
  }
  
  Widget _buildPreferredDecompilerTile(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.build),
      title: const Text('首选反编译器'),
      subtitle: Text(_getDecompilerText(settings.externalToolSettings.preferredDecompiler)),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择首选反编译器'),
            children: [
              RadioListTile<String>(
                value: 'jadx',
                groupValue: settings.externalToolSettings.preferredDecompiler,
                title: const Text('Jadx (内置)'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
                value: 'mt',
                groupValue: settings.externalToolSettings.preferredDecompiler,
                title: const Text('MT Manager'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
                value: 'apk_editor',
                groupValue: settings.externalToolSettings.preferredDecompiler,
                title: const Text('APK Editor'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
        );
        if (result != null) {
          _saveSettings(settings.copyWith(
            externalToolSettings: settings.externalToolSettings.copyWith(
              preferredDecompiler: result,
            ),
          ));
        }
      },
    );
  }
  
  String _getDecompilerText(String decompiler) {
    switch (decompiler) {
      case 'jadx':
        return 'Jadx (内置)';
      case 'mt':
        return 'MT Manager';
      case 'apk_editor':
        return 'APK Editor';
      default:
        return decompiler;
    }
  }
  
  Widget _buildCacheSizeTile() {
    return FutureBuilder<int>(
      future: _repository.getCacheSize(),
      builder: (context, snapshot) {
        final size = snapshot.data ?? 0;
        return ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('缓存大小'),
          subtitle: Text(_repository.formatCacheSize(size)),
        );
      },
    );
  }
  
  Widget _buildClearCacheTile() {
    return ListTile(
      leading: const Icon(Icons.delete_outline),
      title: const Text('清除缓存'),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('清除缓存'),
            content: const Text('确定要清除所有缓存吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _repository.clearCache();
          setState(() {});
        }
      },
    );
  }
}

class _FontSizeDialog extends StatefulWidget {
  final double currentSize;
  
  const _FontSizeDialog({required this.currentSize});
  
  @override
  State<_FontSizeDialog> createState() => _FontSizeDialogState();
}

class _FontSizeDialogState extends State<_FontSizeDialog> {
  late double _size;
  
  @override
  void initState() {
    super.initState();
    _size = widget.currentSize;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('字体大小'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_size.toInt()} px',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _size,
            min: 10,
            max: 30,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _size = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _size),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
