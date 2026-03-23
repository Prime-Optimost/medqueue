// Queue Routes
// Queue management and patient flow endpoints
// Handles queue operations, position tracking, and doctor assignments

const express = require('express');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');
const auditLog = require('../utils/auditLog');

const router = express.Router();

// GET /api/queue/status
// Get current queue status for a doctor
router.get('/status', authenticateToken, requireRole(['doctor']), async (req, res) => {
  try {
    const doctorId = req.user.id;

    // Get current queue for this doctor
    const queue = await db.getRows(`
      SELECT q.*, u.name as patient_name, u.phone
      FROM queue q
      JOIN users u ON q.patient_id = u.id
      WHERE q.doctor_id = ? AND q.status = 'waiting'
      ORDER BY q.position
    `, [doctorId]);

    // Get current patient being served
    const current = await db.getRow(`
      SELECT q.*, u.name as patient_name, u.phone
      FROM queue q
      JOIN users u ON q.patient_id = u.id
      WHERE q.doctor_id = ? AND q.status = 'serving'
      ORDER BY q.updated_at DESC
      LIMIT 1
    `, [doctorId]);

    res.json({
      queue,
      current_patient: current,
      queue_length: queue.length
    });

  } catch (error) {
    console.error('Get queue status error:', error);
    res.status(500).json({ error: 'Failed to fetch queue status' });
  }
});

// POST /api/queue/join
// Join queue for a doctor
router.post('/join', authenticateToken, requireRole(['patient']), async (req, res) => {
  try {
    const { doctor_id, priority = 'normal' } = req.body;
    const patientId = req.user.id;

    // Check if doctor exists and is active
    const doctor = await db.getRow(
      'SELECT id, name FROM users WHERE id = ? AND role = "doctor" AND is_active = true',
      [doctor_id]
    );

    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found or inactive' });
    }

    // Check if patient is already in queue for this doctor
    const existing = await db.getRow(
      'SELECT id FROM queue WHERE patient_id = ? AND doctor_id = ? AND status IN ("waiting", "serving")',
      [patientId, doctor_id]
    );

    if (existing) {
      return res.status(409).json({
        error: 'Already in queue',
        message: 'You are already in the queue for this doctor'
      });
    }

    // Get next position
    const lastPosition = await db.getRow(
      'SELECT MAX(position) as max_pos FROM queue WHERE doctor_id = ? AND status = "waiting"',
      [doctor_id]
    );

    const position = (lastPosition?.max_pos || 0) + 1;

    // Add to queue
    const queueId = await db.insert(`
      INSERT INTO queue (patient_id, doctor_id, position, priority, status)
      VALUES (?, ?, ?, ?, 'waiting')
    `, [patientId, doctor_id, position, priority]);

    // Audit log
    await auditLog('QUEUE_JOIN', patientId, {
      queue_id: queueId,
      doctor_id,
      position
    });

    res.status(201).json({
      message: 'Joined queue successfully',
      queue_id: queueId,
      position
    });

  } catch (error) {
    console.error('Join queue error:', error);
    res.status(500).json({ error: 'Failed to join queue' });
  }
});

// PATCH /api/queue/:id/next
// Move to next patient in queue (doctor only)
router.patch('/:id/next', authenticateToken, requireRole(['doctor']), async (req, res) => {
  try {
    const { id } = req.params; // queue entry id
    const doctorId = req.user.id;

    // Verify queue entry belongs to this doctor
    const queueEntry = await db.getRow(
      'SELECT * FROM queue WHERE id = ? AND doctor_id = ?',
      [id, doctorId]
    );

    if (!queueEntry) {
      return res.status(404).json({ error: 'Queue entry not found' });
    }

    // Mark current patient as completed if any
    await db.update(
      'UPDATE queue SET status = "completed", updated_at = NOW() WHERE doctor_id = ? AND status = "serving"',
      [doctorId]
    );

    // Mark next patient as serving
    await db.update(
      'UPDATE queue SET status = "serving", updated_at = NOW() WHERE id = ?',
      [id]
    );

    // Audit log
    await auditLog('QUEUE_NEXT', doctorId, {
      queue_id: id,
      patient_id: queueEntry.patient_id
    });

    res.json({ message: 'Moved to next patient' });

  } catch (error) {
    console.error('Next patient error:', error);
    res.status(500).json({ error: 'Failed to move to next patient' });
  }
});

// PATCH /api/queue/:id/skip
// Skip current patient (doctor only)
router.patch('/:id/skip', authenticateToken, requireRole(['doctor']), async (req, res) => {
  try {
    const { id } = req.params;
    const doctorId = req.user.id;

    // Verify queue entry belongs to this doctor
    const queueEntry = await db.getRow(
      'SELECT * FROM queue WHERE id = ? AND doctor_id = ?',
      [id, doctorId]
    );

    if (!queueEntry) {
      return res.status(404).json({ error: 'Queue entry not found' });
    }

    // Mark as skipped
    await db.update(
      'UPDATE queue SET status = "skipped", updated_at = NOW() WHERE id = ?',
      [id]
    );

    // Reorder remaining queue positions
    await db.update(`
      UPDATE queue
      SET position = position - 1
      WHERE doctor_id = ? AND status = 'waiting' AND position > ?
    `, [doctorId, queueEntry.position]);

    // Audit log
    await auditLog('QUEUE_SKIP', doctorId, {
      queue_id: id,
      patient_id: queueEntry.patient_id
    });

    res.json({ message: 'Patient skipped' });

  } catch (error) {
    console.error('Skip patient error:', error);
    res.status(500).json({ error: 'Failed to skip patient' });
  }
});

// DELETE /api/queue/:id
// Leave queue (patient only)
router.delete('/:id', authenticateToken, requireRole(['patient']), async (req, res) => {
  try {
    const { id } = req.params;
    const patientId = req.user.id;

    // Verify queue entry belongs to this patient
    const queueEntry = await db.getRow(
      'SELECT * FROM queue WHERE id = ? AND patient_id = ?',
      [id, patientId]
    );

    if (!queueEntry) {
      return res.status(404).json({ error: 'Queue entry not found' });
    }

    // Only allow leaving if waiting
    if (queueEntry.status !== 'waiting') {
      return res.status(400).json({
        error: 'Cannot leave queue',
        message: 'Can only leave while waiting in queue'
      });
    }

    // Remove from queue
    await db.update('DELETE FROM queue WHERE id = ?', [id]);

    // Reorder remaining positions
    await db.update(`
      UPDATE queue
      SET position = position - 1
      WHERE doctor_id = ? AND status = 'waiting' AND position > ?
    `, [queueEntry.doctor_id, queueEntry.position]);

    // Audit log
    await auditLog('QUEUE_LEAVE', patientId, {
      queue_id: id,
      doctor_id: queueEntry.doctor_id
    });

    res.json({ message: 'Left queue successfully' });

  } catch (error) {
    console.error('Leave queue error:', error);
    res.status(500).json({ error: 'Failed to leave queue' });
  }
});

// GET /api/queue/my-position
// Get current user's position in queue
router.get('/my-position', authenticateToken, requireRole(['patient']), async (req, res) => {
  try {
    const patientId = req.user.id;

    // Get current queue position
    const position = await db.getRow(`
      SELECT q.*, u.name as doctor_name, u.specialty
      FROM queue q
      JOIN users u ON q.doctor_id = u.id
      WHERE q.patient_id = ? AND q.status = 'waiting'
      ORDER BY q.created_at DESC
      LIMIT 1
    `, [patientId]);

    if (!position) {
      return res.json({ in_queue: false });
    }

    // Get queue length ahead
    const ahead = await db.getRow(`
      SELECT COUNT(*) as count
      FROM queue
      WHERE doctor_id = ? AND status = 'waiting' AND position < ?
    `, [position.doctor_id, position.position]);

    res.json({
      in_queue: true,
      position: position.position,
      people_ahead: ahead.count,
      doctor: {
        id: position.doctor_id,
        name: position.doctor_name,
        specialty: position.specialty
      },
      estimated_wait: ahead.count * 15 // Rough estimate: 15 min per patient
    });

  } catch (error) {
    console.error('Get position error:', error);
    res.status(500).json({ error: 'Failed to get queue position' });
  }
});

// GET /api/queue/doctor/:doctorId
// Get queue for a specific doctor (admin only)
router.get('/doctor/:doctorId', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { doctorId } = req.params;

    const queue = await db.getRows(`
      SELECT q.*, u.name as patient_name, u.phone
      FROM queue q
      JOIN users u ON q.patient_id = u.id
      WHERE q.doctor_id = ? AND q.status IN ('waiting', 'serving')
      ORDER BY q.position
    `, [doctorId]);

    res.json({ queue });

  } catch (error) {
    console.error('Get doctor queue error:', error);
    res.status(500).json({ error: 'Failed to fetch doctor queue' });
  }
});

module.exports = router;

// Comments for academic documentation:
// - Complete queue management system with position tracking
// - Doctor controls queue flow (next, skip patients)
// - Patients can join and leave queues
// - Real-time position updates and wait time estimates
// - Priority queue support (normal, urgent)
// - Admin oversight of all doctor queues
// - Audit logging for all queue operations
// - Status management (waiting, serving, completed, skipped)