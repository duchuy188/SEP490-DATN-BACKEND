const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const BlacklistedToken = sequelize.define('BlacklistedToken', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    token: {
        type: DataTypes.STRING(500),
        allowNull: false
    },
    expires_at: {
        type: DataTypes.DATE,
        allowNull: false
    }
}, {
    tableName: 'blacklisted_tokens',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = BlacklistedToken;
