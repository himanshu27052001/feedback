# Student Feedback Dashboard

Flask dashboard for analyzing student feedback across batches, teachers, mentors, timing, and score distribution.

## Required Files

These files are needed to run the dashboard:

- `app.py` - Flask backend and data aggregation logic.
- `feedback.db` - main SQLite database containing `student_feedback`.
- `mentor.db` - optional for the app to start, but required for Mentor Audit data.
- `full_kpi_feedback_dashboard.html` - main dashboard template.
- `beautiful_feedback_report.html` - insight report template.
- `requirements.txt` or `pyproject.toml` - Python dependencies.

Useful supporting files:

- `chart_queries.sql` - reference SQL for dashboard metrics and charts.
- `Students Feedback Level 1 (Responses) - Form Responses 1.csv` - source CSV, only needed if rebuilding `feedback.db`.
- `csv_to_sqlite_std.py` / `csv_to_sqlite.py` - scripts for rebuilding the SQLite database from CSV.
- `clean_db.py` - normalizes numeric feedback values in `feedback.db`.
- `check_mentor.py` - quick mentor database check.

## Setup

Using `uv`:

```powershell
uv sync
```

Or using plain `pip`:

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

## Run The Dashboard

From the project root:

```powershell
.\.venv\Scripts\python.exe app.py
```

Open:

```text
http://127.0.0.1:5000/full
```

The root URL `/` redirects to `/full`.

Available pages:

- `/full` - main dashboard.
- `/report` - narrative insight report.

## Rebuild The Database

Only do this if `feedback.db` is missing or the CSV has changed.

```powershell
.\.venv\Scripts\python.exe csv_to_sqlite_std.py
.\.venv\Scripts\python.exe clean_db.py
```

Then run the dashboard again:

```powershell
.\.venv\Scripts\python.exe app.py
```

## Notes

- The dashboard reads directly from `feedback.db`.
- Mentor charts require `mentor.db` with a `student_mentor` table.
- `chart_queries.sql` is not required by Flask at runtime; it documents the SQL behind the dashboard metrics.
