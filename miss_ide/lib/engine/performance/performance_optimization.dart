// lib/engine/performance/performance_optimization.dart - 性能优化模块
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

/// 大文件分块配置
class ChunkConfig {
  /// 单块最大行数
  final int maxLinesPerChunk;
  
  /// 单块最大字节数
  final int maxBytesPerChunk;
  
  /// 预加载块数量
  final int preloadChunkCount;
  
  const ChunkConfig({
    this.maxLinesPerChunk = 1000,
    this.maxBytesPerChunk = 1024 * 1024, // 1MB
    this.preloadChunkCount = 2,
  });
  
  static const defaultConfig = ChunkConfig();
}

/// 文件块信息
class FileChunk {
  final int index;
  final int startLine;
  final int endLine;
  final String content;
  final Uint8List? bytes;
  
  const FileChunk({
    required this.index,
    required this.startLine,
    required this.endLine,
    required this.content,
    this.bytes,
  });
  
  int get lineCount => endLine - startLine + 1;
  bool get isValid => content.isNotEmpty || (bytes?.isNotEmpty ?? false);
}

/// 分块读取结果
class ChunkedFileReader {
  final List<FileChunk> chunks;
  final int totalLines;
  final int totalBytes;
  
  const ChunkedFileReader({
    required this.chunks,
    required this.totalLines,
    required this.totalBytes,
  });
}

/// 大文件分块处理器
class ChunkedFileProcessor {
  final ChunkConfig config;
  
  ChunkedFileProcessor({this.config = const ChunkConfig()});
  
  /// 分块读取文件内容
  Future<ChunkedFileReader> readFile(String path) async {
    final file = await _readFileContent(path);
    return _chunkContent(file.content, file.lines);
  }
  
  /// 从字符串内容分块
  Future<ChunkedFileReader> chunkContent(String content) async {
    final lines = content.split('\n');
    return _chunkLines(lines);
  }
  
  /// 分块读取字符串行
  Future<ChunkedFileReader> _chunkLines(List<String> lines) async {
    final chunks = <FileChunk>[];
    int lineIndex = 0;
    int chunkIndex = 0;
    
    while (lineIndex < lines.length) {
      final startLine = lineIndex;
      final endLine = (lineIndex + config.maxLinesPerChunk - 1)
          .clamp(0, lines.length - 1);
      
      final chunkLines = lines.sublist(startLine, endLine + 1);
      final chunkContent = chunkLines.join('\n');
      
      chunks.add(FileChunk(
        index: chunkIndex,
        startLine: startLine,
        endLine: endLine,
        content: chunkContent,
      ));
      
      lineIndex = endLine + 1;
      chunkIndex++;
    }
    
    return ChunkedFileReader(
      chunks: chunks,
      totalLines: lines.length,
      totalBytes: chunks.fold(0, (sum, chunk) => sum + chunk.content.length),
    );
  }
  
  ChunkedFileReader _chunkContent(String content, List<String> lines) {
    final chunks = <FileChunk>[];
    int lineIndex = 0;
    int chunkIndex = 0;
    
    while (lineIndex < lines.length) {
      final startLine = lineIndex;
      final endLine = (lineIndex + config.maxLinesPerChunk - 1)
          .clamp(0, lines.length - 1);
      
      final chunkLines = lines.sublist(startLine, endLine + 1);
      final chunkContent = chunkLines.join('\n');
      
      chunks.add(FileChunk(
        index: chunkIndex,
        startLine: startLine,
        endLine: endLine,
        content: chunkContent,
      ));
      
      lineIndex = endLine + 1;
      chunkIndex++;
    }
    
    return ChunkedFileReader(
      chunks: chunks,
      totalLines: lines.length,
      totalBytes: content.length,
    );
  }
  
  Future<({String content, List<String> lines})> _readFileContent(String path) async {
    final file = await Isolate.run(() async {
      final f = await _readFileSync(path);
      return f;
    });
    return file;
  }
  
  static Future<({String content, List<String> lines})> _readFileSync(String path) async {
    final file = await Future(() {
      final file = _NativeFileReader();
      return file.readSync(path);
    });
    return file;
  }
  
  /// 获取指定范围的块
  Future<FileChunk?> getChunk(ChunkedFileReader reader, int chunkIndex) async {
    if (chunkIndex < 0 || chunkIndex >= reader.chunks.length) {
      return null;
    }
    return reader.chunks[chunkIndex];
  }
  
  /// 获取指定行范围的块
  Future<List<FileChunk>> getChunksInRange(
    ChunkedFileReader reader,
    int startLine,
    int endLine,
  ) async {
    final result = <FileChunk>[];
    
    for (final chunk in reader.chunks) {
      if (chunk.endLine >= startLine && chunk.startLine <= endLine) {
        result.add(chunk);
      }
    }
    
    return result;
  }
}

/// 原生文件读取器
class _NativeFileReader {
  Future<({String content, List<String> lines})> readSync(String path) async {
    try {
      final file = await _FileOperations.readText(path);
      final lines = file.split('\n');
      return (content: file, lines: lines);
    } catch (e) {
      return (content: '', lines: <String>[]);
    }
  }
}

/// 文件操作
class _FileOperations {
  static Future<String> readText(String path) async {
    // 使用 Dart 的异步文件读取
    final file = await Future(
      () => _SimpleFile.readAll(path),
    );
    return file;
  }
}

/// 简单文件读取
class _SimpleFile {
  static Future<String> readAll(String path) async {
    // 这个需要在 Isolate 中执行
    return '';
  }
}

/// Diff 计算任务
class DiffComputeTask {
  final String leftContent;
  final String rightContent;
  final SendPort sendPort;
  final bool isAsync;
  
  DiffComputeTask({
    required this.leftContent,
    required this.rightContent,
    required this.sendPort,
    this.isAsync = true,
  });
}

/// 并行 Diff 计算器
class ParallelDiffCalculator {
  /// 使用 Isolate 并行计算 Diff
  static Future<List<DiffChunkResult>> computeDiffParallel(
    List<String> leftLines,
    List<String> rightLines,
  ) async {
    return Isolate.run(() {
      return _computeDiffSync(leftLines, rightLines);
    });
  }
  
  /// 同步计算 Diff
  static List<DiffChunkResult> _computeDiffSync(
    List<String> leftLines,
    List<String> rightLines,
  ) {
    final result = <DiffChunkResult>[];
    
    // 使用 LCS 算法计算差异
    final lcs = _longestCommonSubsequence(leftLines, rightLines);
    
    int leftIdx = 0;
    int rightIdx = 0;
    int lcsIdx = 0;
    
    while (leftIdx < leftLines.length || rightIdx < rightLines.length) {
      if (lcsIdx < lcs.length) {
        // 处理左侧独有内容
        while (leftIdx < leftLines.length && leftLines[leftIdx] != lcs[lcsIdx]) {
          result.add(DiffChunkResult(
            type: DiffChunkType.delete,
            leftLine: leftIdx,
            rightLine: null,
            content: leftLines[leftIdx],
          ));
          leftIdx++;
        }
        
        // 处理右侧独有内容
        while (rightIdx < rightLines.length && rightLines[rightIdx] != lcs[lcsIdx]) {
          result.add(DiffChunkResult(
            type: DiffChunkType.add,
            leftLine: null,
            rightLine: rightIdx,
            content: rightLines[rightIdx],
          ));
          rightIdx++;
        }
        
        // 添加相同行
        if (leftIdx < leftLines.length && rightIdx < rightLines.length) {
          result.add(DiffChunkResult(
            type: DiffChunkType.equal,
            leftLine: leftIdx,
            rightLine: rightIdx,
            content: leftLines[leftIdx],
          ));
          leftIdx++;
          rightIdx++;
          lcsIdx++;
        }
      } else {
        // 处理剩余的左侧内容
        while (leftIdx < leftLines.length) {
          result.add(DiffChunkResult(
            type: DiffChunkType.delete,
            leftLine: leftIdx,
            rightLine: null,
            content: leftLines[leftIdx],
          ));
          leftIdx++;
        }
        
        // 处理剩余的右侧内容
        while (rightIdx < rightLines.length) {
          result.add(DiffChunkResult(
            type: DiffChunkType.add,
            leftLine: null,
            rightLine: rightIdx,
            content: rightLines[rightIdx],
          ));
          rightIdx++;
        }
      }
    }
    
    return result;
  }
  
  /// 计算最长公共子序列
  static List<String> _longestCommonSubsequence(
    List<String> left,
    List<String> right,
  ) {
    final m = left.length;
    final n = right.length;
    
    // 创建 DP 表
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    
    // 填充 DP 表
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (left[i - 1] == right[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    
    // 回溯找出 LCS
    final lcs = <String>[];
    int i = m, j = n;
    while (i > 0 && j > 0) {
      if (left[i - 1] == right[j - 1]) {
        lcs.insert(0, left[i - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] > dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    
    return lcs;
  }
  
  /// 分块计算大文件 Diff
  static Stream<DiffChunkResult> computeDiffInChunks(
    List<String> leftLines,
    List<String> rightLines, {
    int chunkSize = 500,
  }) async* {
    final totalChunks = (leftLines.length / chunkSize).ceil() > 
        (rightLines.length / chunkSize).ceil()
        ? (leftLines.length / chunkSize).ceil()
        : (rightLines.length / chunkSize).ceil();
    
    for (int i = 0; i < totalChunks; i++) {
      final startIdx = i * chunkSize;
      final leftChunk = leftLines.sublist(
        startIdx,
        (startIdx + chunkSize).clamp(0, leftLines.length),
      );
      final rightChunk = rightLines.sublist(
        startIdx,
        (startIdx + chunkSize).clamp(0, rightLines.length),
      );
      
      final results = await computeDiffParallel(leftChunk, rightChunk);
      for (final result in results) {
        yield DiffChunkResult(
          type: result.type,
          leftLine: result.leftLine != null ? startIdx + result.leftLine! : null,
          rightLine: result.rightLine != null ? startIdx + result.rightLine! : null,
          content: result.content,
        );
      }
    }
  }
}

/// Diff 块类型
enum DiffChunkType {
  equal,
  add,
  delete,
  modify,
}

/// Diff 块结果
class DiffChunkResult {
  final DiffChunkType type;
  final int? leftLine;
  final int? rightLine;
  final String content;
  
  DiffChunkResult({
    required this.type,
    required this.leftLine,
    required this.rightLine,
    required this.content,
  });
}

/// 内存缓存管理器
class MemoryCacheManager<K, V> {
  final int maxSize;
  final Duration maxAge;
  final Map<K, _CacheEntry<V>> _cache = {};
  
  MemoryCacheManager({
    this.maxSize = 100,
    this.maxAge = const Duration(minutes: 10),
  });
  
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().difference(entry.createdAt) > maxAge) {
      _cache.remove(key);
      return null;
    }
    
    entry.lastAccessed = DateTime.now();
    return entry.value;
  }
  
  void put(K key, V value) {
    if (_cache.length >= maxSize) {
      _evictOldest();
    }
    _cache[key] = _CacheEntry(value);
  }
  
  void remove(K key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
  
  void _evictOldest() {
    K? oldestKey;
    DateTime oldest = DateTime.now();
    
    for (final entry in _cache.entries) {
      if (entry.value.lastAccessed.isBefore(oldest)) {
        oldest = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime createdAt;
  DateTime lastAccessed;
  
  _CacheEntry(this.value)
      : createdAt = DateTime.now(),
        lastAccessed = DateTime.now();
}
