-- Communications Table Schema
-- This table logs WhatsApp communications between patients and doctors
-- Supports both directions and links to appointments

CREATE TABLE communications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    whatsapp_message_id VARCHAR(255),
    direction ENUM('patient_to_doctor', 'doctor_to_patient') NOT NULL,
    content_preview VARCHAR(500),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    appointment_id INT,
    FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL,
    INDEX idx_patient_doctor (patient_id, doctor_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_appointment (appointment_id)
);

-- Comments for academic documentation:
-- - id: Unique identifier for each communication
-- - patient_id: Foreign key to the patient
-- - doctor_id: Foreign key to the doctor
-- - whatsapp_message_id: Unique ID from WhatsApp API
-- - direction: Whether message is from patient to doctor or vice versa
-- - content_preview: First 500 characters of the message content
-- - timestamp: When the message was sent
-- - appointment_id: Links to related appointment if applicable