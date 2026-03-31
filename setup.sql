-- MedQueue GH Database Setup
-- Combined SQL file for complete database initialization
-- Run this file to create all tables and seed data

CREATE DATABASE IF NOT EXISTS medqueue_gh;
USE medqueue_gh;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'doctor', 'patient') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- Appointments table
CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status ENUM('pending', 'confirmed', 'completed', 'cancelled') DEFAULT 'pending',
    reason TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_patient (patient_id),
    INDEX idx_doctor (doctor_id),
    INDEX idx_date (appointment_date),
    INDEX idx_status (status)
);

-- Availability slots table
CREATE TABLE availability_slots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_slot (doctor_id, date, time),
    INDEX idx_doctor_date (doctor_id, date)
);

-- Virtual queues table
CREATE TABLE virtual_queues (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    position INT NOT NULL,
    status ENUM('waiting', 'called', 'completed') DEFAULT 'waiting',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,
    INDEX idx_appointment (appointment_id),
    INDEX idx_status (status)
);

-- Notifications table
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    type ENUM('appointment', 'queue', 'emergency', 'general') DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_type (type),
    INDEX idx_read (is_read)
);

-- Ambulances table (for emergency requests)
CREATE TABLE ambulances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    status ENUM('available', 'dispatched', 'maintenance') DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chatbot interactions table
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

-- Emergency requests table
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
    FOREIGN KEY (ambulance_id) REFERENCES ambulances(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_request_time (request_time),
    INDEX idx_patient (patient_id)
);

-- Communications table
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

-- Audit logs table
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

-- Seed data
-- Note: Passwords are bcrypt hashed with 12 rounds
-- Admin user
INSERT INTO users (full_name, phone_number, email, password, role) VALUES
('Admin User', '+1234567890', 'admin@medqueue.gh', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPjYLC3TkF5W', 'admin');

-- Doctor users
INSERT INTO users (full_name, phone_number, email, password, role) VALUES
('Dr. John Smith', '+1234567891', 'doctor1@medqueue.gh', '$2a$12$abcdefghijklmnopqrstuvwxYZ0123456789', 'doctor'),
('Dr. Jane Doe', '+1234567892', 'doctor2@medqueue.gh', '$2a$12$abcdefghijklmnopqrstuvwxYZ0123456789', 'doctor');

-- Patient users
INSERT INTO users (full_name, phone_number, email, password, role) VALUES
('Patient One', '+1234567893', 'patient1@medqueue.gh', '$2a$12$abcdefghijklmnopqrstuvwxYZ0123456789', 'patient'),
('Patient Two', '+1234567894', 'patient2@medqueue.gh', '$2a$12$abcdefghijklmnopqrstuvwxYZ0123456789', 'patient');

-- Availability slots for today and tomorrow
-- Assuming today is CURDATE(), tomorrow is CURDATE() + INTERVAL 1 DAY
INSERT INTO availability_slots (doctor_id, date, time, is_available) VALUES
-- Doctor 1 (id=2) slots
(2, CURDATE(), '09:00:00', TRUE),
(2, CURDATE(), '10:00:00', TRUE),
(2, CURDATE(), '11:00:00', TRUE),
(2, CURDATE() + INTERVAL 1 DAY, '09:00:00', TRUE),
(2, CURDATE() + INTERVAL 1 DAY, '10:00:00', TRUE),
(2, CURDATE() + INTERVAL 1 DAY, '11:00:00', TRUE),
-- Doctor 2 (id=3) slots
(3, CURDATE(), '14:00:00', TRUE),
(3, CURDATE(), '15:00:00', TRUE),
(3, CURDATE(), '16:00:00', TRUE),
(3, CURDATE() + INTERVAL 1 DAY, '14:00:00', TRUE),
(3, CURDATE() + INTERVAL 1 DAY, '15:00:00', TRUE),
(3, CURDATE() + INTERVAL 1 DAY, '16:00:00', TRUE);

-- Sample ambulance
INSERT INTO ambulances (license_plate) VALUES ('AMB-001');