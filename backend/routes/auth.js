// routes/auth.js - Authentication routes
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { pool } = require('../config/database');
const { authMiddleware, generateToken } = require('../middleware/auth');
const { sendSMS, sendEmail } = require('../utils/notification');
const { generateCode } = require('../utils/helpers');

const router = express.Router();

// Register with email
router.post('/register/email', async (req, res) => {
  try {
    const { email, password, nickname } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    // Check existing user
    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);
    const userId = uuidv4();
    
    // Create user
    await pool.query(
      'INSERT INTO users (id, email, password_hash, nickname, provider) VALUES (?, ?, ?, ?, ?)',
      [userId, email, passwordHash, nickname || email.split('@')[0], 'local']
    );
    
    // Generate token
    const token = generateToken(userId);
    
    res.status(201).json({
      message: 'Registration successful',
      token,
      user: { id: userId, email, nickname: nickname || email.split('@')[0] }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Register with phone
router.post('/register/phone', async (req, res) => {
  try {
    const { phone, code, nickname } = req.body;
    
    if (!phone || !code) {
      return res.status(400).json({ error: 'Phone and code are required' });
    }
    
    // Verify code
    const [codes] = await pool.query(
      'SELECT * FROM verification_codes WHERE phone = ? AND code = ? AND type = ? AND used = FALSE AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
      [phone, code, 'register']
    );
    
    if (codes.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired verification code' });
    }
    
    // Mark code as used
    await pool.query('UPDATE verification_codes SET used = TRUE WHERE id = ?', [codes[0].id]);
    
    // Check existing user
    const [existing] = await pool.query('SELECT id FROM users WHERE phone = ?', [phone]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Phone already registered' });
    }
    
    const userId = uuidv4();
    await pool.query(
      'INSERT INTO users (id, phone, nickname, provider, phone_verified) VALUES (?, ?, ?, ?, ?)',
      [userId, phone, nickname || `User${userId.slice(0, 6)}`, 'local', true]
    );
    
    const token = generateToken(userId);
    
    res.status(201).json({
      message: 'Registration successful',
      token,
      user: { id: userId, phone, nickname: nickname || `User${userId.slice(0, 6)}` }
    });
  } catch (error) {
    console.error('Phone register error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Send SMS verification code
router.post('/sms/send', async (req, res) => {
  try {
    const { phone, type = 'login' } = req.body;
    
    if (!phone) {
      return res.status(400).json({ error: 'Phone is required' });
    }
    
    const code = generateCode(6);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes
    
    // Save code
    await pool.query(
      'INSERT INTO verification_codes (id, phone, code, type, expires_at) VALUES (?, ?, ?, ?, ?)',
      [uuidv4(), phone, code, type, expiresAt]
    );
    
    // Send SMS (disabled for development)
    // await sendSMS(phone, code);
    
    // Return code for development
    res.json({ message: 'Code sent', code }); // Remove in production
  } catch (error) {
    console.error('SMS send error:', error);
    res.status(500).json({ error: 'Failed to send code' });
  }
});

// Login with email/password
router.post('/login/email', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    const [users] = await pool.query('SELECT * FROM users WHERE email = ? AND provider = ?', [email, 'local']);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = users[0];
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Update last login
    await pool.query('UPDATE users SET last_login_at = NOW() WHERE id = ?', [user.id]);
    
    const token = generateToken(user.id);
    
    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        avatar: user.avatar_url,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Login with phone
router.post('/login/phone', async (req, res) => {
  try {
    const { phone, code } = req.body;
    
    if (!phone || !code) {
      return res.status(400).json({ error: 'Phone and code are required' });
    }
    
    const [codes] = await pool.query(
      'SELECT * FROM verification_codes WHERE phone = ? AND code = ? AND type = ? AND used = FALSE AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
      [phone, code, 'login']
    );
    
    if (codes.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired code' });
    }
    
    await pool.query('UPDATE verification_codes SET used = TRUE WHERE id = ?', [codes[0].id]);
    
    const [users] = await pool.query('SELECT * FROM users WHERE phone = ?', [phone]);
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found, please register first' });
    }
    
    const user = users[0];
    await pool.query('UPDATE users SET last_login_at = NOW() WHERE id = ?', [user.id]);
    
    const token = generateToken(user.id);
    
    res.json({
      token,
      user: {
        id: user.id,
        phone: user.phone,
        nickname: user.nickname,
        avatar: user.avatar_url
      }
    });
  } catch (error) {
    console.error('Phone login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// OAuth login (WeChat, Google, Apple)
router.post('/oauth/:provider', async (req, res) => {
  try {
    const { provider } = req.params;
    const { code, accessToken } = req.body;
    
    // Validate provider
    const validProviders = ['wechat', 'google', 'apple'];
    if (!validProviders.includes(provider)) {
      return res.status(400).json({ error: 'Invalid provider' });
    }
    
    // Exchange code for token and get user info (provider-specific logic)
    // For now, return success
    res.json({ message: `${provider} OAuth not fully configured` });
  } catch (error) {
    console.error('OAuth error:', error);
    res.status(500).json({ error: 'OAuth failed' });
  }
});

// Get current user
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT id, email, phone, nickname, avatar_url, role, status, created_at FROM users WHERE id = ?',
      [req.userId]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ user: users[0] });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

// Change password
router.post('/change-password', authMiddleware, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    
    if (!oldPassword || !newPassword) {
      return res.status(400).json({ error: 'Old and new password are required' });
    }
    
    const [users] = await pool.query('SELECT password_hash FROM users WHERE id = ?', [req.userId]);
    const isValid = await bcrypt.compare(oldPassword, users[0].password_hash);
    
    if (!isValid) {
      return res.status(401).json({ error: 'Incorrect old password' });
    }
    
    const newHash = await bcrypt.hash(newPassword, 12);
    await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [newHash, req.userId]);
    
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to change password' });
  }
});

// Forgot password
router.post('/forgot-password', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }
    
    if (code && newPassword) {
      // Reset password
      const [codes] = await pool.query(
        'SELECT * FROM verification_codes WHERE email = ? AND code = ? AND type = ? AND used = FALSE AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
        [email, code, 'reset']
      );
      
      if (codes.length === 0) {
        return res.status(400).json({ error: 'Invalid or expired code' });
      }
      
      await pool.query('UPDATE verification_codes SET used = TRUE WHERE id = ?', [codes[0].id]);
      
      const hash = await bcrypt.hash(newPassword, 12);
      await pool.query('UPDATE users SET password_hash = ? WHERE email = ?', [hash, email]);
      
      return res.json({ message: 'Password reset successfully' });
    }
    
    // Send reset code
    const [codes] = await pool.query(
      'SELECT * FROM verification_codes WHERE email = ? AND type = ? AND used = FALSE AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
      [email, 'reset']
    );
    
    if (codes.length > 0) {
      return res.json({ message: 'Code already sent, please check your email' });
    }
    
    const code = generateCode(6);
    await pool.query(
      'INSERT INTO verification_codes (id, email, code, type, expires_at) VALUES (?, ?, ?, ?, ?)',
      [uuidv4(), email, code, 'reset', new Date(Date.now() + 15 * 60 * 1000)]
    );
    
    // Send email
    // await sendEmail(email, 'Password Reset', `Your reset code is: ${code}`);
    
    res.json({ message: 'Reset code sent', code }); // Remove in production
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Failed to send reset code' });
  }
});

module.exports = router;
