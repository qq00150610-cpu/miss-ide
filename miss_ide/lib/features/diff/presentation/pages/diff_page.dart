// lib/features/diff/presentation/pages/diff_page.dart - 文件对比页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../app/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../engine/diff/diff_result.dart';
import '../../../../engine/diff/diff_engine.dart';
import '../../../../engine/syntax/syntax_theme.dart';

/// 差异对比页面
class DiffPage extends StatefulWidget {
  final String? leftPath;
  final String? rightPath;
  
  const DiffPage({super.key, this.leftPath, this.rightPath});

  @override
  State<DiffPage> createState() => _DiffPageState();
}

class _DiffPageState extends State<DiffPage> {
  // 视图模式
  enum DiffViewMode { single, dual, unified }
  DiffViewMode _viewMode = DiffViewMode.dual;
  
  // 文件信息
  String? _leftPath;
  String? _rightPath;
  String _leftFileName = 'File 1';
  String _rightFileName = 'File 2';
  FileType _fileType = FileType.smali;
  
  // 内容
  List<String> _leftLines = [];
  List<String> _rightLines = [];
  
  // 差异结果
  DiffResult? _diffResult;
  int _currentDiffIndex = 0;
  
  // 状态
  bool _isLoading = true;
  String? _error;
  bool _syncScrollEnabled = true;
  
  // 滚动控制器
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final ItemScrollController _leftItemScrollController = ItemScrollController();
  final ItemScrollController _rightItemScrollController = ItemScrollController();
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _setupScrollSync();
    
    if (widget.leftPath != null && widget.rightPath != null) {
      _loadFiles(widget.leftPath!, widget.rightPath!);
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _setupScrollSync() {
    _leftScrollController.addListener(() {
      if (_syncScrollEnabled && !_isScrolling) {
        _isScrolling = true;
        if (_rightScrollController.hasClients) {
          _rightScrollController.jumpTo(_leftScrollController.offset);
        }
        _isScrolling = false;
      }
    });
    
    _rightScrollController.addListener(() {
      if (_syncScrollEnabled && !_isScrolling) {
        _isScrolling = true;
        if (_leftScrollController.hasClients) {
          _leftScrollController.jumpTo(_rightScrollController.offset);
        }
        _isScrolling = false;
      }
    });
  }

  Future<void> _loadFiles(String leftPath, String rightPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      _leftPath = leftPath;
      _rightPath = rightPath;
      
      _leftFileName = FileUtils.getFileName(leftPath);
      _rightFileName = FileUtils.getFileName(rightPath);
      _fileType = FileType.fromPath(leftPath);
      
      _leftLines = await FileUtils.readFileLines(leftPath);
      _rightLines = await FileUtils.readFileLines(rightPath);
      
      // 计算差异
      final engine = DiffEngineFactory.create(_fileType);
      _diffResult = engine.compute(_leftLines.join('\n'), _rightLines.join('\n'));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _navigateToDiff(int index) {
    if (_diffResult == null || _diffResult!.chunks.isEmpty) return;
    
    setState(() {
      _currentDiffIndex = index.clamp(0, _diffResult!.chunks.length - 1);
    });
    
    final chunk = _diffResult!.chunks[_currentDiffIndex];
    
    if (_viewMode == DiffViewMode.unified) {
      // 统一视图
      _leftItemScrollController.scrollTo(
        index: chunk.leftStartLine - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 双栏视图
      _leftItemScrollController.scrollTo(
        index: chunk.leftStartLine - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _rightItemScrollController.scrollTo(
        index: chunk.rightStartLine - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousDiff() {
    if (_currentDiffIndex > 0) {
      _navigateToDiff(_currentDiffIndex - 1);
    }
  }

  void _nextDiff() {
    if (_diffResult != null && _currentDiffIndex < _diffResult!.chunks.length - 1) {
      _navigateToDiff(_currentDiffIndex + 1);
    }
  }

  void _copyLine(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('文件对比'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(AppRoutes.home),
      ),
      actions: [
        // 差异导航
        if (_diffResult != null && _diffResult!.chunks.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousDiff,
            tooltip: '上一个差异',
          ),
          Text(
            '${_currentDiffIndex + 1}/${_diffResult!.chunks.length}',
            style: const TextStyle(fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextDiff,
            tooltip: '下一个差异',
          ),
        ],
        const VerticalDivider(),
        // 视图模式切换
        SegmentedButton<DiffViewMode>(
          segments: const [
            ButtonSegment(
              value: DiffViewMode.single,
              icon: Icon(Icons.article_outlined, size: 18),
              label: Text('单', style: TextStyle(fontSize: 12)),
            ),
            ButtonSegment(
              value: DiffViewMode.dual,
              icon: Icon(Icons.compare, size: 18),
              label: Text('对比', style: Text: TextStyle(fontSize: 12)),
            ),
            ButtonSegment(
              value: DiffViewMode.unified,
              icon: Icon(Icons.view_stream, size: 18),
              label: Text('统一', style: TextStyle(fontSize: 12)),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (selection) {
            setState(() {
              _viewMode = selection.first;
            });
          },
        ),
        const SizedBox(width: 8),
        // 同步滚动开关
        IconButton(
          icon: Icon(
            _syncScrollEnabled ? Icons.sync : Icons.sync_disabled,
          ),
          onPressed: () {
            setState(() {
              _syncScrollEnabled = !_syncScrollEnabled;
            });
          },
          tooltip: '同步滚动',
        ),
        // 统计信息
        if (_diffResult != null) _buildStatsChip(),
      ],
    );
  }

  Widget _buildStatsChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildStatBadge(
            '+${_diffResult!.addedCount}',
            SyntaxTheme.addedHighlight,
          ),
          const SizedBox(width: 4),
          _buildStatBadge(
            '-${_diffResult!.deletedCount}',
            SyntaxTheme.deletedHighlight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 文件头
        _buildFileHeaders(),
        // 差异视图
        Expanded(
          child: _buildDiffView(),
        ),
        // 差异导航栏
        if (_diffResult != null && _diffResult!.chunks.isNotEmpty)
          _buildDiffNavigator(),
      ],
    );
  }

  Widget _buildFileHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.file_copy_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _leftFileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _fileType == FileType.smali
                  ? SyntaxTheme.smaliDirective
                  : _fileType == FileType.java
                      ? SyntaxTheme.type
                      : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _fileType.displayName,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.compare_arrows, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.file_copy_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rightFileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffView() {
    if (_diffResult == null) {
      return const Center(child: Text('暂无差异数据'));
    }

    switch (_viewMode) {
      case DiffViewMode.single:
        return _buildSingleView();
      case DiffViewMode.dual:
        return _buildDualView();
      case DiffViewMode.unified:
        return _buildUnifiedView();
    }
  }

  Widget _buildSingleView() {
    return _buildDiffContentView(
      lines: _diffResult!.lines,
      showLeftLineNumber: true,
      showRightLineNumber: true,
    );
  }

  Widget _buildDualView() {
    return Row(
      children: [
        Expanded(
          child: _buildDiffContentView(
            lines: _diffResult!.lines.where((l) => l.type != DiffType.add).toList(),
            showLeftLineNumber: true,
            showRightLineNumber: false,
            scrollController: _leftScrollController,
            itemScrollController: _leftItemScrollController,
          ),
        ),
        Container(
          width: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: _buildDiffContentView(
            lines: _diffResult!.lines.where((l) => l.type != DiffType.delete).toList(),
            showLeftLineNumber: false,
            showRightLineNumber: true,
            scrollController: _rightScrollController,
            itemScrollController: _rightItemScrollController,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedView() {
    return _buildDiffContentView(
      lines: _diffResult!.lines,
      showLeftLineNumber: true,
      showRightLineNumber: true,
      itemScrollController: _leftItemScrollController,
    );
  }

  Widget _buildDiffContentView({
    required List<DiffLine> lines,
    required bool showLeftLineNumber,
    required bool showRightLineNumber,
    ScrollController? scrollController,
    ItemScrollController? itemScrollController,
  }) {
    return ListView.builder(
      controller: scrollController,
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return _DiffLineWidget(
          line: line,
          showLeftLineNumber: showLeftLineNumber,
          showRightLineNumber: showRightLineNumber,
          onCopy: () => _copyLine(line.displayContent),
        );
      },
    );
  }

  Widget _buildDiffNavigator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.difference, size: 16),
            const SizedBox(width: 8),
            Text(
              '差异导航:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(_diffResult!.chunks.length, (index) {
              final chunk = _diffResult!.chunks[index];
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () => _navigateToDiff(index),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: index == _currentDiffIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}: L${chunk.leftStartLine}',
                      style: TextStyle(
                        fontSize: 12,
                        color: index == _currentDiffIndex
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 差异行组件
class _DiffLineWidget extends StatelessWidget {
  final DiffLine line;
  final bool showLeftLineNumber;
  final bool showRightLineNumber;
  final VoidCallback onCopy;

  const _DiffLineWidget({
    required this.line,
    required this.showLeftLineNumber,
    required this.showRightLineNumber,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final textColor = _getTextColor();

    return GestureDetector(
      onLongPress: onCopy,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            // 左侧行号
            if (showLeftLineNumber)
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerRight,
                color: Colors.grey.withOpacity(0.1),
                child: Text(
                  line.leftLineNumber?.toString() ?? '',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            // 差异标记
            Container(
              width: 24,
              alignment: Alignment.center,
              child: _getDiffIcon(),
            ),
            // 内容
            Expanded(
              child: Text(
                line.displayContent,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ),
            // 右侧行号
            if (showRightLineNumber)
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerRight,
                color: Colors.grey.withOpacity(0.1),
                child: Text(
                  line.rightLineNumber?.toString() ?? '',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (line.type) {
      case DiffType.add:
        return SyntaxTheme.addedLine;
      case DiffType.delete:
        return SyntaxTheme.deletedLine;
      case DiffType.modify:
        return SyntaxTheme.modifiedLine;
      default:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (line.type) {
      case DiffType.add:
        return SyntaxTheme.addedHighlight;
      case DiffType.delete:
        return SyntaxTheme.deletedHighlight;
      case DiffType.modify:
        return SyntaxTheme.modifiedHighlight;
      default:
        return SyntaxTheme.foreground;
    }
  }

  Widget _getDiffIcon() {
    switch (line.type) {
      case DiffType.add:
        return const Text(
          '+',
          style: TextStyle(
            color: SyntaxTheme.addedHighlight,
            fontWeight: FontWeight.bold,
          ),
        );
      case DiffType.delete:
        return const Text(
          '-',
          style: TextStyle(
            color: SyntaxTheme.deletedHighlight,
            fontWeight: FontWeight.bold,
          ),
        );
      case DiffType.modify:
        return const Text(
          '~',
          style: TextStyle(
            color: SyntaxTheme.modifiedHighlight,
            fontWeight: FontWeight.bold,
          ),
        );
      default:
        return const SizedBox(width: 12);
    }
  }
}
