# Miss IDE Backend API

Miss IDE 移动端反编译工具的后端 API 服务。

## 技术栈

- Node.js + Express
- MySQL 数据库
- JWT 认证
- PM2 进程管理

## 快速开始

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入配置信息
```

### 3. 启动服务

```bash
# 开发环境
npm run dev

# 生产环境
npm start
```

## API 端点

### 认证接口
- `POST /api/auth/register/email` - 邮箱注册
- `POST /api/auth/register/phone` - 手机注册
- `POST /api/auth/login/email` - 邮箱登录
- `POST /api/auth/login/phone` - 手机登录
- `GET /api/auth/me` - 获取当前用户
- `POST /api/auth/change-password` - 修改密码
- `POST /api/auth/forgot-password` - 忘记密码

### 用户接口
- `GET /api/users/profile` - 获取用户资料
- `PUT /api/users/profile` - 更新用户资料
- `GET /api/users/projects` - 获取用户项目
- `POST /api/users/projects` - 创建项目
- `DELETE /api/users/projects/:id` - 删除项目

### 同步接口
- `POST /api/sync` - 同步数据
- `GET /api/sync` - 获取同步数据
- `POST /api/sync/batch` - 批量同步
- `DELETE /api/sync` - 删除同步数据

### 管理接口 (需要管理员权限)
- `GET /api/admin/users` - 获取所有用户
- `PUT /api/admin/users/:id` - 更新用户
- `DELETE /api/admin/users/:id` - 删除用户
- `GET /api/admin/logs` - 获取管理日志
- `GET /api/admin/stats` - 获取统计数据

## 环境变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| PORT | 服务端口 | 3000 |
| DB_HOST | 数据库地址 | localhost |
| DB_PORT | 数据库端口 | 3306 |
| DB_USER | 数据库用户 | root |
| DB_PASSWORD | 数据库密码 | - |
| DB_NAME | 数据库名称 | miss_ide |
| JWT_SECRET | JWT密钥 | - |
| JWT_EXPIRES_IN | Token过期时间 | 7d |

## 部署

### PM2 部署

```bash
npm install -g pm2
pm2 start server.js --name miss-ide-api
pm2 save
pm2 startup
```

### Nginx 配置

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## License

MIT
