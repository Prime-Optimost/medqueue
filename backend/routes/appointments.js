// Appointment Routes
// Appointment booking, management, and doctor schedule endpoints
// Handles patient appointment operations with validation

const express = require('express');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { validateAppointmentBooking } = require('../middleware/validation');
const auditLog = require('../utils/auditLog');

const router = express.Router();

// GET /api/appointments/my
// Get current user's appointments (patient or doctor view)
router.get('/my', authenticateToken, async (req, res) => {
  try {
    let query, params;

    if (req.user.role === 'patient') {
      // Patient sees their own appointments
      query = `
        SELECT a.*, d.name as doctor_name, d.specialty
        FROM appointments a
        JOIN users d ON a.doctor_id = d.id
        WHERE a.patient_id = ?
        ORDER BY a.appointment_date DESC, a.appointment_time DESC
      `;
      params = [req.user.id];
    } else if (req.user.role === 'doctor') {
      // Doctor sees their appointments
      query = `
        SELECT a.*, p.name as patient_name
        FROM appointments a
        JOIN users p ON a.patient_id = p.id
        WHERE a.doctor_id = ?
        ORDER BY a.appointment_date DESC, a.appointment_time DESC
      `;
      params = [req.user.id];
    } else {
      return res.status(403).json({ error: 'Invalid role for this endpoint' });
    }

    const appointments = await db.getRows(query, params);
    res.json({ appointments });

  } catch (error) {
    console.error('Get appointments error:', error);
    res.status(500).json({ error: 'Failed to fetch appointments' });
  }
});

// POST /api/appointments/book
// Book a new appointment
router.post('/book', authenticateToken, requireRole(['patient']), validateAppointmentBooking, async (req, res) => {
  try {
    const { doctor_id, appointment_date, start_time, end_time, description } = req.body;
    const patient_id = req.user.id;

    // Check if doctor exists and is active
    const doctor = await db.getRow(
      'SELECT id, name FROM users WHERE id = ? AND role = "doctor" AND is_active = true',
      [doctor_id]
    );

    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found or inactive' });
    }

    // Check for conflicting appointments
    const conflict = await db.getRow(`
      SELECT id FROM appointments
      WHERE doctor_id = ? AND appointment_date = ? AND appointment_time = ?
      AND status NOT IN ('cancelled', 'no_show')
    `, [doctor_id, appointment_date, start_time]);

    if (conflict) {
      return res.status(409).json({
        error: 'Time slot unavailable',
        message: 'This time slot is already booked'
      });
    }

    // Book appointment
    const appointmentId = await db.insert(`
      INSERT INTO appointments
      (patient_id, doctor_id, appointment_date, appointment_time, end_time, description, status)
      VALUES (?, ?, ?, ?, ?, ?, 'pending')
    `, [patient_id, doctor_id, appointment_date, start_time, end_time, description || null]);

    // Audit log
    await auditLog('APPOINTMENT_BOOK', patient_id, {
      appointment_id: appointmentId,
      doctor_id
    });

    res.status(201).json({
      message: 'Appointment booked successfully',
      appointment_id: appointmentId
    });

  } catch (error) {
    console.error('Book appointment error:', error);
    res.status(500).json({ error: 'Failed to book appointment' });
  }
});

// PATCH /api/appointments/:id
// Update appointment (cancel, reschedule)
router.patch('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, appointment_date, appointment_time, description } = req.body;

    // Get appointment
    const appointment = await db.getRow(
      'SELECT * FROM appointments WHERE id = ?',
      [id]
    );

    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    // Check permissions (patient can modify their own, doctor can modify their patients')
    if (req.user.role === 'patient' && appointment.patient_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (req.user.role === 'doctor' && appointment.doctor_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Build update query
    let updateFields = [];
    let params = [];

    if (status) {
      updateFields.push('status = ?');
      params.push(status);
    }
    if (appointment_date) {
      updateFields.push('appointment_date = ?');
      params.push(appointment_date);
    }
    if (appointment_time) {
      updateFields.push('appointment_time = ?');
      params.push(appointment_time);
    }
    if (description !== undefined) {
      updateFields.push('description = ?');
      params.push(description);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    params.push(id);
    await db.update(`
      UPDATE appointments SET ${updateFields.join(', ')} WHERE id = ?
    `, params);

    // Audit log
    await auditLog('APPOINTMENT_UPDATE', req.user.id, {
      appointment_id: id,
      updates: { status, appointment_date, appointment_time, description }
    });

    res.json({ message: 'Appointment updated successfully' });

  } catch (error) {
    console.error('Update appointment error:', error);
    res.status(500).json({ error: 'Failed to update appointment' });
  }
});

// DELETE /api/appointments/:id
// Cancel appointment
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Get appointment
    const appointment = await db.getRow(
      'SELECT * FROM appointments WHERE id = ?',
      [id]
    );

    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    // Check permissions
    if (req.user.role === 'patient' && appointment.patient_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (req.user.role === 'doctor' && appointment.doctor_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Only allow cancellation of pending/confirmed appointments
    if (!['pending', 'confirmed'].includes(appointment.status)) {
      return res.status(400).json({
        error: 'Cannot cancel appointment',
        message: 'Only pending or confirmed appointments can be cancelled'
      });
    }

    await db.update(
      'UPDATE appointments SET status = "cancelled" WHERE id = ?',
      [id]
    );

    // Audit log
    await auditLog('APPOINTMENT_CANCEL', req.user.id, { appointment_id: id });

    res.json({ message: 'Appointment cancelled successfully' });

  } catch (error) {
    console.error('Cancel appointment error:', error);
    res.status(500).json({ error: 'Failed to cancel appointment' });
  }
});

// GET /api/appointments/doctor-schedule/:doctorId
// Get doctor's available time slots
router.get('/doctor-schedule/:doctorId', authenticateToken, async (req, res) => {
  try {
    const { doctorId } = req.params;
    const { date } = req.query;

    // Check if doctor exists
    const doctor = await db.getRow(
      'SELECT id, name FROM users WHERE id = ? AND role = "doctor" AND is_active = true',
      [doctorId]
    );

    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found' });
    }

    // Get doctor's availability slots
    let query = `
      SELECT * FROM availability_slots
      WHERE doctor_id = ? AND is_available = true
    `;
    let params = [doctorId];

    if (date) {
      query += ' AND date = ?';
      params.push(date);
    }

    query += ' ORDER BY date, start_time';

    const slots = await db.getRows(query, params);
    res.json({ doctor: doctor, slots });

  } catch (error) {
    console.error('Get doctor schedule error:', error);
    res.status(500).json({ error: 'Failed to fetch doctor schedule' });
  }
});

// GET /api/appointments/available-slots
// Get available slots for booking (alternative to doctor-schedule)
router.get('/available-slots', authenticateToken, requireRole(['patient']), async (req, res) => {
  try {
    const { doctor_id, date } = req.query;

    if (!doctor_id || !date) {
      return res.status(400).json({ error: 'doctor_id and date are required' });
    }

    // Get available slots that aren't booked
    const slots = await db.getRows(`
      SELECT s.* FROM availability_slots s
      LEFT JOIN appointments a ON s.doctor_id = a.doctor_id
        AND s.date = a.appointment_date
        AND s.start_time = a.appointment_time
        AND a.status NOT IN ('cancelled', 'no_show')
      WHERE s.doctor_id = ? AND s.date = ? AND s.is_available = true
        AND a.id IS NULL
      ORDER BY s.start_time
    `, [doctor_id, date]);

    res.json({ slots });

  } catch (error) {
    console.error('Get available slots error:', error);
    res.status(500).json({ error: 'Failed to fetch available slots' });
  }
});

module.exports = router;

// Comments for academic documentation:
// - Complete appointment lifecycle management
// - Role-based access control for patients and doctors
// - Conflict detection to prevent double-booking
// - Status validation for appointment operations
// - Doctor schedule and availability slot queries
// - Audit logging for all appointment changes
// - Input validation and error handling