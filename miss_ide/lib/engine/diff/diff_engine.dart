// lib/engine/diff/diff_engine.dart - Diff引擎中心
import '../../core/constants/app_constants.dart';
import 'diff_result.dart';
import 'myers_diff.dart';

/// Diff引擎配置
class DiffEngineConfig {
  final FileType fileType;
  final bool ignoreWhitespace;
  final bool ignoreCase;
  final int contextLines;
  
  const DiffEngineConfig({
    this.fileType = FileType.unknown,
    this.ignoreWhitespace = false,
    this.ignoreCase = false,
    this.contextLines = 3,
  });
}

/// Diff引擎中心
class DiffEngine {
  final DiffEngineConfig config;
  
  DiffEngine({this.config = const DiffEngineConfig()});
  
  /// 计算两个文本的差异
  DiffResult compute(String leftContent, String rightContent) {
    // 分割行
    final leftLines = _splitLines(leftContent);
    final rightLines = _splitLines(rightContent);
    
    // 应用预处理
    final processedLeft = _preprocessLines(leftLines);
    final processedRight = _preprocessLines(rightLines);
    
    // 根据文件类型选择算法
    switch (config.fileType) {
      case FileType.smali:
        return _computeSmaliDiff(processedLeft, processedRight);
      case FileType.java:
        return _computeJavaDiff(processedLeft, processedRight);
      case FileType.dex:
        return _computeDexDiff(leftContent, rightContent);
      default:
        return _computeDefaultDiff(processedLeft, processedRight);
    }
  }
  
  /// 分割文本为行
  List<String> _splitLines(String content) {
    return content.split('\n');
  }
  
  /// 预处理行
  List<String> _preprocessLines(List<String> lines) {
    var processed = lines;
    
    if (config.ignoreWhitespace) {
      processed = processed.map((l) => l.trim()).toList();
    }
    
    if (config.ignoreCase) {
      processed = processed.map((l) => l.toLowerCase()).toList();
    }
    
    return processed;
  }
  
  /// 默认差异计算
  DiffResult _computeDefaultDiff(List<String> left, List<String> right) {
    return MyersDiff.compute(left, right);
  }
  
  /// Smali差异计算
  DiffResult _computeSmaliDiff(List<String> left, List<String> right) {
    // Smali使用标准Myers Diff
    return MyersDiff.compute(left, right);
  }
  
  /// Java差异计算
  DiffResult _computeJavaDiff(List<String> left, List<String> right) {
    // Java使用标准Myers Diff
    return MyersDiff.compute(left, right);
  }
  
  /// DEX差异计算
  DiffResult _computeDexDiff(String leftContent, String rightContent) {
    // DEX使用文本差异
    return MyersDiff.compute(
      leftContent.split('\n'),
      rightContent.split('\n'),
    );
  }
  
  /// 计算单个文件的差异摘要
  Map<String, dynamic> getDiffSummary(DiffResult result) {
    return {
      'hasChanges': result.hasChanges,
      'totalChanges': result.totalChanges,
      'added': result.addedCount,
      'deleted': result.deletedCount,
      'modified': result.modifiedCount,
      'changePercentage': result.changePercentage,
      'chunkCount': result.chunks.length,
    };
  }
}

/// Diff引擎工厂
class DiffEngineFactory {
  /// 创建Diff引擎
  static DiffEngine create(FileType fileType, {bool ignoreWhitespace = false}) {
    return DiffEngine(
      config: DiffEngineConfig(
        fileType: fileType,
        ignoreWhitespace: ignoreWhitespace,
      ),
    );
  }
  
  /// 创建Smali Diff引擎
  static DiffEngine createSmaliEngine() {
    return create(FileType.smali);
  }
  
  /// 创建Java Diff引擎
  static DiffEngine createJavaEngine() {
    return create(FileType.java);
  }
  
  /// 创建Dex Diff引擎
  static DiffEngine createDexEngine() {
    return create(FileType.dex);
  }
}
