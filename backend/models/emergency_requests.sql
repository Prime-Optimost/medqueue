-- Emergency Requests Table Schema
-- This table handles one-tap SOS emergency requests from patients
-- Tracks location, status, and ambulance dispatch information

CREATE TABLE emergency_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location_accuracy DECIMAL(5, 2),
    description TEXT,
    status ENUM('pending', 'dispatched', 'completed', 'cancelled') DEFAULT 'pending',
    ambulance_id INT,
    response_time TIMESTAMP NULL,
    FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (ambulance_id) REFERENCES ambulances(id),
    INDEX idx_status (status),
    INDEX idx_request_time (request_time),
    INDEX idx_patient (patient_id)
);

-- Comments for academic documentation:
-- - id: Unique identifier for each emergency request
-- - patient_id: Foreign key to the patient who triggered SOS
-- - request_time: When the SOS was triggered
-- - latitude/longitude: GPS coordinates of the patient
-- - location_accuracy: Accuracy of GPS location in meters
-- - description: Optional additional description from patient
-- - status: Current status of the emergency response
-- - ambulance_id: Foreign key to assigned ambulance (if dispatched)
-- - response_time: When emergency services responded