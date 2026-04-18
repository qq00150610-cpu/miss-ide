// lib/engine/diff/merge_engine.dart - 合并引擎
import 'diff_result.dart';
import 'diff_engine.dart';

/// 合并冲突
class MergeConflict {
  final int leftStartLine;
  final int rightStartLine;
  final List<String> baseContent;
  final List<String> leftContent;
  final List<String> rightContent;
  final bool resolved;
  final List<String>? resolvedContent;
  
  const MergeConflict({
    required this.leftStartLine,
    required this.rightStartLine,
    required this.baseContent,
    required this.leftContent,
    required this.rightContent,
    this.resolved = false,
    this.resolvedContent,
  });
  
  MergeConflict copyWith({
    int? leftStartLine,
    int? rightStartLine,
    List<String>? baseContent,
    List<String>? leftContent,
    List<String>? rightContent,
    bool? resolved,
    List<String>? resolvedContent,
  }) {
    return MergeConflict(
      leftStartLine: leftStartLine ?? this.leftStartLine,
      rightStartLine: rightStartLine ?? this.rightStartLine,
      baseContent: baseContent ?? this.baseContent,
      leftContent: leftContent ?? this.leftContent,
      rightContent: rightContent ?? this.rightContent,
      resolved: resolved ?? this.resolved,
      resolvedContent: resolvedContent ?? this.resolvedContent,
    );
  }
}

/// 合并结果
class MergeResult extends Equatable {
  final List<String> mergedContent;
  final List<MergeConflict> conflicts;
  final bool hasConflicts;
  final bool isFullyResolved;
  
  const MergeResult({
    required this.mergedContent,
    this.conflicts = const [],
    this.hasConflicts = false,
    this.isFullyResolved = false,
  });
  
  factory MergeResult.empty() {
    return const MergeResult(
      mergedContent: [],
      conflicts: [],
      hasConflicts: false,
      isFullyResolved: true,
    );
  }
  
  @override
  List<Object?> get props => [mergedContent, conflicts, hasConflicts, isFullyResolved];
}

/// 合并策略
enum MergeStrategy {
  useLeft,      // 使用左侧版本
  useRight,     // 使用右侧版本
  useBoth,      // 同时保留两侧
  manual,       // 手动合并
}

/// 合并引擎
class MergeEngine {
  final DiffEngine _diffEngine;
  
  MergeEngine({DiffEngine? diffEngine})
      : _diffEngine = diffEngine ?? DiffEngine();
  
  /// 三路合并
  MergeResult threeWayMerge({
    required String base,
    required String left,
    required String right,
  }) {
    final baseLines = base.split('\n');
    final leftLines = left.split('\n');
    final rightLines = right.split('\n');
    
    // 计算两侧与基础的差异
    final leftDiff = MyersDiff.compute(baseLines, leftLines);
    final rightDiff = MyersDiff.compute(baseLines, rightLines);
    
    final conflicts = <MergeConflict>[];
    final mergedLines = <String>[];
    int lineIndex = 0;
    
    // 简化版本：逐行处理
    final maxLen = [baseLines.length, leftLines.length, rightLines.length].reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < maxLen; i++) {
      final baseLine = i < baseLines.length ? baseLines[i] : '';
      final leftLine = i < leftLines.length ? leftLines[i] : '';
      final rightLine = i < rightLines.length ? rightLines[i] : '';
      
      if (leftLine == rightLine) {
        // 两侧相同，直接使用
        mergedLines.add(leftLine);
      } else if (leftLine == baseLine) {
        // 左侧未变，使用右侧
        mergedLines.add(rightLine);
      } else if (rightLine == baseLine) {
        // 右侧未变，使用左侧
        mergedLines.add(leftLine);
      } else {
        // 冲突
        conflicts.add(MergeConflict(
          leftStartLine: i + 1,
          rightStartLine: i + 1,
          baseContent: [baseLine],
          leftContent: [leftLine],
          rightContent: [rightLine],
        ));
        
        // 默认使用左侧解决冲突（可通过策略调整）
        mergedLines.add(leftLine);
      }
    }
    
    return MergeResult(
      mergedContent: mergedLines,
      conflicts: conflicts,
      hasConflicts: conflicts.isNotEmpty,
      isFullyResolved: conflicts.isEmpty,
    );
  }
  
  /// 解决冲突
  MergeConflict resolveConflict(
    MergeConflict conflict,
    MergeStrategy strategy, {
    List<String>? manualContent,
  }) {
    switch (strategy) {
      case MergeStrategy.useLeft:
        return conflict.copyWith(
          resolved: true,
          resolvedContent: conflict.leftContent,
        );
      case MergeStrategy.useRight:
        return conflict.copyWith(
          resolved: true,
          resolvedContent: conflict.rightContent,
        );
      case MergeStrategy.useBoth:
        return conflict.copyWith(
          resolved: true,
          resolvedContent: [...conflict.leftContent, ...conflict.rightContent],
        );
      case MergeStrategy.manual:
        return conflict.copyWith(
          resolved: manualContent != null,
          resolvedContent: manualContent,
        );
    }
  }
  
  /// 应用合并结果
  String applyMergedContent(MergeResult result) {
    return result.mergedContent.join('\n');
  }
  
  /// 检查是否所有冲突都已解决
  bool checkAllResolved(MergeResult result) {
    return result.conflicts.every((c) => c.resolved);
  }
}
