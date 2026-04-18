// routes/admin.js - Admin routes
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { pool } = require('../config/database');
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get all users (admin only)
router.get('/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 20, status, role } = req.query;
    const offset = (page - 1) * limit;
    
    let query = 'SELECT id, email, phone, nickname, avatar_url, role, status, last_login_at, created_at FROM users WHERE 1=1';
    const params = [];
    
    if (status) {
      query += ' AND status = ?';
      params.push(status);
    }
    
    if (role) {
      query += ' AND role = ?';
      params.push(role);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));
    
    const [users] = await pool.query(query, params);
    
    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM users WHERE 1=1';
    const countParams = [];
    if (status) { countQuery += ' AND status = ?'; countParams.push(status); }
    if (role) { countQuery += ' AND role = ?'; countParams.push(role); }
    
    const [countResult] = await pool.query(countQuery, countParams);
    
    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: countResult[0].total,
        pages: Math.ceil(countResult[0].total / limit)
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
});

// Update user (admin only)
router.put('/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { role, status } = req.body;
    
    await pool.query(
      'UPDATE users SET role = COALESCE(?, role), status = COALESCE(?, status) WHERE id = ?',
      [role, status, id]
    );
    
    // Log action
    await pool.query(
      'INSERT INTO admin_logs (id, admin_id, action, target_type, target_id, details, ip_address) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [uuidv4(), req.userId, 'update_user', 'user', id, JSON.stringify({ role, status }), req.ip]
    );
    
    res.json({ message: 'User updated' });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// Delete user (admin only)
router.delete('/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    
    if (id === req.userId) {
      return res.status(400).json({ error: 'Cannot delete yourself' });
    }
    
    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    await pool.query(
      'INSERT INTO admin_logs (id, admin_id, action, target_type, target_id, ip_address) VALUES (?, ?, ?, ?, ?, ?)',
      [uuidv4(), req.userId, 'delete_user', 'user', id, req.ip]
    );
    
    res.json({ message: 'User deleted' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// Get admin logs
router.get('/logs', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    
    const [logs] = await pool.query(
      `SELECT l.*, u.nickname as admin_nickname 
       FROM admin_logs l 
       LEFT JOIN users u ON l.admin_id = u.id 
       ORDER BY l.created_at DESC 
       LIMIT ? OFFSET ?`,
      [parseInt(limit), parseInt(offset)]
    );
    
    res.json({ logs });
  } catch (error) {
    console.error('Get logs error:', error);
    res.status(500).json({ error: 'Failed to get logs' });
  }
});

// Get statistics
router.get('/stats', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const [[userStats]] = await pool.query(`
      SELECT 
        COUNT(*) as total_users,
        SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_users,
        SUM(CASE WHEN role = 'admin' THEN 1 ELSE 0 END) as admins,
        SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as new_users_7d
      FROM users
    `);
    
    const [[projectStats]] = await pool.query(`
      SELECT COUNT(*) as total_projects
      FROM projects
    `);
    
    const [[syncStats]] = await pool.query(`
      SELECT COUNT(*) as total_syncs
      FROM sync_data
    `);
    
    res.json({
      users: userStats,
      projects: projectStats,
      syncs: syncStats
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to get statistics' });
  }
});

module.exports = router;
