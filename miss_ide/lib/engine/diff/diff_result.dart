// lib/engine/diff/diff_result.dart - Diff结果模型
import 'package:equatable/equatable.dart';

/// 差异类型
enum DiffType {
  equal,     // 相同
  add,       // 新增
  delete,    // 删除
  modify,    // 修改
  conflict,  // 冲突
}

/// 差异行
class DiffLine extends Equatable {
  final int? leftLineNumber;
  final int? rightLineNumber;
  final String leftContent;
  final String rightContent;
  final DiffType type;
  
  const DiffLine({
    this.leftLineNumber,
    this.rightLineNumber,
    this.leftContent = '',
    this.rightContent = '',
    this.type = DiffType.equal,
  });
  
  /// 是否为空行
  bool get isEmpty => leftContent.isEmpty && rightContent.isEmpty;
  
  /// 获取显示内容
  String get displayContent {
    switch (type) {
      case DiffType.equal:
        return leftContent;
      case DiffType.add:
        return rightContent;
      case DiffType.delete:
        return leftContent;
      case DiffType.modify:
      case DiffType.conflict:
        return leftContent.isNotEmpty ? leftContent : rightContent;
    }
  }
  
  @override
  List<Object?> get props => [leftLineNumber, rightLineNumber, leftContent, rightContent, type];
}

/// 差异块
class DiffChunk extends Equatable {
  final int leftStartLine;
  final int rightStartLine;
  final List<DiffLine> lines;
  final DiffType type;
  final String? description;
  
  const DiffChunk({
    required this.leftStartLine,
    required this.rightStartLine,
    required this.lines,
    required this.type,
    this.description,
  });
  
  /// 获取差异行数
  int get leftLineCount => lines.where((l) => l.type != DiffType.add).length;
  int get rightLineCount => lines.where((l) => l.type != DiffType.delete).length;
  
  /// 是否有冲突
  bool get hasConflict => type == DiffType.conflict;
  
  /// 获取唯一标识
  String get id => '$leftStartLine-$rightStartLine';
  
  @override
  List<Object?> get props => [leftStartLine, rightStartLine, lines, type, description];
}

/// 差异结果
class DiffResult extends Equatable {
  final List<DiffLine> lines;
  final List<DiffChunk> chunks;
  final int totalChanges;
  final int addedCount;
  final int deletedCount;
  final int modifiedCount;
  
  const DiffResult({
    this.lines = const [],
    this.chunks = const [],
    this.totalChanges = 0,
    this.addedCount = 0,
    this.deletedCount = 0,
    this.modifiedCount = 0,
  });
  
  /// 创建空结果
  factory DiffResult.empty() => const DiffResult();
  
  /// 是否有差异
  bool get hasChanges => totalChanges > 0;
  
  /// 获取差异百分比
  double get changePercentage {
    if (lines.isEmpty) return 0;
    return (totalChanges / lines.length * 100).clamp(0, 100);
  }
  
  /// 获取添加的代码片段
  List<String> get addedLines {
    return lines
        .where((l) => l.type == DiffType.add)
        .map((l) => l.rightContent)
        .toList();
  }
  
  /// 获取删除的代码片段
  List<String> get deletedLines {
    return lines
        .where((l) => l.type == DiffType.delete)
        .map((l) => l.leftContent)
        .toList();
  }
  
  @override
  List<Object?> get props => [lines, chunks, totalChanges, addedCount, deletedCount, modifiedCount];
}

/// 差异导航信息
class DiffNavigation extends Equatable {
  final int currentIndex;
  final int totalDiffs;
  final List<DiffChunk> diffChunks;
  
  const DiffNavigation({
    this.currentIndex = 0,
    this.totalDiffs = 0,
    this.diffChunks = const [],
  });
  
  /// 是否有下一个差异
  bool get hasNext => currentIndex < totalDiffs - 1;
  
  /// 是否有上一个差异
  bool get hasPrevious => currentIndex > 0;
  
  /// 获取当前差异
  DiffChunk? get currentChunk {
    if (diffChunks.isEmpty || currentIndex >= diffChunks.length) return null;
    return diffChunks[currentIndex];
  }
  
  @override
  List<Object?> get props => [currentIndex, totalDiffs, diffChunks];
}
