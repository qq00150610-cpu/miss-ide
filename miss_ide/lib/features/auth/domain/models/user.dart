// lib/features/auth/domain/models/user.dart - 用户模型
import 'package:equatable/equatable.dart';

/// 用户角色
enum UserRole {
  user,
  vip,
  admin,
}

/// 用户状态
enum UserStatus {
  active,
  disabled,
  banned,
}

/// 登录方式
enum LoginType {
  phone,
  email,
  wechat,
  apple,
  google,
}

/// 用户模型
class User extends Equatable {
  final String id;
  final String? phone;
  final String? email;
  final String? nickname;
  final String? avatar;
  final UserRole role;
  final UserStatus status;
  final String? wechatOpenid;
  final String? wechatUnionid;
  final String? appleId;
  final String? googleId;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    this.phone,
    this.email,
    this.nickname,
    this.avatar,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.wechatOpenid,
    this.wechatUnionid,
    this.appleId,
    this.googleId,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.lastLoginAt,
    this.lastLoginIp,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isVip => role == UserRole.vip;
  bool get isActive => status == UserStatus.active;

  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? nickname,
    String? avatar,
    UserRole? role,
    UserStatus? status,
    String? wechatOpenid,
    String? wechatUnionid,
    String? appleId,
    String? googleId,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      status: status ?? this.status,
      wechatOpenid: wechatOpenid ?? this.wechatOpenid,
      wechatUnionid: wechatUnionid ?? this.wechatUnionid,
      appleId: appleId ?? this.appleId,
      googleId: googleId ?? this.googleId,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'email': email,
    'nickname': nickname,
    'avatar': avatar,
    'role': role.name,
    'status': status.name,
    'wechatOpenid': wechatOpenid,
    'wechatUnionid': wechatUnionid,
    'appleId': appleId,
    'googleId': googleId,
    'emailVerified': emailVerified,
    'phoneVerified': phoneVerified,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'lastLoginIp': lastLoginIp,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      wechatOpenid: json['wechatOpenid'] as String?,
      wechatUnionid: json['wechatUnionid'] as String?,
      appleId: json['appleId'] as String?,
      googleId: json['googleId'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      lastLoginIp: json['lastLoginIp'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id, phone, email, nickname, avatar, role, status,
    wechatOpenid, wechatUnionid, appleId, googleId,
    emailVerified, phoneVerified, lastLoginAt, lastLoginIp,
    createdAt, updatedAt,
  ];
}

/// 用户绑定邮箱
class UserEmail extends Equatable {
  final String id;
  final String userId;
  final String email;
  final bool isPrimary;
  final bool verified;
  final DateTime createdAt;

  const UserEmail({
    required this.id,
    required this.userId,
    required this.email,
    this.isPrimary = false,
    this.verified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'email': email,
    'isPrimary': isPrimary,
    'verified': verified,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserEmail.fromJson(Map<String, dynamic> json) {
    return UserEmail(
      id: json['id'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, email, isPrimary, verified, createdAt];
}

/// 登录日志
class LoginLog extends Equatable {
  final String id;
  final String userId;
  final LoginType loginType;
  final String ipAddress;
  final String? deviceInfo;
  final DateTime createdAt;

  const LoginLog({
    required this.id,
    required this.userId,
    required this.loginType,
    required this.ipAddress,
    this.deviceInfo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'loginType': loginType.name,
    'ipAddress': ipAddress,
    'deviceInfo': deviceInfo,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LoginLog.fromJson(Map<String, dynamic> json) {
    return LoginLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      loginType: LoginType.values.firstWhere(
        (e) => e.name == json['loginType'],
        orElse: () => LoginType.email,
      ),
      ipAddress: json['ipAddress'] as String,
      deviceInfo: json['deviceInfo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, loginType, ipAddress, deviceInfo, createdAt];
}
