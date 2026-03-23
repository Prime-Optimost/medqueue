// Validation Middleware
// Input sanitization and validation using express-validator
// Ensures all user inputs are safe and properly formatted

const { body, param, query, validationResult } = require('express-validator');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      error: 'Validation failed',
      message: 'Please check your input data',
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg,
        value: err.value
      }))
    });
  }
  next();
};

// User Registration Validation
const validateRegistration = [
  body('full_name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Full name must be between 2 and 100 characters')
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('Full name can only contain letters and spaces'),

  body('phone_number')
    .trim()
    .matches(/^(\+233|0)[0-9]{9}$/)
    .withMessage('Phone number must be a valid Ghanaian number'),

  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),

  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),

  body('role')
    .isIn(['patient', 'doctor'])
    .withMessage('Role must be either patient or doctor'),

  handleValidationErrors
];

// User Login Validation
const validateLogin = [
  body('username')
    .trim()
    .notEmpty()
    .withMessage('Username is required'),

  body('password')
    .notEmpty()
    .withMessage('Password is required'),

  handleValidationErrors
];

// OTP Verification Validation
const validateOTP = [
  body('user_id')
    .isInt({ min: 1 })
    .withMessage('Valid user ID is required'),

  body('otp')
    .isLength({ min: 6, max: 6 })
    .isNumeric()
    .withMessage('OTP must be exactly 6 digits'),

  handleValidationErrors
];

// Appointment Booking Validation
const validateAppointmentBooking = [
  body('doctor_id')
    .isInt({ min: 1 })
    .withMessage('Valid doctor ID is required'),

  body('appointment_date')
    .isISO8601()
    .withMessage('Valid appointment date is required'),

  body('start_time')
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .withMessage('Start time must be in HH:MM format'),

  body('end_time')
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .withMessage('End time must be in HH:MM format'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),

  handleValidationErrors
];

// Chat Message Validation
const validateChatMessage = [
  body('message')
    .trim()
    .notEmpty()
    .withMessage('Message cannot be empty')
    .isLength({ max: 1000 })
    .withMessage('Message cannot exceed 1000 characters'),

  handleValidationErrors
];

// Chatbot Message Validation
const validateChatbotMessage = [
  body('message')
    .trim()
    .notEmpty()
    .withMessage('Message cannot be empty')
    .isLength({ max: 500 })
    .withMessage('Message cannot exceed 500 characters'),

  handleValidationErrors
];

// Emergency SOS Validation
const validateSOS = [
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Valid latitude is required'),

  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Valid longitude is required'),

  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Description cannot exceed 200 characters'),

  handleValidationErrors
];

// Admin User Status Update Validation
const validateUserStatusUpdate = [
  param('id')
    .isInt({ min: 1 })
    .withMessage('Valid user ID is required'),

  body('status')
    .isIn(['active', 'inactive'])
    .withMessage('Status must be either active or inactive'),

  handleValidationErrors
];

// Admin Slot Creation Validation
const validateSlotCreation = [
  body('doctor_id')
    .isInt({ min: 1 })
    .withMessage('Valid doctor ID is required'),

  body('date')
    .isISO8601()
    .withMessage('Valid date is required'),

  body('start_time')
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .withMessage('Start time must be in HH:MM format'),

  body('end_time')
    .matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .withMessage('End time must be in HH:MM format'),

  body('interval_minutes')
    .isInt({ min: 15, max: 120 })
    .withMessage('Interval must be between 15 and 120 minutes'),

  handleValidationErrors
];

module.exports = {
  validateRegistration,
  validateLogin,
  validateOTP,
  validateAppointmentBooking,
  validateChatMessage,
  validateChatbotMessage,
  validateSOS,
  validateUserStatusUpdate,
  validateSlotCreation,
  handleValidationErrors
};

// Comments for academic documentation:
// - Validation Middleware: Comprehensive input sanitization
// - Field-level validation with specific error messages
// - Ghanaian phone number format validation
// - Strong password requirements
// - Time format validation for appointments
// - Length limits to prevent abuse
// - Coordinate validation for GPS data
// - Role-based validation for admin operations