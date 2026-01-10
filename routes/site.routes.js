const express = require('express');
const router = express.Router();
const SiteController = require('../controllers/SiteController');
const SiteValidator = require('../validators/site.validator');
const authMiddleware = require('../middlewares/auth.middleware');
const i18nMiddleware = require('../middlewares/i18n.middleware');
const { upload } = require('../config/cloudinary.config');

router.use(i18nMiddleware);

// Admin routes - Create site with image upload
router.post(
  '/',
  authMiddleware,
  authMiddleware.authorize('admin'),
  upload.single('cover_image'), 
  SiteValidator.createSite,
  SiteController.createSite
);

module.exports = router;
