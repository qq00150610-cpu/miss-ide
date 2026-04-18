-- Miss IDE 数据库初始化脚本
-- 数据库: MySQL 8.0+

-- 创建数据库
CREATE DATABASE IF NOT EXISTS miss_ide DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE miss_ide;

-- =====================================================
-- 用户表
-- =====================================================
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY COMMENT '用户ID',
    phone VARCHAR(20) UNIQUE COMMENT '手机号',
    email VARCHAR(100) UNIQUE COMMENT '邮箱',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar VARCHAR(255) COMMENT '头像URL',
    
    -- 用户角色和状态
    role ENUM('user', 'vip', 'admin') DEFAULT 'user' COMMENT '用户角色',
    status ENUM('active', 'disabled', 'banned') DEFAULT 'active' COMMENT '用户状态',
    
    -- 第三方登录
    wechat_openid VARCHAR(100) COMMENT '微信OpenID',
    wechat_unionid VARCHAR(100) COMMENT '微信UnionID',
    apple_id VARCHAR(100) COMMENT 'Apple ID',
    google_id VARCHAR(100) COMMENT 'Google ID',
    
    -- 验证状态
    email_verified BOOLEAN DEFAULT FALSE COMMENT '邮箱是否验证',
    phone_verified BOOLEAN DEFAULT FALSE COMMENT '手机是否验证',
    
    -- 安全信息
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '密码修改时间',
    last_login_at TIMESTAMP NULL COMMENT '最后登录时间',
    last_login_ip VARCHAR(45) COMMENT '最后登录IP',
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    -- 索引
    INDEX idx_phone (phone),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_role (role),
    INDEX idx_wechat_openid (wechat_openid),
    INDEX idx_apple_id (apple_id),
    INDEX idx_google_id (google_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- =====================================================
-- 用户邮箱表（支持多邮箱）
-- =====================================================
CREATE TABLE user_emails (
    id VARCHAR(36) PRIMARY KEY COMMENT '记录ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    email VARCHAR(100) NOT NULL COMMENT '邮箱地址',
    is_primary BOOLEAN DEFAULT FALSE COMMENT '是否主邮箱',
    verified BOOLEAN DEFAULT FALSE COMMENT '是否验证',
    verification_token VARCHAR(255) COMMENT '验证令牌',
    verification_expires_at TIMESTAMP NULL COMMENT '验证过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    UNIQUE INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户邮箱表';

-- =====================================================
-- 登录日志表
-- =====================================================
CREATE TABLE login_logs (
    id VARCHAR(36) PRIMARY KEY COMMENT '日志ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    login_type ENUM('phone', 'email', 'wechat', 'apple', 'google', 'sms_code') DEFAULT 'email' COMMENT '登录方式',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    device_info TEXT COMMENT '设备信息',
    user_agent VARCHAR(500) COMMENT 'User Agent',
    location VARCHAR(255) COMMENT '登录地点',
    success BOOLEAN DEFAULT TRUE COMMENT '是否成功',
    failure_reason VARCHAR(255) COMMENT '失败原因',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_login_type (login_type),
    INDEX idx_created_at (created_at),
    INDEX idx_ip_address (ip_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录日志表';

-- =====================================================
-- 验证码表
-- =====================================================
CREATE TABLE verification_codes (
    id VARCHAR(36) PRIMARY KEY COMMENT '记录ID',
    user_id VARCHAR(36) COMMENT '用户ID（可选）',
    code VARCHAR(10) NOT NULL COMMENT '验证码',
    type ENUM('register', 'login', 'forgot_password', 'bind_email', 'bind_phone') NOT NULL COMMENT '验证码类型',
    target VARCHAR(100) NOT NULL COMMENT '目标（手机号或邮箱）',
    used BOOLEAN DEFAULT FALSE COMMENT '是否已使用',
    expires_at TIMESTAMP NOT NULL COMMENT '过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    INDEX idx_target (target),
    INDEX idx_type (type),
    INDEX idx_expires_at (expires_at),
    INDEX idx_code_target (code, target)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='验证码表';

-- =====================================================
-- 用户会话表
-- =====================================================
CREATE TABLE user_sessions (
    id VARCHAR(36) PRIMARY KEY COMMENT '会话ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    token VARCHAR(500) NOT NULL COMMENT '访问令牌',
    refresh_token VARCHAR(500) COMMENT '刷新令牌',
    device_info VARCHAR(255) COMMENT '设备信息',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    expires_at TIMESTAMP NOT NULL COMMENT '过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '最后活动时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_token (token(255)),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户会话表';

-- =====================================================
-- 用户设置同步表
-- =====================================================
CREATE TABLE user_settings_sync (
    id VARCHAR(36) PRIMARY KEY COMMENT '记录ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    settings_key VARCHAR(100) NOT NULL COMMENT '设置键',
    settings_value TEXT COMMENT '设置值(JSON)',
    version INT DEFAULT 1 COMMENT '版本号',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE INDEX idx_user_settings (user_id, settings_key),
    INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户设置同步表';

-- =====================================================
-- 密码重置令牌表
-- =====================================================
CREATE TABLE password_reset_tokens (
    id VARCHAR(36) PRIMARY KEY COMMENT '记录ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    token VARCHAR(255) NOT NULL COMMENT '重置令牌',
    used BOOLEAN DEFAULT FALSE COMMENT '是否已使用',
    expires_at TIMESTAMP NOT NULL COMMENT '过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='密码重置令牌表';

-- =====================================================
-- 公告表（管理后台）
-- =====================================================
CREATE TABLE announcements (
    id VARCHAR(36) PRIMARY KEY COMMENT '公告ID',
    title VARCHAR(255) NOT NULL COMMENT '标题',
    content TEXT NOT NULL COMMENT '内容',
    type ENUM('info', 'warning', 'important') DEFAULT 'info' COMMENT '类型',
    target ENUM('all', 'user', 'vip', 'admin') DEFAULT 'all' COMMENT '目标用户',
    priority INT DEFAULT 0 COMMENT '优先级',
    published BOOLEAN DEFAULT FALSE COMMENT '是否发布',
    published_at TIMESTAMP NULL COMMENT '发布时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX idx_published (published),
    INDEX idx_target (target),
    INDEX idx_published_at (published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='公告表';

-- =====================================================
-- 用户公告阅读记录表
-- =====================================================
CREATE TABLE announcement_reads (
    id VARCHAR(36) PRIMARY KEY COMMENT '记录ID',
    user_id VARCHAR(36) NOT NULL COMMENT '用户ID',
    announcement_id VARCHAR(36) NOT NULL COMMENT '公告ID',
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '阅读时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE,
    UNIQUE INDEX idx_user_announcement (user_id, announcement_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='公告阅读记录表';

-- =====================================================
-- 触发器：用户登录后更新最后登录信息
-- =====================================================
DELIMITER //

CREATE TRIGGER tr_user_login AFTER INSERT ON login_logs
FOR EACH ROW
BEGIN
    IF NEW.success = TRUE THEN
        UPDATE users 
        SET last_login_at = NEW.created_at,
            last_login_ip = NEW.ip_address
        WHERE id = NEW.user_id;
    END IF;
END//

DELIMITER ;

-- =====================================================
-- 初始数据
-- =====================================================

-- 创建管理员账号（密码: admin123）
INSERT INTO users (id, email, password_hash, nickname, role, status, email_verified, phone_verified)
VALUES (
    'admin-001',
    'admin@miss-ide.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMy.MQDqVKF2wKJ5j5r5q5q5q5q5q5q5q5q', -- 实际需要哈希
    '管理员',
    'admin',
    'active',
    TRUE,
    FALSE
);

-- 创建示例公告
INSERT INTO announcements (id, title, content, type, target, priority, published, published_at)
VALUES (
    'ann-001',
    '欢迎使用 Miss IDE',
    'Miss IDE 是一款功能强大的 Android 反编译与分析工具，欢迎使用！',
    'info',
    'all',
    0,
    TRUE,
    NOW()
);
