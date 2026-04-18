// routes/users.js - User management routes
const express = require('express');
const { pool } = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get user profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT id, email, phone, nickname, avatar_url, role, status, email_verified, phone_verified, last_login_at, created_at FROM users WHERE id = ?',
      [req.userId]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ user: users[0] });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

// Update user profile
router.put('/profile', authMiddleware, async (req, res) => {
  try {
    const { nickname, avatar_url } = req.body;
    
    await pool.query(
      'UPDATE users SET nickname = COALESCE(?, nickname), avatar_url = COALESCE(?, avatar_url) WHERE id = ?',
      [nickname, avatar_url, req.userId]
    );
    
    res.json({ message: 'Profile updated' });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Get user projects
router.get('/projects', authMiddleware, async (req, res) => {
  try {
    const [projects] = await pool.query(
      'SELECT * FROM projects WHERE user_id = ? ORDER BY updated_at DESC',
      [req.userId]
    );
    
    res.json({ projects });
  } catch (error) {
    console.error('Get projects error:', error);
    res.status(500).json({ error: 'Failed to get projects' });
  }
});

// Create project
router.post('/projects', authMiddleware, async (req, res) => {
  try {
    const { name, description, settings } = req.body;
    const { v4: uuidv4 } = require('uuid');
    const projectId = uuidv4();
    
    await pool.query(
      'INSERT INTO projects (id, user_id, name, description, settings) VALUES (?, ?, ?, ?, ?)',
      [projectId, req.userId, name, description, JSON.stringify(settings || {})]
    );
    
    res.status(201).json({ project: { id: projectId, name } });
  } catch (error) {
    console.error('Create project error:', error);
    res.status(500).json({ error: 'Failed to create project' });
  }
});

// Delete project
router.delete('/projects/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    
    const [result] = await pool.query(
      'DELETE FROM projects WHERE id = ? AND user_id = ?',
      [id, req.userId]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }
    
    res.json({ message: 'Project deleted' });
  } catch (error) {
    console.error('Delete project error:', error);
    res.status(500).json({ error: 'Failed to delete project' });
  }
});

module.exports = router;
