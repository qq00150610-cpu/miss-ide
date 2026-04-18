// lib/engine/merge/three_way_merge_engine.dart - 三路合并引擎
import 'dart:async';
import 'dart:isolate';
import '../diff/myers_diff.dart';
import '../diff/diff_result.dart';

/// 三路合并的三个版本
class MergeVersion {
  /// 基础版本（共同祖先）
  final String base;
  
  /// 本地版本（当前修改）
  final String local;
  
  /// 远程版本（对方修改）
  final String remote;
  
  /// 版本标签
  final String? baseLabel;
  final String? localLabel;
  final String? remoteLabel;
  
  const MergeVersion({
    required this.base,
    required this.local,
    required this.remote,
    this.baseLabel,
    this.localLabel,
    this.remoteLabel,
  });
}

/// 合并冲突类型
enum ConflictType {
  /// 无冲突
  none,
  /// 添加冲突（两边都添加了不同的内容）
  addAdd,
  /// 删除冲突（一端删除，一端修改）
  deleteModify,
  /// 修改冲突（两边修改了同一区域）
  modifyModify,
  /// 复杂冲突
  complex,
}

/// 合并冲突信息
class MergeConflict {
  final int id;
  final int baseStart;
  final int baseEnd;
  final int localStart;
  final int localEnd;
  final int remoteStart;
  final int remoteEnd;
  final String baseContent;
  final String localContent;
  final String remoteContent;
  final ConflictType type;
  final bool resolved;
  String? resolvedContent;
  MergeResolution? resolution;
  
  MergeConflict({
    required this.id,
    required this.baseStart,
    required this.baseEnd,
    required this.localStart,
    required this.localEnd,
    required this.remoteStart,
    required this.remoteEnd,
    required this.baseContent,
    required this.localContent,
    required this.remoteContent,
    required this.type,
    this.resolved = false,
    this.resolvedContent,
    this.resolution,
  });
  
  MergeConflict copyWith({
    bool? resolved,
    String? resolvedContent,
    MergeResolution? resolution,
  }) {
    return MergeConflict(
      id: id,
      baseStart: baseStart,
      baseEnd: baseEnd,
      localStart: localStart,
      localEnd: localEnd,
      remoteStart: remoteStart,
      remoteEnd: remoteEnd,
      baseContent: baseContent,
      localContent: localContent,
      remoteContent: remoteContent,
      type: type,
      resolved: resolved ?? this.resolved,
      resolvedContent: resolvedContent ?? this.resolvedContent,
      resolution: resolution ?? this.resolution,
    );
  }
}

/// 合并解决策略
enum MergeResolution {
  /// 采用基础版本
  useBase,
  /// 采用本地版本
  useLocal,
  /// 采用远程版本
  useRemote,
  /// 手动合并
  manual,
  /// 保留所有变更（宽松合并）
  keepAll,
}

/// 合并块类型
enum MergeChunkType {
  /// 三方相同
  unchanged,
  /// 仅本地修改
  localOnly,
  /// 仅远程修改
  remoteOnly,
  /// 两边都修改（无冲突）
  bothModified,
  /// 存在冲突
  conflict,
}

/// 合并块
class MergeChunk {
  final MergeChunkType type;
  final int baseStartLine;
  final int baseEndLine;
  final int localStartLine;
  final int localEndLine;
  final int remoteStartLine;
  final int remoteEndLine;
  final String baseContent;
  final String localContent;
  final String remoteContent;
  final String? mergedContent;
  final List<MergeConflict> conflicts;
  
  const MergeChunk({
    required this.type,
    required this.baseStartLine,
    required this.baseEndLine,
    required this.localStartLine,
    required this.localEndLine,
    required this.remoteStartLine,
    required this.remoteEndLine,
    required this.baseContent,
    required this.localContent,
    required this.remoteContent,
    this.mergedContent,
    this.conflicts = const [],
  });
}

/// 三路合并结果
class ThreeWayMergeResult {
  final bool hasConflicts;
  final List<MergeChunk> chunks;
  final List<MergeConflict> allConflicts;
  final String mergedContent;
  final int baseLineCount;
  final int localLineCount;
  final int remoteLineCount;
  final int unchangedLines;
  final int modifiedLines;
  
  const ThreeWayMergeResult({
    required this.hasConflicts,
    required this.chunks,
    required this.allConflicts,
    required this.mergedContent,
    required this.baseLineCount,
    required this.localLineCount,
    required this.remoteLineCount,
    required this.unchangedLines,
    required this.modifiedLines,
  });
  
  int get unresolvedConflictCount => 
      allConflicts.where((c) => !c.resolved).length;
  
  int get resolvedConflictCount => 
      allConflicts.where((c) => c.resolved).length;
}

/// 三路合并引擎
class ThreeWayMergeEngine {
  /// 执行三路合并
  static Future<ThreeWayMergeResult> merge(MergeVersion version) async {
    return Isolate.run(() => _performMerge(version));
  }
  
  /// 同步执行三路合并
  static ThreeWayMergeResult mergeSync(MergeVersion version) {
    return _performMerge(version);
  }
  
  static ThreeWayMergeResult _performMerge(MergeVersion version) {
    final baseLines = version.base.split('\n');
    final localLines = version.local.split('\n');
    final remoteLines = version.remote.split('\n');
    
    // 第一步：分别计算 local 相对于 base 的差异
    final localDiff = MyersDiff.compute(baseLines, localLines);
    
    // 第二步：分别计算 remote 相对于 base 的差异
    final remoteDiff = MyersDiff.compute(baseLines, remoteLines);
    
    // 第三步：分析差异重叠区域，检测冲突
    final conflicts = <MergeConflict>[];
    final chunks = <MergeChunk>[];
    
    int baseIdx = 0;
    int localIdx = 0;
    int remoteIdx = 0;
    int conflictId = 0;
    
    // 构建差异范围映射
    final localRanges = _buildDiffRanges(localDiff);
    final remoteRanges = _buildDiffRanges(remoteDiff);
    
    // 遍历所有差异区域
    final allRanges = [...localRanges, ...remoteRanges];
    allRanges.sort((a, b) => a.start.compareTo(b.start));
    
    int processedBaseIdx = 0;
    
    for (final range in allRanges) {
      // 处理未修改的区域（相同部分）
      if (processedBaseIdx < range.start) {
        final unchangedContent = baseLines
            .sublist(processedBaseIdx, range.start)
            .join('\n');
        
        chunks.add(MergeChunk(
          type: MergeChunkType.unchanged,
          baseStartLine: processedBaseIdx + 1,
          baseEndLine: range.start,
          localStartLine: _findLocalLine(localDiff, processedBaseIdx) + 1,
          localEndLine: _findLocalLine(localDiff, range.start - 1) + 1,
          remoteStartLine: _findRemoteLine(remoteDiff, processedBaseIdx) + 1,
          remoteEndLine: _findRemoteLine(remoteDiff, range.start - 1) + 1,
          baseContent: unchangedContent,
          localContent: unchangedContent,
          remoteContent: unchangedContent,
          mergedContent: unchangedContent,
        ));
      }
      
      // 检查是否有重叠的修改
      final localMod = localRanges.firstWhere(
        (r) => r.overlaps(range),
        orElse: () => DiffRange.empty(),
      );
      final remoteMod = remoteRanges.firstWhere(
        (r) => r.overlaps(range),
        orElse: () => DiffRange.empty(),
      );
      
      if (localMod.isNotEmpty && remoteMod.isNotEmpty) {
        // 存在修改重叠，可能有冲突
        final localContent = _getContentInRange(localLines, localMod);
        final remoteContent = _getContentInRange(remoteLines, remoteMod);
        final baseContent = _getContentInRange(baseLines, range);
        
        // 检查是否为真正的冲突
        if (localContent == remoteContent) {
          // 两边修改相同，无冲突
          chunks.add(MergeChunk(
            type: MergeChunkType.bothModified,
            baseStartLine: range.start + 1,
            baseEndLine: range.end + 1,
            localStartLine: localMod.start + 1,
            localEndLine: localMod.end + 1,
            remoteStartLine: remoteMod.start + 1,
            remoteEndLine: remoteMod.end + 1,
            baseContent: baseContent,
            localContent: localContent,
            remoteContent: remoteContent,
            mergedContent: localContent,
          ));
        } else {
          // 存在冲突
          final conflict = MergeConflict(
            id: conflictId++,
            baseStart: range.start,
            baseEnd: range.end,
            localStart: localMod.start,
            localEnd: localMod.end,
            remoteStart: remoteMod.start,
            remoteEnd: remoteMod.end,
            baseContent: baseContent,
            localContent: localContent,
            remoteContent: remoteContent,
            type: ConflictType.modifyModify,
          );
          conflicts.add(conflict);
          
          chunks.add(MergeChunk(
            type: MergeChunkType.conflict,
            baseStartLine: range.start + 1,
            baseEndLine: range.end + 1,
            localStartLine: localMod.start + 1,
            localEndLine: localMod.end + 1,
            remoteStartLine: remoteMod.start + 1,
            remoteEndLine: remoteMod.end + 1,
            baseContent: baseContent,
            localContent: localContent,
            remoteContent: remoteContent,
            conflicts: [conflict],
          ));
        }
      } else if (localMod.isNotEmpty) {
        // 仅本地修改
        final localContent = _getContentInRange(localLines, localMod);
        final baseContent = _getContentInRange(baseLines, range);
        
        chunks.add(MergeChunk(
          type: MergeChunkType.localOnly,
          baseStartLine: range.start + 1,
          baseEndLine: range.end + 1,
          localStartLine: localMod.start + 1,
          localEndLine: localMod.end + 1,
          remoteStartLine: range.start + 1,
          remoteEndLine: range.end + 1,
          baseContent: baseContent,
          localContent: localContent,
          remoteContent: baseContent,
          mergedContent: localContent,
        ));
      } else if (remoteMod.isNotEmpty) {
        // 仅远程修改
        final remoteContent = _getContentInRange(remoteLines, remoteMod);
        final baseContent = _getContentInRange(baseLines, range);
        
        chunks.add(MergeChunk(
          type: MergeChunkType.remoteOnly,
          baseStartLine: range.start + 1,
          baseEndLine: range.end + 1,
          localStartLine: range.start + 1,
          localEndLine: range.end + 1,
          remoteStartLine: remoteMod.start + 1,
          remoteEndLine: remoteMod.end + 1,
          baseContent: baseContent,
          localContent: baseContent,
          remoteContent: remoteContent,
          mergedContent: remoteContent,
        ));
      }
      
      processedBaseIdx = range.end + 1;
    }
    
    // 处理剩余的未修改内容
    if (processedBaseIdx < baseLines.length) {
      final unchangedContent = baseLines.sublist(processedBaseIdx).join('\n');
      chunks.add(MergeChunk(
        type: MergeChunkType.unchanged,
        baseStartLine: processedBaseIdx + 1,
        baseEndLine: baseLines.length,
        localStartLine: _findLocalLine(localDiff, processedBaseIdx) + 1,
        localEndLine: localLines.length,
        remoteStartLine: _findRemoteLine(remoteDiff, processedBaseIdx) + 1,
        remoteEndLine: remoteLines.length,
        baseContent: unchangedContent,
        localContent: unchangedContent,
        remoteContent: unchangedContent,
        mergedContent: unchangedContent,
      ));
    }
    
    // 生成合并结果
    final mergedContent = _generateMergedContent(chunks);
    
    // 统计
    int unchangedLines = 0;
    int modifiedLines = 0;
    for (final chunk in chunks) {
      final lineCount = chunk.mergedContent.split('\n').length;
      if (chunk.type == MergeChunkType.unchanged) {
        unchangedLines += lineCount;
      } else {
        modifiedLines += lineCount;
      }
    }
    
    return ThreeWayMergeResult(
      hasConflicts: conflicts.isNotEmpty,
      chunks: chunks,
      allConflicts: conflicts,
      mergedContent: mergedContent,
      baseLineCount: baseLines.length,
      localLineCount: localLines.length,
      remoteLineCount: remoteLines.length,
      unchangedLines: unchangedLines,
      modifiedLines: modifiedLines,
    );
  }
  
  /// 构建差异范围列表
  static List<DiffRange> _buildDiffRanges(DiffResult diff) {
    final ranges = <DiffRange>[];
    
    for (final chunk in diff.chunks) {
      if (chunk.type == DiffType.add || chunk.type == DiffType.modify) {
        ranges.add(DiffRange(
          start: chunk.rightStartLine - 1,
          end: chunk.rightStartLine + chunk.rightLines.length - 1,
        ));
      }
    }
    
    return ranges;
  }
  
  /// 获取范围内的内容
  static String _getContentInRange(List<String> lines, DiffRange range) {
    if (range.isEmpty) return '';
    final end = range.end.clamp(0, lines.length - 1);
    final start = range.start.clamp(0, end);
    return lines.sublist(start, end + 1).join('\n');
  }
  
  /// 查找本地版本对应的行
  static int _findLocalLine(DiffResult diff, int baseLine) {
    int offset = 0;
    for (final chunk in diff.chunks) {
      if (chunk.rightStartLine - 1 >= baseLine) {
        return baseLine + offset;
      }
      offset += chunk.rightLines.length - chunk.leftLines.length;
    }
    return baseLine + offset;
  }
  
  /// 查找远程版本对应的行
  static int _findRemoteLine(DiffResult diff, int baseLine) {
    return _findLocalLine(diff, baseLine);
  }
  
  /// 生成合并后的内容
  static String _generateMergedContent(List<MergeChunk> chunks) {
    final buffer = StringBuffer();
    
    for (final chunk in chunks) {
      if (chunk.type == MergeChunkType.conflict) {
        // 对于未解决的冲突，保留冲突标记
        buffer.writeln('<<<<<<< LOCAL');
        buffer.write(chunk.localContent);
        buffer.writeln('=======');
        buffer.write(chunk.remoteContent);
        buffer.writeln('>>>>>>> REMOTE');
      } else if (chunk.mergedContent != null) {
        buffer.writeln(chunk.mergedContent);
      }
    }
    
    return buffer.toString().trimRight();
  }
  
  /// 自动解决冲突（基于策略）
  static ThreeWayMergeResult resolveConflicts(
    ThreeWayMergeResult result,
    MergeResolution resolution,
  ) {
    if (!result.hasConflicts) return result;
    
    final newChunks = <MergeChunk>[];
    String mergedContent = '';
    
    for (final chunk in result.chunks) {
      if (chunk.type != MergeChunkType.conflict) {
        newChunks.add(chunk);
        mergedContent += chunk.mergedContent ?? '';
        mergedContent += '\n';
        continue;
      }
      
      final conflict = chunk.conflicts.first;
      String resolvedContent;
      
      switch (resolution) {
        case MergeResolution.useLocal:
          resolvedContent = conflict.localContent;
          break;
        case MergeResolution.useRemote:
          resolvedContent = conflict.remoteContent;
          break;
        case MergeResolution.useBase:
          resolvedContent = conflict.baseContent;
          break;
        case MergeResolution.keepAll:
          resolvedContent = '${conflict.localContent}\n${conflict.remoteContent}';
          break;
        case MergeResolution.manual:
          // 保持冲突标记
          mergedContent += '<<<<<<< LOCAL\n';
          mergedContent += conflict.localContent;
          mergedContent += '\n=======\n';
          mergedContent += conflict.remoteContent;
          mergedContent += '\n>>>>>>> REMOTE\n';
          continue;
      }
      
      final resolvedConflict = conflict.copyWith(
        resolved: true,
        resolvedContent: resolvedContent,
        resolution: resolution,
      );
      
      newChunks.add(MergeChunk(
        type: MergeChunkType.bothModified,
        baseStartLine: chunk.baseStartLine,
        baseEndLine: chunk.baseEndLine,
        localStartLine: chunk.localStartLine,
        localEndLine: chunk.localEndLine,
        remoteStartLine: chunk.remoteStartLine,
        remoteEndLine: chunk.remoteEndLine,
        baseContent: chunk.baseContent,
        localContent: chunk.localContent,
        remoteContent: chunk.remoteContent,
        mergedContent: resolvedContent,
        conflicts: [resolvedConflict],
      ));
      
      mergedContent += resolvedContent;
      mergedContent += '\n';
    }
    
    final newConflicts = result.allConflicts.map((c) {
      if (!c.resolved) {
        return c.copyWith(
          resolved: true,
          resolvedContent: resolution == MergeResolution.useLocal
              ? c.localContent
              : resolution == MergeResolution.useRemote
                  ? c.remoteContent
                  : c.baseContent,
          resolution: resolution,
        );
      }
      return c;
    }).toList();
    
    return ThreeWayMergeResult(
      hasConflicts: newConflicts.any((c) => !c.resolved),
      chunks: newChunks,
      allConflicts: newConflicts,
      mergedContent: mergedContent.trimRight(),
      baseLineCount: result.baseLineCount,
      localLineCount: result.localLineCount,
      remoteLineCount: result.remoteLineCount,
      unchangedLines: result.unchangedLines,
      modifiedLines: result.modifiedLines,
    );
  }
}

/// 差异范围
class DiffRange {
  final int start;
  final int end;
  
  const DiffRange({required this.start, required this.end});
  
  factory DiffRange.empty() => const DiffRange(start: 0, end: -1);
  
  bool get isEmpty => start > end;
  
  bool overlaps(DiffRange other) {
    return start <= other.end && end >= other.start;
  }
}
