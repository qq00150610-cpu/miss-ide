// lib/engine/plugin/plugin_system.dart - 插件系统核心
import 'package:flutter/material.dart';

/// 插件元信息
class PluginMeta {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String homepage;
  final List<String> tags;
  final String? iconPath;
  final String? previewImage;
  final bool isBuiltIn;
  final bool isEnabled;
  final DateTime? installedAt;
  final DateTime? updatedAt;

  const PluginMeta({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
    this.author = '',
    this.homepage = '',
    this.tags = const [],
    this.iconPath,
    this.previewImage,
    this.isBuiltIn = false,
    this.isEnabled = true,
    this.installedAt,
    this.updatedAt,
  });

  PluginMeta copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    String? author,
    String? homepage,
    List<String>? tags,
    String? iconPath,
    String? previewImage,
    bool? isBuiltIn,
    bool? isEnabled,
    DateTime? installedAt,
    DateTime? updatedAt,
  }) {
    return PluginMeta(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      author: author ?? this.author,
      homepage: homepage ?? this.homepage,
      tags: tags ?? this.tags,
      iconPath: iconPath ?? this.iconPath,
      previewImage: previewImage ?? this.previewImage,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'description': description,
    'author': author,
    'homepage': homepage,
    'tags': tags,
    'iconPath': iconPath,
    'previewImage': previewImage,
    'isBuiltIn': isBuiltIn,
    'isEnabled': isEnabled,
    'installedAt': installedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory PluginMeta.fromJson(Map<String, dynamic> json) {
    return PluginMeta(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? '',
      homepage: json['homepage'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      iconPath: json['iconPath'] as String?,
      previewImage: json['previewImage'] as String?,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      installedAt: json['installedAt'] != null
          ? DateTime.parse(json['installedAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// 菜单项
class MenuItem {
  final String id;
  final String label;
  final String? icon;
  final String? shortcut;
  final VoidCallback? onTap;
  final List<MenuItem> children;
  final int? sortOrder;

  const MenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.shortcut,
    this.onTap,
    this.children = const [],
    this.sortOrder,
  });
}

/// 命令
class Command {
  final String id;
  final String name;
  final String? description;
  final String? shortcut;
  final Future<void> Function()? execute;
  final bool Function()? isEnabled;
  final bool Function()? isVisible;

  const Command({
    required this.id,
    required this.name,
    this.description,
    this.shortcut,
    this.execute,
    this.isEnabled,
    this.isVisible,
  });
}

/// 设置项
class SettingsItem {
  final String key;
  final String label;
  final String type; // 'string', 'bool', 'int', 'enum', 'color'
  final dynamic defaultValue;
  final dynamic value;
  final Map<String, dynamic>? options;
  final String? description;

  const SettingsItem({
    required this.key,
    required this.label,
    required this.type,
    this.defaultValue,
    this.value,
    this.options,
    this.description,
  });
}

/// 插件状态
enum PluginState {
  unloaded,
  loading,
  loaded,
  error,
  disabled,
}

/// 插件基类
abstract class MissPlugin {
  PluginMeta get meta;
  PluginState get state;
  String? get errorMessage;

  /// 插件初始化
  Future<void> onInit();

  /// 插件销毁
  Future<void> onDispose();

  /// 获取提供的菜单项
  List<MenuItem> contributeMenuItems();

  /// 获取提供的命令
  List<Command> contributeCommands();

  /// 获取提供的面板
  Widget? contributePanel(String location);

  /// 获取提供的设置项
  List<SettingsItem> contributeSettings();

  /// 获取依赖的插件
  List<String> get dependencies;

  /// 获取插件配置
  Map<String, dynamic> getConfig();

  /// 设置插件配置
  Future<void> setConfig(Map<String, dynamic> config);
}

/// 插件接口版本
class PluginInterfaceVersion {
  static const int major = 1;
  static const int minor = 0;
  static String get version => '$major.$minor';
}
