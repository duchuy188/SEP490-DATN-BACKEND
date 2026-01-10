const { Site } = require('../models');
const Logger = require('../utils/logger.util');

class SiteService {
  /**
   * Create new site (Admin only)
   * @param {Object} siteData - Site information
   * @param {string} adminId - ID of admin creating the site
   * @returns {Object} - Created site
   */
  static async createSite(siteData, adminId) {
    try {
      const {
        name,
        description,
        history,
        address,
        province,
        district,
        latitude,
        longitude,
        region,
        type,
        patron_saint,
        cover_image,
        opening_hours,
        contact_info
      } = siteData;

    
      const existingSite = await Site.findOne({
        where: {
          name: name.trim(),
          province: province?.trim()
        }
      });

      if (existingSite) {
        throw new Error('Site already exists');
      }

     
      const site = await Site.create({
        name: name.trim(),
        description,
        history,
        address,
        province: province?.trim(),
        district: district?.trim(),
        latitude,
        longitude,
        region,
        type,
        patron_saint,
        cover_image,
        opening_hours,
        contact_info,
        created_by: adminId,
        status: 'approved', 
        is_active: true
      });

      Logger.info(`Site created by admin: ${site.id} - ${site.name}`);

      return {
        id: site.id,
        name: site.name,
        description: site.description,
        address: site.address,
        province: site.province,
        district: site.district,
        latitude: site.latitude,
        longitude: site.longitude,
        region: site.region,
        type: site.type,
        patron_saint: site.patron_saint,
        cover_image: site.cover_image,
        status: site.status,
        is_active: site.is_active,
        created_by: site.created_by,
        created_at: site.created_at
      };
    } catch (error) {
      Logger.error('Create site error:', error);
      throw error;
    }
  }
}

module.exports = SiteService;
