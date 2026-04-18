// lib/features/editor/presentation/pages/editor_page.dart - 代码编辑器页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/smali.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/file_utils.dart';

/// 代码编辑器页面
class EditorPage extends StatefulWidget {
  final String? filePath;
  
  const EditorPage({super.key, this.filePath});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late CodeLineEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  
  String? _currentFilePath;
  String _fileName = 'Untitled';
  FileType _fileType = FileType.smali;
  bool _isLoading = true;
  String? _error;
  bool _hasChanges = false;
  List<String> _undoStack = [];
  List<String> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController();
    _controller.addListener(_onContentChanged);
    
    if (widget.filePath != null) {
      _loadFile(widget.filePath!);
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadFile(String path) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final content = await FileUtils.readFileContent(path);
      _controller.text = content;
      _currentFilePath = path;
      _fileName = FileUtils.getFileName(path);
      _fileType = FileType.fromPath(path);
      
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _saveFile() async {
    if (_currentFilePath == null) return;
    
    try {
      await FileUtils.writeFileContent(_currentFilePath!, _controller.text);
      setState(() {
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  void _undo() {
    // 简化实现
  }

  void _redo() {
    // 简化实现
  }

  void _search() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        onSearch: (query) {
          // 实现搜索功能
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_getFileIcon(), size: 20),
            const SizedBox(width: 8),
            Text(_fileName),
            if (_hasChanges)
              const Text(' *', style: TextStyle(color: Colors.orange)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
            tooltip: '重做',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
            tooltip: '搜索',
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: _currentFilePath != null
                ? () => _showDiffPicker()
                : null,
            tooltip: '对比',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFile,
            tooltip: '保存',
          ),
        ],
      ),
      body: _buildBody(),
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
        // 文件信息栏
        _buildInfoBar(),
        // 编辑器
        Expanded(
          child: _buildEditor(),
        ),
        // 状态栏
        _buildStatusBar(),
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _buildTag(_fileType.displayName, _getFileColor()),
          const SizedBox(width: 8),
          Text(
            _currentFilePath ?? 'New File',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return CodeEditor(
      controller: _controller,
      scrollController: _scrollController,
      style: CodeEditorStyle(
        fontSize: 14,
        fontFamily: 'monospace',
        codeTheme: CodeHighlightTheme(
          theme: atomOneDarkTheme,
          languages: {
            'smali': CodeHighlightThemeMode(mode: langSmali),
            'java': CodeHighlightThemeMode(mode: langJava),
          },
        ),
      ),
      wordWrap: false,
      showLineNumbers: true,
      indicatorBuilder: (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
              style: const TextStyle(
                color: Color(0xFF858585),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '行: ${_controller.lines.length}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 16),
          Text(
            '字符: ${_controller.text.length}',
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          Text(
            _fileType.displayName,
            style: TextStyle(
              fontSize: 12,
              color: _getFileColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (_fileType) {
      case FileType.smali:
        return Icons.code;
      case FileType.java:
        return Icons.java;
      case FileType.dex:
        return Icons.memory;
      case FileType.xml:
        return Icons.data_object;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (_fileType) {
      case FileType.smali:
        return const Color(0xFF3B82F6);
      case FileType.java:
        return const Color(0xFFF97316);
      case FileType.dex:
        return const Color(0xFF8B5CF6);
      case FileType.apk:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('是否保存更改?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveFile();
              if (mounted) {
                context.go(AppRoutes.home);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDiffPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择对比文件'),
        content: const Text('将选择第二个文件与当前文件进行对比'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // 打开文件选择器
              // 然后跳转到对比页面
            },
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
  }
}

/// 搜索对话框
class _SearchDialog extends StatefulWidget {
  final Function(String) onSearch;
  
  const _SearchDialog({required this.onSearch});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _controller = TextEditingController();
  bool _caseSensitive = false;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('搜索'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '搜索内容...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onSearch(value);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _caseSensitive,
                onChanged: (value) {
                  setState(() {
                    _caseSensitive = value ?? false;
                  });
                },
              ),
              const Text('区分大小写'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSearch(_controller.text);
            }
          },
          child: const Text('搜索'),
        ),
      ],
    );
  }
}
