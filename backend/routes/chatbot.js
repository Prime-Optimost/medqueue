// Chatbot Routes
// Handles AI chatbot interactions for symptom guidance and emergency flagging
// Endpoints: POST /api/chatbot/message, GET /api/chatbot/history/:userId

const express = require('express');
const router = express.Router();
const openai = require('../config/openai');
const db = require('../config/database'); // Assuming database config exists
const { authenticateToken, requireRole } = require('../middleware/auth'); // JWT middleware

// POST /api/chatbot/message
// Receives symptom input, sends to OpenAI, saves interaction, returns response
router.post('/message', authenticateToken, requireRole(['patient']), async (req, res) => {
    try {
        const { symptom_input, session_id } = req.body;
        const user_id = req.user.id;

        // Validate input
        if (!symptom_input || symptom_input.trim().length === 0) {
            return res.status(400).json({ error: 'Symptom input is required' });
        }

        // System prompt for OpenAI
        const systemPrompt = `You are a basic first-aid and symptom guidance assistant for a Ghanaian hospital mobile app. You provide general health information and first-aid tips only. You must NEVER diagnose, prescribe, or replace a doctor. Every single response must end with this disclaimer: '⚠️ Disclaimer: This is not a medical diagnosis. Please consult a qualified doctor for proper medical advice.' If the user describes symptoms that sound like a medical emergency (chest pain, difficulty breathing, unconsciousness, severe bleeding), set is_emergency_flagged to true and urgently advise them to use the Emergency SOS button.`;

        // Call OpenAI API
        const completion = await openai.chat.completions.create({
            model: 'gpt-3.5-turbo',
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: symptom_input }
            ],
            max_tokens: 500,
            temperature: 0.7
        });

        const chatbot_response = completion.choices[0].message.content;

        // Check for emergency keywords in user input
        const emergencyKeywords = ['chest pain', 'difficulty breathing', 'unconscious', 'severe bleeding', 'heart attack', 'stroke'];
        const is_emergency_flagged = emergencyKeywords.some(keyword =>
            symptom_input.toLowerCase().includes(keyword)
        );

        // Fallback: ensure disclaimer is always present
        if (!chatbot_response.includes('⚠️ Disclaimer:')) {
            chatbot_response += '\n\n⚠️ Disclaimer: This is not a medical diagnosis. Please consult a qualified doctor for proper medical advice.';
        }

        // Save to database
        const query = `
            INSERT INTO chatbot_interactions
            (user_id, session_id, symptom_input, chatbot_response, is_emergency_flagged)
            VALUES (?, ?, ?, ?, ?)
        `;
        await db.execute(query, [user_id, session_id || 'default', symptom_input, chatbot_response, is_emergency_flagged]);

        // Return response
        res.json({
            response: chatbot_response,
            is_emergency_flagged,
            timestamp: new Date()
        });

    } catch (error) {
        console.error('Chatbot error:', error);
        res.status(500).json({ error: 'Failed to process chatbot request' });
    }
});

// GET /api/chatbot/history/:userId
// Returns past chatbot sessions for a user
router.get('/history/:userId', authenticateToken, requireRole(['patient', 'doctor', 'admin']), async (req, res) => {
    try {
        const { userId } = req.params;
        const requestingUserId = req.user.id;
        const userRole = req.user.role;

        // Allow patients to view their own history, doctors/admins to view any
        if (userRole === 'patient' && parseInt(userId) !== requestingUserId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const query = `
            SELECT id, session_id, symptom_input, chatbot_response, timestamp, is_emergency_flagged
            FROM chatbot_interactions
            WHERE user_id = ?
            ORDER BY timestamp DESC
            LIMIT 100
        `;
        const [rows] = await db.execute(query, [userId]);

        res.json({ interactions: rows });

    } catch (error) {
        console.error('Chatbot history error:', error);
        res.status(500).json({ error: 'Failed to fetch chatbot history' });
    }
});

module.exports = router;

// Comments for academic documentation:
// - POST /message: Processes symptom input through OpenAI API with strict medical disclaimer
// - Emergency detection: Checks for critical symptoms and flags appropriately
// - Database logging: All interactions saved for audit and review
// - GET /history: Provides access to past conversations for continuity
// - Security: JWT authentication and role-based access control