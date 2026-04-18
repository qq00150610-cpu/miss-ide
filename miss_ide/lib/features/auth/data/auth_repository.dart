// lib/features/auth/data/auth_repository.dart - 认证数据仓库
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user.dart';
import '../domain/auth_service.dart';

/// 本地认证服务实现
class LocalAuthRepository implements AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'current_user';
  static const _smsCodeKey = 'sms_code_';
  static const _emailCodeKey = 'email_code_';

  User? _currentUser;
  String? _token;
  final _authStateController = StreamController<User?>.broadcast();

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _token != null && _currentUser != null;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  LocalAuthRepository() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      _authStateController.add(_currentUser);
    }
  }

  Future<void> _saveAuth(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _token = token;
    _currentUser = user;
    _authStateController.add(_currentUser);
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<AuthResult> registerWithPhone({
    required String phone,
    required String password,
    required String verifyCode,
  }) async {
    // 验证验证码
    if (!await verifySmsCode(phone, verifyCode)) {
      return const AuthResult(
        success: false,
        error: '验证码错误或已过期',
      );
    }

    // 模拟注册成功
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      phone: phone,
      nickname: '用户${phone.substring(phone.length - 4)}',
      phoneVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const token = 'mock_token_register_phone';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String verifyCode,
  }) async {
    if (!await verifyEmailCode(email, verifyCode)) {
      return const AuthResult(
        success: false,
        error: '验证码错误或已过期',
      );
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      nickname: email.split('@').first,
      emailVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const token = 'mock_token_register_email';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    // 模拟登录
    final user = User(
      id: 'mock_user_id',
      phone: phone,
      nickname: '用户${phone.substring(phone.length - 4)}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    const token = 'mock_token_login_phone';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> loginWithPhoneCode({
    required String phone,
    required String verifyCode,
  }) async {
    if (!await verifySmsCode(phone, verifyCode)) {
      return const AuthResult(
        success: false,
        error: '验证码错误或已过期',
      );
    }

    final user = User(
      id: 'mock_user_id',
      phone: phone,
      nickname: '用户${phone.substring(phone.length - 4)}',
      phoneVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    const token = 'mock_token_login_phone_code';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final user = User(
      id: 'mock_user_id',
      email: email,
      nickname: email.split('@').first,
      emailVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    const token = 'mock_token_login_email';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> loginWithWechat(String code) async {
    // 模拟微信登录
    final user = User(
      id: 'mock_wechat_user_id',
      nickname: '微信用户',
      wechatOpenid: 'mock_openid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const token = 'mock_token_wechat';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> loginWithApple(String identityToken, String authorizationCode) async {
    final user = User(
      id: 'mock_apple_user_id',
      nickname: 'Apple 用户',
      appleId: 'mock_apple_id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const token = 'mock_token_apple';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<AuthResult> loginWithGoogle(String idToken) async {
    final user = User(
      id: 'mock_google_user_id',
      nickname: 'Google 用户',
      googleId: 'mock_google_id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const token = 'mock_token_google';
    await _saveAuth(user, token);
    return AuthResult(success: true, user: user, token: token);
  }

  @override
  Future<void> signOut() async {
    await _clearAuth();
  }

  @override
  Future<SendCodeResult> sendSmsCode(String phone) async {
    // 生成4位验证码
    final code = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    
    // 存储验证码（实际应该发送到服务器）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_smsCodeKey$phone', code);
    await prefs.setString('${_smsCodeKey}${phone}_time', DateTime.now().add(const Duration(minutes: 5)).toIso8601String());
    
    // 实际应该调用短信API发送
    return SendCodeResult(
      success: true,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  @override
  Future<SendCodeResult> sendEmailCode(String email) async {
    final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_emailCodeKey$email', code);
    await prefs.setString('${_emailCodeKey}${email}_time', DateTime.now().add(const Duration(minutes: 30)).toIso8601String());
    
    // 实际应该调用邮件API发送
    return SendCodeResult(
      success: true,
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<bool> verifySmsCode(String phone, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString('$_smsCodeKey$phone');
    final expiryStr = prefs.getString('${_smsCodeKey}${phone}_time');
    
    if (storedCode == null || expiryStr == null) {
      return code == '123456'; // 测试用固定验证码
    }
    
    final expiry = DateTime.parse(expiryStr);
    if (DateTime.now().isAfter(expiry)) {
      return false;
    }
    
    return storedCode == code || code == '123456'; // 测试用
  }

  @override
  Future<bool> verifyEmailCode(String email, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString('$_emailCodeKey$email');
    final expiryStr = prefs.getString('${_emailCodeKey${email}}_time');
    
    if (storedCode == null || expiryStr == null) {
      return code == '123456';
    }
    
    final expiry = DateTime.parse(expiryStr);
    if (DateTime.now().isAfter(expiry)) {
      return false;
    }
    
    return storedCode == code || code == '123456';
  }

  @override
  Future<ResetPasswordResult> forgotPasswordByEmail(String email) async {
    await sendEmailCode(email);
    return const ResetPasswordResult(success: true);
  }

  @override
  Future<ResetPasswordResult> forgotPasswordByPhone(String phone, String verifyCode) async {
    if (!await verifySmsCode(phone, verifyCode)) {
      return const ResetPasswordResult(success: false, error: '验证码错误');
    }
    return const ResetPasswordResult(success: true);
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    // 实际应该验证token并更新密码
    return const ResetPasswordResult(success: true);
  }

  @override
  Future<bool> bindEmail(String email, String verifyCode) async {
    if (!await verifyEmailCode(email, verifyCode)) {
      return false;
    }
    
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        email: email,
        emailVerified: true,
        updatedAt: DateTime.now(),
      );
      await _saveAuth(_currentUser!, _token!);
    }
    return true;
  }

  @override
  Future<bool> unbindEmail(String email) async {
    // 解绑邮箱需要验证
    return true;
  }

  @override
  Future<User?> getUserProfile() async {
    return _currentUser;
  }

  @override
  Future<User?> updateProfile({
    String? nickname,
    String? avatar,
  }) async {
    if (_currentUser == null) return null;
    
    _currentUser = _currentUser!.copyWith(
      nickname: nickname ?? _currentUser!.nickname,
      avatar: avatar ?? _currentUser!.avatar,
      updatedAt: DateTime.now(),
    );
    
    await _saveAuth(_currentUser!, _token!);
    return _currentUser;
  }

  @override
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // 验证旧密码并更新
    return true;
  }

  @override
  Future<List<LoginLog>> getLoginLogs() async {
    // 返回模拟数据
    return [
      LoginLog(
        id: '1',
        userId: _currentUser?.id ?? '',
        loginType: LoginType.email,
        ipAddress: '127.0.0.1',
        deviceInfo: 'Android 14',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LoginLog(
        id: '2',
        userId: _currentUser?.id ?? '',
        loginType: LoginType.wechat,
        ipAddress: '192.168.1.1',
        deviceInfo: 'Android 13',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<bool> linkAccount(LoginType type, String token) async {
    // 绑定第三方账号
    return true;
  }

  void dispose() {
    _authStateController.close();
  }
}
