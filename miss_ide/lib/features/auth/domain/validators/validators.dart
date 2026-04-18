// lib/features/auth/domain/validators/validators.dart - 验证器
/// 手机号验证器
class PhoneValidator {
  static final _chinaMobileRegex = RegExp(r'^1[3-9]\d{9}$');
  static final _internationalRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

  /// 验证手机号格式
  static bool isValid(String phone, {bool allowInternational = true}) {
    if (phone.isEmpty) return false;
    
    // 中国大陆手机号
    if (_chinaMobileRegex.hasMatch(phone)) return true;
    
    // 国际手机号
    if (allowInternational && _internationalRegex.hasMatch(phone)) return true;
    
    return false;
  }

  /// 格式化手机号
  static String format(String phone) {
    // 移除空格和连字符
    var formatted = phone.replaceAll(RegExp(r'[\s\-]'), '');
    
    // 中国大陆手机号添加空格格式化
    if (formatted.length == 11 && _chinaMobileRegex.hasMatch(formatted)) {
      return '${formatted.substring(0, 3)} ${formatted.substring(3, 7)} ${formatted.substring(7)}';
    }
    
    return formatted;
  }

  /// 获取手机号归属地（简化版）
  static String? getCarrier(String phone) {
    if (phone.length != 11) return null;
    
    final prefix = phone.substring(0, 3);
    final carriers = {
      '134': '中国移动', '135': '中国移动', '136': '中国移动', '137': '中国移动',
      '138': '中国移动', '139': '中国移动', '147': '中国移动', '150': '中国移动',
      '151': '中国移动', '152': '中国移动', '157': '中国移动', '158': '中国移动',
      '159': '中国移动', '178': '中国移动', '182': '中国移动', '183': '中国移动',
      '184': '中国移动', '187': '中国移动', '188': '中国移动', '198': '中国移动',
      '130': '中国联通', '131': '中国联通', '132': '中国联通', '145': '中国联通',
      '155': '中国联通', '156': '中国联通', '166': '中国联通', '175': '中国联通',
      '176': '中国联通', '185': '中国联通', '186': '中国联通',
      '133': '中国电信', '149': '中国电信', '153': '中国电信', '173': '中国电信',
      '177': '中国电信', '180': '中国电信', '181': '中国电信', '189': '中国电信',
      '191': '中国电信', '199': '中国电信',
      '170': '虚拟运营商', '171': '虚拟运营商',
    };
    
    return carriers[prefix];
  }
}

/// 邮箱验证器
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// 验证邮箱格式
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email);
  }

  /// 获取邮箱域名
  static String? getDomain(String email) {
    if (!isValid(email)) return null;
    return email.split('@').last;
  }

  /// 隐藏邮箱中间部分
  static String mask(String email) {
    if (!isValid(email)) return email;
    
    final parts = email.split('@');
    final localPart = parts[0];
    final domain = parts[1];
    
    if (localPart.length <= 3) {
      return '${localPart[0]}***@$domain';
    }
    
    return '${localPart.substring(0, 3)}***@$domain';
  }
}

/// 密码验证器
class PasswordValidator {
  /// 密码强度等级
  static const int strengthWeak = 1;
  static const int strengthMedium = 2;
  static const int strengthStrong = 3;

  /// 验证密码强度
  static int getStrength(String password) {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    // 长度检查
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // 包含数字
    if (RegExp(r'\d').hasMatch(password)) score++;
    
    // 包含小写字母
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    
    // 包含大写字母
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    
    // 包含特殊字符
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    if (score <= 2) return strengthWeak;
    if (score <= 4) return strengthMedium;
    return strengthStrong;
  }

  /// 验证密码是否符合要求
  static bool isValid(String password, {
    int minLength = 8,
    bool requireNumber = true,
    bool requireLetter = true,
    bool requireSpecial = false,
  }) {
    if (password.length < minLength) return false;
    if (requireNumber && !RegExp(r'\d').hasMatch(password)) return false;
    if (requireLetter && !RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
    if (requireSpecial && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return false;
    }
    return true;
  }

  /// 获取密码强度描述
  static String getStrengthText(String password) {
    final strength = getStrength(password);
    switch (strength) {
      case strengthWeak:
        return '弱';
      case strengthMedium:
        return '中等';
      case strengthStrong:
        return '强';
      default:
        return '';
    }
  }
}

/// 验证码验证器
class VerificationCodeValidator {
  static final _codeRegex = RegExp(r'^\d{4,6}$');

  /// 验证验证码格式
  static bool isValid(String code) {
    if (code.isEmpty) return false;
    return _codeRegex.hasMatch(code);
  }
}
