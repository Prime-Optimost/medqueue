// WhatsApp API Configuration
// This file sets up the Twilio WhatsApp client for doctor-patient communication
// Can be swapped to Meta Cloud API later for production use

const twilio = require('twilio');

// Initialize Twilio client with credentials from environment variables
// Get these from https://console.twilio.com/
// Add TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_NUMBER to .env
const accountSid = process.env.TWILIO_ACCOUNT_SID; // <-- PASTE YOUR TWILIO ACCOUNT SID HERE IN .env
const authToken = process.env.TWILIO_AUTH_TOKEN;   // <-- PASTE YOUR TWILIO AUTH TOKEN HERE IN .env
const whatsappNumber = process.env.TWILIO_WHATSAPP_NUMBER; // <-- PASTE YOUR TWILIO WHATSAPP NUMBER HERE IN .env

// Initialize Twilio client only if valid credentials are provided
let client = null;
if (accountSid && accountSid.startsWith('AC') && authToken) {
    client = twilio(accountSid, authToken);
} else {
    console.warn('⚠️  Twilio credentials not configured. WhatsApp integration disabled.');
    console.warn('   To enable, add TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_WHATSAPP_NUMBER to .env');
}

// Export client and WhatsApp number
module.exports = {
    client,
    whatsappNumber
};

// Comments for academic documentation:
// - Uses Twilio SDK for WhatsApp Business API integration
// - Credentials stored securely in environment variables
// - whatsappNumber should be in format: 'whatsapp:+1234567890'
// - For production, consider migrating to Meta Cloud API for better performance
// - Mock mode available via WHATSAPP_MOCK=true in .env for development