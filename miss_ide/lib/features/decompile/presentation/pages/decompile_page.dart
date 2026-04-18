// lib/features/decompile/presentation/pages/decompile_page.dart - 反编译页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../app/app_router.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../engine/decompile/decompile_engine.dart';

/// 反编译页面
class DecompilePage extends StatefulWidget {
  final String? apkPath;
  
  const DecompilePage({super.key, this.apkPath});

  @override
  State<DecompilePage> createState() => _DecompilePageState();
}

class _DecompilePageState extends State<DecompilePage> {
  final DecompileEngine _engine = DecompileEngine();
  
  String? _apkPath;
  String _apkFileName = '';
  DecompileResult? _result;
  ApkInfo? _apkInfo;
  bool _isExtracting = true;
  String? _error;
  
  // Tab 控制
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.apkPath != null) {
      _extractApk(widget.apkPath!);
    } else {
      setState(() {
        _isExtracting = false;
        _error = 'No APK file specified';
      });
    }
  }

  Future<void> _extractApk(String path) async {
    setState(() {
      _isExtracting = true;
      _error = null;
      _apkPath = path;
      _apkFileName = FileUtils.getFileName(path);
    });
    
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final outputPath = '${appDir.path}/decompiled/${FileUtils.getBaseName(path)}';
      
      // 执行反编译
      _result = await _engine.extractApk(path, outputPath);
      
      if (_result!.success) {
        setState(() {
          _apkInfo = _result!.apkInfo;
          _isExtracting = false;
        });
      } else {
        setState(() {
          _error = _result!.error;
          _isExtracting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExtracting = false;
      });
    }
  }

  void _openInProject() {
    if (_result != null && _result!.success) {
      context.go('${AppRoutes.project}?path=${Uri.encodeComponent(_result!.outputPath)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_apkFileName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          if (_result != null && _result!.success)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _openInProject,
              tooltip: '在项目中打开',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isExtracting) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    return _buildContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            '正在解压 APK...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _apkFileName,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '解压失败',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // APK 信息卡
        _buildApkInfoCard(),
        // Tab 栏
        _buildTabBar(),
        // Tab 内容
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildApkInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.android,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _apkInfo?.packageName ?? _apkFileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_apkInfo?.versionName != null)
                      Text(
                        'Version: ${_apkInfo!.versionName} (${_apkInfo!.versionCode})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(Icons.storage, '${_result!.extractedFiles.length} files'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.memory, '${_apkInfo?.dexFiles.length ?? 0} dex'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.security, '${_apkInfo?.permissions.length ?? 0} permissions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          _buildTab('组件', 0, Icons.widgets),
          _buildTab('权限', 1, Icons.security),
          _buildTab('资源', 2, Icons.folder),
          _buildTab('文件', 3, Icons.insert_drive_file),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildComponentsTab();
      case 1:
        return _buildPermissionsTab();
      case 2:
        return _buildResourcesTab();
      case 3:
        return _buildFilesTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildComponentsTab() {
    final components = [
      ...(_apkInfo?.activities ?? []).map((a) => _ComponentItem('Activity', a)),
      ...(_apkInfo?.services ?? []).map((s) => _ComponentItem('Service', s)),
      ...(_apkInfo?.receivers ?? []).map((r) => _ComponentItem('Receiver', r)),
      ...(_apkInfo?.providers ?? []).map((p) => _ComponentItem('Provider', p)),
    ];

    if (components.isEmpty) {
      return const Center(child: Text('No components found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final item = components[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getComponentColor(item.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getComponentIcon(item.type),
                color: _getComponentColor(item.type),
                size: 20,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              item.type,
              style: TextStyle(
                fontSize: 12,
                color: _getComponentColor(item.type),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionsTab() {
    final permissions = _apkInfo?.permissions ?? [];

    if (permissions.isEmpty) {
      return const Center(child: Text('No permissions found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        final shortName = permission.split('.').last;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              shortName,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              permission,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    final resources = _apkInfo?.resources ?? [];

    if (resources.isEmpty) {
      return const Center(child: Text('No resources found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final fileName = FileUtils.getFileName(resource);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getResourceIcon(resource),
              color: const Color(0xFF6366F1),
            ),
            title: Text(
              fileName,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              resource,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 打开资源文件
            },
          ),
        );
      },
    );
  }

  Widget _buildFilesTab() {
    final files = _result?.extractedFiles ?? [];

    if (files.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    // 按类型分组
    final smaliFiles = files.where((f) => f.endsWith('.smali')).toList();
    final dexFiles = files.where((f) => f.endsWith('.dex')).toList();
    final xmlFiles = files.where((f) => f.endsWith('.xml')).toList();
    final otherFiles = files.where((f) => 
      !f.endsWith('.smali') && !f.endsWith('.dex') && !f.endsWith('.xml')
    ).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dexFiles.isNotEmpty)
          _buildFileSection('DEX Files', dexFiles, Icons.memory, const Color(0xFF8B5CF6)),
        if (smaliFiles.isNotEmpty)
          _buildFileSection('Smali Files', smaliFiles.take(20).toList(), Icons.code, const Color(0xFF3B82F6)),
        if (xmlFiles.isNotEmpty)
          _buildFileSection('XML Files', xmlFiles.take(20).toList(), Icons.data_object, const Color(0xFFF97316)),
        if (otherFiles.isNotEmpty)
          _buildFileSection('Other Files', otherFiles.take(20).toList(), Icons.insert_drive_file, Colors.grey),
      ],
    );
  }

  Widget _buildFileSection(String title, List<String> files, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                '$title (${files.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ...files.map((f) => Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            dense: true,
            title: Text(
              f,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              context.go('${AppRoutes.editor}?path=${Uri.encodeComponent('${_result!.outputPath}/$f')}');
            },
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'Activity':
        return Icons.android;
      case 'Service':
        return Icons.settings_applications;
      case 'Receiver':
        return Icons.notifications;
      case 'Provider':
        return Icons.storage;
      default:
        return Icons.widgets;
    }
  }

  Color _getComponentColor(String type) {
    switch (type) {
      case 'Activity':
        return const Color(0xFF10B981);
      case 'Service':
        return const Color(0xFF6366F1);
      case 'Receiver':
        return const Color(0xFFF59E0B);
      case 'Provider':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceIcon(String path) {
    final ext = FileUtils.getExtension(path);
    switch (ext) {
      case '.xml':
        return Icons.data_object;
      case '.png':
      case '.jpg':
      case '.jpeg':
        return Icons.image;
      case '.svg':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _ComponentItem {
  final String type;
  final String name;
  
  _ComponentItem(this.type, this.name);
}
