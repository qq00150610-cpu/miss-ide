// lib/features/settings/domain/settings_model.dart - 设置数据模型
import 'package:flutter/material.dart';

/// 编辑器设置
class EditorSettings {
  final double fontSize;
  final String fontFamily;
  final int tabSize;
  final bool showLineNumbers;
  final bool highlightCurrentLine;
  final bool wordWrap;
  final bool showMinimap;
  final bool autoSave;
  final int autoSaveInterval; // 秒
  final bool enableAutoComplete;
  final bool enableCodeFolding;
  final bool enableBracketMatching;
  final String indentType; // 'space' | 'tab'
  
  const EditorSettings({
    this.fontSize = 14.0,
    this.fontFamily = 'monospace',
    this.tabSize = 4,
    this.showLineNumbers = true,
    this.highlightCurrentLine = true,
    this.wordWrap = false,
    this.showMinimap = false,
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.enableAutoComplete = true,
    this.enableCodeFolding = true,
    this.enableBracketMatching = true,
    this.indentType = 'space',
  });
  
  EditorSettings copyWith({
    double? fontSize,
    String? fontFamily,
    int? tabSize,
    bool? showLineNumbers,
    bool? highlightCurrentLine,
    bool? wordWrap,
    bool? showMinimap,
    bool? autoSave,
    int? autoSaveInterval,
    bool? enableAutoComplete,
    bool? enableCodeFolding,
    bool? enableBracketMatching,
    String? indentType,
  }) {
    return EditorSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      tabSize: tabSize ?? this.tabSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      highlightCurrentLine: highlightCurrentLine ?? this.highlightCurrentLine,
      wordWrap: wordWrap ?? this.wordWrap,
      showMinimap: showMinimap ?? this.showMinimap,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      enableAutoComplete: enableAutoComplete ?? this.enableAutoComplete,
      enableCodeFolding: enableCodeFolding ?? this.enableCodeFolding,
      enableBracketMatching: enableBracketMatching ?? this.enableBracketMatching,
      indentType: indentType ?? this.indentType,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'tabSize': tabSize,
    'showLineNumbers': showLineNumbers,
    'highlightCurrentLine': highlightCurrentLine,
    'wordWrap': wordWrap,
    'showMinimap': showMinimap,
    'autoSave': autoSave,
    'autoSaveInterval': autoSaveInterval,
    'enableAutoComplete': enableAutoComplete,
    'enableCodeFolding': enableCodeFolding,
    'enableBracketMatching': enableBracketMatching,
    'indentType': indentType,
  };
  
  factory EditorSettings.fromJson(Map<String, dynamic> json) {
    return EditorSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? 'monospace',
      tabSize: json['tabSize'] as int? ?? 4,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      highlightCurrentLine: json['highlightCurrentLine'] as bool? ?? true,
      wordWrap: json['wordWrap'] as bool? ?? false,
      showMinimap: json['showMinimap'] as bool? ?? false,
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveInterval: json['autoSaveInterval'] as int? ?? 30,
      enableAutoComplete: json['enableAutoComplete'] as bool? ?? true,
      enableCodeFolding: json['enableCodeFolding'] as bool? ?? true,
      enableBracketMatching: json['enableBracketMatching'] as bool? ?? true,
      indentType: json['indentType'] as String? ?? 'space',
    );
  }
}

/// 反编译设置
class DecompileSettings {
  final String outputDirectory;
  final bool deobfuscationEnabled;
  final bool skipResources;
  final bool showDebugInfo;
  final String outputFormat; // 'java' | 'smali' | 'both'
  final int maxThreads;
  final bool autoOpenAfterDecompile;
  
  const DecompileSettings({
    this.outputDirectory = '',
    this.deobfuscationEnabled = false,
    this.skipResources = false,
    this.showDebugInfo = false,
    this.outputFormat = 'java',
    this.maxThreads = 4,
    this.autoOpenAfterDecompile = true,
  });
  
  DecompileSettings copyWith({
    String? outputDirectory,
    bool? deobfuscationEnabled,
    bool? skipResources,
    bool? showDebugInfo,
    String? outputFormat,
    int? maxThreads,
    bool? autoOpenAfterDecompile,
  }) {
    return DecompileSettings(
      outputDirectory: outputDirectory ?? this.outputDirectory,
      deobfuscationEnabled: deobfuscationEnabled ?? this.deobfuscationEnabled,
      skipResources: skipResources ?? this.skipResources,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      outputFormat: outputFormat ?? this.outputFormat,
      maxThreads: maxThreads ?? this.maxThreads,
      autoOpenAfterDecompile: autoOpenAfterDecompile ?? this.autoOpenAfterDecompile,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'outputDirectory': outputDirectory,
    'deobfuscationEnabled': deobfuscationEnabled,
    'skipResources': skipResources,
    'showDebugInfo': showDebugInfo,
    'outputFormat': outputFormat,
    'maxThreads': maxThreads,
    'autoOpenAfterDecompile': autoOpenAfterDecompile,
  };
  
  factory DecompileSettings.fromJson(Map<String, dynamic> json) {
    return DecompileSettings(
      outputDirectory: json['outputDirectory'] as String? ?? '',
      deobfuscationEnabled: json['deobfuscationEnabled'] as bool? ?? false,
      skipResources: json['skipResources'] as bool? ?? false,
      showDebugInfo: json['showDebugInfo'] as bool? ?? false,
      outputFormat: json['outputFormat'] as String? ?? 'java',
      maxThreads: json['maxThreads'] as int? ?? 4,
      autoOpenAfterDecompile: json['autoOpenAfterDecompile'] as bool? ?? true,
    );
  }
}

/// 外部工具配置
class ExternalToolSettings {
  final bool preferExternalTools;
  final String preferredDecompiler; // 'jadx' | 'mt' | 'apk_editor'
  final bool autoCheckToolUpdates;
  final Map<String, bool> toolEnabled;
  
  const ExternalToolSettings({
    this.preferExternalTools = false,
    this.preferredDecompiler = 'jadx',
    this.autoCheckToolUpdates = true,
    this.toolEnabled = const {},
  });
  
  ExternalToolSettings copyWith({
    bool? preferExternalTools,
    String? preferredDecompiler,
    bool? autoCheckToolUpdates,
    Map<String, bool>? toolEnabled,
  }) {
    return ExternalToolSettings(
      preferExternalTools: preferExternalTools ?? this.preferExternalTools,
      preferredDecompiler: preferredDecompiler ?? this.preferredDecompiler,
      autoCheckToolUpdates: autoCheckToolUpdates ?? this.autoCheckToolUpdates,
      toolEnabled: toolEnabled ?? this.toolEnabled,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'preferExternalTools': preferExternalTools,
    'preferredDecompiler': preferredDecompiler,
    'autoCheckToolUpdates': autoCheckToolUpdates,
    'toolEnabled': toolEnabled,
  };
  
  factory ExternalToolSettings.fromJson(Map<String, dynamic> json) {
    return ExternalToolSettings(
      preferExternalTools: json['preferExternalTools'] as bool? ?? false,
      preferredDecompiler: json['preferredDecompiler'] as String? ?? 'jadx',
      autoCheckToolUpdates: json['autoCheckToolUpdates'] as bool? ?? true,
      toolEnabled: (json['toolEnabled'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool)) ??
          {},
    );
  }
}

/// 存储设置
class StorageSettings {
  final String defaultProjectPath;
  final String defaultDecompileOutputPath;
  final int maxRecentProjects;
  final bool enableAutoBackup;
  final int backupInterval; // 分钟
  final int maxCacheSize; // MB
  
  const StorageSettings({
    this.defaultProjectPath = '',
    this.defaultDecompileOutputPath = '',
    this.maxRecentProjects = 10,
    this.enableAutoBackup = true,
    this.backupInterval = 60,
    this.maxCacheSize = 500,
  });
  
  StorageSettings copyWith({
    String? defaultProjectPath,
    String? defaultDecompileOutputPath,
    int? maxRecentProjects,
    bool? enableAutoBackup,
    int? backupInterval,
    int? maxCacheSize,
  }) {
    return StorageSettings(
      defaultProjectPath: defaultProjectPath ?? this.defaultProjectPath,
      defaultDecompileOutputPath: 
          defaultDecompileOutputPath ?? this.defaultDecompileOutputPath,
      maxRecentProjects: maxRecentProjects ?? this.maxRecentProjects,
      enableAutoBackup: enableAutoBackup ?? this.enableAutoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'defaultProjectPath': defaultProjectPath,
    'defaultDecompileOutputPath': defaultDecompileOutputPath,
    'maxRecentProjects': maxRecentProjects,
    'enableAutoBackup': enableAutoBackup,
    'backupInterval': backupInterval,
    'maxCacheSize': maxCacheSize,
  };
  
  factory StorageSettings.fromJson(Map<String, dynamic> json) {
    return StorageSettings(
      defaultProjectPath: json['defaultProjectPath'] as String? ?? '',
      defaultDecompileOutputPath: 
          json['defaultDecompileOutputPath'] as String? ?? '',
      maxRecentProjects: json['maxRecentProjects'] as int? ?? 10,
      enableAutoBackup: json['enableAutoBackup'] as bool? ?? true,
      backupInterval: json['backupInterval'] as int? ?? 60,
      maxCacheSize: json['maxCacheSize'] as int? ?? 500,
    );
  }
}

/// 应用主题模式
enum AppThemeMode {
  system,
  light,
  dark,
}

/// 代码高亮主题
enum CodeHighlightTheme {
  monokai,
  dracula,
  github,
  solarizedDark,
  solarizedLight,
  nord,
  oneDark,
  material,
  defaultLight,
}

/// 应用设置（总）
class AppSettings {
  final AppThemeMode themeMode;
  final CodeHighlightTheme codeHighlightTheme;
  final bool useMaterial3;
  final String language;
  final EditorSettings editorSettings;
  final DecompileSettings decompileSettings;
  final ExternalToolSettings externalToolSettings;
  final StorageSettings storageSettings;
  
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.codeHighlightTheme = CodeHighlightTheme.monokai,
    this.useMaterial3 = true,
    this.language = 'zh_CN',
    this.editorSettings = const EditorSettings(),
    this.decompileSettings = const DecompileSettings(),
    this.externalToolSettings = const ExternalToolSettings(),
    this.storageSettings = const StorageSettings(),
  });
  
  AppSettings copyWith({
    AppThemeMode? themeMode,
    CodeHighlightTheme? codeHighlightTheme,
    bool? useMaterial3,
    String? language,
    EditorSettings? editorSettings,
    DecompileSettings? decompileSettings,
    ExternalToolSettings? externalToolSettings,
    StorageSettings? storageSettings,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      codeHighlightTheme: codeHighlightTheme ?? this.codeHighlightTheme,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      language: language ?? this.language,
      editorSettings: editorSettings ?? this.editorSettings,
      decompileSettings: decompileSettings ?? this.decompileSettings,
      externalToolSettings: externalToolSettings ?? this.externalToolSettings,
      storageSettings: storageSettings ?? this.storageSettings,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'codeHighlightTheme': codeHighlightTheme.index,
    'useMaterial3': useMaterial3,
    'language': language,
    'editorSettings': editorSettings.toJson(),
    'decompileSettings': decompileSettings.toJson(),
    'externalToolSettings': externalToolSettings.toJson(),
    'storageSettings': storageSettings.toJson(),
  };
  
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values[json['themeMode'] as int? ?? 0],
      codeHighlightTheme: 
          CodeHighlightTheme.values[json['codeHighlightTheme'] as int? ?? 0],
      useMaterial3: json['useMaterial3'] as bool? ?? true,
      language: json['language'] as String? ?? 'zh_CN',
      editorSettings: EditorSettings.fromJson(
          json['editorSettings'] as Map<String, dynamic>? ?? {}),
      decompileSettings: DecompileSettings.fromJson(
          json['decompileSettings'] as Map<String, dynamic>? ?? {}),
      externalToolSettings: ExternalToolSettings.fromJson(
          json['externalToolSettings'] as Map<String, dynamic>? ?? {}),
      storageSettings: StorageSettings.fromJson(
          json['storageSettings'] as Map<String, dynamic>? ?? {}),
    );
  }
}
