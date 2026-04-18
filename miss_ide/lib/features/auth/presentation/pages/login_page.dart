// lib/features/auth/presentation/pages/login_page.dart - 登录页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/validators/validators.dart';
import '../domain/auth_service.dart';
import '../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  const LoginPage({
    super.key,
    this.onLoginSuccess,
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = LocalAuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _loginMethod = 'phone'; // 'phone', 'email', 'sms'

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    AuthResult result;

    if (_loginMethod == 'email') {
      result = await _authService.loginWithEmail(
        email: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    } else if (_loginMethod == 'sms') {
      result = await _authService.loginWithPhoneCode(
        phone: _phoneController.text.trim(),
        verifyCode: _passwordController.text,
      );
    } else {
      result = await _authService.loginWithPhone(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (result.success) {
      widget.onLoginSuccess?.call();
    } else {
      _showError(result.error ?? '登录失败');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo
                Icon(
                  Icons.android,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Miss IDE',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Android 反编译与分析工具',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // 登录方式切换
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'phone', label: Text('手机号')),
                    ButtonSegment(value: 'email', label: Text('邮箱')),
                    ButtonSegment(value: 'sms', label: Text('验证码')),
                  ],
                  selected: {_loginMethod},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _loginMethod = selection.first;
                      _passwordController.clear();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 手机号/邮箱输入
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+@.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: _loginMethod == 'email' ? '邮箱' : '手机号',
                    prefixIcon: Icon(
                      _loginMethod == 'email' ? Icons.email : Icons.phone,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入${_loginMethod == 'email' ? '邮箱' : '手机号'}';
                    }
                    if (_loginMethod == 'email') {
                      if (!EmailValidator.isValid(value)) {
                        return '请输入有效的邮箱地址';
                      }
                    } else {
                      if (!PhoneValidator.isValid(value)) {
                        return '请输入有效的手机号';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码/验证码输入
                if (_loginMethod != 'sms')
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码至少6位';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _passwordController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      labelText: '验证码',
                      prefixIcon: const Icon(Icons.sms),
                      suffixIcon: TextButton(
                        onPressed: () async {
                          if (!PhoneValidator.isValid(_phoneController.text)) {
                            _showError('请输入有效的手机号');
                            return;
                          }
                          final result = await _authService.sendSmsCode(
                            _phoneController.text.trim(),
                          );
                          if (result.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('验证码已发送')),
                            );
                          }
                        },
                        child: const Text('获取验证码'),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return '请输入6位验证码';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 8),

                // 忘记密码
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onForgotPasswordTap,
                    child: const Text('忘记密码？'),
                  ),
                ),
                const SizedBox(height: 16),

                // 登录按钮
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('登录'),
                ),
                const SizedBox(height: 24),

                // 第三方登录
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '其他登录方式',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialLoginButton(
                      icon: Icons.wechat,
                      label: '微信',
                      color: const Color(0xFF07C160),
                      onTap: () => _handleWechatLogin(),
                    ),
                    const SizedBox(width: 16),
                    _SocialLoginButton(
                      icon: Icons.apple,
                      label: 'Apple',
                      color: Colors.black,
                      onTap: () => _handleAppleLogin(),
                    ),
                    const SizedBox(width: 16),
                    _SocialLoginButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      color: const Color(0xFF4285F4),
                      onTap: () => _handleGoogleLogin(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 注册入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: widget.onRegisterTap,
                      child: const Text('立即注册'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleWechatLogin() async {
    // 实际实现需要调用微信SDK
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('微信登录开发中')),
    );
  }

  Future<void> _handleAppleLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple登录开发中')),
    );
  }

  Future<void> _handleGoogleLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google登录开发中')),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
