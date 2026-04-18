// routes/sync.js - Cloud sync routes
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { pool } = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Sync data
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { data_type, data_key, data_value } = req.body;
    
    if (!data_type || !data_key) {
      return res.status(400).json({ error: 'data_type and data_key are required' });
    }
    
    const syncId = uuidv4();
    
    await pool.query(
      `INSERT INTO sync_data (id, user_id, data_type, data_key, data_value, version)
       VALUES (?, ?, ?, ?, ?, 1)
       ON DUPLICATE KEY UPDATE
         data_value = VALUES(data_value),
         version = version + 1,
         updated_at = NOW()`,
      [syncId, req.userId, data_type, data_key, JSON.stringify(data_value)]
    );
    
    res.json({ message: 'Data synced successfully' });
  } catch (error) {
    console.error('Sync error:', error);
    res.status(500).json({ error: 'Sync failed' });
  }
});

// Get synced data
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { data_type, data_key } = req.query;
    
    let query = 'SELECT * FROM sync_data WHERE user_id = ?';
    const params = [req.userId];
    
    if (data_type) {
      query += ' AND data_type = ?';
      params.push(data_type);
    }
    
    if (data_key) {
      query += ' AND data_key = ?';
      params.push(data_key);
    }
    
    query += ' ORDER BY updated_at DESC';
    
    const [rows] = await pool.query(query, params);
    
    const data = rows.map(row => ({
      ...row,
      data_value: JSON.parse(row.data_value || 'null')
    }));
    
    res.json({ data });
  } catch (error) {
    console.error('Get sync data error:', error);
    res.status(500).json({ error: 'Failed to get data' });
  }
});

// Batch sync
router.post('/batch', authMiddleware, async (req, res) => {
  try {
    const { items } = req.body;
    
    if (!items || !Array.isArray(items)) {
      return res.status(400).json({ error: 'items array is required' });
    }
    
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();
      
      for (const item of items) {
        const { data_type, data_key, data_value } = item;
        if (!data_type || !data_key) continue;
        
        await connection.query(
          `INSERT INTO sync_data (id, user_id, data_type, data_key, data_value, version)
           VALUES (?, ?, ?, ?, ?, 1)
           ON DUPLICATE KEY UPDATE
             data_value = VALUES(data_value),
             version = version + 1,
             updated_at = NOW()`,
          [uuidv4(), req.userId, data_type, data_key, JSON.stringify(data_value)]
        );
      }
      
      await connection.commit();
      res.json({ message: 'Batch sync successful', count: items.length });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Batch sync error:', error);
    res.status(500).json({ error: 'Batch sync failed' });
  }
});

// Delete synced data
router.delete('/', authMiddleware, async (req, res) => {
  try {
    const { data_type, data_key } = req.query;
    
    let query = 'DELETE FROM sync_data WHERE user_id = ?';
    const params = [req.userId];
    
    if (data_type) {
      query += ' AND data_type = ?';
      params.push(data_type);
    }
    
    if (data_key) {
      query += ' AND data_key = ?';
      params.push(data_key);
    }
    
    const [result] = await pool.query(query, params);
    
    res.json({ message: 'Data deleted', count: result.affectedRows });
  } catch (error) {
    console.error('Delete sync data error:', error);
    res.status(500).json({ error: 'Failed to delete data' });
  }
});

module.exports = router;
