const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

const fromEmail = process.env.EMAIL_FROM;
const fromName = process.env.EMAIL_FROM_NAME;


const from = fromEmail.includes('<')
  ? fromEmail
  : `${fromName} <${fromEmail}>`;

const emailConfig = {
  from,
  fromName,
  fromEmail
};

module.exports = { resend, emailConfig };
