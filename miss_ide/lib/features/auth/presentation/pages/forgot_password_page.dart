// lib/features/auth/presentation/pages/forgot_password_page.dart - 忘记密码页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/validators/validators.dart';
import '../domain/auth_service.dart';
import '../data/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onResetSuccess;

  const ForgotPasswordPage({
    super.key,
    this.onBack,
    this.onResetSuccess,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _verifyCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = LocalAuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _resetMethod = 'phone'; // 'phone', 'email'
  int _step = 1; // 1: 输入账号, 2: 验证, 3: 重置密码
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _verifyCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendVerifyCode() async {
    final contact = _resetMethod == 'phone'
        ? _phoneController.text.trim()
        : _emailController.text.trim();

    if (_resetMethod == 'phone' && !PhoneValidator.isValid(contact)) {
      _showError('请输入有效的手机号');
      return;
    }

    if (_resetMethod == 'email' && !EmailValidator.isValid(contact)) {
      _showError('请输入有效的邮箱地址');
      return;
    }

    setState(() => _isLoading = true);

    final result = _resetMethod == 'phone'
        ? await _authService.forgotPasswordByPhone(contact, '')
        : await _authService.forgotPasswordByEmail(contact);

    setState(() => _isLoading = false);

    if (result.success) {
      setState(() {
        _countdown = 60;
        _step = 2;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证码已发送到${_resetMethod == 'phone' ? '手机' : '邮箱'}')),
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

  Future<void> _verifyCode() async {
    if (_verifyCodeController.text.length != 6) {
      _showError('请输入6位验证码');
      return;
    }

    final contact = _resetMethod == 'phone'
        ? _phoneController.text.trim()
        : _emailController.text.trim();

    bool verified;
    if (_resetMethod == 'phone') {
      verified = await _authService.verifySmsCode(contact, _verifyCodeController.text);
    } else {
      verified = await _authService.verifyEmailCode(contact, _verifyCodeController.text);
    }

    if (verified) {
      setState(() => _step = 3);
    } else {
      _showError('验证码错误或已过期');
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(
      token: 'reset_token',
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      widget.onResetSuccess?.call();
    } else {
      _showError(result.error ?? '重置失败');
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
        title: const Text('找回密码'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
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
                // 步骤指示
                _StepIndicator(currentStep: _step, totalSteps: 3),
                const SizedBox(height: 32),

                if (_step == 1) ...[
                  // 步骤1: 输入账号
                  Text(
                    '请输入您的${_resetMethod == 'phone' ? '手机号' : '邮箱'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  if (_resetMethod == 'phone')
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _isLoading ? null : _sendVerifyCode,
                    child: const Text('下一步'),
                  ),
                ] else if (_step == 2) ...[
                  // 步骤2: 输入验证码
                  Text(
                    '请输入发送到${_resetMethod == 'phone' ? _phoneController.text : _emailController.text}的验证码',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

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
                          _countdown > 0 ? '${_countdown}s' : '重新发送',
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

                  FilledButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    child: const Text('验证'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('返回'),
                  ),
                ] else ...[
                  // 步骤3: 设置新密码
                  Text(
                    '请设置您的新密码',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '新密码',
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入新密码';
                      }
                      if (!PasswordValidator.isValid(value)) {
                        return '密码至少8位，需包含数字和字母';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '确认密码',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('完成'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => setState(() => _step = 2),
                    child: const Text('返回'),
                  ),
                ],

                const SizedBox(height: 16),

                // 重置方式切换
                TextButton(
                  onPressed: () {
                    setState(() {
                      _resetMethod = _resetMethod == 'phone' ? 'email' : 'phone';
                      _step = 1;
                    });
                  },
                  child: Text(
                    '使用${_resetMethod == 'phone' ? '邮箱' : '手机号'}找回',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final stepNum = index + 1;
        final isActive = stepNum <= currentStep;
        final isCompleted = stepNum < currentStep;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '$stepNum',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: stepNum < currentStep
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
