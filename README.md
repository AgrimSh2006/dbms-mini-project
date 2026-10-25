# Library Management System (DBMS Mini Project)

A SQL-based Library Management System that manages students, books, and book issue/return records.

- **Database:** MySQL 8.x
- **Files:** `library_management.sql` (schema, sample data, queries), `screenshots/` (query outputs), this README (report)

## How to Run

```bash
mysql -u root -p < library_management.sql
```

Or open the file in MySQL Workbench and run it. Take screenshots of each query result and save them in the `screenshots/` folder.

## 1. Database Design

| Table | Purpose | Primary Key | Foreign Keys |
|-------|---------|-------------|--------------|
| `Students` | Student details | `student_id` | - |
| `Books` | Book catalogue and stock | `book_id` | - |
| `Book_Issue` | Issue and return records | `issue_id` | `student_id` → Students, `book_id` → Books |

### ER Relationship

```
Students (1) ────< Book_Issue >──── (1) Books
```

One student can borrow many books, and one book can be issued many times. `Book_Issue` is the junction table that resolves this many-to-many relationship. A `NULL` `return_date` means the book is still issued.

## 2. Database Concepts Used

- **Primary key:** uniquely identifies each row (`student_id`, `book_id`, `issue_id`), with `AUTO_INCREMENT`.
- **Foreign key:** `Book_Issue` references `Students` and `Books`, which enforces referential integrity so a book cannot be issued to a non-existent student. `ON DELETE CASCADE` removes dependent issue records when a parent row is deleted.
- **Constraints:** `NOT NULL`, `UNIQUE` (email, ISBN), `CHECK` (non-negative copies, `available_copies <= total_copies`, `due_date >= issue_date`), and `DEFAULT` values.
- **Joins:** `INNER JOIN` to combine student, book, and issue data; `LEFT JOIN` to include students with no issues.
- **Aggregate functions:** `COUNT`, `SUM`, `AVG` with `GROUP BY` for reports such as books per student and stock per category.
- **Subqueries:** to find students who have never borrowed a book.
- **DML operations:** `INSERT`, `UPDATE`, `DELETE`.
- **Transactions:** issuing and returning a book each update two tables, so they are wrapped in `START TRANSACTION ... COMMIT` to keep data consistent.
- **Views:** `Issued_Books_View` simplifies a frequently used join.
- **Normalization:** the tables are in 3NF. Student and book details are stored once and referenced by ID rather than repeated in each issue record.

## 3. Key Queries

**Available books**
```sql
SELECT book_id, title, author, available_copies
FROM Books WHERE available_copies > 0;
```

**Student details**
```sql
SELECT * FROM Students;
```

**Books issued to a particular student**
```sql
SELECT s.name, b.title, bi.issue_date, bi.due_date, bi.return_date
FROM Book_Issue bi
JOIN Students s ON bi.student_id = s.student_id
JOIN Books b    ON bi.book_id = b.book_id
WHERE s.student_id = 1;
```

The full list (overdue books, fines, most issued books, etc.) is in `library_management.sql`.

## 4. Screenshots

Add your screenshots here after running the script:

| Query | Screenshot |
|-------|-----------|
| Table creation | `screenshots/01_tables.png` |
| Sample data | `screenshots/02_data.png` |
| Available books | `screenshots/03_available_books.png` |
| Student details | `screenshots/04_students.png` |
| Books issued to a student | `screenshots/05_student_books.png` |

## 5. Connecting the Database to a Website

A website never talks to the database directly from the browser. A three-tier architecture is used:

```
Browser (HTML/CSS/JS)  →  Backend server (Node.js / Flask / PHP / Spring)  →  MySQL (LibraryDB)
```

1. **Frontend:** the user fills a form or opens a page (e.g. "My issued books").
2. **Backend:** the server receives the HTTP request, validates it, and connects to MySQL using a driver or connector (`mysql-connector-python`, `mysql2` for Node, JDBC for Java, PDO for PHP).
3. **Query execution:** the backend runs the SQL using **parameterized queries** to prevent SQL injection.
4. **Response:** results are returned to the browser as JSON or rendered HTML.

Example with Python and Flask:

```python
from flask import Flask, jsonify
import mysql.connector

app = Flask(__name__)

def get_db():
    return mysql.connector.connect(
        host="localhost", user="library_user",
        password="secret", database="LibraryDB")

@app.route("/students/<int:sid>/books")
def student_books(sid):
    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT b.title, bi.issue_date, bi.due_date, bi.return_date
        FROM Book_Issue bi JOIN Books b ON bi.book_id = b.book_id
        WHERE bi.student_id = %s""", (sid,))   # parameterized query
    rows = cur.fetchall()
    db.close()
    return jsonify(rows)
```

Security practices: store credentials in environment variables, use a database user with limited privileges, hash passwords, use HTTPS, and use connection pooling for performance.

## 6. Distributed Database for Multiple Campuses

If a university has libraries on several campuses (e.g. Main, North, South), a **distributed database** stores data across multiple sites while presenting it as one logical system.

**Fragmentation (how data is split)**
- *Horizontal fragmentation:* each campus stores its own rows. For example, `Books` and `Book_Issue` rows for the North campus are stored at the North server.
- *Vertical fragmentation:* rarely used here, but sensitive columns such as personal contact details could be stored separately.

**Replication (copies of data)**
- The shared catalogue (`Books` titles and authors) and `Students` records are replicated to every campus, so local searches are fast and a site can keep working if another goes down.
- Master-slave or multi-master replication keeps the copies synchronized.

**Benefits**
- **Faster local access:** most queries are served by the campus's own server.
- **Availability and fault tolerance:** if one campus server fails, others continue to operate.
- **Scalability:** new campuses can be added as new nodes.
- **Cross-campus services:** a student can search for a book and borrow it from another campus, or return it at any campus.
- **Local autonomy:** each campus manages its own stock.

**Challenges**
- Keeping replicas consistent (for example, two campuses issuing the last copy of a book at the same time). This is handled using distributed transactions (two-phase commit) or eventual consistency with conflict resolution.
- Network latency and failure handling.
- Higher cost and complexity of security, backup, and administration.

**Example design:** each campus has a local MySQL node holding its own `Book_Issue` records and local stock. A global catalogue is replicated to all nodes. A `campus_id` column is added to `Books` and `Book_Issue`, and a central coordinator or middleware routes inter-campus requests.

## 7. Conclusion

The project shows a normalized relational design with keys and constraints, sample data, join and aggregate queries, and transactional data manipulation. It can be extended with a web frontend, fine calculation triggers, and a multi-campus distributed setup.
