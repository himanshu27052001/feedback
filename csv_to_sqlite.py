import pandas as pd
import sqlite3
import os

csv_file = "Students Feedback Level 1 (Responses) - Form Responses 1.csv"
db_file = "feedback.db"
table_name = "student_feedback"

if not os.path.exists(csv_file):
    print(f"Error: {csv_file} not found.")
else:
    try:
        # Read CSV
        print(f"Reading {csv_file}...")
        df = pd.read_csv(csv_file)
        
        # Connect to SQLite
        print(f"Connecting to {db_file}...")
        conn = sqlite3.connect(db_file)
        
        # Write to SQLite
        print(f"Writing to table '{table_name}'...")
        df.to_sql(table_name, conn, if_exists='replace', index=False)
        
        conn.close()
        print("Done! Database created successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")
