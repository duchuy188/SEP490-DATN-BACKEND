const SiteService = require('../services/siteService');
const ResponseUtil = require('../utils/response.util');
const { validationResult } = require('express-validator');
const { formatValidationErrors } = require('../utils/validation.util');

// Create new site (Admin only)
exports.createSite = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const formattedErrors = formatValidationErrors(errors.array());
      return ResponseUtil.badRequest(res, req.__('validation.failed'), formattedErrors);
    }

    // Parse JSON strings from form-data
    if (req.body.opening_hours && typeof req.body.opening_hours === 'string') {
      try {
        req.body.opening_hours = JSON.parse(req.body.opening_hours);
      } catch (e) {
        return ResponseUtil.badRequest(res, 'Invalid opening_hours JSON format');
      }
    }

    if (req.body.contact_info && typeof req.body.contact_info === 'string') {
      try {
        req.body.contact_info = JSON.parse(req.body.contact_info);
      } catch (e) {
        return ResponseUtil.badRequest(res, 'Invalid contact_info JSON format');
      }
    }

    // Get uploaded image URL from Cloudinary
    if (req.file) {
      req.body.cover_image = req.file.path; 
    }

    const result = await SiteService.createSite(req.body, req.user.id);
    return ResponseUtil.created(res, result, req.__('site.create_success'));
  } catch (error) {
    if (error.message === 'Site already exists') {
      return ResponseUtil.conflict(res, req.__('site.already_exists'));
    }
    return ResponseUtil.error(res, req.__('error.server_error'));
  }
};
