// Chat Routes
// Handles WhatsApp communication between patients and doctors
// Endpoints: POST /api/chat/send, GET /api/chat/history/:patientId/:doctorId, POST /api/chat/webhook

const express = require('express');
const router = express.Router();
const { client, whatsappNumber } = require('../config/whatsapp');
const db = require('../config/database'); // Assuming database config exists
const { authenticateToken, requireRole } = require('../middleware/auth'); // JWT middleware
const fcm = require('../config/fcm'); // Assuming FCM config exists

// POST /api/chat/send
// Logs message and sends via WhatsApp Business API
router.post('/send', authenticateToken, requireRole(['patient', 'doctor']), async (req, res) => {
    try {
        const { recipient_id, message, appointment_id } = req.body;
        const sender_id = req.user.id;
        const sender_role = req.user.role;

        // Determine direction and validate
        let direction, patient_id, doctor_id;
        if (sender_role === 'patient') {
            direction = 'patient_to_doctor';
            patient_id = sender_id;
            doctor_id = recipient_id;
        } else if (sender_role === 'doctor') {
            direction = 'doctor_to_patient';
            patient_id = recipient_id;
            doctor_id = sender_id;
        } else {
            return res.status(403).json({ error: 'Invalid sender role' });
        }

        // Get recipient's WhatsApp number
        const [recipientRows] = await db.execute('SELECT phone FROM users WHERE id = ?', [recipient_id]);
        if (recipientRows.length === 0) {
            return res.status(404).json({ error: 'Recipient not found' });
        }
        const recipientNumber = recipientRows[0].phone;

        // Mock mode check
        const isMockMode = process.env.WHATSAPP_MOCK === 'true';

        let whatsapp_message_id = null;

        if (isMockMode) {
            // Mock mode: just log to console
            console.log(`[MOCK WhatsApp] From ${sender_id} to ${recipient_id}: ${message}`);
            whatsapp_message_id = `mock_${Date.now()}`;
        } else {
            // Production: send via Twilio WhatsApp API
            const twilioMessage = await client.messages.create({
                from: `whatsapp:${whatsappNumber}`,
                to: `whatsapp:${recipientNumber}`,
                body: message
            });
            whatsapp_message_id = twilioMessage.sid;
        }

        // Log to communications table
        const content_preview = message.length > 500 ? message.substring(0, 500) + '...' : message;
        const query = `
            INSERT INTO communications
            (patient_id, doctor_id, whatsapp_message_id, direction, content_preview, appointment_id)
            VALUES (?, ?, ?, ?, ?, ?)
        `;
        await db.execute(query, [patient_id, doctor_id, whatsapp_message_id, direction, content_preview, appointment_id || null]);

        // Send FCM push notification to recipient
        const [fcmTokens] = await db.execute('SELECT fcm_token FROM users WHERE id = ? AND fcm_token IS NOT NULL', [recipient_id]);
        if (fcmTokens.length > 0) {
            fcm.sendMulticast({
                tokens: fcmTokens.map(row => row.fcm_token),
                notification: {
                    title: sender_role === 'doctor' ? 'New message from doctor' : 'New message from patient',
                    body: content_preview
                },
                data: {
                    type: 'chat_message',
                    sender_id: sender_id.toString(),
                    patient_id: patient_id.toString(),
                    doctor_id: doctor_id.toString()
                }
            }).catch(err => console.error('FCM send error:', err));
        }

        res.json({
            success: true,
            message_id: whatsapp_message_id,
            mock_mode: isMockMode
        });

    } catch (error) {
        console.error('Chat send error:', error);
        res.status(500).json({ error: 'Failed to send message' });
    }
});

// GET /api/chat/history/:patientId/:doctorId
// Returns conversation history between patient and doctor
router.get('/history/:patientId/:doctorId', authenticateToken, requireRole(['patient', 'doctor']), async (req, res) => {
    try {
        const { patientId, doctorId } = req.params;
        const requestingUserId = req.user.id;
        const userRole = req.user.role;

        // Validate access: patients can only see their own chats, doctors can see assigned patients
        if (userRole === 'patient' && parseInt(patientId) !== requestingUserId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        if (userRole === 'doctor' && parseInt(doctorId) !== requestingUserId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const query = `
            SELECT c.*, u_sender.name as sender_name, u_recipient.name as recipient_name
            FROM communications c
            JOIN users u_sender ON (
                (c.direction = 'patient_to_doctor' AND u_sender.id = c.patient_id) OR
                (c.direction = 'doctor_to_patient' AND u_sender.id = c.doctor_id)
            )
            JOIN users u_recipient ON (
                (c.direction = 'patient_to_doctor' AND u_recipient.id = c.doctor_id) OR
                (c.direction = 'doctor_to_patient' AND u_recipient.id = c.patient_id)
            )
            WHERE c.patient_id = ? AND c.doctor_id = ?
            ORDER BY c.timestamp ASC
            LIMIT 1000
        `;
        const [rows] = await db.execute(query, [patientId, doctorId]);

        res.json({ messages: rows });

    } catch (error) {
        console.error('Chat history error:', error);
        res.status(500).json({ error: 'Failed to fetch chat history' });
    }
});

// POST /api/chat/webhook
// WhatsApp webhook to receive incoming messages
router.post('/webhook', async (req, res) => {
    try {
        // Verify webhook (in production, implement Twilio signature validation)
        const { From, To, Body, MessageSid } = req.body;

        // Extract phone numbers (remove whatsapp: prefix)
        const senderNumber = From.replace('whatsapp:', '');
        const recipientNumber = To.replace('whatsapp:', '');

        // Find sender and recipient users
        // This is a simplified implementation - in production, maintain a phone->user mapping
        const [senderRows] = await db.execute('SELECT id, role FROM users WHERE phone = ?', [senderNumber]);
        const [recipientRows] = await db.execute('SELECT id, role FROM users WHERE phone = ?', [recipientNumber]);

        if (senderRows.length === 0 || recipientRows.length === 0) {
            return res.status(200).send('OK'); // Acknowledge but ignore unknown numbers
        }

        const sender = senderRows[0];
        const recipient = recipientRows[0];

        // Determine direction and IDs
        let direction, patient_id, doctor_id;
        if (sender.role === 'patient') {
            direction = 'patient_to_doctor';
            patient_id = sender.id;
            doctor_id = recipient.id;
        } else {
            direction = 'doctor_to_patient';
            patient_id = recipient.id;
            doctor_id = sender.id;
        }

        // Log incoming message
        const content_preview = Body.length > 500 ? Body.substring(0, 500) + '...' : Body;
        const query = `
            INSERT INTO communications
            (patient_id, doctor_id, whatsapp_message_id, direction, content_preview)
            VALUES (?, ?, ?, ?, ?)
        `;
        await db.execute(query, [patient_id, doctor_id, MessageSid, direction, content_preview]);

        // Send FCM notification to recipient
        const [fcmTokens] = await db.execute('SELECT fcm_token FROM users WHERE id = ? AND fcm_token IS NOT NULL', [recipient.id]);
        if (fcmTokens.length > 0) {
            fcm.sendMulticast({
                tokens: fcmTokens.map(row => row.fcm_token),
                notification: {
                    title: 'New WhatsApp message',
                    body: content_preview
                },
                data: {
                    type: 'whatsapp_message',
                    sender_id: sender.id.toString()
                }
            }).catch(err => console.error('FCM send error:', err));
        }

        res.status(200).send('OK');

    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).send('Error');
    }
});

module.exports = router;

// Comments for academic documentation:
// - POST /send: Handles outgoing messages with mock mode for development
// - Mock mode: Console logging when WHATSAPP_MOCK=true for testing
// - Database logging: All communications tracked for audit purposes
// - GET /history: Secure access to conversation history
// - POST /webhook: Receives incoming WhatsApp messages via Twilio
// - FCM integration: Push notifications for real-time messaging