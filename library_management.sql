-- =====================================================
-- Library Management System (MySQL)
-- DBMS Mini Project
-- =====================================================

-- 1. CREATE DATABASE
DROP DATABASE IF EXISTS LibraryDB;
CREATE DATABASE LibraryDB;
USE LibraryDB;

-- =====================================================
-- 2. CREATE TABLES
-- =====================================================

CREATE TABLE Students (
    student_id   INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(100) NOT NULL UNIQUE,
    phone        VARCHAR(15),
    department   VARCHAR(50) NOT NULL,
    join_date    DATE NOT NULL DEFAULT (CURRENT_DATE)
);

CREATE TABLE Books (
    book_id      INT PRIMARY KEY AUTO_INCREMENT,
    title        VARCHAR(150) NOT NULL,
    author       VARCHAR(100) NOT NULL,
    category     VARCHAR(50),
    isbn         VARCHAR(20) UNIQUE,
    total_copies INT NOT NULL CHECK (total_copies >= 0),
    available_copies INT NOT NULL CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies)
);

-- Book_Issue stores both issue and return records
-- (return_date is NULL until the book is returned)
CREATE TABLE Book_Issue (
    issue_id     INT PRIMARY KEY AUTO_INCREMENT,
    student_id   INT NOT NULL,
    book_id      INT NOT NULL,
    issue_date   DATE NOT NULL,
    due_date     DATE NOT NULL,
    return_date  DATE NULL,
    fine_amount  DECIMAL(8,2) DEFAULT 0.00,
    CONSTRAINT fk_issue_student FOREIGN KEY (student_id)
        REFERENCES Students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_issue_book FOREIGN KEY (book_id)
        REFERENCES Books(book_id) ON DELETE CASCADE,
    CHECK (due_date >= issue_date),
    CHECK (return_date IS NULL OR return_date >= issue_date)
);

-- =====================================================
-- 3. INSERT SAMPLE DATA
-- =====================================================

INSERT INTO Students (name, email, phone, department, join_date) VALUES
('Aman Sharma',   'aman.sharma@college.edu',   '9876500001', 'Computer Science', '2024-07-15'),
('Priya Singh',   'priya.singh@college.edu',   '9876500002', 'Electronics',      '2024-07-15'),
('Rohan Verma',   'rohan.verma@college.edu',   '9876500003', 'Mechanical',       '2023-07-20'),
('Simran Kaur',   'simran.kaur@college.edu',   '9876500004', 'Computer Science', '2023-07-20'),
('Karan Mehta',   'karan.mehta@college.edu',   '9876500005', 'Civil',            '2025-07-10'),
('Neha Gupta',    'neha.gupta@college.edu',    '9876500006', 'Information Technology', '2025-07-10');

INSERT INTO Books (title, author, category, isbn, total_copies, available_copies) VALUES
('Database System Concepts',        'Silberschatz, Korth, Sudarshan', 'Computer Science', '9780078022159', 5, 4),
('Fundamentals of Database Systems','Elmasri, Navathe',               'Computer Science', '9780133970777', 4, 4),
('Operating System Concepts',       'Abraham Silberschatz',           'Computer Science', '9781118063330', 3, 2),
('Computer Networks',               'Andrew S. Tanenbaum',            'Computer Science', '9780132126953', 4, 4),
('Digital Design',                  'M. Morris Mano',                 'Electronics',      '9780132774208', 3, 3),
('Engineering Mechanics',           'S. Timoshenko',                  'Mechanical',       '9780070647831', 2, 1),
('Thermodynamics: An Engineering Approach', 'Yunus Cengel',           'Mechanical',       '9780073398174', 3, 3),
('Structural Analysis',             'R. C. Hibbeler',                 'Civil',            '9780134610672', 2, 2),
('Introduction to Algorithms',      'Cormen, Leiserson, Rivest, Stein','Computer Science','9780262033848', 3, 2),
('Clean Code',                      'Robert C. Martin',               'Software Engineering','9780132350884', 2, 0),
('Let Us C',                        'Yashavant Kanetkar',             'Computer Science', '9788183331630', 6, 6);

-- Issue records (some returned, some still pending)
INSERT INTO Book_Issue (student_id, book_id, issue_date, due_date, return_date, fine_amount) VALUES
(1, 1,  '2026-09-01', '2026-09-15', '2026-09-14', 0.00),
(1, 9,  '2026-10-05', '2026-10-19', NULL,         0.00),
(2, 5,  '2026-09-10', '2026-09-24', '2026-09-30', 30.00),
(3, 6,  '2026-10-01', '2026-10-15', NULL,         0.00),
(4, 3,  '2026-10-10', '2026-10-24', NULL,         0.00),
(4, 10, '2026-10-12', '2026-10-26', NULL,         0.00),
(5, 8,  '2026-09-20', '2026-10-04', '2026-10-03', 0.00),
(6, 10, '2026-10-15', '2026-10-29', NULL,         0.00);

-- =====================================================
-- 4. QUERIES: AVAILABLE BOOKS AND STUDENT DETAILS
-- =====================================================

-- 4.1 Display all available books
SELECT book_id, title, author, category, available_copies
FROM Books
WHERE available_copies > 0
ORDER BY title;

-- 4.2 Display all student details
SELECT * FROM Students;

-- 4.3 Students of a particular department
SELECT student_id, name, email, phone
FROM Students
WHERE department = 'Computer Science';

-- =====================================================
-- 5. BOOKS ISSUED TO A PARTICULAR STUDENT (JOIN)
-- =====================================================

-- Books issued to student with student_id = 1 (Aman Sharma)
SELECT s.student_id,
       s.name,
       b.title,
       b.author,
       bi.issue_date,
       bi.due_date,
       bi.return_date,
       CASE WHEN bi.return_date IS NULL THEN 'Issued' ELSE 'Returned' END AS status
FROM Book_Issue bi
JOIN Students s ON bi.student_id = s.student_id
JOIN Books b    ON bi.book_id = b.book_id
WHERE s.student_id = 1;

-- Same query, searching by name
SELECT s.name, b.title, bi.issue_date, bi.due_date
FROM Book_Issue bi
JOIN Students s ON bi.student_id = s.student_id
JOIN Books b    ON bi.book_id = b.book_id
WHERE s.name = 'Simran Kaur';

-- =====================================================
-- 6. ADDITIONAL QUERIES (JOINS, AGGREGATES, GROUPING)
-- =====================================================

-- 6.1 Books currently issued (not yet returned)
SELECT s.name, b.title, bi.issue_date, bi.due_date
FROM Book_Issue bi
JOIN Students s ON bi.student_id = s.student_id
JOIN Books b    ON bi.book_id = b.book_id
WHERE bi.return_date IS NULL;

-- 6.2 Number of books issued per student (aggregate + GROUP BY)
SELECT s.name, COUNT(bi.issue_id) AS books_issued
FROM Students s
LEFT JOIN Book_Issue bi ON s.student_id = bi.student_id
GROUP BY s.student_id, s.name
ORDER BY books_issued DESC;

-- 6.3 Most frequently issued books
SELECT b.title, COUNT(*) AS times_issued
FROM Book_Issue bi
JOIN Books b ON bi.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY times_issued DESC;

-- 6.4 Total copies, available copies and number of titles per category
SELECT category,
       COUNT(*)              AS titles,
       SUM(total_copies)     AS total_copies,
       SUM(available_copies) AS available_copies
FROM Books
GROUP BY category;

-- 6.5 Total fine collected, and average fine
SELECT SUM(fine_amount) AS total_fine, AVG(fine_amount) AS avg_fine
FROM Book_Issue;

-- 6.6 Overdue books as of a given date
SELECT s.name, b.title, bi.due_date,
       DATEDIFF('2026-10-25', bi.due_date) AS days_overdue
FROM Book_Issue bi
JOIN Students s ON bi.student_id = s.student_id
JOIN Books b    ON bi.book_id = b.book_id
WHERE bi.return_date IS NULL
  AND bi.due_date < '2026-10-25';

-- 6.7 Students who have never issued a book
SELECT name FROM Students
WHERE student_id NOT IN (SELECT DISTINCT student_id FROM Book_Issue);

-- =====================================================
-- 7. DATA MANIPULATION: ISSUE, RETURN, UPDATE, DELETE
-- =====================================================

-- 7.1 Issue a book (Neha Gupta takes 'Let Us C', book_id = 11)
START TRANSACTION;
INSERT INTO Book_Issue (student_id, book_id, issue_date, due_date)
VALUES (6, 11, '2026-10-25', '2026-11-08');
UPDATE Books SET available_copies = available_copies - 1 WHERE book_id = 11;
COMMIT;

-- 7.2 Return a book (Aman Sharma returns 'Introduction to Algorithms')
START TRANSACTION;
UPDATE Book_Issue
SET return_date = '2026-10-25'
WHERE student_id = 1 AND book_id = 9 AND return_date IS NULL;
UPDATE Books SET available_copies = available_copies + 1 WHERE book_id = 9;
COMMIT;

-- 7.3 Update a student's phone number
UPDATE Students SET phone = '9999900001' WHERE student_id = 1;

-- 7.4 Delete a book that is not referenced anywhere
INSERT INTO Books (title, author, category, isbn, total_copies, available_copies)
VALUES ('Temporary Book', 'Unknown', 'Misc', '0000000000', 1, 1);
DELETE FROM Books WHERE title = 'Temporary Book';

-- 7.5 Verify the changes
SELECT book_id, title, available_copies FROM Books WHERE book_id IN (9, 11);
SELECT * FROM Book_Issue ORDER BY issue_id;

-- =====================================================
-- 8. VIEW (optional convenience)
-- =====================================================

CREATE OR REPLACE VIEW Issued_Books_View AS
SELECT bi.issue_id, s.name AS student_name, b.title AS book_title,
       bi.issue_date, bi.due_date, bi.return_date
FROM Book_Issue bi
JOIN Students s ON bi.student_id = s.student_id
JOIN Books b    ON bi.book_id = b.book_id;

SELECT * FROM Issued_Books_View;
