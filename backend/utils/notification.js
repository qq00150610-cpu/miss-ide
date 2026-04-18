// utils/notification.js - Notification utilities
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT || 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

async function sendSMS(phone, code) {
  // Integrate with Aliyun SMS
  // This is a placeholder for SMS sending
  console.log(`Sending SMS to ${phone}: ${code}`);
  return true;
}

async function sendEmail(to, subject, text) {
  try {
    await transporter.sendMail({
      from: process.env.SMTP_USER,
      to,
      subject,
      text
    });
    return true;
  } catch (error) {
    console.error('Email send error:', error);
    return false;
  }
}

module.exports = {
  sendSMS,
  sendEmail
};
