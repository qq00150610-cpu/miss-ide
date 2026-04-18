// lib/core/constants/editor_constants.dart - 编辑器常量

/// 编辑器常量
class EditorConstants {
  EditorConstants._();
  
  /// 行号配置
  static const double lineNumberWidth = 50.0;
  static const String lineNumberFormat = '%4d';
  
  /// 缩进配置
  static const int indentSize = 4;
  static const String indentString = '    ';
  
  /// 搜索配置
  static const int searchDebounceMs = 300;
  static const int maxSearchResults = 1000;
  
  /// 撤销/重做配置
  static const int maxUndoStackSize = 100;
  
  /// 标记配置
  static const String bookmarkPrefix = ' bookmark:';
  static const String todoPattern = r'(TODO|FIXME|HACK|XXX):';
}

/// Smali 语法高亮配置
class SmaliSyntax {
  SmaliSyntax._();
  
  /// Smali 关键字
  static const List<String> keywords = [
    '.method', '.end method', '.field', '.end field',
    '.class', '.super', '.source', '.annotation', '.end annotation',
    '.register', '.locals', '.param', '.end param',
    '.local', '.end local', '.restart local',
    '.catch', '.catchall', '.end catch',
    '.line', '.source',
    'public', 'private', 'protected', 'static', 'final',
    'abstract', 'volatile', 'transient', 'synchronized', 'native',
    'bridge', 'varargs', 'enum', 'annotation', 'synthetic',
  ];
  
  /// Smali 指令
  static const List<String> opcodes = [
    'move', 'move-object', 'move-result', 'move-result-wide', 'move-exception',
    'return-void', 'return', 'return-wide', 'return-object',
    'monitor-enter', 'monitor-exit', 'check-cast', 'instance-of',
    'array-length', 'new-array', 'filled-new-array', 'filled-new-array-range',
    'fill-array-data',
    'throw', 'goto', 'goto/16', 'goto/32',
    'packed-switch', 'sparse-switch',
    'cmpl-float', 'cmpg-float', 'cmpl-double', 'cmpg-double', 'cmp-long',
    'if-eq', 'if-ne', 'if-lt', 'if-ge', 'if-gt', 'if-le',
    'if-eqz', 'if-nez', 'if-ltz', 'if-gez', 'if-gtz', 'if-lez',
    'invoke-virtual', 'invoke-super', 'invoke-direct', 'invoke-static',
    'invoke-interface', 'invoke-virtual/range', 'invoke-super/range',
    'invoke-direct/range', 'invoke-static/range', 'invoke-interface/range',
    'nop', 'breakpoint',
  ];
  
  /// 寄存器模式
  static final RegExp registerPattern = RegExp(r'v\d+|p\d+|p\d+\.\.\w+|v\d+\.\.\w+');
  
  /// 类型描述符模式 (Lcom/example/Class;)
  static final RegExp typeDescriptorPattern = RegExp(r'L[a-zA-Z_][a-zA-Z0-9_/$;]*;');
  
  /// 方法签名模式
  static final RegExp methodSignaturePattern = RegExp(r'\((.*?)\)(.*)');
  
  /// 注释模式
  static final RegExp commentPattern = RegExp(r'#.*$', multiLine: true);
  
  /// 行号指令
  static final RegExp lineNumberPattern = RegExp(r'\.line\s+(\d+)');
}

/// Java 语法高亮配置
class JavaSyntax {
  JavaSyntax._();
  
  /// Java 关键字
  static const List<String> keywords = [
    'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
    'char', 'class', 'const', 'continue', 'default', 'do', 'double',
    'else', 'enum', 'extends', 'final', 'finally', 'float', 'for',
    'goto', 'if', 'implements', 'import', 'instanceof', 'int', 'interface',
    'long', 'native', 'new', 'package', 'private', 'protected', 'public',
    'return', 'short', 'static', 'strictfp', 'super', 'switch',
    'synchronized', 'this', 'throw', 'throws', 'transient', 'try', 'void',
    'volatile', 'while', 'true', 'false', 'null',
  ];
  
  /// 注释模式
  static final RegExp singleLineCommentPattern = RegExp(r'//.*$', multiLine: true);
  static final RegExp multiLineCommentPattern = RegExp(r'/\*.*?\*/', dotAll: true);
  
  /// 字符串模式
  static final RegExp stringPattern = RegExp(r'"(?:[^"\\]|\\.)*"');
  
  /// 数字模式
  static final RegExp numberPattern = RegExp(r'\b\d+(\.\d+)?[fFdDlL]?\b');
  
  /// 注解模式
  static final RegExp annotationPattern = RegExp(r'@[a-zA-Z_][a-zA-Z0-9_]*');
}
