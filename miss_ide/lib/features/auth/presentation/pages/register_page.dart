// lib/features/auth/presentation/pages/register_page.dart - 注册页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/validators/validators.dart';
import '../domain/auth_service.dart';
import '../data/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;
  final VoidCallback? onLoginTap;

  const RegisterPage({
    super.key,
    this.onRegisterSuccess,
    this.onLoginTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verifyCodeController = TextEditingController();
  final _authService = LocalAuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _registerMethod = 'phone'; // 'phone', 'email'
  String _verifyCode = '';
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verifyCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerifyCode() async {
    final contact = _registerMethod == 'phone'
        ? _phoneController.text.trim()
        : _emailController.text.trim();

    if (_registerMethod == 'phone' && !PhoneValidator.isValid(contact)) {
      _showError('请输入有效的手机号');
      return;
    }

    if (_registerMethod == 'email' && !EmailValidator.isValid(contact)) {
      _showError('请输入有效的邮箱地址');
      return;
    }

    setState(() => _isLoading = true);

    final result = _registerMethod == 'phone'
        ? await _authService.sendSmsCode(contact)
        : await _authService.sendEmailCode(contact);

    setState(() => _isLoading = false);

    if (result.success) {
      setState(() {
        _countdown = 60;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证码已发送到${_registerMethod == 'phone' ? '手机' : '邮箱'}')),
      );
    } else {
      _showError(result.error ?? '发送失败');
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    AuthResult result;

    if (_registerMethod == 'phone') {
      result = await _authService.registerWithPhone(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        verifyCode: _verifyCodeController.text,
      );
    } else {
      result = await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        verifyCode: _verifyCodeController.text,
      );
    }

    setState(() => _isLoading = false);

    if (result.success) {
      widget.onRegisterSuccess?.call();
    } else {
      _showError(result.error ?? '注册失败');
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
      appBar: AppBar(
        title: const Text('注册'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onLoginTap,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 注册方式切换
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'phone', label: Text('手机号注册')),
                    ButtonSegment(value: 'email', label: Text('邮箱注册')),
                  ],
                  selected: {_registerMethod},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _registerMethod = selection.first;
                      _verifyCodeController.clear();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 手机号/邮箱输入
                if (_registerMethod == 'phone')
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: '手机号',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (!PhoneValidator.isValid(value)) {
                        return '请输入有效的手机号';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!EmailValidator.isValid(value)) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),

                // 密码输入
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                    helperText: '至少8位，包含数字和字母',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (!PasswordValidator.isValid(value)) {
                      return '密码至少8位，需包含数字和字母';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // 密码强度指示
                _PasswordStrengthIndicator(
                  password: _passwordController.text,
                ),
                const SizedBox(height: 16),

                // 确认密码
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 验证码
                TextFormField(
                  controller: _verifyCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    labelText: '验证码',
                    prefixIcon: const Icon(Icons.sms),
                    suffixIcon: TextButton(
                      onPressed: _countdown > 0 || _isLoading ? null : _sendVerifyCode,
                      child: Text(
                        _countdown > 0 ? '${_countdown}s后重试' : '获取验证码',
                      ),
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
                const SizedBox(height: 24),

                // 注册按钮
                FilledButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('注册'),
                ),
                const SizedBox(height: 16),

                // 服务条款
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (value) {},
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: '我已阅读并同意',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          children: [
                            TextSpan(
                              text: '《用户协议》',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const TextSpan(text: '和'),
                            TextSpan(
                              text: '《隐私政策》',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 登录入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '已有账号？',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: widget.onLoginTap,
                      child: const Text('立即登录'),
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
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = PasswordValidator.getStrength(password);
    final strengthText = PasswordValidator.getStrengthText(password);

    Color color;
    switch (strength) {
      case PasswordValidator.strengthWeak:
        color = Colors.red;
        break;
      case PasswordValidator.strengthMedium:
        color = Colors.orange;
        break;
      case PasswordValidator.strengthStrong:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 3,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthText,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
