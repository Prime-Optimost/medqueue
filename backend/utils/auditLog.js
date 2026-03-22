// Audit Log Utility
// Reusable helper for logging sensitive actions to the audit_logs table
// Used across all controllers for security and compliance tracking

const db = require('../config/database'); // Assuming database config exists

/**
 * Logs an audit event to the database
 * @param {string} action - The action performed (e.g., 'LOGIN', 'BOOK_APPOINTMENT')
 * @param {number} userId - ID of the user performing the action
 * @param {object} details - Additional details about the action
 * @param {string} ipAddress - IP address of the request (optional)
 */
async function auditLog(action, userId, details = {}, ipAddress = null) {
    try {
        const query = `
            INSERT INTO audit_logs
            (action, user_id, details, ip_address, timestamp)
            VALUES (?, ?, ?, ?, NOW())
        `;
        const detailsJson = JSON.stringify(details);

        await db.execute(query, [action, userId, detailsJson, ipAddress]);

        console.log(`Audit: ${action} by user ${userId}`);
    } catch (error) {
        console.error('Audit log error:', error);
        // Don't throw error to avoid breaking the main flow
    }
}

module.exports = auditLog;

// Comments for academic documentation:
// - Centralized audit logging utility for security compliance
// - Logs all sensitive actions with user ID and details
// - Asynchronous operation to avoid blocking main requests
// - JSON serialization of action details for flexibility
// - Error handling prevents audit failures from breaking app flow