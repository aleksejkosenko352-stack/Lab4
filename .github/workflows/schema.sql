CREATE TABLE department (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

CREATE TABLE employee (
    emp_id SERIAL PRIMARY KEY,
    dept_id INTEGER NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),

    CONSTRAINT fk_employee_dept
        FOREIGN KEY (dept_id)
        REFERENCES department (dept_id)
);
