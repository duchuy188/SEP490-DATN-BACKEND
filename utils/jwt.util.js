const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { jwt: jwtConfig } = require('../config/app.config');

class JwtUtil {
  /**
   * Tạo access token 
   * @param {string} userId - ID của user
   * @returns {string} - JWT access token
   */
  static generateAccessToken(userId) {
    return jwt.sign({ userId, type: 'access' }, jwtConfig.secret, { 
      expiresIn: jwtConfig.expiresIn 
    });
  }

  /**
   * Tạo refresh token 
   * @param {string} userId - ID của user
   * @returns {string} - JWT refresh token
   */
  static generateRefreshToken(userId) {
    const expiresIn = process.env.REFRESH_TOKEN_EXPIRES_IN || '7d';
    return jwt.sign({ userId, type: 'refresh' }, jwtConfig.secret, { expiresIn });
  }

  /**
   * Xác thực và giải mã JWT token
   * @param {string} token - JWT token cần verify
   * @returns {Object|null} - Decoded payload hoặc null nếu token không hợp lệ
   */
  static verifyToken(token) {
    try {
      return jwt.verify(token, jwtConfig.secret);
    } catch (error) {
      return null;
    }
  }

  static hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}

module.exports = JwtUtil;
