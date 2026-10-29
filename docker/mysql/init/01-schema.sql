-- =============================================================
-- QA Live Healthcare - database schema
-- Executed automatically the first time the MySQL container starts
-- (files in /docker-entrypoint-initdb.d are run in file-name order).
-- =============================================================

-- Guarantee UTF-8 parsing regardless of the mysql client's default charset.
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS doctor_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE doctor_db;

-- -------------------------------------------------------------
-- doctor: replaces web/qa-web/src/data/doctor-user-list.json
-- -------------------------------------------------------------
DROP TABLE IF EXISTS doctor;
CREATE TABLE doctor (
  id          VARCHAR(20)  NOT NULL COMMENT '业务主键，如 doc001',
  username    VARCHAR(50)  NOT NULL COMMENT '登录用户名',
  password    VARCHAR(100) NOT NULL COMMENT 'BCrypt 密码哈希',
  name        VARCHAR(50)  NOT NULL COMMENT '医生姓名',
  title       VARCHAR(50)  DEFAULT NULL COMMENT '职称',
  department  VARCHAR(100) DEFAULT NULL COMMENT '科室',
  avatar      VARCHAR(255) DEFAULT NULL COMMENT '头像 URL',
  experience  VARCHAR(100) DEFAULT NULL COMMENT '从业经验',
  specialties JSON         DEFAULT NULL COMMENT '擅长领域（JSON 数组）',
  is_active   TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '是否在线接诊',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_doctor_username (username)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '医生信息';

-- -------------------------------------------------------------
-- patient: consultation users (username + password login)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS patient;
CREATE TABLE patient (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  username    VARCHAR(50)  NOT NULL COMMENT '登录用户名',
  password    VARCHAR(100) NOT NULL COMMENT 'BCrypt 密码哈希',
  name        VARCHAR(50)  NOT NULL COMMENT '患者姓名',
  birthday    DATE         DEFAULT NULL,
  phone       VARCHAR(20)  DEFAULT NULL,
  gender      VARCHAR(10)  DEFAULT NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_patient_username (username)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '问诊用户（患者）账号';

-- -------------------------------------------------------------
-- Application account used by qa-service-user. On a fresh volume
-- MYSQL_USER already exists; IF NOT EXISTS keeps this script idempotent.
-- -------------------------------------------------------------
CREATE USER IF NOT EXISTS 'qa_user'@'%' IDENTIFIED BY 'Qa@123456';
GRANT ALL PRIVILEGES ON doctor_db.* TO 'qa_user'@'%';
FLUSH PRIVILEGES;
