// lib/features/users/user_list_page.dart - 用户列表页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _searchController = TextEditingController();
  String _filterRole = '全部';
  String _filterStatus = '全部';
  String _filterLoginType = '全部';

  final List<_UserData> _users = List.generate(
    50,
    (index) => _UserData(
      id: 'user_$index',
      email: 'user$index@example.com',
      phone: '138****${1000 + index}',
      nickname: '用户$index',
      role: ['普通用户', 'VIP', '管理员'][index % 3],
      status: ['正常', '禁用', '封禁'][index % 3],
      loginType: ['手机', '邮箱', '微信', 'Apple', 'Google'][index % 5],
      createdAt: DateTime.now().subtract(Duration(days: index)),
      lastLoginAt: DateTime.now().subtract(Duration(hours: index * 2)),
    ),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              '用户管理',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // 搜索和筛选
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '搜索用户邮箱/手机号/昵称',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.search),
                          label: const Text('搜索'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _FilterDropdown(
                          label: '角色',
                          value: _filterRole,
                          options: const ['全部', '普通用户', 'VIP', '管理员'],
                          onChanged: (value) {
                            setState(() => _filterRole = value!);
                          },
                        ),
                        const SizedBox(width: 16),
                        _FilterDropdown(
                          label: '状态',
                          value: _filterStatus,
                          options: const ['全部', '正常', '禁用', '封禁'],
                          onChanged: (value) {
                            setState(() => _filterStatus = value!);
                          },
                        ),
                        const SizedBox(width: 16),
                        _FilterDropdown(
                          label: '登录方式',
                          value: _filterLoginType,
                          options: const ['全部', '手机', '邮箱', '微信', 'Apple', 'Google'],
                          onChanged: (value) {
                            setState(() => _filterLoginType = value!);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 用户列表
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[100],
                      ),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('昵称')),
                        DataColumn(label: Text('邮箱')),
                        DataColumn(label: Text('手机号')),
                        DataColumn(label: Text('角色')),
                        DataColumn(label: Text('状态')),
                        DataColumn(label: Text('登录方式')),
                        DataColumn(label: Text('注册时间')),
                        DataColumn(label: Text('最后登录')),
                        DataColumn(label: Text('操作')),
                      ],
                      rows: _users.map((user) => DataRow(
                        cells: [
                          DataCell(Text(user.id)),
                          DataCell(Text(user.nickname)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.phone)),
                          DataCell(_RoleChip(role: user.role)),
                          DataCell(_StatusChip(status: user.status)),
                          DataCell(Text(user.loginType)),
                          DataCell(Text(_formatDate(user.createdAt))),
                          DataCell(Text(_formatDateTime(user.lastLoginAt))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => context.go('/users/${user.id}'),
                                tooltip: '查看详情',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(user),
                                tooltip: '编辑',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteDialog(user),
                                tooltip: '删除',
                              ),
                            ],
                          )),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showEditDialog(_UserData user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑用户 ${user.nickname}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: user.role,
              decoration: const InputDecoration(labelText: '角色'),
              items: const [
                DropdownMenuItem(value: '普通用户', child: Text('普通用户')),
                DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                DropdownMenuItem(value: '管理员', child: Text('管理员')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: user.status,
              decoration: const InputDecoration(labelText: '状态'),
              items: const [
                DropdownMenuItem(value: '正常', child: Text('正常')),
                DropdownMenuItem(value: '禁用', child: Text('禁用')),
                DropdownMenuItem(value: '封禁', child: Text('封禁')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(_UserData user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除用户 ${user.nickname} 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _UserData {
  final String id;
  final String email;
  final String phone;
  final String nickname;
  final String role;
  final String status;
  final String loginType;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  _UserData({
    required this.id,
    required this.email,
    required this.phone,
    required this.nickname,
    required this.role,
    required this.status,
    required this.loginType,
    required this.createdAt,
    required this.lastLoginAt,
  });
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: '),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: value,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case '管理员':
        color = Colors.red;
        break;
      case 'VIP':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(role, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case '正常':
        color = Colors.green;
        break;
      case '禁用':
        color = Colors.orange;
        break;
      case '封禁':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}
