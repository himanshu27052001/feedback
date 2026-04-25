import sqlite3
import json

def get_db_info():
    conn = sqlite3.connect('feedback.db')
    cursor = conn.cursor()
    
    # Get table info
    cursor.execute("PRAGMA table_info(student_feedback)")
    columns = cursor.fetchall()
    
    # Get sample data
    cursor.execute("SELECT * FROM student_feedback LIMIT 1")
    sample = cursor.fetchone()
    
    conn.close()
    
    return {
        "columns": [c[1] for c in columns],
        "sample": sample
    }

if __name__ == "__main__":
    print(json.dumps(get_db_info(), indent=2))
