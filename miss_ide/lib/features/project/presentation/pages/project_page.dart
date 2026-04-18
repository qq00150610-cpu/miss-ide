// lib/features/project/presentation/pages/project_page.dart - 项目页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_router.dart';
import '../../../../shared/models/file_node.dart';
import '../../../../shared/services/file_tree_service.dart';
import '../bloc/project_bloc.dart';

/// 项目页面
class ProjectPage extends ConsumerStatefulWidget {
  final String? projectPath;
  
  const ProjectPage({super.key, this.projectPath});

  @override
  ConsumerState<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends ConsumerState<ProjectPage> {
  late ProjectNotifier _projectNotifier;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProject();
    });
  }

  Future<void> _initProject() async {
    if (widget.projectPath != null) {
      final projectService = await ref.read(projectServiceInitializerProvider.future);
      final fileTreeService = ref.read(fileTreeServiceProvider);
      _projectNotifier = ProjectNotifier(projectService, fileTreeService);
      await _projectNotifier.openProject(widget.projectPath!);
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = _projectNotifier.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.currentProject?.name ?? 'Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (state.fileTree.basePath != null) {
                _projectNotifier.loadFileTree(state.fileTree.basePath!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: state.fileTree.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFileTree(state.fileTree.rootNodes),
    );
  }

  Widget _buildFileTree(List<FileNode> nodes) {
    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _FileTreeItem(
          node: nodes[index],
          projectNotifier: _projectNotifier,
          onNodeTap: _handleNodeTap,
          onNodeExpand: _handleNodeExpand,
        );
      },
    );
  }

  void _handleNodeTap(FileNode node) {
    _projectNotifier.selectNode(node);
    
    if (!node.isDirectory) {
      // 打开文件
      context.go('${AppRoutes.editor}?path=${Uri.encodeComponent(node.path)}');
    }
  }

  void _handleNodeExpand(FileNode node) {
    _projectNotifier.toggleNode(node);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        onSearch: (query) async {
          final results = await _projectNotifier.searchFiles(query);
          if (mounted) {
            Navigator.pop(context);
            _showSearchResults(results);
          }
        },
      ),
    );
  }

  void _showSearchResults(List<FileNode> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '搜索结果 (${results.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final node = results[index];
                      return ListTile(
                        leading: Icon(_getFileIcon(node)),
                        title: Text(node.name),
                        subtitle: Text(
                          node.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _handleNodeTap(node);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getFileIcon(FileNode node) {
    if (node.isDirectory) {
      return Icons.folder;
    }
    switch (node.fileType.extension) {
      case 'smali':
        return Icons.code;
      case 'java':
        return Icons.java;
      case 'dex':
        return Icons.memory;
      case 'apk':
        return Icons.android;
      case 'xml':
        return Icons.data_object;
      default:
        return Icons.insert_drive_file;
    }
  }
}

/// 文件树项组件
class _FileTreeItem extends StatelessWidget {
  final FileNode node;
  final ProjectNotifier projectNotifier;
  final Function(FileNode) onNodeTap;
  final Function(FileNode) onNodeExpand;

  const _FileTreeItem({
    required this.node,
    required this.projectNotifier,
    required this.onNodeTap,
    required this.onNodeExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => onNodeTap(node),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0 + node.level * 20,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                if (node.isDirectory)
                  GestureDetector(
                    onTap: () => onNodeExpand(node),
                    child: Icon(
                      node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Icon(
                  _getFileIcon(),
                  size: 20,
                  color: _getFileColor(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: node.isDirectory ? null : _getFileColor(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (node.size != null)
                  Text(
                    _formatSize(node.size!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (node.isDirectory && node.isExpanded && node.children.isNotEmpty)
          ...node.children.map((child) => _FileTreeItem(
            node: child,
            projectNotifier: projectNotifier,
            onNodeTap: onNodeTap,
            onNodeExpand: onNodeExpand,
          )),
      ],
    );
  }

  IconData _getFileIcon() {
    if (node.isDirectory) {
      return node.isExpanded ? Icons.folder_open : Icons.folder;
    }
    switch (node.fileType.extension) {
      case 'smali':
        return Icons.code;
      case 'java':
        return Icons.java;
      case 'dex':
        return Icons.memory;
      case 'apk':
        return Icons.android;
      case 'xml':
        return Icons.data_object;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    if (node.isDirectory) {
      return const Color(0xFF6366F1);
    }
    switch (node.fileType.extension) {
      case 'smali':
        return const Color(0xFF3B82F6);
      case 'java':
        return const Color(0xFFF97316);
      case 'dex':
        return const Color(0xFF8B5CF6);
      case 'apk':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('搜索文件'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '输入文件名...',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onSearch(value);
          }
        },
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
