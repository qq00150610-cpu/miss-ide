// lib/engine/plugin/builtin/language_plugin.dart - 语言高亮插件
import 'package:flutter/material.dart';
import '../plugin_system.dart';

/// 支持的语言列表
class LanguageDefinition {
  final String id;
  final String name;
  final List<String> fileExtensions;
  final Map<String, String> keywords;
  final String commentSingle;
  final String? commentMultiStart;
  final String? commentMultiEnd;

  const LanguageDefinition({
    required this.id,
    required this.name,
    required this.fileExtensions,
    this.keywords = const {},
    this.commentSingle = '//',
    this.commentMultiStart,
    this.commentMultiEnd,
  });

  static const LanguageDefinition java = LanguageDefinition(
    id: 'java',
    name: 'Java',
    fileExtensions: ['.java'],
    keywords: {
      'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
      'char', 'class', 'const', 'continue', 'default', 'do', 'double',
      'else', 'enum', 'extends', 'final', 'finally', 'float', 'for',
      'goto', 'if', 'implements', 'import', 'instanceof', 'int',
      'interface', 'long', 'native', 'new', 'package', 'private',
      'protected', 'public', 'return', 'short', 'static', 'strictfp',
      'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
      'transient', 'try', 'void', 'volatile', 'while', 'true', 'false', 'null',
    },
    commentSingle: '//',
    commentMultiStart: '/*',
    commentMultiEnd: '*/',
  );

  static const LanguageDefinition smali = LanguageDefinition(
    id: 'smali',
    name: 'Smali',
    fileExtensions: ['.smali'],
    keywords: {
      '.class', '.super', '.field', '.method', '.end method', '.end field',
      '.annotation', '.end annotation', '.implements', '.source',
      'public', 'private', 'protected', 'static', 'final', 'abstract',
      'synchronized', 'volatile', 'transient', 'native', 'bridge',
      'varargs', 'enum', 'constructor', 'declared_synchronized',
      'void', 'boolean', 'byte', 'char', 'short', 'int', 'long', 'float', 'double',
      'return', 'return-void', 'move', 'move-result', 'invoke', 'throw',
    },
    commentSingle: '#',
  );

  static const LanguageDefinition xml = LanguageDefinition(
    id: 'xml',
    name: 'XML',
    fileExtensions: ['.xml', '.axml', '.layout'],
    keywords: {
      'xmlns', 'xmlns:android', 'xmlns:app', 'xmlns:aapt',
      'android:', 'app:', 'tools:',
    },
    commentSingle: '<!--',
    commentMultiEnd: '-->',
    commentMultiStart: '',
  );

  static const LanguageDefinition json = LanguageDefinition(
    id: 'json',
    name: 'JSON',
    fileExtensions: ['.json'],
    keywords: {'true', 'false', 'null'},
  );

  static const LanguageDefinition dart = LanguageDefinition(
    id: 'dart',
    name: 'Dart',
    fileExtensions: ['.dart'],
    keywords: {
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case',
      'catch', 'class', 'const', 'continue', 'covariant', 'default',
      'deferred', 'do', 'dynamic', 'else', 'enum', 'export', 'extends',
      'extension', 'external', 'factory', 'false', 'final', 'finally',
      'for', 'Function', 'get', 'hide', 'if', 'implements', 'import',
      'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', 'null',
      'on', 'operator', 'part', 'required', 'rethrow', 'return', 'set',
      'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true',
      'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
    },
    commentSingle: '//',
    commentMultiStart: '/*',
    commentMultiEnd: '*/',
  );
}

/// 语言高亮插件
class LanguagePlugin implements MissPlugin {
  @override
  PluginMeta get meta => const PluginMeta(
    id: 'language-plugin',
    name: '语言插件',
    version: '1.0.0',
    description: '提供多种编程语言的语法高亮支持',
    author: 'Miss IDE Team',
    tags: ['language', 'syntax', 'highlight'],
    isBuiltIn: true,
  );

  PluginState _state = PluginState.unloaded;
  @override
  PluginState get state => _state;

  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> _config = {};
  final Map<String, LanguageDefinition> _languages = {
    'java': LanguageDefinition.java,
    'smali': LanguageDefinition.smali,
    'xml': LanguageDefinition.xml,
    'json': LanguageDefinition.json,
    'dart': LanguageDefinition.dart,
  };

  @override
  List<String> get dependencies => [];

  @override
  Future<void> onInit() async {
    _state = PluginState.loading;
    // 可以添加更多内置语言
    _state = PluginState.loaded;
  }

  @override
  Future<void> onDispose() async {
    _state = PluginState.unloaded;
  }

  @override
  List<MenuItem> contributeMenuItems() => [];

  @override
  List<Command> contributeCommands() => [];

  @override
  Widget? contributePanel(String location) => null;

  @override
  List<SettingsItem> contributeSettings() => [
    const SettingsItem(
      key: 'language.enableHighlight',
      label: '启用语法高亮',
      type: 'bool',
      defaultValue: true,
      description: '是否启用代码语法高亮',
    ),
    const SettingsItem(
      key: 'language.highlightCurrentLine',
      label: '高亮当前行',
      type: 'bool',
      defaultValue: true,
      description: '高亮编辑器当前行',
    ),
    const SettingsItem(
      key: 'language.matchBrackets',
      label: '匹配括号高亮',
      type: 'bool',
      defaultValue: true,
      description: '高亮匹配的括号',
    ),
  ];

  @override
  Map<String, dynamic> getConfig() => _config;

  @override
  Future<void> setConfig(Map<String, dynamic> config) async {
    _config = config;
  }

  /// 获取语言定义
  LanguageDefinition? getLanguage(String languageId) => _languages[languageId];

  /// 从文件扩展名获取语言
  LanguageDefinition? getLanguageByExtension(String extension) {
    for (final lang in _languages.values) {
      if (lang.fileExtensions.contains(extension)) {
        return lang;
      }
    }
    return null;
  }

  /// 获取所有支持的语言
  List<LanguageDefinition> get allLanguages => _languages.values.toList();

  /// 注册自定义语言
  void registerLanguage(LanguageDefinition definition) {
    _languages[definition.id] = definition;
  }

  /// 获取文件对应的语言ID
  String? getLanguageIdForFile(String filePath) {
    final ext = filePath.contains('.') 
        ? '.${filePath.split('.').last}'
        : '';
    
    for (final entry in _languages.entries) {
      if (entry.value.fileExtensions.contains(ext)) {
        return entry.key;
      }
    }
    return null;
  }
}
