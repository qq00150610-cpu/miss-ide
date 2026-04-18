// lib/features/users/user_detail_page.dart - 用户详情页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // 模拟用户数据
    final user = _MockUser(
      id: userId,
      email: 'user@example.com',
      phone: '138****1234',
      nickname: '示例用户',
      avatar: null,
      role: 'VIP',
      status: '正常',
      emailVerified: true,
      phoneVerified: true,
      wechatBounded: true,
      appleBounded: false,
      googleBounded: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastLoginIp: '192.168.1.1',
      lastLoginDevice: 'Android 14',
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 返回按钮
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/users'),
                ),
                const SizedBox(width: 8),
                Text(
                  '用户详情',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：基本信息
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(title: '基本信息'),
                          const Divider(),
                          _InfoRow(label: '用户ID', value: user.id),
                          _InfoRow(label: '昵称', value: user.nickname),
                          _InfoRow(label: '邮箱', value: user.email),
                          _InfoRow(label: '手机号', value: user.phone),
                          _InfoRow(label: '角色', value: user.role),
                          _InfoRow(label: '状态', value: user.status),
                          _InfoRow(
                            label: '注册时间',
                            value: DateFormat('yyyy-MM-dd HH:mm').format(user.createdAt),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () => _showEditDialog(context),
                                icon: const Icon(Icons.edit),
                                label: const Text('编辑'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.security),
                                label: const Text('重置密码'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 右侧：账号绑定
                Expanded(
                  child: Column(
                    children: [
                      // 绑定信息
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: '账号绑定'),
                              const Divider(),
                              _BindingRow(
                                icon: Icons.email,
                                name: '邮箱',
                                value: user.email,
                                verified: user.emailVerified,
                              ),
                              _BindingRow(
                                icon: Icons.phone,
                                name: '手机号',
                                value: user.phone,
                                verified: user.phoneVerified,
                              ),
                              _BindingRow(
                                icon: Icons.wechat,
                                name: '微信',
                                value: '已绑定',
                                verified: user.wechatBounded,
                              ),
                              _BindingRow(
                                icon: Icons.apple,
                                name: 'Apple',
                                value: user.appleBounded ? '已绑定' : '未绑定',
                                verified: user.appleBounded,
                              ),
                              _BindingRow(
                                icon: Icons.g_mobiledata,
                                name: 'Google',
                                value: user.googleBounded ? '已绑定' : '未绑定',
                                verified: user.googleBounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 安全信息
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: '最近登录'),
                              const Divider(),
                              _InfoRow(
                                label: '登录时间',
                                value: DateFormat('yyyy-MM-dd HH:mm').format(user.lastLoginAt),
                              ),
                              _InfoRow(label: '登录IP', value: user.lastLoginIp),
                              _InfoRow(label: '登录设备', value: user.lastLoginDevice),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 登录日志
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: '登录日志'),
                    const Divider(),
                    _LoginLogTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑用户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: '昵称'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'VIP',
              decoration: const InputDecoration(labelText: '角色'),
              items: const [
                DropdownMenuItem(value: '普通用户', child: Text('普通用户')),
                DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                DropdownMenuItem(value: '管理员', child: Text('管理员')),
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
}

class _MockUser {
  final String id;
  final String email;
  final String phone;
  final String nickname;
  final String? avatar;
  final String role;
  final String status;
  final bool emailVerified;
  final bool phoneVerified;
  final bool wechatBounded;
  final bool appleBounded;
  final bool googleBounded;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String lastLoginIp;
  final String lastLoginDevice;

  _MockUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.nickname,
    this.avatar,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.phoneVerified,
    required this.wechatBounded,
    required this.appleBounded,
    required this.googleBounded,
    required this.createdAt,
    required this.lastLoginAt,
    required this.lastLoginIp,
    required this.lastLoginDevice,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _BindingRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String value;
  final bool verified;

  const _BindingRow({
    required this.icon,
    required this.name,
    required this.value,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(name),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 8),
          Icon(
            verified ? Icons.check_circle : Icons.error,
            color: verified ? Colors.green : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _LoginLogTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          children: const [
            _TableHeader('时间'),
            _TableHeader('方式'),
            _TableHeader('IP地址'),
            _TableHeader('设备'),
          ],
        ),
        ...List.generate(5, (index) => TableRow(
          children: [
            _TableCell(DateFormat('yyyy-MM-dd HH:mm').format(
              DateTime.now().subtract(Duration(hours: index * 2)),
            )),
            _TableCell(['邮箱', '微信', 'Apple', 'Google', '手机'][index]),
            _TableCell('192.168.1.${100 + index}'),
            _TableCell('Android 14'),
          ],
        )),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
