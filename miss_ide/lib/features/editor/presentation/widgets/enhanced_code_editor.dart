// lib/features/editor/presentation/widgets/enhanced_code_editor.dart - 增强型代码编辑器
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 编辑器标签页
class EditorTab {
  final String id;
  final String title;
  final String filePath;
  final String content;
  final bool isModified;
  final FileType fileType;
  
  const EditorTab({
    required this.id,
    required this.title,
    required this.filePath,
    required this.content,
    this.isModified = false,
    this.fileType = FileType.text,
  });
  
  EditorTab copyWith({
    String? title,
    String? content,
    bool? isModified,
  }) {
    return EditorTab(
      id: id,
      title: title ?? this.title,
      filePath: filePath,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
      fileType: fileType,
    );
  }
}

/// 文件类型
enum FileType {
  text,
  java,
  smali,
  xml,
  json,
  other,
}

/// 代码编辑器状态管理
class EditorState {
  final List<EditorTab> tabs;
  final int activeTabIndex;
  final Map<String, TextEditingController> controllers;
  final Map<String, List<TextEditingValue>> undoStack;
  final Map<String, List<TextEditingValue>> redoStack;
  final Map<String, List<FoldRegion>> foldRegions;
  
  const EditorState({
    this.tabs = const [],
    this.activeTabIndex = 0,
    this.controllers = const {},
    this.undoStack = const {},
    this.redoStack = const {},
    this.foldRegions = const {},
  });
  
  EditorState copyWith({
    List<EditorTab>? tabs,
    int? activeTabIndex,
    Map<String, TextEditingController>? controllers,
    Map<String, List<TextEditingValue>>? undoStack,
    Map<String, List<TextEditingValue>>? redoStack,
    Map<String, List<FoldRegion>>? foldRegions,
  }) {
    return EditorState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      controllers: controllers ?? this.controllers,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      foldRegions: foldRegions ?? this.foldRegions,
    );
  }
  
  EditorTab? get activeTab => 
      tabs.isNotEmpty && activeTabIndex < tabs.length 
          ? tabs[activeTabIndex] 
          : null;
}

/// 代码折叠区域
class FoldRegion {
  final int startLine;
  final int endLine;
  final String summary;
  final bool isFolded;
  
  const FoldRegion({
    required this.startLine,
    required this.endLine,
    required this.summary,
    this.isFolded = false,
  });
  
  FoldRegion copyWith({bool? isFolded}) {
    return FoldRegion(
      startLine: startLine,
      endLine: endLine,
      summary: summary,
      isFolded: isFolded ?? this.isFolded,
    );
  }
}

/// 增强型代码编辑器 Widget
class EnhancedCodeEditor extends StatefulWidget {
  final List<EditorTab> tabs;
  final int activeTabIndex;
  final Function(int) onTabChanged;
  final Function(int) onTabClosed;
  final Function(String tabId, String content) onContentChanged;
  final EditorConfig config;
  
  const EnhancedCodeEditor({
    super.key,
    required this.tabs,
    required this.activeTabIndex,
    required this.onTabChanged,
    required this.onTabClosed,
    required this.onContentChanged,
    this.config = const EditorConfig(),
  });
  
  @override
  State<EnhancedCodeEditor> createState() => _EnhancedCodeEditorState();
}

class _EnhancedCodeEditorState extends State<EnhancedCodeEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final Map<String, List<FoldRegion>> _foldRegions = {};
  
  @override
  void initState() {
    super.initState();
    _initControllers();
  }
  
  void _initControllers() {
    for (final tab in widget.tabs) {
      _getOrCreateController(tab);
      _getOrCreateFocusNode(tab.id);
      _getOrCreateScrollController(tab.id);
      _detectFoldRegions(tab);
    }
  }
  
  TextEditingController _getOrCreateController(EditorTab tab) {
    if (!_controllers.containsKey(tab.id)) {
      _controllers[tab.id] = TextEditingController(text: tab.content);
      _controllers[tab.id]!.addListener(() {
        widget.onContentChanged(tab.id, _controllers[tab.id]!.text);
      });
    }
    return _controllers[tab.id]!;
  }
  
  FocusNode _getOrCreateFocusNode(String tabId) {
    if (!_focusNodes.containsKey(tabId)) {
      _focusNodes[tabId] = FocusNode();
    }
    return _focusNodes[tabId]!;
  }
  
  ScrollController _getOrCreateScrollController(String tabId) {
    if (!_scrollControllers.containsKey(tabId)) {
      _scrollControllers[tabId] = ScrollController();
    }
    return _scrollControllers[tabId]!;
  }
  
  void _detectFoldRegions(EditorTab tab) {
    if (_foldRegions.containsKey(tab.id)) return;
    
    final regions = <FoldRegion>[];
    final lines = tab.content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测代码块开始
      if (line.startsWith('.method') || 
          line.startsWith('class ') ||
          line.startsWith('{')) {
        // 查找对应的结束
        int endLine = i;
        String summary = line;
        
        if (line.startsWith('.method')) {
          // 查找 .end method
          for (int j = i + 1; j < lines.length; j++) {
            if (lines[j].trim() == '.end method') {
              endLine = j;
              break;
            }
          }
          summary = '方法: ${line.replaceFirst('.method', '').trim()}';
        } else if (line.startsWith('class ')) {
          for (int j = i + 1; j < lines.length; j++) {
            if (lines[j].trim() == '}') {
              endLine = j;
              break;
            }
          }
          summary = '类: ${line.replaceFirst('class ', '').split(RegExp(r'[ {]')).first}';
        }
        
        if (endLine > i) {
          regions.add(FoldRegion(
            startLine: i,
            endLine: endLine,
            summary: summary,
          ));
        }
      }
    }
    
    _foldRegions[tab.id] = regions;
  }
  
  @override
  void didUpdateWidget(EnhancedCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 检查是否有新增的标签页
    for (final tab in widget.tabs) {
      if (!_controllers.containsKey(tab.id)) {
        _getOrCreateController(tab);
        _getOrCreateFocusNode(tab.id);
        _getOrCreateScrollController(tab.id);
        _detectFoldRegions(tab);
      }
    }
    
    // 移除已关闭的标签页控制器
    final tabIds = widget.tabs.map((t) => t.id).toSet();
    _controllers.removeWhere((id, _) => !tabIds.contains(id));
    _focusNodes.removeWhere((id, _) => !tabIds.contains(id));
    _scrollControllers.removeWhere((id, _) => !tabIds.contains(id));
    _foldRegions.removeWhere((id, _) => !tabIds.contains(id));
  }
  
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(child: _buildEditorContent()),
      ],
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        itemBuilder: (context, index) {
          final tab = widget.tabs[index];
          final isActive = index == widget.activeTabIndex;
          
          return GestureDetector(
            onTap: () => widget.onTabChanged(index),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive 
                    ? Theme.of(context).colorScheme.surface
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: isActive 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getFileIcon(tab.fileType),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      tab.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  if (tab.isModified)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => widget.onTabClosed(index),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _getFileIcon(FileType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case FileType.java:
        icon = Icons.coffee;
        color = Colors.orange;
        break;
      case FileType.smali:
        icon = Icons.code;
        color = Colors.blue;
        break;
      case FileType.xml:
        icon = Icons.data_object;
        color = Colors.green;
        break;
      case FileType.json:
        icon = Icons.data_array;
        color = Colors.amber;
        break;
      default:
        icon = Icons.description;
        color = Colors.grey;
    }
    
    return Icon(icon, size: 16, color: color);
  }
  
  Widget _buildEditorContent() {
    final activeTab = widget.tabs.isNotEmpty 
        ? widget.tabs[widget.activeTabIndex] 
        : null;
    
    if (activeTab == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有打开的文件', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    final controller = _controllers[activeTab.id]!;
    final focusNode = _focusNodes[activeTab.id]!;
    final scrollController = _scrollControllers[activeTab.id]!;
    final foldRegions = _foldRegions[activeTab.id] ?? [];
    
    return Row(
      children: [
        // 行号栏
        _buildLineNumberGutter(controller, scrollController),
        
        // 编辑器内容
        Expanded(
          child: _buildCodeEditor(
            controller,
            focusNode,
            scrollController,
            activeTab,
            foldRegions,
          ),
        ),
        
        // 折叠指示器
        if (widget.config.enableCodeFolding)
          _buildFoldGutter(foldRegions, scrollController),
      ],
    );
  }
  
  Widget _buildLineNumberGutter(
    TextEditingController controller,
    ScrollController scrollController,
  ) {
    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        itemCount: controller.text.split('\n').length,
        itemBuilder: (context, index) {
          return Container(
            height: widget.config.lineHeight,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.config.fontSize,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCodeEditor(
    TextEditingController controller,
    FocusNode focusNode,
    ScrollController scrollController,
    EditorTab tab,
    List<FoldRegion> foldRegions,
  ) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      scrollController: scrollController,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontFamily: widget.config.fontFamily,
        fontSize: widget.config.fontSize,
        height: widget.config.lineHeight / widget.config.fontSize,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(8),
      ),
      inputFormatters: [
        _TabFormatter(tabSize: widget.config.tabSize),
        if (widget.config.enableBracketMatching)
          _BracketMatchingFormatter(),
      ],
    );
  }
  
  Widget _buildFoldGutter(
    List<FoldRegion> foldRegions,
    ScrollController scrollController,
  ) {
    return Container(
      width: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        itemCount: foldRegions.length,
        itemBuilder: (context, index) {
          final region = foldRegions[index];
          return GestureDetector(
            onTap: () => _toggleFold(index),
            child: Container(
              height: widget.config.lineHeight,
              alignment: Alignment.center,
              child: Icon(
                region.isFolded 
                    ? Icons.chevron_right 
                    : Icons.expand_more,
                size: 16,
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _toggleFold(int index) {
    // 实现折叠切换逻辑
  }
}

/// 编辑器配置
class EditorConfig {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final int tabSize;
  final bool enableCodeFolding;
  final bool enableAutoComplete;
  final bool enableBracketMatching;
  final bool showLineNumbers;
  final bool highlightCurrentLine;
  
  const EditorConfig({
    this.fontSize = 14,
    this.fontFamily = 'monospace',
    this.lineHeight = 20,
    this.tabSize = 4,
    this.enableCodeFolding = true,
    this.enableAutoComplete = true,
    this.enableBracketMatching = true,
    this.showLineNumbers = true,
    this.highlightCurrentLine = true,
  });
}

/// Tab 格式化器
class _TabFormatter extends TextInputFormatter {
  final int tabSize;
  
  _TabFormatter({this.tabSize = 4});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();
    int spaces = 0;
    
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '\t') {
        buffer.write(' ' * tabSize);
        spaces += tabSize;
      } else {
        buffer.write(text[i]);
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

/// 括号匹配格式化器
class _BracketMatchingFormatter extends TextInputFormatter {
  static const _brackets = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final cursorPos = newValue.selection.baseOffset;
    
    if (cursorPos <= 0 || cursorPos > text.length) {
      return newValue;
    }
    
    final prevChar = text[cursorPos - 1];
    final nextChar = cursorPos < text.length ? text[cursorPos] : null;
    
    // 自动补全括号
    if (_brackets.containsKey(prevChar) && nextChar == null) {
      final closingBracket = _brackets[prevChar];
      return TextEditingValue(
        text: '$text$closingBracket',
        selection: TextSelection.collapsed(offset: cursorPos),
      );
    }
    
    return newValue;
  }
}

/// 查找替换对话框
class FindReplaceDialog extends StatefulWidget {
  final Function(String) onFind;
  final Function(String, String) onReplace;
  final Function(String, String) onReplaceAll;
  
  const FindReplaceDialog({
    super.key,
    required this.onFind,
    required this.onReplace,
    required this.onReplaceAll,
  });
  
  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _regex = false;
  
  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('查找和替换'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _findController,
              decoration: const InputDecoration(
                labelText: '查找',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
              onSubmitted: (_) => _find(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _replaceController,
              decoration: const InputDecoration(
                labelText: '替换为',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.find_replace),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: const Text('区分大小写'),
                  selected: _caseSensitive,
                  onSelected: (v) => setState(() => _caseSensitive = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('全词匹配'),
                  selected: _wholeWord,
                  onSelected: (v) => setState(() => _wholeWord = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('正则表达式'),
                  selected: _regex,
                  onSelected: (v) => setState(() => _regex = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onReplace(
              _findController.text,
              _replaceController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('替换'),
        ),
        TextButton(
          onPressed: () {
            widget.onReplaceAll(
              _findController.text,
              _replaceController.text,
            );
            Navigator.pop(context);
          },
          child: const Text('全部替换'),
        ),
        ElevatedButton(
          onPressed: _find,
          child: const Text('查找下一个'),
        ),
      ],
    );
  }
  
  void _find() {
    widget.onFind(_findController.text);
  }
}
