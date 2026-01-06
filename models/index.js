const sequelize = require('../config/database');

// Import models here
// const User = require('./user.model');

const db = {
  sequelize,
  // User,
};

// Define associations here
// User.hasMany(Post);
// Post.belongsTo(User);

module.exports = db;
