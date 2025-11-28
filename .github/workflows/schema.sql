-- Схема реляційної БД для SecureRest-SocialGuard (PostgreSQL)

-- Схема 
CREATE SCHEMA IF NOT EXISTS securemon;

SET search_path = securemon, public;

-- Таблиця employees
CREATE TABLE securemon.employees (
  emp_id BIGSERIAL PRIMARY KEY,
  last_name VARCHAR(100) NOT NULL,
  position VARCHAR(100),
  -- посилання на інші таблиці (nullable, зв'язки додаються нижче)
  workload_index_id BIGINT,
  stress_level_id BIGINT,
  corporate_data_id BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Регулярний вираз для last_name:
-- дозволяємо літери української та латиниці, пробіли, дефіс, апостроф; мін 1, макс 100
ALTER TABLE securemon.employees
  ADD CONSTRAINT chk_employees_last_name_regex
  CHECK ( last_name ~ '^[A-Za-zА-Яа-яЁёІіЇїЄєҐґ\'\\-\\s]{1,100}$' );

-- Таблиця workload_data
CREATE TABLE securemon.workload_data (
  wd_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL,
  tasks_count INTEGER DEFAULT 0,
  avg_complexity NUMERIC(5,2) DEFAULT 0,
  avg_time_minutes NUMERIC(6,2) DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_wd_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE CASCADE
);

-- Таблиця workload_index
CREATE TABLE securemon.workload_index (
  wi_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL,
  value NUMERIC(5,2) NOT NULL,
  threshold NUMERIC(5,2) DEFAULT 70.00,
  calculated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_wi_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE CASCADE
);

-- Таблиця stress_level
CREATE TABLE securemon.stress_level (
  sl_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL,
  value INTEGER NOT NULL,
  category VARCHAR(50),
  measured_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_sl_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE CASCADE
);

-- Таблиця recommendations
CREATE TABLE securemon.recommendations (
  rec_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL,
  wi_id BIGINT,
  type VARCHAR(100),
  description TEXT,
  break_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_rec_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE CASCADE,
  CONSTRAINT fk_rec_wi FOREIGN KEY (wi_id) REFERENCES securemon.workload_index(wi_id) ON DELETE SET NULL
);

-- Таблиця social_activity
CREATE TABLE securemon.social_activity (
  sa_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL,
  content_text TEXT NOT NULL,
  content_type VARCHAR(50),
  risk_score NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  external_post_id VARCHAR(200),
  CONSTRAINT fk_sa_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE CASCADE
);

-- Регулярний вираз для external_post_id.
-- Приклад обмеження: дозволяємо літери, цифри, дефіс, підкреслення, двокрапку, слеш; максимум 200 символів.
ALTER TABLE securemon.social_activity
  ADD CONSTRAINT chk_sa_external_post_id_regex
  CHECK ( external_post_id IS NULL OR external_post_id ~ '^[A-Za-z0-9_\\-:\\/\\.]{1,200}$' );

-- Таблиця risk_analysis
CREATE TABLE securemon.risk_analysis (
  ra_id BIGSERIAL PRIMARY KEY,
  sa_id BIGINT,
  wi_id BIGINT,
  risk_level VARCHAR(50),
  description TEXT,
  analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_ra_sa FOREIGN KEY (sa_id) REFERENCES securemon.social_activity(sa_id) ON DELETE SET NULL,
  CONSTRAINT fk_ra_wi FOREIGN KEY (wi_id) REFERENCES securemon.workload_index(wi_id) ON DELETE SET NULL
);

-- Таблиця corporate_data
CREATE TABLE securemon.corporate_data (
  cd_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT UNIQUE,
  work_schedule TEXT,
  constraints TEXT,
  load NUMERIC(5,2),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_cd_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE CASCADE
);

-- Таблиця security_alerts
CREATE TABLE securemon.security_alerts (
  alert_id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT,
  message TEXT,
  alert_type VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  resolved BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_alert_employee FOREIGN KEY (employee_id) REFERENCES securemon.employees(emp_id) ON DELETE SET NULL
);

-- Індекси для швидкого пошуку
CREATE INDEX idx_wi_employee ON securemon.workload_index(employee_id);
CREATE INDEX idx_sl_employee ON securemon.stress_level(employee_id);
CREATE INDEX idx_sa_employee_created ON securemon.social_activity(employee_id, created_at);
CREATE INDEX idx_ra_analyzed_at ON securemon.risk_analysis(analyzed_at);

-- Коментарі 
COMMENT ON TABLE securemon.employees IS 'Співробітники органів безпеки (користувачі системи)';
COMMENT ON COLUMN securemon.employees.last_name IS 'Прізвище співробітника. Обмеження: букви УКР/латиниця, дефіс, пробіли, апостроф.';
COMMENT ON COLUMN securemon.social_activity.external_post_id IS 'Ідентифікатор посту у зовнішній соцмережі (якщо є).';

