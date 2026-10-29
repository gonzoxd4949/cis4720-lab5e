/* ==========================================================================
   lab5e_starter.sql
   CIS 4720 Database Management and SQL
   In Class Lab 5e

   WHAT THIS FILE IS
   Completed Lab 5e based on the supplied Lab 5d starter. The numbered
   sections now include all required statements and test queries.

   WHAT IT ALREADY BUILDS
     1. The schema cis_students_db
     2. students, five rows, with a surrogate key that fills itself in
     3. test_scores, ten rows, linked by a foreign key
     4. The student_scores view
     5. The calculate_gpa function, and every gpa filled in

   BEFORE YOU RUN IT
   Connect SQLTools to information_schema first, the same as Lab 5d. The
   first two statements in this file create cis_students_db and switch you
   into it. Step 2 of the lab walks through it.

   HOW TO RUN IT
   One statement at a time. Put the cursor on it and press Ctrl + E twice.
   The function near the bottom is a single statement from CREATE FUNCTION
   down to END, so select the whole block and run the selection.

   LABELING AND COMMENTING IS REQUIRED
   The new Lab 5e statements below include explanatory comments.
   The instructor grades comments as well as the SQL.
   ========================================================================== */


-- This creates the lab database if it does not already exist.
CREATE DATABASE IF NOT EXISTS cis_students_db;

-- This makes the lab database active for the statements that follow.
USE cis_students_db;


-- ======================================================================
-- FROM LAB 5D. The two tables and their data.
-- ======================================================================


CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name  VARCHAR(40) NOT NULL,
    gpa        FLOAT(4,2)
);
INSERT INTO students VALUES (NULL,'Jenna','Wilson',NULL);
INSERT INTO students VALUES (NULL,'Robert','Reese',NULL);
INSERT INTO students VALUES (NULL,'Maria Elena','Jimenez',NULL);
INSERT INTO students VALUES (NULL,'Inder','Singh',NULL);
INSERT INTO students (first_name,last_name) VALUES ('Rita','Nunez');
INSERT INTO students (first_name,last_name) VALUES ('James','Toor');

-- James was student 6. Deleting him is why the counter now says 7.
DELETE FROM students WHERE first_name = 'James' AND last_name = 'Toor';

CREATE TABLE test_scores (
    test_score_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name     VARCHAR(20) NOT NULL,
    student_id    INT NOT NULL,
    score         FLOAT,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

INSERT INTO test_scores VALUES (null,"quiz1",1,90),(null,"quiz1",2,85),(null,"quiz1",3,95),
 (null,"quiz2",1,80),(null,"quiz2",2,72),(null,"quiz2",3,88),(null,"quiz2",4,91),
 (null,"quiz3",2,95),(null,"quiz3",3,94),(null,"quiz3",4,74);


-- ======================================================================
-- FROM LAB 5D. The view.
-- ======================================================================

CREATE VIEW student_scores AS
SELECT s.student_id,
       CONCAT(s.first_name, ' ', s.last_name) AS student_name,
       t.test_name,
       t.score
FROM students s
LEFT OUTER JOIN test_scores t ON s.student_id = t.student_id;


-- ======================================================================
-- FROM LAB 5D. The function. Select this whole block and run the
-- selection, because it is one statement from CREATE down to END.
-- ======================================================================

CREATE FUNCTION calculate_gpa(p_student_id INT)
RETURNS DECIMAL(4,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gpa DECIMAL(4,2);

    SELECT ROUND(AVG(score), 2)
    INTO v_gpa
    FROM test_scores
    WHERE student_id = p_student_id
      AND score IS NOT NULL;

    RETURN IFNULL(v_gpa, 0.00);
END;

UPDATE students SET gpa = calculate_gpa(student_id);


-- ======================================================================
-- CHECKS. These only read, so they are safe to run again any time.
-- Expect 85.00, 84.00, 92.33, 82.50 and 0.00.
-- ======================================================================

SELECT * FROM students;
SELECT * FROM student_scores;


-- ######################################################################
-- LAB 5E SOLUTIONS START BELOW THIS LINE
--
-- LABELING AND COMMENTING IS REQUIRED. It is worth a full point.
--
-- Steps 4 through 10 are completed below. Run each statement in order.
-- ######################################################################


-- =================================================================
-- STEP 4. Look at the counters the server is keeping
-- =================================================================

-- checks the counters information_schema tables
SELECT table_name, auto_increment
FROM information_schema.tables
WHERE table_schema = 'cis_students_db'
 -- AND auto_increment IS NOT NULL;
set session information_schema_stats_expiry=0;

-- =================================================================
-- STEP 5. Create the attendance table, starting its key at 500
-- =================================================================

-- This creates attendance with a generated primary key and links it to students.
-- The first attendance ID will be 500 instead of 1.
CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    attended_on DATE,
    status VARCHAR(10),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
) AUTO_INCREMENT = 500;

-- This displays the column definitions confirms the primary and generated key.
DESCRIBE attendance;


-- =================================================================
-- STEP 6. Add three attendance rows and watch the ids
-- =================================================================

-- This adds three attendance records without using attendance_id values.
INSERT INTO attendance (student_id, attended_on, status)
VALUES (1, '2026-10-05', 'present'),
       (2, '2026-10-05', 'absent'),
       (3, '2026-10-06', 'present');

-- Shows the ID that MySQL generated 500, 501, and 502.
SELECT * FROM attendance;


-- =================================================================
-- STEP 7. DELETE and TRUNCATE on a scrap table
-- =================================================================

-- Creates the scrap table using id with auto_increment and lable varchar(10)
USE cis_students_db;

CREATE TABLE scrap (
    id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(10)
);

-- Adds three rows using generated IDs 1, 2, and 3.
INSERT INTO scrap (label)
VALUES ('one'), ('two'), ('three');

-- Checks the next ID after inserting three rows.
SELECT table_name, auto_increment
FROM information_schema.tables
WHERE table_schema = 'cis_students_db'
  AND auto_increment IS NOT NULL
  AND table_name = 'scrap';

-- Deletes all practice rows while leaving the ID counter unchanged.
DELETE FROM scrap;

-- This checks that DELETE did not reset the counter which should be 4.
SELECT table_name, auto_increment
FROM information_schema.tables
WHERE table_schema = 'cis_students_db'
  AND auto_increment IS NOT NULL
  AND table_name = 'scrap';

-- Clears the practice table and resets its generated ID counter.
TRUNCATE TABLE scrap;

-- Confirms TRUNCATE reset the next generated ID back to 1.
SELECT table_name, auto_increment
FROM information_schema.tables
WHERE table_schema = 'cis_students_db'
  AND auto_increment IS NOT NULL
  AND table_name = 'scrap';

-- Removes the practice table now that the counter test is finished.
DROP TABLE scrap;


-- =================================================================
-- STEP 8. A BEFORE INSERT trigger that fills in what you left out
--
-- Copy this from the handout. It is one statement from CREATE TRIGGER
-- down to END, so select the whole block and run the selection.
-- =================================================================

-- This trigger fills in todays date when no date is given and capitalizes status.
CREATE TRIGGER trg_attendance_before_insert
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    -- If a new attendance record has no date this supplies todays date.
    IF NEW.attended_on IS NULL THEN
        SET NEW.attended_on = CURDATE();
    END IF;

    -- This stores the new attendance status in uppercase letters.
    SET NEW.status = UPPER(NEW.status);
END;


-- =================================================================
-- STEP 9. An AFTER DELETE trigger, the gap Lab 5d left open
-- =================================================================

-- This trigger fixes a student's GPA automatically after a test score is deleted.
CREATE TRIGGER trg_scores_after_delete
AFTER DELETE ON test_scores
FOR EACH ROW
BEGIN
    -- OLD.student_id identifies the student whose test score was removed.
    UPDATE students
    SET gpa = calculate_gpa(OLD.student_id)
    WHERE student_id = OLD.student_id;
END;


-- =================================================================
-- STEP 10. Prove both triggers work
-- =================================================================

-- Inserts student 4 without a date to test the BEFORE INSERT trigger.
INSERT INTO attendance (student_id, status)
VALUES (4, 'present');

-- This verifies that the new attendance row has ID 503, today's date, and PRESENT.
SELECT * FROM attendance;

-- This temporarily adds Jennas quiz4 score=100
INSERT INTO test_scores (test_name, student_id, score)
VALUES ('quiz4', 1, 100);

-- This manually updates Jennas GPA from 85.00 to 90.00
UPDATE students
SET gpa = calculate_gpa(1)
WHERE student_id = 1;

-- This confirms that Jennas GPA is 90.00 before deleting quiz4.
SELECT student_id, first_name, last_name, gpa
FROM students
WHERE student_id = 1;

-- deletes Jennas quiz4 score and automatically fires the AFTER DELETE trigger.
DELETE FROM test_scores
WHERE test_name = 'quiz4'


-- =================================================================
-- STEP 11 and 12. Push to GitHub and submit the URL
-- Nothing to write here. Follow the handout.
-- =================================================================
