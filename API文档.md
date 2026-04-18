# Miss IDE 后端 API 文档

## 概述

本文档描述 Miss IDE 后端 RESTful API 接口。

## 基础信息

- **基础URL**: `https://api.miss-ide.com/api/v1`
- **认证方式**: Bearer Token (JWT)
- **数据格式**: JSON
- **字符编码**: UTF-8

## 认证接口

### 用户注册

#### 手机号注册

```
POST /auth/register/phone
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| password | string | 是 | 密码 |
| verifyCode | string | 是 | 验证码 |

**请求示例**:

```json
{
  "phone": "13812345678",
  "password": "YourPassword123",
  "verifyCode": "123456"
}
```

**响应示例**:

```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "user": {
      "id": "user_001",
      "phone": "13812345678",
      "nickname": "用户5678",
      "role": "user",
      "status": "active"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 邮箱注册

```
POST /auth/register/email
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码 |
| verifyCode | string | 是 | 验证码 |

### 用户登录

#### 手机号登录

```
POST /auth/login/phone
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| password | string | 是 | 密码 |

#### 手机号验证码登录

```
POST /auth/login/phone-code
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| verifyCode | string | 是 | 验证码 |

#### 邮箱登录

```
POST /auth/login/email
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| password | string | 是 | 密码 |

#### 微信登录

```
POST /auth/login/wechat
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | 是 | 微信授权码 |

**响应示例**:

```json
{
  "code": 200,
  "data": {
    "user": {
      "id": "user_wechat_001",
      "nickname": "微信用户",
      "wechatOpenid": "oxxxxxxx"
    },
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "isNewUser": true
  }
}
```

#### Apple 登录

```
POST /auth/login/apple
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| identityToken | string | 是 | Apple ID Token |
| authorizationCode | string | 是 | 授权码 |

#### Google 登录

```
POST /auth/login/google
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| idToken | string | 是 | Google ID Token |

### 验证码

#### 发送短信验证码

```
POST /auth/send-sms
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | 是 | 手机号 |
| type | string | 是 | 验证码类型: register, login, forgot_password |

**响应示例**:

```json
{
  "code": 200,
  "message": "验证码已发送",
  "data": {
    "expiresAt": "2024-01-01T12:05:00Z"
  }
}
```

#### 发送邮箱验证码

```
POST /auth/send-email
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| type | string | 是 | 验证码类型: register, login, forgot_password, bind_email |

### 密码管理

#### 忘记密码

```
POST /auth/forgot-password
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 是 | 找回方式: email, phone |
| email | string | 否 | 邮箱地址（type=email时必填） |
| phone | string | 否 | 手机号（type=phone时必填） |

#### 重置密码

```
POST /auth/reset-password
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| token | string | 是 | 重置令牌 |
| newPassword | string | 是 | 新密码 |

### 邮箱管理

#### 绑定邮箱

```
POST /auth/bind-email
```

**请求头**: `Authorization: Bearer {token}`

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| verifyCode | string | 是 | 验证码 |

#### 解绑邮箱

```
DELETE /auth/unbind-email
```

**请求头**: `Authorization: Bearer {token}`

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |

## 用户接口

### 获取用户信息

```
GET /auth/user/profile
```

**请求头**: `Authorization: Bearer {token}`

**响应示例**:

```json
{
  "code": 200,
  "data": {
    "id": "user_001",
    "phone": "13812345678",
    "email": "user@example.com",
    "nickname": "用户名",
    "avatar": "https://...",
    "role": "user",
    "status": "active",
    "emailVerified": true,
    "phoneVerified": true,
    "wechatOpenid": "oxxxxx",
    "googleId": "xxxxx",
    "lastLoginAt": "2024-01-01T12:00:00Z",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

### 更新用户信息

```
PUT /auth/user/profile
```

**请求头**: `Authorization: Bearer {token}`

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| nickname | string | 否 | 昵称 |
| avatar | string | 否 | 头像URL |

### 修改密码

```
PUT /auth/user/password
```

**请求头**: `Authorization: Bearer {token}`

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| oldPassword | string | 是 | 旧密码 |
| newPassword | string | 是 | 新密码 |

### 获取登录日志

```
GET /auth/user/login-logs
```

**请求头**: `Authorization: Bearer {token}`

**查询参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码（默认1） |
| pageSize | int | 否 | 每页数量（默认20） |

**响应示例**:

```json
{
  "code": 200,
  "data": {
    "list": [
      {
        "id": "log_001",
        "loginType": "email",
        "ipAddress": "192.168.1.1",
        "deviceInfo": "Chrome/Windows",
        "location": "广东深圳",
        "success": true,
        "createdAt": "2024-01-01T12:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 100
    }
  }
}
```

## 管理后台接口

### 用户管理

#### 用户列表

```
GET /admin/users
```

**请求头**: `Authorization: Bearer {admin_token}`

**查询参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码 |
| pageSize | int | 否 | 每页数量 |
| keyword | string | 否 | 搜索关键词 |
| role | string | 否 | 角色筛选 |
| status | string | 否 | 状态筛选 |
| loginType | string | 否 | 登录方式筛选 |

**响应示例**:

```json
{
  "code": 200,
  "data": {
    "list": [
      {
        "id": "user_001",
        "email": "user@example.com",
        "phone": "138****5678",
        "nickname": "用户名",
        "role": "user",
        "status": "active",
        "loginType": "email",
        "createdAt": "2024-01-01T00:00:00Z",
        "lastLoginAt": "2024-01-01T12:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 1000
    }
  }
}
```

#### 用户详情

```
GET /admin/users/:id
```

**请求头**: `Authorization: Bearer {admin_token}`

#### 更新用户状态

```
PUT /admin/users/:id/status
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | string | 是 | 用户状态: active, disabled, banned |
| reason | string | 否 | 操作原因 |

#### 更新用户角色

```
PUT /admin/users/:id/role
```

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| role | string | 是 | 用户角色: user, vip, admin |

### 统计数据

#### 获取统计数据

```
GET /admin/statistics
```

**请求头**: `Authorization: Bearer {admin_token}`

**查询参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| startDate | string | 否 | 开始日期 |
| endDate | string | 否 | 结束日期 |

**响应示例**:

```json
{
  "code": 200,
  "data": {
    "totalUsers": 12345,
    "activeUsers": 8234,
    "todayNewUsers": 156,
    "vipUsers": 567,
    "userGrowth": [
      {"date": "2024-01-01", "count": 100},
      {"date": "2024-01-02", "count": 120}
    ],
    "registrationMethods": [
      {"method": "phone", "count": 5000},
      {"method": "email", "count": 4000},
      {"method": "wechat", "count": 2000},
      {"method": "apple", "count": 1000},
      {"method": "google", "count": 345}
    ],
    "topRegions": [
      {"region": "北京", "count": 2500},
      {"region": "上海", "count": 2000}
    ]
  }
}
```

## 同步接口

### 同步设置

```
POST /sync/settings
```

**请求头**: `Authorization: Bearer {token}`

**请求参数**:

```json
{
  "settings": {
    "editor.fontSize": 14,
    "editor.theme": "monokai"
  },
  "version": 1,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 获取远程设置

```
GET /sync/settings
```

**请求头**: `Authorization: Bearer {token}`

### 解决同步冲突

```
POST /sync/resolve
```

**请求参数**:

```json
{
  "conflictId": "conflict_001",
  "resolution": "keepLocal",
  "mergedData": {}
}
```

## 错误码

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证或认证过期 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 422 | 验证失败 |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |

## 响应格式

### 成功响应

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {}
}
```

### 错误响应

```json
{
  "code": 400,
  "message": "参数错误",
  "errors": {
    "phone": ["手机号格式不正确"]
  }
}
```
