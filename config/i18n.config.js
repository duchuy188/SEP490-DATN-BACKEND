const i18n = require('i18n');
const path = require('path');

i18n.configure({
  locales: ['vi', 'en'],
  defaultLocale: 'vi',
  directory: path.join(__dirname, '../locales'),
  objectNotation: true,
  updateFiles: false,
  syncFiles: false
});

module.exports = i18n;
