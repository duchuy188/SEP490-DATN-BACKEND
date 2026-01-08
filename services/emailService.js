const { resend, emailConfig } = require('../config/resend.config');
const Logger = require('../utils/logger.util');

class EmailService {
  /**
   * Gửi OTP qua email
   * @param {string} email - Email người nhận
   * @param {string} otp - Mã OTP
   */
  static async sendOTP(email, otp) {
    try {
      Logger.info(`Attempting to send OTP to: ${email}`);
      Logger.info(`Email config: ${JSON.stringify(emailConfig)}`);

      const { data, error } = await resend.emails.send({
        from: emailConfig.from,
        to: email,
        subject: 'Reset Your Password - OTP Code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">Reset Your Password</h2>
            <p>You have requested to reset your password. Use the OTP code below:</p>
            <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
              <h1 style="color: #4CAF50; letter-spacing: 5px; margin: 0;">${otp}</h1>
            </div>
            <p>This OTP will expire in <strong>10 minutes</strong>.</p>
            <p>If you didn't request this, please ignore this email.</p>
            <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
            <p style="color: #999; font-size: 12px;">
              ${emailConfig.fromName}<br>
              This is an automated email, please do not reply.
            </p>
          </div>
        `
      });

      if (error) {
        Logger.error('Resend API error:', error);
        throw new Error(`Failed to send email: ${error.message || JSON.stringify(error)}`);
      }

      Logger.info(`OTP sent successfully to: ${email}, ID: ${data?.id}`);
      return data;
    } catch (error) {
      Logger.error('Email service error:', error);
      throw error;
    }
  }
}

module.exports = EmailService;
