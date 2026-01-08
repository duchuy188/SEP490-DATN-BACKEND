/**
 * Format validation errors - chỉ lấy lỗi đầu tiên của mỗi field
 * @param {Array} errors - Array of validation errors from express-validator
 * @returns {Array} - Formatted errors with field and message
 */
const formatValidationErrors = (errors) => {
  const seen = new Set();
  return errors
    .filter(err => {
      if (seen.has(err.path)) return false;
      seen.add(err.path);
      return true;
    })
    .map(err => ({
      field: err.path,
      message: err.msg
    }));
};

module.exports = { formatValidationErrors };
