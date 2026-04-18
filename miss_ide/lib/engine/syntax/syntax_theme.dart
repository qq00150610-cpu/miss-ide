// lib/engine/syntax/syntax_theme.dart - 语法高亮主题
import 'package:flutter/material.dart';

/// 语法高亮颜色主题
class SyntaxTheme {
  // 基础颜色
  static const Color background = Color(0xFF1E1E1E);
  static const Color foreground = Color(0xFFD4D4D4);
  static const Color selection = Color(0xFF264F78);
  static const Color cursor = Color(0xFFAEAFAD);
  
  // 注释
  static const Color comment = Color(0xFF6A9955);
  static const Color lineComment = Color(0xFF6A9955);
  
  // 关键字
  static const Color keyword = Color(0xFF569CD6);
  static const Color controlKeyword = Color(0xFFC586C0);
  
  // 字符串
  static const Color string = Color(0xFFCE9178);
  static const Color stringEscape = Color(0xFFD7BA7D);
  
  // 数字
  static const Color number = Color(0xFFB5CEA8);
  static const Color hexNumber = Color(0xFFB5CEA8);
  
  // 类型
  static const Color type = Color(0xFF4EC9B0);
  static const Color className = Color(0xFF4EC9B0);
  static const Color structName = Color(0xFF4EC9B0);
  static const Color interfaceName = Color(0xFF4EC9B0);
  static const Color enumName = Color(0xFF4EC9B0);
  
  // 方法/函数
  static const Color function = Color(0xFFDCDCAA);
  static const Color method = Color(0xFFDCDCAA);
  
  // 变量
  static const Color variable = Color(0xFF9CDCFE);
  static const Color parameter = Color(0xFF9CDCFE);
  static const Color property = Color(0xFF9CDCFE);
  
  // 常量
  static const Color constant = Color(0xFF4FC1FF);
  
  // 运算符
  static const Color operator = Color(0xFFD4D4D4);
  static const Color punctuation = Color(0xFFD4D4D4);
  
  // 标签
  static const Color label = Color(0xFFE8D44D);
  static const Color tag = Color(0xFF569CD6);
  static const Color attribute = Color(0xFF9CDCFE);
  
  // XML/HTML特定
  static const Color xmlTag = Color(0xFF569CD6);
  static const Color xmlAttr = Color(0xFF9CDCFE);
  static const Color xmlValue = Color(0xFFCE9178);
  
  // Smali特定
  static const Color smaliDirective = Color(0xFF569CD6);
  static const Color smaliMethod = Color(0xFFDCDCAA);
  static const Color smaliField = Color(0xFF9CDCFE);
  static const Color smaliRegister = Color(0xFFB5CEA8);
  static const Color smaliType = Color(0xFF4EC9B0);
  static const Color smaliOpcode = Color(0xFFD4D4D4);
  
  // 差异高亮
  static const Color addedLine = Color(0xFF2D5A2D);
  static const Color deletedLine = Color(0xFF5A2D2D);
  static const Color modifiedLine = Color(0xFF5A5A2D);
  static const Color addedHighlight = Color(0xFF22C55E);
  static const Color deletedHighlight = Color(0xFFEF4444);
  static const Color modifiedHighlight = Color(0xFFF59E0B);
  
  // 行号
  static const Color lineNumber = Color(0xFF858585);
  static const Color lineNumberForeground = Color(0xFF858585);
  
  // 折叠区域
  static const Color foldingHighlight = Color(0xFFE8E8E8);
  
  /// 获取差异类型对应的颜色
  static Color getDiffColor(String diffType) {
    switch (diffType) {
      case 'add':
        return addedHighlight;
      case 'delete':
        return deletedHighlight;
      case 'modify':
        return modifiedHighlight;
      default:
        return foreground;
    }
  }
  
  /// 获取差异行背景色
  static Color getDiffBackground(String diffType) {
    switch (diffType) {
      case 'add':
        return addedLine;
      case 'delete':
        return deletedLine;
      case 'modify':
        return modifiedLine;
      default:
        return background;
    }
  }
}

/// 语法高亮样式
class SyntaxStyle {
  final Color color;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  
  const SyntaxStyle({
    required this.color,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });
  
  TextStyle toTextStyle({double fontSize = 14}) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontSize: fontSize,
      fontFamily: 'monospace',
    );
  }
}

/// 语法高亮主题映射
class SyntaxHighlighting {
  static final Map<String, SyntaxStyle> smaliTheme = {
    'comment': const SyntaxStyle(color: SyntaxTheme.comment),
    'keyword': const SyntaxStyle(color: SyntaxTheme.keyword),
    'directive': const SyntaxStyle(color: SyntaxTheme.smaliDirective),
    'method': const SyntaxStyle(color: SyntaxTheme.smaliMethod),
    'field': const SyntaxStyle(color: SyntaxTheme.smaliField),
    'register': const SyntaxStyle(color: SyntaxTheme.smaliRegister),
    'type': const SyntaxStyle(color: SyntaxTheme.smaliType),
    'opcode': const SyntaxStyle(color: SyntaxTheme.smaliOpcode),
    'string': const SyntaxStyle(color: SyntaxTheme.string),
    'number': const SyntaxStyle(color: SyntaxTheme.number),
    'default': const SyntaxStyle(color: SyntaxTheme.foreground),
  };
  
  static final Map<String, SyntaxStyle> javaTheme = {
    'comment': const SyntaxStyle(color: SyntaxTheme.comment),
    'keyword': const SyntaxStyle(color: SyntaxTheme.keyword),
    'controlKeyword': const SyntaxStyle(color: SyntaxTheme.controlKeyword),
    'string': const SyntaxStyle(color: SyntaxTheme.string),
    'number': const SyntaxStyle(color: SyntaxTheme.number),
    'type': const SyntaxStyle(color: SyntaxTheme.type),
    'className': const SyntaxStyle(color: SyntaxTheme.className),
    'method': const SyntaxStyle(color: SyntaxTheme.method),
    'variable': const SyntaxStyle(color: SyntaxTheme.variable),
    'annotation': const SyntaxStyle(color: SyntaxTheme.constant),
    'default': const SyntaxStyle(color: SyntaxTheme.foreground),
  };
}
