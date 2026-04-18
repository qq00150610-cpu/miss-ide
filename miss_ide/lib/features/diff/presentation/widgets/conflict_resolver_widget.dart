// lib/features/diff/presentation/widgets/conflict_resolver_widget.dart - 冲突解决组件
import 'package:flutter/material.dart';
import '../../../engine/merge/three_way_merge_engine.dart';

/// 冲突解决面板
class ConflictResolverWidget extends StatefulWidget {
  final MergeConflict conflict;
  final Function(MergeResolution) onResolve;
  final Function(String) onManualResolve;
  
  const ConflictResolverWidget({
    super.key,
    required this.conflict,
    required this.onResolve,
    required this.onManualResolve,
  });
  
  @override
  State<ConflictResolverWidget> createState() => _ConflictResolverWidgetState();
}

class _ConflictResolverWidgetState extends State<ConflictResolverWidget> {
  late TextEditingController _manualController;
  bool _showManualEditor = false;
  
  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController();
  }
  
  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: _showManualEditor
                ? _buildManualEditor()
                : _buildThreeColumnView(),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '冲突 #${widget.conflict.id + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Base: ${widget.conflict.baseStart + 1}-${widget.conflict.baseEnd + 1} | '
                  'Local: ${widget.conflict.localStart + 1}-${widget.conflict.localEnd + 1} | '
                  'Remote: ${widget.conflict.remoteStart + 1}-${widget.conflict.remoteEnd + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: '手动编辑',
            onPressed: () {
              setState(() {
                _showManualEditor = !_showManualEditor;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildThreeColumnView() {
    return Row(
      children: [
        Expanded(
          child: _buildVersionColumn(
            'BASE',
            widget.conflict.baseContent,
            Colors.grey,
            Icons.commit,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildVersionColumn(
            'LOCAL',
            widget.conflict.localContent,
            Colors.blue,
            Icons.computer,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildVersionColumn(
            'REMOTE',
            widget.conflict.remoteContent,
            Colors.green,
            Icons.cloud,
          ),
        ),
      ],
    );
  }
  
  Widget _buildVersionColumn(
    String label,
    String content,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(color: color, width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: color.withOpacity(0.05),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildManualEditor() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              const Text('手动编辑解决内容'),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('完成'),
                onPressed: () {
                  widget.onManualResolve(_manualController.text);
                  setState(() {
                    _showManualEditor = false;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: _manualController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              hintText: '在此输入合并后的内容...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.commit,
            label: '采用基础',
            color: Colors.grey,
            onPressed: () => widget.onResolve(MergeResolution.useBase),
          ),
          _buildActionButton(
            icon: Icons.computer,
            label: '采用本地',
            color: Colors.blue,
            onPressed: () => widget.onResolve(MergeResolution.useLocal),
          ),
          _buildActionButton(
            icon: Icons.cloud,
            label: '采用远程',
            color: Colors.green,
            onPressed: () => widget.onResolve(MergeResolution.useRemote),
          ),
          _buildActionButton(
            icon: Icons.auto_fix_high,
            label: '保留全部',
            color: Colors.orange,
            onPressed: () => widget.onResolve(MergeResolution.keepAll),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
    );
  }
}

/// 冲突列表组件
class ConflictListWidget extends StatelessWidget {
  final List<MergeConflict> conflicts;
  final int currentIndex;
  final Function(int) onSelectConflict;
  final Function(int, MergeResolution) onResolveConflict;
  final Function(int, String) onManualResolve;
  
  const ConflictListWidget({
    super.key,
    required this.conflicts,
    required this.currentIndex,
    required this.onSelectConflict,
    required this.onResolveConflict,
    required this.onManualResolve,
  });
  
  @override
  Widget build(BuildContext context) {
    final unresolvedConflicts = conflicts.where((c) => !c.resolved).toList();
    final resolvedCount = conflicts.length - unresolvedConflicts.length;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(
                unresolvedConflicts.isEmpty
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '冲突 (${resolvedCount}/${conflicts.length} 已解决)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (unresolvedConflicts.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('全部采用本地'),
                  onPressed: () {
                    for (int i = 0; i < conflicts.length; i++) {
                      if (!conflicts[i].resolved) {
                        onResolveConflict(i, MergeResolution.useLocal);
                      }
                    }
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              final isSelected = index == currentIndex;
              final isResolved = conflict.resolved;
              
              return ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
                leading: CircleAvatar(
                  backgroundColor: isResolved
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                  child: isResolved
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text('${index + 1}'),
                ),
                title: Text(
                  '冲突 #${index + 1} (行 ${conflict.baseStart + 1}-${conflict.baseEnd + 1})',
                  style: TextStyle(
                    decoration: isResolved ? TextDecoration.lineThrough : null,
                    color: isResolved ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  isResolved
                      ? '已解决 (${_getResolutionText(conflict.resolution)})'
                      : _getConflictTypeText(conflict.type),
                  style: TextStyle(
                    color: isResolved ? Colors.green : Colors.grey,
                  ),
                ),
                trailing: isResolved
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.chevron_right),
                onTap: () => onSelectConflict(index),
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _getConflictTypeText(ConflictType type) {
    switch (type) {
      case ConflictType.addAdd:
        return '添加冲突：两边添加了不同内容';
      case ConflictType.deleteModify:
        return '删除/修改冲突';
      case ConflictType.modifyModify:
        return '修改冲突：两边修改了同一区域';
      case ConflictType.complex:
        return '复杂冲突';
      case ConflictType.none:
        return '无冲突';
    }
  }
  
  String _getResolutionText(MergeResolution? resolution) {
    switch (resolution) {
      case MergeResolution.useBase:
        return '采用基础';
      case MergeResolution.useLocal:
        return '采用本地';
      case MergeResolution.useRemote:
        return '采用远程';
      case MergeResolution.manual:
        return '手动编辑';
      case MergeResolution.keepAll:
        return '保留全部';
      case null:
        return '未知';
    }
  }
}

/// 合并结果预览组件
class MergeResultPreview extends StatelessWidget {
  final ThreeWayMergeResult result;
  final ScrollController? scrollController;
  
  const MergeResultPreview({
    super.key,
    required this.result,
    this.scrollController,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsBar(context),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: scrollController,
              itemCount: result.chunks.length,
              itemBuilder: (context, index) {
                return _buildChunkPreview(context, result.chunks[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            '总行数',
            '${result.unchangedLines + result.modifiedLines}',
            Colors.blue,
          ),
          _buildStatItem(
            context,
            '未修改',
            '${result.unchangedLines}',
            Colors.grey,
          ),
          _buildStatItem(
            context,
            '已修改',
            '${result.modifiedLines}',
            Colors.orange,
          ),
          _buildStatItem(
            context,
            '冲突',
            '${result.allConflicts.length}',
            result.hasConflicts ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildChunkPreview(BuildContext context, MergeChunk chunk) {
    Color bgColor;
    Color borderColor;
    String prefix;
    
    switch (chunk.type) {
      case MergeChunkType.unchanged:
        bgColor = Colors.transparent;
        borderColor = Colors.grey.withOpacity(0.3);
        prefix = '';
        break;
      case MergeChunkType.localOnly:
        bgColor = Colors.blue.withOpacity(0.1);
        borderColor = Colors.blue;
        prefix = '[LOCAL] ';
        break;
      case MergeChunkType.remoteOnly:
        bgColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        prefix = '[REMOTE] ';
        break;
      case MergeChunkType.bothModified:
        bgColor = Colors.orange.withOpacity(0.1);
        borderColor = Colors.orange;
        prefix = '[BOTH] ';
        break;
      case MergeChunkType.conflict:
        bgColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        prefix = '[CONFLICT] ';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
          bottom: BorderSide(color: borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          if (chunk.type == MergeChunkType.conflict)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Text(
              prefix + (chunk.mergedContent ?? '').split('\n').first,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: chunk.type == MergeChunkType.unchanged
                    ? Colors.grey
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
