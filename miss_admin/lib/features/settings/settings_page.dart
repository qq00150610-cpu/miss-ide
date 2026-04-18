// lib/features/settings/settings_page.dart - 系统设置页面
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统设置',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // 基础设置
            _SettingsSection(
              title: '基础设置',
              children: [
                _SettingsTile(
                  icon: Icons.site,
                  title: '网站信息',
                  subtitle: '配置网站名称、Logo等基本信息',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.email,
                  title: '邮件设置',
                  subtitle: '配置邮件服务器和发送规则',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.sms,
                  title: '短信设置',
                  subtitle: '配置短信服务商和模板',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 安全设置
            _SettingsSection(
              title: '安全设置',
              children: [
                _SettingsTile(
                  icon: Icons.password,
                  title: '密码策略',
                  subtitle: '配置密码强度和过期策略',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.security,
                  title: '登录限制',
                  subtitle: '配置登录失败次数限制',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.verified_user,
                  title: '双因素认证',
                  subtitle: '启用或禁用双因素认证',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 通知设置
            _SettingsSection(
              title: '通知设置',
              children: [
                _SettingsTile(
                  icon: Icons.notifications,
                  title: '推送通知',
                  subtitle: '配置应用内推送通知',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.campaign,
                  title: '公告管理',
                  subtitle: '创建和管理系统公告',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 备份设置
            _SettingsSection(
              title: '备份与恢复',
              children: [
                _SettingsTile(
                  icon: Icons.backup,
                  title: '数据备份',
                  subtitle: '手动备份系统数据',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.restore,
                  title: '数据恢复',
                  subtitle: '从备份恢复系统数据',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 关于
            _SettingsSection(
              title: '关于',
              children: [
                _SettingsTile(
                  icon: Icons.info,
                  title: '关于系统',
                  subtitle: 'Miss IDE Admin v1.0.0',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.description,
                  title: '使用文档',
                  subtitle: '查看系统使用文档',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
