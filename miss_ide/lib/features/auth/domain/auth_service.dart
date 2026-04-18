// lib/features/auth/domain/auth_service.dart - 认证服务
import 'dart:async';
import '../domain/models/user.dart';

/// 认证结果
class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  const AuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });
}

/// 发送验证码结果
class SendCodeResult {
  final bool success;
  final String? error;
  final DateTime? expiresAt;

  const SendCodeResult({
    required this.success,
    this.error,
    this.expiresAt,
  });
}

/// 重置密码结果
class ResetPasswordResult {
  final bool success;
  final String? error;

  const ResetPasswordResult({
    required this.success,
    this.error,
  });
}

/// 认证服务接口
abstract class AuthService {
  /// 获取当前用户
  User? get currentUser;

  /// 是否已登录
  bool get isLoggedIn;

  /// 认证状态流
  Stream<User?> get authStateChanges;

  /// 手机号注册
  Future<AuthResult> registerWithPhone({
    required String phone,
    required String password,
    required String verifyCode,
  });

  /// 邮箱注册
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String verifyCode,
  });

  /// 手机号登录
  Future<AuthResult> loginWithPhone({
    required String phone,
    required String password,
  });

  /// 手机号验证码登录
  Future<AuthResult> loginWithPhoneCode({
    required String phone,
    required String verifyCode,
  });

  /// 邮箱登录
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  /// 微信登录
  Future<AuthResult> loginWithWechat(String code);

  /// 苹果登录
  Future<AuthResult> loginWithApple(String identityToken, String authorizationCode);

  /// 谷歌登录
  Future<AuthResult> loginWithGoogle(String idToken);

  /// 登出
  Future<void> signOut();

  /// 发送短信验证码
  Future<SendCodeResult> sendSmsCode(String phone);

  /// 发送邮箱验证码
  Future<SendCodeResult> sendEmailCode(String email);

  /// 验证短信验证码
  Future<bool> verifySmsCode(String phone, String code);

  /// 验证邮箱验证码
  Future<bool> verifyEmailCode(String email, String code);

  /// 忘记密码 - 邮箱
  Future<ResetPasswordResult> forgotPasswordByEmail(String email);

  /// 忘记密码 - 手机
  Future<ResetPasswordResult> forgotPasswordByPhone(String phone, String verifyCode);

  /// 重置密码
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
  });

  /// 绑定邮箱
  Future<bool> bindEmail(String email, String verifyCode);

  /// 解绑邮箱
  Future<bool> unbindEmail(String email);

  /// 获取用户信息
  Future<User?> getUserProfile();

  /// 更新用户信息
  Future<User?> updateProfile({
    String? nickname,
    String? avatar,
  });

  /// 更改密码
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// 获取登录日志
  Future<List<LoginLog>> getLoginLogs();

  /// 绑定第三方账号
  Future<bool> linkAccount(LoginType type, String token);
}
