// Emergency Routes
// Handles one-tap SOS emergency requests and admin management
// Endpoints: POST /api/emergency/sos, GET /api/emergency/active, PATCH /api/emergency/:id/status

const express = require('express');
const router = express.Router();
const db = require('../config/database'); // Assuming database config exists
const { authenticateToken, requireRole } = require('../middleware/auth'); // JWT middleware
const fcm = require('../config/fcm'); // Assuming FCM config exists

// POST /api/emergency/sos
// Receives patient SOS request, saves to DB, sends FCM notifications
router.post('/sos', authenticateToken, requireRole(['patient']), async (req, res) => {
    try {
        const { latitude, longitude, description } = req.body;
        const patient_id = req.user.id;

        // Validate required coordinates
        if (!latitude || !longitude) {
            return res.status(400).json({ error: 'GPS coordinates are required' });
        }

        // Get patient name for notification
        const [patientRows] = await db.execute('SELECT name FROM users WHERE id = ?', [patient_id]);
        const patientName = patientRows[0]?.name || 'Unknown Patient';

        // Save emergency request
        const query = `
            INSERT INTO emergency_requests
            (patient_id, latitude, longitude, description)
            VALUES (?, ?, ?, ?)
        `;
        const [result] = await db.execute(query, [patient_id, latitude, longitude, description || null]);

        // Send FCM push notification to all admin accounts
        const notificationMessage = `🚨 EMERGENCY: Patient ${patientName} has triggered SOS at coordinates: ${latitude}, ${longitude}`;

        // Get all admin FCM tokens
        const [adminTokens] = await db.execute(`
            SELECT fcm_token FROM users
            WHERE role = 'admin' AND fcm_token IS NOT NULL
        `);

        // Send notifications asynchronously (non-blocking)
        if (adminTokens.length > 0) {
            const tokens = adminTokens.map(row => row.fcm_token);
            fcm.sendMulticast({
                tokens,
                notification: {
                    title: 'Emergency SOS Alert',
                    body: notificationMessage
                },
                data: {
                    type: 'emergency',
                    emergency_id: result.insertId.toString(),
                    patient_id: patient_id.toString()
                }
            }).catch(err => console.error('FCM send error:', err));
        }

        // Respond immediately (under 5 seconds requirement)
        res.json({
            success: true,
            message: 'Emergency services have been notified. Help is on the way.',
            emergency_id: result.insertId,
            coordinates: { latitude, longitude }
        });

    } catch (error) {
        console.error('Emergency SOS error:', error);
        res.status(500).json({ error: 'Failed to process emergency request' });
    }
});

// GET /api/emergency/active
// Admin/doctor views all active emergency requests
router.get('/active', authenticateToken, requireRole(['admin', 'doctor']), async (req, res) => {
    try {
        const query = `
            SELECT er.*, u.name as patient_name, u.phone as patient_phone
            FROM emergency_requests er
            JOIN users u ON er.patient_id = u.id
            WHERE er.status IN ('pending', 'dispatched')
            ORDER BY er.request_time DESC
        `;
        const [rows] = await db.execute(query);

        res.json({ emergencies: rows });

    } catch (error) {
        console.error('Emergency active error:', error);
        res.status(500).json({ error: 'Failed to fetch active emergencies' });
    }
});

// PATCH /api/emergency/:id/status
// Admin updates emergency status
router.patch('/:id/status', authenticateToken, requireRole(['admin']), async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        // Validate status
        const validStatuses = ['pending', 'dispatched', 'completed', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        // Update status and response_time if dispatched
        let query, params;
        if (status === 'dispatched') {
            query = `
                UPDATE emergency_requests
                SET status = ?, response_time = CURRENT_TIMESTAMP
                WHERE id = ?
            `;
            params = [status, id];
        } else {
            query = `UPDATE emergency_requests SET status = ? WHERE id = ?`;
            params = [status, id];
        }

        const [result] = await db.execute(query, params);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Emergency request not found' });
        }

        res.json({ success: true, message: `Emergency status updated to ${status}` });

    } catch (error) {
        console.error('Emergency status update error:', error);
        res.status(500).json({ error: 'Failed to update emergency status' });
    }
});

module.exports = router;

// Comments for academic documentation:
// - POST /sos: Fast emergency response with immediate confirmation
// - FCM notifications: Asynchronous push alerts to admin devices
// - GET /active: Real-time monitoring of emergency situations
// - PATCH /status: Workflow management for emergency response teams
// - Performance: Optimized for sub-5-second response times