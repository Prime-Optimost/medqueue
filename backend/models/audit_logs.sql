-- Audit Logs Table Schema
-- Security and compliance logging for all sensitive actions
-- Tracks user activities for audit trails and system monitoring

CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(100) NOT NULL,
    user_id INT NOT NULL,
    details JSON,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_action (action),
    INDEX idx_user_timestamp (user_id, timestamp),
    INDEX idx_timestamp (timestamp),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Comments for academic documentation:
-- - id: Unique identifier for each audit entry
-- - action: Type of action performed (LOGIN, BOOK_APPOINTMENT, etc.)
-- - user_id: ID of the user who performed the action
-- - details: JSON object containing action-specific information
-- - ip_address: IP address from which the action was performed
-- - timestamp: When the action occurred
-- - Indexes for efficient querying and reporting