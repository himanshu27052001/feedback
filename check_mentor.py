import sqlite3

def check_mentor_db():
    conn = sqlite3.connect('mentor.db')
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM student_mentor LIMIT 5;")
    rows = cursor.fetchall()
    print("Rows in student_mentor:", rows)
    conn.close()

if __name__ == '__main__':
    check_mentor_db()
