import sqlite3
import pandas as pd

def clean_string(val):
    if pd.isna(val) or str(val).strip().upper() == 'N/A' or str(val).strip() == '':
        return None
    if isinstance(val, str):
        match = str(val).split('(')[0].strip()
        try:
            return float(match)
        except:
            return val
    return val

def run_cleanup():
    conn = sqlite3.connect('feedback.db')
    df = pd.read_sql_query("SELECT * FROM student_feedback", conn)
    
    # Clean all columns that should be numeric
    for col in df.columns:
        if any(x in col.lower() for x in ['vibe', 'comfort', 'approach', 'interest', 'tough', 'peace', 'hygiene', 'admin', 'energy']):
            df[col] = df[col].apply(clean_string)
    
    # Save back
    df.to_sql('student_feedback', conn, if_exists='replace', index=False)
    conn.close()
    print("Database cleaned and normalized.")

if __name__ == "__main__":
    run_cleanup()
