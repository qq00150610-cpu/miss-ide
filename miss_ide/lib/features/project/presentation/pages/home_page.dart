// lib/features/project/presentation/pages/home_page.dart - 首页
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_router.dart';
import '../../../../shared/models/project_model.dart';
import '../../../../shared/services/project_service.dart';
import '../../../../shared/services/file_tree_service.dart';
import '../bloc/project_bloc.dart';

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ProjectNotifier _projectNotifier;
  final _searchController = TextEditingController();
  List<ProjectModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initProjectNotifier();
  }

  Future<void> _initProjectNotifier() async {
    final projectService = await ref.read(projectServiceInitializerProvider.future);
    final fileTreeService = ref.read(fileTreeServiceProvider);
    _projectNotifier = ProjectNotifier(projectService, fileTreeService);
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectBlocProvider);
    
    // 同步状态
    if (_projectNotifier.state.status != projectState.status ||
        _projectNotifier.state.recentProjects != projectState.recentProjects) {
      // 状态已更新
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部区域
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            
            // 搜索区域
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            
            // 功能入口
            SliverToBoxAdapter(
              child: _buildFeatureCards(context),
            ),
            
            // 最近项目
            SliverToBoxAdapter(
              child: _buildRecentSection(context),
            ),
            
            // 底部空间
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mobile_friendly,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Miss IDE',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Android 反编译开发工具',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索项目...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _searchResults = [];
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
        onSubmitted: (value) async {
          if (value.isNotEmpty) {
            final results = await _projectNotifier.searchFiles(value);
            setState(() {
              _searchResults = results.map((node) {
                return ProjectModel(
                  id: node.path,
                  name: node.name,
                  path: node.path,
                  createdAt: DateTime.now(),
                  modifiedAt: DateTime.now(),
                );
              }).toList();
            });
          }
        },
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷功能',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.folder_open,
                  title: '打开项目',
                  subtitle: '打开已有文件夹',
                  color: const Color(0xFF6366F1),
                  onTap: () => _openProject(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.compare_arrows,
                  title: '文件对比',
                  subtitle: '对比两个文件差异',
                  color: const Color(0xFF10B981),
                  onTap: () => _openDiffPicker(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.android,
                  title: '反编译 APK',
                  subtitle: '解压分析 APK',
                  color: const Color(0xFFF97316),
                  onTap: () => _openApkPicker(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.code,
                  title: '代码编辑',
                  subtitle: '编辑 Smali/Java',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    // 默认打开编辑器
                    context.go(AppRoutes.editor);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    final state = _projectNotifier.state;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近项目',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.recentProjects.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // 清除最近项目
                  },
                  child: const Text('清除'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSearching && _searchResults.isNotEmpty)
            ...(_searchResults.map((p) => _buildProjectCard(p)))
          else if (state.recentProjects.isEmpty)
            _buildEmptyState()
          else
            ...(state.recentProjects.take(5).map((p) => _buildProjectCard(p))),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.folder,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(project.name),
        subtitle: Text(
          project.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.go('${AppRoutes.project}?path=${Uri.encodeComponent(project.path)}');
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无最近项目',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '打开一个项目开始使用',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 打开项目选择器
  Future<void> _openProject() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await _projectNotifier.openProject(result);
      if (mounted) {
        context.go('${AppRoutes.project}?path=${Uri.encodeComponent(result)}');
      }
    }
  }

  /// 打开文件对比
  Future<void> _openDiffPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['smali', 'java', 'dex', 'txt'],
      dialogTitle: '选择第一个文件',
    );
    
    if (result != null && result.files.isNotEmpty) {
      final leftPath = result.files.first.path;
      if (leftPath != null && mounted) {
        // 打开第二个文件选择
        final result2 = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['smali', 'java', 'dex', 'txt'],
          dialogTitle: '选择第二个文件',
        );
        
        if (result2 != null && result2.files.isNotEmpty) {
          final rightPath = result2.files.first.path;
          if (rightPath != null && mounted) {
            context.go(
              '${AppRoutes.diff}?left=${Uri.encodeComponent(leftPath)}&right=${Uri.encodeComponent(rightPath)}',
            );
          }
        }
      }
    }
  }

  /// 打开APK选择器
  Future<void> _openApkPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      dialogTitle: '选择 APK 文件',
    );
    
    if (result != null && result.files.isNotEmpty) {
      final apkPath = result.files.first.path;
      if (apkPath != null && mounted) {
        context.go('${AppRoutes.decompile}?apk=${Uri.encodeComponent(apkPath)}');
      }
    }
  }
}

/// 功能卡片组件
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
