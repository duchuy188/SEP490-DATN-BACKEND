const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const SiteMedia = sequelize.define('SiteMedia', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    site_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'sites',
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    url: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    type: {
        type: DataTypes.ENUM('image', 'video', 'panorama'),
        defaultValue: 'image'
    },
    caption: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    is_main: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
    }
}, {
    tableName: 'site_media',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
});

module.exports = SiteMedia;
