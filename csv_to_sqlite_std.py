import csv
import sqlite3
import os
import re

csv_file = "Students Feedback Level 1 (Responses) - Form Responses 1.csv"
db_file = "feedback.db"
table_name = "student_feedback"

def clean_column_name(name):
    # Remove special characters and replace spaces with underscores for better SQL compatibility
    # Keep it simple for now
    clean = re.sub(r'[^a-zA-Z0-9]', '_', name.strip())
    # Avoid double underscores
    clean = re.sub(r'_+', '_', clean)
    # Trim underscores from start and end
    clean = clean.strip('_')
    return clean if clean else "column"

if not os.path.exists(csv_file):
    print(f"Error: {csv_file} not found.")
else:
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            headers = next(reader)
            
            # Clean headers
            clean_headers = [clean_column_name(h) for h in headers]
            
            # Create mapping to handle duplicate cleaned headers if any
            final_headers = []
            seen = {}
            for h in clean_headers:
                if h in seen:
                    seen[h] += 1
                    final_headers.append(f"{h}_{seen[h]}")
                else:
                    seen[h] = 0
                    final_headers.append(h)

            print(f"Creating database {db_file}...")
            conn = sqlite3.connect(db_file)
            cursor = conn.cursor()
            
            # Create table
            columns_sql = ", ".join([f'"{h}" TEXT' for h in final_headers])
            cursor.execute(f"DROP TABLE IF EXISTS {table_name}")
            cursor.execute(f"CREATE TABLE {table_name} ({columns_sql})")
            
            # Insert data
            placeholders = ", ".join(["?" for _ in final_headers])
            insert_sql = f"INSERT INTO {table_name} VALUES ({placeholders})"
            
            print("Importing data...")
            count = 0
            for row in reader:
                # Handle rows with different lengths if any
                if len(row) < len(final_headers):
                    row.extend([""] * (len(final_headers) - len(row)))
                elif len(row) > len(final_headers):
                    row = row[:len(final_headers)]
                
                cursor.execute(insert_sql, row)
                count += 1
            
            conn.commit()
            conn.close()
            print(f"Done! Imported {count} rows into table '{table_name}'.")
            
    except Exception as e:
        print(f"An error occurred: {e}")
