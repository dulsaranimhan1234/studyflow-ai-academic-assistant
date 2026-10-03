CREATE DATABASE IF NOT EXISTS studyflow;

USE studyflow;

CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student VARCHAR(100) NOT NULL,
    subject VARCHAR(150) NOT NULL,
    task VARCHAR(255) NOT NULL,
    deadline DATE NOT NULL,
    priority VARCHAR(20),
    days_remaining INT,
    urgency VARCHAR(20),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
