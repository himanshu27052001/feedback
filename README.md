# Student Feedback Dashboard

Cloudflare Workers dashboard for analyzing student feedback across batches, teachers, mentors, timing, and score distribution.

The analytics are built locally from SQLite into static HTML/JSON. Cloudflare Workers serves those generated assets in production, so the edge runtime does not need Python, pandas, Flask, or SQLite.

## Required Files

These files are needed to run the dashboard:

- `app.py` - build-time data aggregation and static renderer.
- `feedback.db` - main SQLite database containing `student_feedback`.
- `mentor.db` - optional for the app to start, but required for Mentor Audit data.
- `full_kpi_feedback_dashboard.html` - main dashboard template.
- `beautiful_feedback_report.html` - insight report template.
- `src/worker.js` - Cloudflare Worker route adapter.
- `wrangler.toml` - Worker deployment configuration.
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

## Build The Dashboard

From the project root:

```powershell
npm run build
```

This creates:

```text
dist/full.html
dist/report.html
dist/data.json
```

## Preview Or Deploy On Cloudflare Workers

Install the Node dependencies once:

```powershell
npm install
```

Preview locally through Wrangler:

```powershell
npm run preview
```

Deploy:

```powershell
npm run deploy
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

- Production requests are served by Cloudflare Workers from `dist/`.
- Re-run `npm run build` whenever `feedback.db`, `mentor.db`, or the templates change.
- Mentor charts require `mentor.db` with a `student_mentor` table.
- `chart_queries.sql` is not required at runtime; it documents the SQL behind the dashboard metrics.
