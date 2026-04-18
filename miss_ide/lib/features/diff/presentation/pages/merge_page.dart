// lib/features/diff/presentation/pages/merge_page.dart - 三路合并页面
import 'package:flutter/material.dart';
import '../../../engine/merge/three_way_merge_engine.dart';
import 'widgets/conflict_resolver_widget.dart';

/// 三路合并页面
class MergePage extends StatefulWidget {
  final String basePath;
  final String localPath;
  final String remotePath;
  final String? baseContent;
  final String? localContent;
  final String? remoteContent;
  
  const MergePage({
    super.key,
    required this.basePath,
    required this.localPath,
    required this.remotePath,
    this.baseContent,
    this.localContent,
    this.remoteContent,
  });
  
  @override
  State<MergePage> createState() => _MergePageState();
}

class _MergePageState extends State<MergePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  ThreeWayMergeResult? _mergeResult;
  int _currentConflictIndex = 0;
  bool _isLoading = true;
  String? _error;
  
  // 合并结果（用户编辑后）
  String? _editedContent;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startMerge();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _startMerge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final version = MergeVersion(
        base: widget.baseContent ?? '',
        local: widget.localContent ?? '',
        remote: widget.remoteContent ?? '',
        baseLabel: widget.basePath.split('/').last,
        localLabel: widget.localPath.split('/').last,
        remoteLabel: widget.remotePath.split('/').last,
      );
      
      final result = await ThreeWayMergeEngine.merge(version);
      
      setState(() {
        _mergeResult = result;
        _editedContent = result.mergedContent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _resolveConflict(int conflictIndex, MergeResolution resolution) {
    if (_mergeResult == null) return;
    
    final resolvedResult = ThreeWayMergeEngine.resolveConflicts(
      _mergeResult!,
      resolution,
    );
    
    setState(() {
      _mergeResult = resolvedResult;
      _editedContent = resolvedResult.mergedContent;
      
      // 移动到下一个未解决的冲突
      final unresolved = resolvedResult.allConflicts
          .asMap()
          .entries
          .where((e) => !e.value.resolved)
          .map((e) => e.key)
          .toList();
      
      if (unresolved.isNotEmpty) {
        _currentConflictIndex = unresolved.first;
      } else {
        _currentConflictIndex = 0;
      }
    });
  }
  
  void _resolveConflictManually(int conflictIndex, String content) {
    if (_mergeResult == null) return;
    
    // 手动编辑解决
    final conflicts = List<MergeConflict>.from(_mergeResult!.allConflicts);
    final conflict = conflicts[conflictIndex];
    
    conflicts[conflictIndex] = conflict.copyWith(
      resolved: true,
      resolvedContent: content,
      resolution: MergeResolution.manual,
    );
    
    // 重新构建合并结果
    final resolvedResult = ThreeWayMergeResult(
      hasConflicts: conflicts.any((c) => !c.resolved),
      chunks: _buildMergedChunks(conflicts),
      allConflicts: conflicts,
      mergedContent: _editedContent ?? '',
      baseLineCount: _mergeResult!.baseLineCount,
      localLineCount: _mergeResult!.localLineCount,
      remoteLineCount: _mergeResult!.remoteLineCount,
      unchangedLines: _mergeResult!.unchangedLines,
      modifiedLines: _mergeResult!.modifiedLines,
    );
    
    setState(() {
      _mergeResult = resolvedResult;
    });
  }
  
  List<MergeChunk> _buildMergedChunks(List<MergeConflict> conflicts) {
    if (_mergeResult == null) return [];
    
    return _mergeResult!.chunks.map((chunk) {
      if (chunk.type == MergeChunkType.conflict) {
        final conflict = conflicts.firstWhere(
          (c) => c.id == chunk.conflicts.first.id,
          orElse: () => chunk.conflicts.first,
        );
        
        return MergeChunk(
          type: conflict.resolved 
              ? MergeChunkType.bothModified 
              : MergeChunkType.conflict,
          baseStartLine: chunk.baseStartLine,
          baseEndLine: chunk.baseEndLine,
          localStartLine: chunk.localStartLine,
          localEndLine: chunk.localEndLine,
          remoteStartLine: chunk.remoteStartLine,
          remoteEndLine: chunk.remoteEndLine,
          baseContent: chunk.baseContent,
          localContent: chunk.localContent,
          remoteContent: chunk.remoteContent,
          mergedContent: conflict.resolvedContent ?? chunk.mergedContent,
          conflicts: [conflict],
        );
      }
      return chunk;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('三路合并'),
        actions: [
          if (_mergeResult != null) ...[
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '全部采用本地',
              onPressed: () => _resolveAllWithLocal(),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存结果',
              onPressed: _saveResult,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '冲突列表'),
            Tab(text: '逐个解决'),
            Tab(text: '预览'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在分析差异...'),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('合并失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startMerge,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildConflictListTab(),
        _buildConflictResolverTab(),
        _buildPreviewTab(),
      ],
    );
  }
  
  Widget _buildConflictListTab() {
    final result = _mergeResult!;
    final unresolvedConflicts = result.allConflicts
        .asMap()
        .entries
        .where((e) => !e.value.resolved)
        .map((e) => e.key)
        .toList();
    
    return Column(
      children: [
        // 统计信息
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                '总冲突',
                result.allConflicts.length.toString(),
                Colors.orange,
              ),
              _buildStatChip(
                '未解决',
                unresolvedConflicts.length.toString(),
                Colors.red,
              ),
              _buildStatChip(
                '已解决',
                result.resolvedConflictCount.toString(),
                Colors.green,
              ),
            ],
          ),
        ),
        
        // 冲突列表
        Expanded(
          child: ConflictListWidget(
            conflicts: result.allConflicts,
            currentIndex: _currentConflictIndex,
            onSelectConflict: (index) {
              setState(() {
                _currentConflictIndex = index;
                _tabController.animateTo(1);
              });
            },
            onResolveConflict: (index, resolution) {
              _resolveConflict(index, resolution);
            },
            onManualResolve: (index, content) {
              _resolveConflictManually(index, content);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
  
  Widget _buildConflictResolverTab() {
    final result = _mergeResult!;
    final unresolved = result.allConflicts
        .asMap()
        .entries
        .where((e) => !e.value.resolved)
        .toList();
    
    if (unresolved.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('所有冲突已解决！'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('查看预览'),
            ),
          ],
        ),
      );
    }
    
    if (_currentConflictIndex >= unresolved.length) {
      _currentConflictIndex = 0;
    }
    
    final currentEntry = unresolved[_currentConflictIndex];
    final conflict = currentEntry.value;
    
    return Column(
      children: [
        // 导航栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentConflictIndex > 0
                    ? () => setState(() => _currentConflictIndex--)
                    : null,
              ),
              Expanded(
                child: Text(
                  '冲突 ${currentEntry.key + 1} / ${unresolved.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentConflictIndex < unresolved.length - 1
                    ? () => setState(() => _currentConflictIndex++)
                    : null,
              ),
            ],
          ),
        ),
        
        // 冲突解决面板
        Expanded(
          child: ConflictResolverWidget(
            key: ValueKey(conflict.id),
            conflict: conflict,
            onResolve: (resolution) {
              _resolveConflict(currentEntry.key, resolution);
            },
            onManualResolve: (content) {
              _resolveConflictManually(currentEntry.key, content);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreviewTab() {
    final result = _mergeResult!;
    
    return Column(
      children: [
        // 统计和预览
        MergeResultPreview(
          result: result,
          scrollController: ScrollController(),
        ),
        
        // 编辑器预览
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '合并结果预览',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_mergeResult!.hasConflicts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '仍有冲突未解决',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '合并完成',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _editedContent ?? result.mergedContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  void _resolveAllWithLocal() {
    if (_mergeResult == null) return;
    
    final resolved = ThreeWayMergeEngine.resolveConflicts(
      _mergeResult!,
      MergeResolution.useLocal,
    );
    
    setState(() {
      _mergeResult = resolved;
      _editedContent = resolved.mergedContent;
      _currentConflictIndex = 0;
    });
  }
  
  Future<void> _saveResult() async {
    if (_editedContent == null) return;
    
    // TODO: 实现保存逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('合并结果已保存'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
