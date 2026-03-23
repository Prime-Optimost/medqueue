// Authentication Middleware
// JWT token validation and role-based access control
// Protects admin routes and ensures user authentication

const jwt = require('jsonwebtoken');

// JWT Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      error: 'Access token required',
      message: 'Please provide a valid JWT token'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
          error: 'Token expired',
          message: 'Your session has expired. Please login again.'
        });
      }
      return res.status(403).json({
        error: 'Invalid token',
        message: 'The provided token is invalid or malformed'
      });
    }

    req.user = user; // Attach user info to request
    next();
  });
};

// Role-based Access Control Middleware
const requireRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'You must be logged in to access this resource'
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Insufficient permissions',
        message: `This resource requires one of the following roles: ${allowedRoles.join(', ')}`
      });
    }

    next();
  };
};

// Optional authentication (doesn't fail if no token)
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token) {
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (!err) {
        req.user = user;
      }
      next();
    });
  } else {
    next();
  }
};

module.exports = {
  authenticateToken,
  requireRole,
  optionalAuth
};

// Comments for academic documentation:
// - Auth Middleware: JWT validation and role-based access control
// - authenticateToken: Verifies JWT and attaches user to request
// - requireRole: Checks if user has required role permissions
// - optionalAuth: Allows routes to work with or without authentication
// - Error responses include specific messages for better UX
// - Token expiry handling with clear error messages