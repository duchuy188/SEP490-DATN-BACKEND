const express = require('express');
const router = express.Router();
const authRoutes = require('./auth.routes');

router.get('/', (req, res) => {
  res.json({
    message: 'API is working',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      docs: '/api-docs',
      auth: '/api/auth'
    }
  });
});

// Auth routes
router.use('/auth', authRoutes);

module.exports = router;
