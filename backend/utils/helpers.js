// utils/helpers.js - Helper functions
function generateCode(length = 6) {
  let code = '';
  for (let i = 0; i < length; i++) {
    code += Math.floor(Math.random() * 10);
  }
  return code;
}

function validateEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

function validatePhone(phone) {
  const re = /^1[3-9]\d{9}$/;
  return re.test(phone);
}

function formatDate(date) {
  return new Date(date).toISOString().split('T')[0];
}

module.exports = {
  generateCode,
  validateEmail,
  validatePhone,
  formatDate
};
