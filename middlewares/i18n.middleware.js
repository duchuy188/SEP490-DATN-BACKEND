const i18n = require('../config/i18n.config');

/**
 * Middleware để set ngôn ngữ dựa trên:
 * 1. User language (nếu đã đăng nhập)
 * 2. Header Accept-Language
 * 3. Default: vi
 */
const i18nMiddleware = (req, res, next) => {
  let locale = 'vi';


  if (req.user && req.user.language) {
    locale = req.user.language;
  }

  else if (req.headers['accept-language']) {
    const headerLang = req.headers['accept-language'].split(',')[0].split('-')[0];
    if (['vi', 'en'].includes(headerLang)) {
      locale = headerLang;
    }
  }


  req.setLocale(locale);

  next();
};

module.exports = i18nMiddleware;
