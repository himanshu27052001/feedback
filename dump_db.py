import sqlite3
import json

def get_db_info():
    conn = sqlite3.connect('feedback.db')
    cursor = conn.cursor()
    
    # Check tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cursor.fetchall()]
    
    res = {"tables": tables, "details": {}}
    
    for table in tables:
        cursor.execute(f"PRAGMA table_info({table})")
        res["details"][table] = [c[1] for c in cursor.fetchall()]
    
    conn.close()
    return res

print(json.dumps(get_db_info(), indent=2))
