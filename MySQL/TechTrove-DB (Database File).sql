CREATE DATABASE tech_trove_db;
CREATE TABLE roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL,
    description VARCHAR(255)
);
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(20),
    department VARCHAR(50),
    hire_date DATE,
    role_id INT,
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);
CREATE TABLE projects (
    project_id INT PRIMARY KEY AUTO_INCREMENT,
    client_name VARCHAR(150),
    client_email VARCHAR(150),
    project_name VARCHAR(150),
    assigned_engineer VARCHAR(100),
    project_status VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12,2),
    access_level VARCHAR(50),
    data_sensitivity VARCHAR(50),
    issue_reported TEXT,
    last_access DATETIME
);
CREATE TABLE issues (
    issue_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT,
    issue_reported TEXT,
    date_reported DATETIME,
    severity VARCHAR(50),
    reported_by VARCHAR(100),
    status VARCHAR(50),
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);
CREATE TABLE access_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(100),
    timestamp DATETIME,
    ip_address VARCHAR(45),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);
-- Inserted data into all tables
-- RBAC
-- 1. Administrator: full access
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'Admin#999';
GRANT ALL PRIVILEGES ON tech_trove_db.* TO 'admin_user'@'%';
-- 2. Manager: manage projects and view users
CREATE USER 'manager_user'@'%' IDENTIFIED BY 'Manager#123';
GRANT SELECT, INSERT, UPDATE, DELETE ON tech_trove_db.projects TO 'manager_user'@'%';
GRANT SELECT ON tech_trove_db.users TO 'manager_user'@'%';
-- 3. Engineer: view and update assigned projects
CREATE USER 'engineer_user'@'%' IDENTIFIED BY 'Engineer#321';
GRANT SELECT, UPDATE ON tech_trove_db.projects TO 'engineer_user'@'%';
GRANT SELECT ON tech_trove_db.issues TO 'engineer_user'@'%';
-- 4. Analyst: read-only access for reporting
CREATE USER 'analyst_user'@'%' IDENTIFIED BY 'Analyst#456';
GRANT SELECT ON tech_trove_db.* TO 'analyst_user'@'%';
-- 5. Support: handle issues only
CREATE USER 'support_user'@'%' IDENTIFIED BY 'Support#654';
GRANT SELECT, INSERT, UPDATE ON tech_trove_db.issues TO 'support_user'@'%';
-- 6. Auditor: read-only access with focus on logs
CREATE USER 'auditor_user'@'%' IDENTIFIED BY 'Audit#888';
GRANT SELECT ON tech_trove_db.access_logs TO 'auditor_user'@'%';
GRANT SELECT ON tech_trove_db.projects TO 'auditor_user'@'%';
-- 7. Team Lead: manage assigned projects and review team issues
CREATE USER 'teamlead_user'@'%' IDENTIFIED BY 'TeamLead#777';
GRANT SELECT, INSERT, UPDATE ON tech_trove_db.projects TO 'teamlead_user'@'%';
GRANT SELECT, UPDATE ON tech_trove_db.issues TO 'teamlead_user'@'%';
GRANT SELECT ON tech_trove_db.users TO 'teamlead_user'@'%';
FLUSH PRIVILEGES;
-- Encryption
SET @key = 'T3chTr0v3_S3cur3Key#2025';
ALTER TABLE projects 
MODIFY client_name VARBINARY(255),
MODIFY client_email VARBINARY(255);
UPDATE projects
SET 
    client_name = AES_ENCRYPT(client_name, @key),
    client_email = AES_ENCRYPT(client_email, @key);
SELECT client_name, client_email FROM projects;
SELECT 
    CAST(AES_DECRYPT(client_name, @key) AS CHAR) AS client_name,
    CAST(AES_DECRYPT(client_email, @key) AS CHAR) AS client_email
FROM projects;
-- Creating Decrypted View
CREATE OR REPLACE VIEW decrypted_projects AS
SELECT 
    project_id,
    CAST(AES_DECRYPT(client_name, 'T3chTr0v3_S3cur3Key#2025') AS CHAR) AS client_name,
    CAST(AES_DECRYPT(client_email, 'T3chTr0v3_S3cur3Key#2025') AS CHAR) AS client_email,
    project_name,
    project_status,
    budget
FROM projects;
GRANT SELECT ON tech_trove_db.decrypted_projects TO 'manager_user'@'%';
GRANT SELECT ON tech_trove_db.decrypted_projects TO 'admin_user'@'%';
REVOKE SELECT ON tech_trove_db.decrypted_projects FROM 'engineer_user'@'%';
REVOKE SELECT ON tech_trove_db.* FROM 'engineer_user'@'%';
GRANT SELECT ON tech_trove_db.projects TO 'engineer_user'@'%';
-- Encrypting Budget and Issues Reported
SET @key = 'T3chTr0v3_S3cur3Key#2025';
ALTER TABLE projects 
MODIFY budget VARBINARY(255);
ALTER TABLE issues 
MODIFY issue_reported VARBINARY(255);
UPDATE projects 
SET budget = AES_ENCRYPT(budget, @key);
UPDATE issues 
SET issue_reported = AES_ENCRYPT(issue_reported, @key);
CREATE OR REPLACE VIEW decrypted_projects AS
SELECT 
    project_id,
    CAST(AES_DECRYPT(client_name, 'T3chTr0v3_S3cur3Key#2025') AS CHAR) AS client_name,
    CAST(AES_DECRYPT(client_email, 'T3chTr0v3_S3cur3Key#2025') AS CHAR) AS client_email,
    CAST(AES_DECRYPT(budget, 'T3chTr0v3_S3cur3Key#2025') AS CHAR) AS budget,
    project_name,
    project_status
FROM projects;

CREATE OR REPLACE VIEW decrypted_issues AS
SELECT 
    issue_id,
    project_id,
    CAST(AES_DECRYPT(issue_reported, 'T3chTr0v3_S3cur3Key#2025') AS CHAR) AS issue_reported,
    severity,
    status
FROM issues;
-- Admin and Manager can see decrypted views
GRANT SELECT ON tech_trove_db.decrypted_projects TO 'admin_user'@'%';
GRANT SELECT ON tech_trove_db.decrypted_projects TO 'manager_user'@'%';
GRANT SELECT ON tech_trove_db.decrypted_issues TO 'admin_user'@'%';
GRANT SELECT ON tech_trove_db.decrypted_issues TO 'manager_user'@'%';
-- All others see only encrypted data
GRANT SELECT ON tech_trove_db.projects TO 'engineer_user'@'%';
GRANT SELECT ON tech_trove_db.issues TO 'engineer_user'@'%';
GRANT SELECT ON tech_trove_db.projects TO 'analyst_user'@'%';
GRANT SELECT ON tech_trove_db.issues TO 'analyst_user'@'%';
GRANT SELECT ON tech_trove_db.projects TO 'support_user'@'%';
GRANT SELECT ON tech_trove_db.issues TO 'support_user'@'%';
GRANT SELECT ON tech_trove_db.projects TO 'auditor_user'@'%';
GRANT SELECT ON tech_trove_db.issues TO 'auditor_user'@'%';
GRANT SELECT ON tech_trove_db.projects TO 'teamlead_user'@'%';
GRANT SELECT ON tech_trove_db.issues TO 'teamlead_user'@'%';

