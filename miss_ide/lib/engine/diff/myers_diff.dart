// lib/engine/diff/myers_diff.dart - Myers Diff 算法实现
import 'dart:math';
import 'diff_result.dart';

/// Myers Diff 算法实现
/// 一种经典的最优diff算法，时间复杂度 O((N+M)D)
class MyersDiff {
  /// 计算两个字符串列表的差异
  static DiffResult compute(List<String> left, List<String> right) {
    if (left.isEmpty && right.isEmpty) {
      return DiffResult.empty();
    }
    
    if (left.isEmpty) {
      // 全部是新增
      return _createResult(_createAddLines(right), right.length, 0, right.length, 0);
    }
    
    if (right.isEmpty) {
      // 全部是删除
      return _createResult(_createDeleteLines(left), 0, left.length, 0, left.length);
    }
    
    // 使用 Myers 算法计算最短编辑脚本
    final lcs = _myersLCS(left, right);
    return _buildDiffResult(left, right, lcs);
  }
  
  /// Myers LCS 算法
  static List<_EditOperation> _myersLCS(List<String> left, List<String> right) {
    final n = left.length;
    final m = right.length;
    final max = n + m;
    
    // 存储 V 数组，key 是 k = x - y
    final v = <int, int>{1: 0};
    final trace = <Map<int, int>>[];
    
    // 存储回溯路径
    final path = <_EditOperation>[];
    
    for (int d = 0; d <= max; d++) {
      trace.add(Map<int, int>.from(v));
      
      for (int k = -d; k <= d; k += 2) {
        int x;
        
        if (k == -d || (k != d && v[k - 1]! < v[k + 1]!)) {
          x = v[k + 1]!;
        } else {
          x = v[k - 1]! + 1;
        }
        
        int y = x - k;
        
        // 对角线移动（匹配）
        while (x < n && y < m && left[x] == right[y]) {
          x++;
          y++;
        }
        
        v[k] = x;
        
        // 检查是否完成
        if (x >= n && y >= m) {
          // 回溯路径
          return _backtrack(trace, left, right, n, m);
        }
      }
    }
    
    return _backtrack(trace, left, right, n, m);
  }
  
  /// 回溯最短编辑脚本
  static List<_EditOperation> _backtrack(
    List<Map<int, int>> trace,
    List<String> left,
    List<String> right,
    int n,
    int m,
  ) {
    final operations = <_EditOperation>[];
    int x = n;
    int y = m;
    
    for (int d = trace.length - 1; d >= 0 && (x > 0 || y > 0); d--) {
      final v = trace[d];
      final k = x - y;
      
      int prevK;
      if (k == -d || (k != d && v[k - 1]! < v[k + 1]!)) {
        prevK = k + 1;
      } else {
        prevK = k - 1;
      }
      
      final prevX = v[prevK]!;
      final prevY = prevX - prevK;
      
      // 添加编辑操作
      while (x > prevX && y > prevY) {
        operations.insert(0, _EditOperation(_OperationType.equal, x - 1, y - 1));
        x--;
        y--;
      }
      
      if (d > 0) {
        if (x == prevX) {
          operations.insert(0, _EditOperation(_OperationType.insert, x, y - 1));
          y--;
        } else {
          operations.insert(0, _EditOperation(_OperationType.delete, x - 1, y));
          x--;
        }
      }
    }
    
    return operations;
  }
  
  /// 构建差异结果
  static DiffResult _buildDiffResult(
    List<String> left,
    List<String> right,
    List<_EditOperation> operations,
  ) {
    final diffLines = <DiffLine>[];
    final chunks = <DiffChunk>[];
    
    int leftLineNum = 1;
    int rightLineNum = 1;
    int leftStart = 1;
    int rightStart = 1;
    
    int addedCount = 0;
    int deletedCount = 0;
    int modifiedCount = 0;
    
    DiffChunk? currentChunk;
    final currentLines = <DiffLine>[];
    DiffType? chunkType;
    
    for (final op in operations) {
      switch (op.type) {
        case _OperationType.equal:
          // 完成当前chunk
          if (currentLines.isNotEmpty && chunkType != null) {
            chunks.add(DiffChunk(
              leftStartLine: leftStart,
              rightStartLine: rightStart,
              lines: List.from(currentLines),
              type: chunkType,
            ));
            currentLines.clear();
          }
          
          diffLines.add(DiffLine(
            leftLineNumber: leftLineNum,
            rightLineNumber: rightLineNum,
            leftContent: left[op.leftIndex],
            rightContent: right[op.rightIndex],
            type: DiffType.equal,
          ));
          leftLineNum++;
          rightLineNum++;
          leftStart = leftLineNum;
          rightStart = rightLineNum;
          break;
          
        case _OperationType.delete:
          diffLines.add(DiffLine(
            leftLineNumber: leftLineNum,
            leftContent: left[op.leftIndex],
            type: DiffType.delete,
          ));
          deletedCount++;
          leftLineNum++;
          
          if (chunkType == null) {
            chunkType = DiffType.delete;
          }
          currentLines.add(diffLines.last);
          break;
          
        case _OperationType.insert:
          diffLines.add(DiffLine(
            rightLineNumber: rightLineNum,
            rightContent: right[op.rightIndex],
            type: DiffType.add,
          ));
          addedCount++;
          rightLineNum++;
          
          if (chunkType == null) {
            chunkType = DiffType.add;
          }
          currentLines.add(diffLines.last);
          break;
      }
    }
    
    // 添加最后一个chunk
    if (currentLines.isNotEmpty && chunkType != null) {
      chunks.add(DiffChunk(
        leftStartLine: leftStart,
        rightStartLine: rightStart,
        lines: List.from(currentLines),
        type: chunkType,
      ));
    }
    
    return DiffResult(
      lines: diffLines,
      chunks: chunks,
      totalChanges: addedCount + deletedCount + modifiedCount,
      addedCount: addedCount,
      deletedCount: deletedCount,
      modifiedCount: modifiedCount,
    );
  }
  
  /// 创建全新增结果
  static DiffResult _createResult(
    List<DiffLine> lines,
    int added,
    int deleted,
    int modified,
    int total,
  ) {
    return DiffResult(
      lines: lines,
      chunks: [
        DiffChunk(
          leftStartLine: 1,
          rightStartLine: 1,
          lines: lines,
          type: lines.first.type,
        ),
      ],
      totalChanges: total,
      addedCount: added,
      deletedCount: deleted,
      modifiedCount: modified,
    );
  }
  
  /// 创建新增行
  static List<DiffLine> _createAddLines(List<String> right) {
    return List.generate(
      right.length,
      (i) => DiffLine(
        rightLineNumber: i + 1,
        rightContent: right[i],
        type: DiffType.add,
      ),
    );
  }
  
  /// 创建删除行
  static List<DiffLine> _createDeleteLines(List<String> left) {
    return List.generate(
      left.length,
      (i) => DiffLine(
        leftLineNumber: i + 1,
        leftContent: left[i],
        type: DiffType.delete,
      ),
    );
  }
}

/// 编辑操作类型
enum _OperationType {
  equal,
  insert,
  delete,
}

/// 编辑操作
class _EditOperation {
  final _OperationType type;
  final int leftIndex;
  final int rightIndex;
  
  _EditOperation(this.type, this.leftIndex, this.rightIndex);
}
