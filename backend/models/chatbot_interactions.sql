-- Chatbot Interactions Table Schema
-- This table stores all interactions between patients and the AI chatbot
-- Used for medical symptom guidance and emergency flagging

CREATE TABLE chatbot_interactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_id VARCHAR(255) NOT NULL,
    symptom_input TEXT NOT NULL,
    chatbot_response TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_emergency_flagged BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_session (user_id, session_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_emergency (is_emergency_flagged)
);

-- Comments for academic documentation:
-- - id: Unique identifier for each interaction
-- - user_id: Foreign key linking to the patient/user
-- - session_id: Groups interactions within a single chat session
-- - symptom_input: The patient's symptom description
-- - chatbot_response: The AI-generated response with disclaimer
-- - timestamp: When the interaction occurred
-- - is_emergency_flagged: Boolean indicating if symptoms suggest emergency