// OpenAI API Configuration
// This file sets up the OpenAI client for the AI chatbot functionality
// Used for processing patient symptoms and providing first-aid guidance

const OpenAI = require('openai');

// Initialize OpenAI client with API key from environment variables
// IMPORTANT: Get your API key from https://platform.openai.com/api-keys
// Add OPENAI_API_KEY=your_key_here to your .env file
const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY, // <-- PASTE YOUR OPENAI API KEY HERE IN .env
});

// Export the configured client for use in chatbot routes
module.exports = openai;

// Comments for academic documentation:
// - Uses OpenAI SDK for API interactions
// - API key is securely stored in environment variables
// - Client is configured once and reused across requests
// - For production, ensure API key has appropriate rate limits and billing