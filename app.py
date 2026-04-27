try:
    import pysqlite3 as sqlite3
    import sys
    sys.modules["sqlite3"] = sqlite3
except ImportError:
    import sqlite3
# import sqlite3
import pandas as pd
import json
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / 'feedback.db'
MENTOR_DB_PATH = BASE_DIR / 'mentor.db'
DIST_DIR = BASE_DIR / 'dist'

TEACHERS = {
    "Asawari Ma'am": "Chemistry",
    "Aniket Sir": "Maths",
    "Russell Sir": "Physics",
    "Vibha Ma'am": "Bio",
    "Shreyash Sir": "Hist/Pol Sci",
    "Chetna Ma'am": "Geo/Eco",
    "Ashish Sir": "English",
    "Ayushi Ma'am": "English",
    "Kapil Sir": "Maths",
    "Kuldeep Sir": "Maths",
    "Dhulesh Sir": "Maths"
}

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    if os.path.exists(MENTOR_DB_PATH):
        conn.execute(f"ATTACH DATABASE '{MENTOR_DB_PATH}' AS mdb")
    return conn

def get_schema_info(conn):
    cursor = conn.execute("SELECT * FROM student_feedback LIMIT 1")
    cols = [description[0] for description in cursor.description]
    batch_col = next((c for c in cols if 'class_batch' in c.lower() or 'batch' in c.lower()), None)
    
    vibe_map = {}
    comfort_map = {}
    interest_map = {}
    for t_name in TEACHERS:
        t_base = t_name.replace("Ma'am", "").replace("Sir", "").strip().lower()
        vibe_map[t_name] = next((c for c in cols if 'vibe' in c.lower() and t_base in c.lower()), None)
        comfort_map[t_name] = next((c for c in cols if ('comfort' in c.lower() or 'approach' in c.lower()) and t_base in c.lower()), None)
        interest_map[t_name] = next((c for c in cols if 'interest' in c.lower() and t_base in c.lower()), None)

    infra_map = {'ma': 'tough_questions', 'cc': 'classroom_peace', 'hy': 'hygiene', 'ad': 'admin', 'en': 'energy'}
    infra_cols = {k: next((c for c in cols if sub.lower() in c.lower()), None) for k, sub in infra_map.items()}
    
    timing_col = next((c for c in cols if 'time' in c.lower() and 'summer' in c.lower()), None)
    
    return batch_col, vibe_map, comfort_map, interest_map, infra_cols, timing_col

def get_summary_stats(conn, batch_col):
    summary_sql = f"""
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN "{batch_col}" LIKE '%10%' THEN 1 END),
        COUNT(CASE WHEN "{batch_col}" LIKE '%9%' THEN 1 END)
    FROM student_feedback
    """
    s_row = conn.execute(summary_sql).fetchone()
    
    batch_sql = f"SELECT \"{batch_col}\", COUNT(*) FROM student_feedback GROUP BY 1"
    batch_res = conn.execute(batch_sql).fetchall()
    batches = sorted([str(r[0]) for r in batch_res if r[0]])
    batch_n = {str(r[0]): r[1] for r in batch_res if r[0]}
    
    largest_batch_row = sorted(batch_res, key=lambda x: x[1], reverse=True)[0] if batch_res else ("N/A", 0)
    
    return {
        'total': s_row[0], 'g10': s_row[1], 'g9': s_row[2],
        'g10_b': len([b for b in batches if '10' in b]), 'g10_p': round(s_row[1]/s_row[0]*100) if s_row[0] else 0,
        'g9_b': len([b for b in batches if '9' in b]), 'g9_p': round(s_row[2]/s_row[0]*100) if s_row[0] else 0,
        'largest': str(largest_batch_row[0]), 'largest_n': largest_batch_row[1]
    }, batches, batch_n

def get_teacher_stats(conn, vibe_map, comfort_map, interest_map):
    t_selects = []
    for t_name in TEACHERS:
        v, a, e = vibe_map[t_name], comfort_map[t_name], interest_map[t_name]
        # Data is assumed cleaned! No 'clean' function used here.
        t_selects.append(f'AVG("{v}")')
        t_selects.append(f'AVG("{a}")')
        t_selects.append(f'AVG("{e}")')
        t_selects.append(f'COUNT(CASE WHEN CAST("{v}" AS REAL) BETWEEN 4 AND 5 THEN 1 END) * 100.0 / COUNT("{v}")')
        t_selects.append(f'COUNT(CASE WHEN CAST("{v}" AS REAL) BETWEEN 1 AND 2 THEN 1 END) * 100.0 / COUNT("{v}")')
        t_selects.append(f'COUNT(CASE WHEN "{v}" IS NOT NULL OR "{a}" IS NOT NULL OR "{e}" IS NOT NULL THEN 1 END)')
    
    t_ov_sql = f"SELECT {', '.join(t_selects)} FROM student_feedback"
    t_ov_res = conn.execute(t_ov_sql).fetchone()
    
    teacher_stats = []
    for i, t_name in enumerate(TEACHERS):
        base = i * 6
        try:
            v_avg = float(t_ov_res[base] or 0)
            a_avg = float(t_ov_res[base+1] or 0)
            e_avg = float(t_ov_res[base+2] or 0)
            pp = round(float(t_ov_res[base+3] or 0), 1)
            dd = round(float(t_ov_res[base+4] or 0), 1)
            response_count = int(t_ov_res[base+5] or 0)
        except:
            v_avg, a_avg, e_avg, pp, dd, response_count = 0, 0, 0, 0, 0, 0
            
        ov_score = (v_avg + a_avg + e_avg) / 3
        
        teacher_stats.append({
            "n": t_name, "s": TEACHERS[t_name], "v": v_avg, "a": a_avg, "e": e_avg, "ov": ov_score,
            "pp": pp, "dd": dd, "rc": response_count, "bb": {},
            "initials": "".join([p[0] for p in t_name.split() if p[0].isupper()])
        })
    return sorted(teacher_stats, key=lambda x: x['ov'], reverse=True)

def get_batch_teacher_stats(conn, batch_col, vibe_map, comfort_map, interest_map):
    rating_cols = []
    for t_name in TEACHERS:
        rating_cols.extend([vibe_map[t_name], comfort_map[t_name], interest_map[t_name]])

    rating_cols = [c for c in rating_cols if c]
    select_cols = [batch_col] + rating_cols
    df = pd.read_sql_query(
        "SELECT " + ", ".join([f'"{c}"' for c in select_cols]) + " FROM student_feedback",
        conn
    )

    for col in rating_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    teacher_batch = {t_name: {} for t_name in TEACHERS}
    batch_scores = {}

    for batch, batch_df in df.groupby(batch_col, dropna=True):
        batch_name = str(batch)
        batch_score_values = []

        for t_name in TEACHERS:
            v_col = vibe_map[t_name]
            a_col = comfort_map[t_name]
            e_col = interest_map[t_name]
            cols = [c for c in [v_col, a_col, e_col] if c]
            if not cols:
                continue

            values = batch_df[cols].apply(pd.to_numeric, errors='coerce')
            valid_count = int(values.notna().any(axis=1).sum())
            if valid_count == 0:
                continue

            v_avg = float(values[v_col].mean()) if v_col and values[v_col].notna().any() else None
            a_avg = float(values[a_col].mean()) if a_col and values[a_col].notna().any() else None
            e_avg = float(values[e_col].mean()) if e_col and values[e_col].notna().any() else None

            teacher_batch[t_name][batch_name] = {
                "v": v_avg,
                "a": a_avg,
                "e": e_avg,
                "n": valid_count
            }
            batch_score_values.extend(values.to_numpy().flatten())

        score_series = pd.Series(batch_score_values).dropna()
        if not score_series.empty:
            batch_scores[batch_name] = float(score_series.mean())

    return teacher_batch, batch_scores

def get_core_metrics(conn, batch_col, vibe_map, comfort_map, interest_map):
    rating_cols = []
    vibe_cols = []
    for t_name in TEACHERS:
        vibe_col = vibe_map[t_name]
        cols = [vibe_col, comfort_map[t_name], interest_map[t_name]]
        rating_cols.extend([c for c in cols if c])
        if vibe_col:
            vibe_cols.append(vibe_col)

    select_cols = [batch_col] + rating_cols
    df = pd.read_sql_query(
        "SELECT " + ", ".join([f'"{c}"' for c in select_cols]) + " FROM student_feedback",
        conn
    )
    for col in rating_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    all_ratings = df[rating_cols].stack().dropna()
    vibe_ratings = df[vibe_cols].stack().dropna()

    grade_10 = df[df[batch_col].astype(str).str.contains('10', na=False)]
    grade_9 = df[df[batch_col].astype(str).str.contains('9', na=False)]
    parameter_scores = {
        'Vibe': df[vibe_cols].stack().dropna().mean() if vibe_cols else None,
        'Approach': df[[comfort_map[t] for t in TEACHERS if comfort_map[t]]].stack().dropna().mean(),
        'Engagement': df[[interest_map[t] for t in TEACHERS if interest_map[t]]].stack().dropna().mean()
    }
    weakest_name, weakest_score = min(
        ((name, score) for name, score in parameter_scores.items() if pd.notna(score)),
        key=lambda item: item[1],
        default=('N/A', 0)
    )
    teachers_above_4 = 0
    for t_name in TEACHERS:
        cols = [vibe_map[t_name], comfort_map[t_name], interest_map[t_name]]
        cols = [c for c in cols if c]
        teacher_values = df[cols].stack().dropna()
        if not teacher_values.empty and teacher_values.mean() > 4:
            teachers_above_4 += 1

    return {
        'institute_avg': round(float(all_ratings.mean()), 2) if not all_ratings.empty else 0,
        'promoter_rate': round(float((vibe_ratings.between(4, 5).sum() / len(vibe_ratings)) * 100), 1) if len(vibe_ratings) else 0,
        'detractor_rate': round(float((vibe_ratings.between(1, 2).sum() / len(vibe_ratings)) * 100), 1) if len(vibe_ratings) else 0,
        'g10_avg': round(float(grade_10[rating_cols].stack().dropna().mean()), 2) if not grade_10.empty else 0,
        'g9_avg': round(float(grade_9[rating_cols].stack().dropna().mean()), 2) if not grade_9.empty else 0,
        'teachers_above_4': teachers_above_4,
        'teacher_count': len(TEACHERS),
        'weakest_parameter': weakest_name,
        'weakest_parameter_score': round(float(weakest_score), 2) if weakest_score else 0
    }

def get_mentor_audit(conn, batch_col, infra_cols):
    mentor_data = []
    try:
        # Using the attached 'mdb' for student_mentor
        m_query = f"""
        WITH a AS (SELECT trim(class_batch) as cb, mentor FROM mdb.student_mentor),
             b AS (SELECT sf."{batch_col}" as bc, a.mentor, CAST("{infra_cols['ma']}" AS REAL) as tq, CAST("{infra_cols['cc']}" AS REAL) as pe 
                   FROM student_feedback sf 
                   LEFT JOIN a ON sf."{batch_col}" = a.cb)
        SELECT 
            mentor, 
            AVG(tq) as approachability, 
            AVG(pe) as class_control, 
            COUNT(*) as feedback_count,
            GROUP_CONCAT(tq) as tq_dist,
            GROUP_CONCAT(pe) as pe_dist
        FROM b 
        WHERE mentor IS NOT NULL 
        GROUP BY 1 
        ORDER BY 2 DESC
        """
        m_res = conn.execute(m_query).fetchall()
        for row in m_res:
            try:
                mentor_data.append({
                    'name': row[0],
                    'approach': float(row[1] or 0),
                    'mgmt': float(row[2] or 0),
                    'count': row[3],
                    'approach_dist': [float(x) for x in (row[4] or "").split(',') if x and x != 'None'],
                    'mgmt_dist': [float(x) for x in (row[5] or "").split(',') if x and x != 'None']
                })
            except:
                pass
    except Exception as e:
        print(f"Mentor query failed: {e}")
    return mentor_data

def get_infra_stats(conn, batch_col, infra_cols):
    infra_selects = [f'AVG("{col}")' for col in infra_cols.values() if col]
    infra_keys = [k for k, v in infra_cols.items() if v]
    if not infra_selects: return {}
    infra_sql = f"SELECT \"{batch_col}\", {', '.join(infra_selects)} FROM student_feedback GROUP BY 1"
    try:
        infra_res = conn.execute(infra_sql).fetchall()
        return {str(r[0]): {k: float(r[i+1] or 0) for i, k in enumerate(infra_keys)} for r in infra_res if r[0]}
    except:
        return {}

def get_timing_data(conn, timing_col):
    timing_stats = [0] * 6
    if timing_col:
        t_res = conn.execute(f'SELECT "{timing_col}" FROM student_feedback').fetchall()
        for r in t_res:
            if not r[0]: continue
            s = str(r[0]).lower()
            if '10:' in s or '9:' in s or '8:' in s or ('am' in s and '11:' not in s and '12:' not in s): timing_stats[0] += 1
            elif '11:' in s: timing_stats[1] += 1
            elif '12:' in s: timing_stats[2] += 1
            elif '1:' in s: timing_stats[3] += 1
            elif '2:' in s: timing_stats[4] += 1
            else: timing_stats[5] += 1
    return timing_stats

def get_dashboard_data():
    conn = get_db_connection()
    try:
        batch_col, vibe_map, comfort_map, interest_map, infra_cols, timing_col = get_schema_info(conn)
        
        summary, batches, batch_n = get_summary_stats(conn, batch_col)
        teacher_stats = get_teacher_stats(conn, vibe_map, comfort_map, interest_map)
        teacher_batch, batch_scores = get_batch_teacher_stats(conn, batch_col, vibe_map, comfort_map, interest_map)
        core_metrics = get_core_metrics(conn, batch_col, vibe_map, comfort_map, interest_map)
        for teacher in teacher_stats:
            teacher["bb"] = teacher_batch.get(teacher["n"], {})
        mentor_data = get_mentor_audit(conn, batch_col, infra_cols)
        infra_data = get_infra_stats(conn, batch_col, infra_cols)
        timing_data = get_timing_data(conn, timing_col)
        
        return {
            'batches': batches,
            'batchN': batch_n,
            'batchScores': batch_scores,
            'teachers': [{"n": t, "s": TEACHERS[t]} for t in TEACHERS],
            'data': {},
            'infraData': infra_data,
            'summary': summary,
            'coreMetrics': core_metrics,
            'TS': teacher_stats,
            'timing': timing_data,
            'mentorData': mentor_data
        }
    finally:
        conn.close()

def _json(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'))

def _render_template(template_name, data):
    html = (BASE_DIR / template_name).read_text(encoding='utf-8')

    json_keys = {
        'batches': data['batches'],
        'batchN': data['batchN'],
        'teachers': data['teachers'],
        'data': data['data'],
        'infraData': data['infraData'],
        'TS': data['TS'],
        'batchScores': data['batchScores'],
        'timing': data['timing'],
        'mentorData': data['mentorData'],
        'summary': data['summary'],
    }
    for key, value in json_keys.items():
        html = html.replace(f'{{{{ {key} | tojson | safe }}}}', _json(value))

    scalar_replacements = {
        '{{ summary.total }}': str(data['summary']['total']),
        '{{ summary.g10_b + summary.g9_b }}': str(data['summary']['g10_b'] + data['summary']['g9_b']),
        "{{ '%.2f'|format(coreMetrics.institute_avg) }}": f"{data['coreMetrics']['institute_avg']:.2f}",
        "{{ '%.1f'|format(coreMetrics.promoter_rate) }}": f"{data['coreMetrics']['promoter_rate']:.1f}",
        "{{ '%.1f'|format(coreMetrics.detractor_rate) }}": f"{data['coreMetrics']['detractor_rate']:.1f}",
        '{{ coreMetrics.teachers_above_4 }}': str(data['coreMetrics']['teachers_above_4']),
        '{{ coreMetrics.teacher_count }}': str(data['coreMetrics']['teacher_count']),
        '{{ coreMetrics.weakest_parameter }}': str(data['coreMetrics']['weakest_parameter']),
        "{{ '%.2f'|format(coreMetrics.weakest_parameter_score) }}": f"{data['coreMetrics']['weakest_parameter_score']:.2f}",
        "{{ '%.2f'|format(coreMetrics.g10_avg) }}": f"{data['coreMetrics']['g10_avg']:.2f}",
        '{{ summary.g10_b }}': str(data['summary']['g10_b']),
        '{{ summary.g10 }}': str(data['summary']['g10']),
        "{{ '%.2f'|format(coreMetrics.g9_avg) }}": f"{data['coreMetrics']['g9_avg']:.2f}",
        '{{ summary.g9_b }}': str(data['summary']['g9_b']),
        '{{ summary.g9 }}': str(data['summary']['g9']),
    }
    for token, value in scalar_replacements.items():
        html = html.replace(token, value)

    return html

def build_static_site():
    data = get_dashboard_data()
    DIST_DIR.mkdir(exist_ok=True)
    (DIST_DIR / 'full.html').write_text(
        _render_template('full_kpi_feedback_dashboard.html', data),
        encoding='utf-8'
    )
    (DIST_DIR / 'report.html').write_text(
        _render_template('beautiful_feedback_report.html', data),
        encoding='utf-8'
    )
    (DIST_DIR / 'data.json').write_text(_json(data), encoding='utf-8')
    print(f"Built Cloudflare Worker assets in {DIST_DIR}")

if __name__ == '__main__':
    build_static_site()
