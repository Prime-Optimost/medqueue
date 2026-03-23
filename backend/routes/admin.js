// Admin Routes
// Comprehensive admin dashboard endpoints for system management and analytics
// Endpoints: GET /stats, GET /appointments, GET /users, PATCH /users/:id/status, GET /reports/noshow, GET /reports/queue, POST /doctors/slots

const express = require('express');
const router = express.Router();
const db = require('../config/database'); // Assuming database config exists
const { authenticateToken, requireRole } = require('../middleware/auth'); // JWT middleware
const { query, validationResult } = require('express-validator');
const { validateUserStatusUpdate, validateSlotCreation } = require('../middleware/validation');
const auditLog = require('../utils/auditLog');

// GET /api/admin/stats
// Returns summary statistics for admin dashboard
router.get('/stats', authenticateToken, requireRole(['admin']), async (req, res) => {
    try {
        // Get total patients
        const [patientRows] = await db.execute('SELECT COUNT(*) as total FROM users WHERE role = "patient"');
        const totalPatients = patientRows[0].total;

        // Get total doctors
        const [doctorRows] = await db.execute('SELECT COUNT(*) as total FROM users WHERE role = "doctor"');
        const totalDoctors = doctorRows[0].total;

        // Get today's appointments
        const today = new Date().toISOString().split('T')[0];
        const [todayAppts] = await db.execute('SELECT COUNT(*) as total FROM appointments WHERE DATE(appointment_date) = ?', [today]);
        const todaysAppointments = todayAppts[0].total;

        // Get active queue count
        const [queueRows] = await db.execute('SELECT COUNT(*) as total FROM queue WHERE status = "waiting"');
        const activeQueueCount = queueRows[0].total;

        // Get pending emergency requests
        const [emergencyRows] = await db.execute('SELECT COUNT(*) as total FROM emergency_requests WHERE status = "pending"');
        const pendingEmergencies = emergencyRows[0].total;

        // Calculate no-show rate (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const [noshowRows] = await db.execute(`
            SELECT COUNT(*) as noshows FROM appointments
            WHERE status = 'no_show' AND appointment_date >= ?
        `, [thirtyDaysAgo.toISOString().split('T')[0]]);
        const [totalApptsRows] = await db.execute(`
            SELECT COUNT(*) as total FROM appointments
            WHERE appointment_date >= ?
        `, [thirtyDaysAgo.toISOString().split('T')[0]]);
        const noshowRate = totalApptsRows[0].total > 0 ? (noshowRows[0].noshows / totalApptsRows[0].total * 100).toFixed(2) : 0;

        res.json({
            totalPatients,
            totalDoctors,
            todaysAppointments,
            activeQueueCount,
            pendingEmergencies,
            noshowRate: parseFloat(noshowRate)
        });

    } catch (error) {
        console.error('Admin stats error:', error);
        res.status(500).json({ error: 'Failed to fetch admin statistics' });
    }
});

// GET /api/admin/appointments
// Paginated list of all appointments with filters
router.get('/appointments', authenticateToken, requireRole(['admin']), [
    query('page').optional().isInt({ min: 1 }).toInt(),
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
    query('date').optional().isISO8601(),
    query('status').optional().isIn(['pending', 'confirmed', 'completed', 'cancelled', 'no_show']),
    query('doctor_id').optional().isInt().toInt(),
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(422).json({ errors: errors.array() });
        }

        const { page = 1, limit = 20, date, status, doctor_id } = req.query;
        const offset = (page - 1) * limit;

        let whereClause = '';
        let params = [];

        if (date) {
            whereClause += ' AND DATE(a.appointment_date) = ?';
            params.push(date);
        }
        if (status) {
            whereClause += ' AND a.status = ?';
            params.push(status);
        }
        if (doctor_id) {
            whereClause += ' AND a.doctor_id = ?';
            params.push(doctor_id);
        }

        const [rows] = await db.execute(`
            SELECT a.*, u_patient.name as patient_name, u_doctor.name as doctor_name
            FROM appointments a
            JOIN users u_patient ON a.patient_id = u_patient.id
            JOIN users u_doctor ON a.doctor_id = u_doctor.id
            WHERE 1=1 ${whereClause}
            ORDER BY a.appointment_date DESC, a.appointment_time DESC
            LIMIT ? OFFSET ?
        `, [...params, limit, offset]);

        const [countRows] = await db.execute(`
            SELECT COUNT(*) as total FROM appointments a WHERE 1=1 ${whereClause}
        `, params);

        res.json({
            appointments: rows,
            pagination: {
                page,
                limit,
                total: countRows[0].total,
                pages: Math.ceil(countRows[0].total / limit)
            }
        });

    } catch (error) {
        console.error('Admin appointments error:', error);
        res.status(500).json({ error: 'Failed to fetch appointments' });
    }
});

// GET /api/admin/users
// Paginated list of all users with role filter
router.get('/users', authenticateToken, requireRole(['admin']), [
    query('page').optional().isInt({ min: 1 }).toInt(),
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
    query('role').optional().isIn(['patient', 'doctor', 'admin']),
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(422).json({ errors: errors.array() });
        }

        const { page = 1, limit = 20, role } = req.query;
        const offset = (page - 1) * limit;

        let whereClause = '';
        let params = [];

        if (role) {
            whereClause = 'WHERE role = ?';
            params.push(role);
        }

        const [rows] = await db.execute(`
            SELECT id, name, email, phone, role, is_active, created_at
            FROM users
            ${whereClause}
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        `, [...params, limit, offset]);

        const [countRows] = await db.execute(`
            SELECT COUNT(*) as total FROM users ${whereClause}
        `, params);

        res.json({
            users: rows,
            pagination: {
                page,
                limit,
                total: countRows[0].total,
                pages: Math.ceil(countRows[0].total / limit)
            }
        });

    } catch (error) {
        console.error('Admin users error:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// PATCH /api/admin/users/:id/status
// Admin activates or deactivates a user account
router.patch('/users/:id/status', authenticateToken, requireRole(['admin']), validateUserStatusUpdate, async (req, res) => {
    try {
        const { id } = req.params;
        const { is_active } = req.body;

        const [result] = await db.execute(
            'UPDATE users SET is_active = ? WHERE id = ?',
            [is_active, id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Audit log the action
        await auditLog('USER_STATUS_CHANGE', req.user.id, { user_id: id, is_active });

        res.json({ success: true, message: `User ${is_active ? 'activated' : 'deactivated'}` });

    } catch (error) {
        console.error('Admin user status update error:', error);
        res.status(500).json({ error: 'Failed to update user status' });
    }
});

// GET /api/admin/reports/noshow
// Returns no-show statistics grouped by week
router.get('/reports/noshow', authenticateToken, requireRole(['admin']), async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT
                YEARWEEK(appointment_date) as week,
                COUNT(*) as total_appointments,
                SUM(CASE WHEN status = 'no_show' THEN 1 ELSE 0 END) as no_shows,
                ROUND(SUM(CASE WHEN status = 'no_show' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as no_show_rate
            FROM appointments
            WHERE appointment_date >= DATE_SUB(CURDATE(), INTERVAL 12 WEEK)
            GROUP BY YEARWEEK(appointment_date)
            ORDER BY week DESC
        `);

        res.json({ noshowStats: rows });

    } catch (error) {
        console.error('Admin noshow report error:', error);
        res.status(500).json({ error: 'Failed to generate no-show report' });
    }
});

// GET /api/admin/reports/queue
// Returns average wait time per doctor per day
router.get('/reports/queue', authenticateToken, requireRole(['admin']), async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT
                DATE(q.created_at) as date,
                u.name as doctor_name,
                AVG(TIMESTAMPDIFF(MINUTE, q.created_at, q.completed_at)) as avg_wait_minutes
            FROM queue q
            JOIN users u ON q.doctor_id = u.id
            WHERE q.status = 'completed' AND q.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(q.created_at), q.doctor_id
            ORDER BY date DESC, avg_wait_minutes DESC
        `);

        res.json({ queueStats: rows });

    } catch (error) {
        console.error('Admin queue report error:', error);
        res.status(500).json({ error: 'Failed to generate queue report' });
    }
});

// GET /api/admin/reports/appointments-week
// Returns number of appointments per day for the last 7 days
router.get('/reports/appointments-week', authenticateToken, requireRole(['admin']), async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT
                DATE(appointment_date) as date,
                COUNT(*) as total_appointments
            FROM appointments
            WHERE appointment_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
            GROUP BY DATE(appointment_date)
            ORDER BY DATE(appointment_date)
        `);

        res.json({ appointmentWeekStats: rows });
    } catch (error) {
        console.error('Admin appointments week report error:', error);
        res.status(500).json({ error: 'Failed to generate appointments week report' });
    }
});

// GET /api/admin/reports/status-distribution
// Returns appointment status counts for charting
router.get('/reports/status-distribution', authenticateToken, requireRole(['admin']), async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT
                status,
                COUNT(*) as count
            FROM appointments
            WHERE appointment_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY status
        `);

        res.json({ statusDistribution: rows });
    } catch (error) {
        console.error('Admin status distribution report error:', error);
        res.status(500).json({ error: 'Failed to generate status distribution report' });
    }
});

// POST /api/admin/doctors/slots
// Admin creates availability slots for a doctor
router.post('/doctors/slots', authenticateToken, requireRole(['admin']), validateSlotCreation, async (req, res) => {
    try {
        const { doctor_id, date, start_time, end_time, interval_minutes } = req.body;

        // Generate time slots
        const slots = [];
        let currentTime = new Date(`${date}T${start_time}`);
        const endTime = new Date(`${date}T${end_time}`);

        while (currentTime < endTime) {
            slots.push({
                doctor_id,
                date,
                start_time: currentTime.toTimeString().slice(0, 5),
                end_time: new Date(currentTime.getTime() + interval_minutes * 60000).toTimeString().slice(0, 5),
                is_available: true
            });
            currentTime = new Date(currentTime.getTime() + interval_minutes * 60000);
        }

        // Insert slots (assuming availability_slots table exists)
        for (const slot of slots) {
            await db.execute(`
                INSERT INTO availability_slots (doctor_id, date, start_time, end_time, is_available)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE is_available = VALUES(is_available)
            `, [slot.doctor_id, slot.date, slot.start_time, slot.end_time, slot.is_available]);
        }

        // Audit log
        await auditLog('CREATE_SLOTS', req.user.id, { doctor_id, date, slots_created: slots.length });

        res.json({ success: true, slots_created: slots.length });

    } catch (error) {
        console.error('Admin create slots error:', error);
        res.status(500).json({ error: 'Failed to create availability slots' });
    }
});

module.exports = router;

// Comments for academic documentation:
// - Comprehensive admin API with statistics, user management, and reporting
// - Input validation using express-validator for security
// - Parameterized queries prevent SQL injection
// - Audit logging for all sensitive admin actions
// - Pagination for large datasets
// - Role-based access control ensures admin-only access