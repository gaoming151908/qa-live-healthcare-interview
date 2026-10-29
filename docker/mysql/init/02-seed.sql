-- =============================================================
-- Seed data for local development / demo.
-- Doctor password for every seeded doctor: 123456
-- Seeded patient password:                  Patient@123
-- Passwords are BCrypt hashes, never plain text.
-- =============================================================

SET NAMES utf8mb4;
USE doctor_db;

INSERT INTO doctor (id, username, password, name, title, department, avatar, experience, specialties, is_active)
VALUES
  ('doc001', 'dr-zhang-wei',
   '$2y$10$uXx6UPJbLEVtBH7/gW9Cieif.VFuW.6Vo/qrbCqoAOovY.o83w2KK',
   '张伟医生', '主任医师', '心内科',
   'https://images.pexels.com/photos/5215024/pexels-photo-5215024.jpeg?auto=compress&cs=tinysrgb&w=400',
   '15年临床经验', '["高血压", "冠心病", "心律失常"]', 1),
  ('doc002', 'dr-li-na',
   '$2y$10$uXx6UPJbLEVtBH7/gW9Cieif.VFuW.6Vo/qrbCqoAOovY.o83w2KK',
   '李娜医生', '副主任医师', '儿科',
   'https://images.pexels.com/photos/5327585/pexels-photo-5327585.jpeg?auto=compress&cs=tinysrgb&w=400',
   '10年临床经验', '["儿童感冒", "儿童发育", "疫苗接种"]', 1),
  ('doc003', 'dr-wang-qiang',
   '$2y$10$uXx6UPJbLEVtBH7/gW9Cieif.VFuW.6Vo/qrbCqoAOovY.o83w2KK',
   '王强医生', '主治医师', '骨科',
   'https://images.pexels.com/photos/5452293/pexels-photo-5452293.jpeg?auto=compress&cs=tinysrgb&w=400',
   '8年临床经验', '["骨折", "关节炎", "运动损伤"]', 1),
  ('doc004', 'dr-liu-min',
   '$2y$10$uXx6UPJbLEVtBH7/gW9Cieif.VFuW.6Vo/qrbCqoAOovY.o83w2KK',
   '刘敏医生', '主任医师', '妇产科',
   'https://images.pexels.com/photos/5452201/pexels-photo-5452201.jpeg?auto=compress&cs=tinysrgb&w=400',
   '18年临床经验', '["孕期保健", "妇科炎症", "产后恢复"]', 0),
  ('doc005', 'dr-chen-jie',
   '$2y$10$uXx6UPJbLEVtBH7/gW9Cieif.VFuW.6Vo/qrbCqoAOovY.o83w2KK',
   '陈杰医生', '副主任医师', '消化内科',
   'https://images.pexels.com/photos/5215024/pexels-photo-5215024.jpeg?auto=compress&cs=tinysrgb&w=400',
   '12年临床经验', '["胃炎", "肠道疾病", "肝病"]', 1)
ON DUPLICATE KEY UPDATE
  username    = VALUES(username),
  password    = VALUES(password),
  name        = VALUES(name),
  title       = VALUES(title),
  department  = VALUES(department),
  avatar      = VALUES(avatar),
  experience  = VALUES(experience),
  specialties = VALUES(specialties),
  is_active   = VALUES(is_active);

INSERT INTO patient (username, password, name, birthday, phone, gender)
VALUES
  ('zhaoming', '$2y$10$iRn1EcypblwltYmwL1o2UeSnRovEUUcDH/P56lkEzeumuBjZAiPGi',
   '赵明', '1985-03-15', '13800001234', '男'),
  ('sunli', '$2y$10$iRn1EcypblwltYmwL1o2UeSnRovEUUcDH/P56lkEzeumuBjZAiPGi',
   '孙丽', '1990-07-22', '13900005678', '女')
ON DUPLICATE KEY UPDATE
  password = VALUES(password),
  name     = VALUES(name),
  birthday = VALUES(birthday),
  phone    = VALUES(phone),
  gender   = VALUES(gender);
