-- SQL queries for dashboard charts and KPI tables.
-- Run from the project root against feedback.db.
-- Mentor queries expect mentor.db to be available in the same folder.

ATTACH DATABASE 'mentor.db' AS mdb;

-- 1. Executive summary cards
SELECT
  COUNT(*) AS total_responses,
  COUNT(CASE WHEN class_batch LIKE '%10%' THEN 1 END) AS grade_10_responses,
  COUNT(CASE WHEN class_batch LIKE '%9%' THEN 1 END) AS grade_9_responses,
  COUNT(DISTINCT CASE WHEN class_batch LIKE '%10%' THEN class_batch END) AS grade_10_batches,
  COUNT(DISTINCT CASE WHEN class_batch LIKE '%9%' THEN class_batch END) AS grade_9_batches,
  ROUND(COUNT(CASE WHEN class_batch LIKE '%10%' THEN 1 END) * 100.0 / COUNT(*), 0) AS grade_10_percent,
  ROUND(COUNT(CASE WHEN class_batch LIKE '%9%' THEN 1 END) * 100.0 / COUNT(*), 0) AS grade_9_percent
FROM student_feedback;

-- 2. Largest batch summary card
SELECT
  class_batch,
  COUNT(*) AS response_count
FROM student_feedback
WHERE class_batch IS NOT NULL
GROUP BY class_batch
ORDER BY response_count DESC
LIMIT 1;

-- 2a. Core metric averages for deep analysis cards
WITH teacher_ratings AS (
  SELECT class_batch, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
  SELECT class_batch, vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
  SELECT class_batch, vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
  SELECT class_batch, vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
  SELECT class_batch, vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT class_batch, vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT class_batch, vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
  SELECT class_batch, vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT class_batch, vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
  SELECT class_batch, vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT class_batch, vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
),
all_metric_values AS (
  SELECT class_batch, vibe AS rating FROM teacher_ratings UNION ALL
  SELECT class_batch, approach FROM teacher_ratings UNION ALL
  SELECT class_batch, engage FROM teacher_ratings
),
parameter_scores AS (
  SELECT 'Vibe' AS parameter, AVG(vibe) AS avg_score FROM teacher_ratings UNION ALL
  SELECT 'Approach', AVG(approach) FROM teacher_ratings UNION ALL
  SELECT 'Engagement', AVG(engage) FROM teacher_ratings
)
SELECT
  ROUND((SELECT AVG(rating) FROM all_metric_values WHERE rating IS NOT NULL), 2) AS institute_avg,
  ROUND((SELECT COUNT(*) * 100.0 FROM teacher_ratings WHERE vibe BETWEEN 4 AND 5) / (SELECT COUNT(vibe) FROM teacher_ratings), 1) AS promoter_rate,
  ROUND((SELECT COUNT(*) * 100.0 FROM teacher_ratings WHERE vibe BETWEEN 1 AND 2) / (SELECT COUNT(vibe) FROM teacher_ratings), 1) AS detractor_rate,
  ROUND((SELECT AVG(rating) FROM all_metric_values WHERE rating IS NOT NULL AND class_batch LIKE '%10%'), 2) AS grade_10_avg,
  ROUND((SELECT AVG(rating) FROM all_metric_values WHERE rating IS NOT NULL AND class_batch LIKE '%9%'), 2) AS grade_9_avg,
  (SELECT parameter FROM parameter_scores WHERE avg_score IS NOT NULL ORDER BY avg_score ASC LIMIT 1) AS weakest_parameter,
  ROUND((SELECT avg_score FROM parameter_scores WHERE avg_score IS NOT NULL ORDER BY avg_score ASC LIMIT 1), 2) AS weakest_parameter_score,
  (
    SELECT COUNT(*)
    FROM (
      SELECT teacher
      FROM (
        SELECT 'Asawari Ma''am' AS teacher, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
        SELECT 'Aniket Sir', vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
        SELECT 'Russell Sir', vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
        SELECT 'Vibha Ma''am', vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
        SELECT 'Shreyash Sir', vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
        SELECT 'Chetna Ma''am', vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
        SELECT 'Ashish Sir', vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
        SELECT 'Ayushi Ma''am', vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
        SELECT 'Kapil Sir', vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
        SELECT 'Kuldeep Sir', vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
        SELECT 'Dhulesh Sir', vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
      )
      GROUP BY teacher
      HAVING (AVG(vibe) + AVG(approach) + AVG(engage)) / 3.0 > 4
    )
  ) AS teachers_above_4;

-- 3. Responses by batch chart/cards
SELECT
  class_batch,
  COUNT(*) AS response_count
FROM student_feedback
WHERE class_batch IS NOT NULL
GROUP BY class_batch
ORDER BY class_batch;

-- 4. Score distribution chart across all teacher rating dimensions
WITH rating_values AS (
  SELECT vibe_asawari_chem AS rating FROM student_feedback UNION ALL
  SELECT doubt_comfort_asawari_chem FROM student_feedback UNION ALL
  SELECT interest_asawari_chem FROM student_feedback UNION ALL
  SELECT vibe_aniket_maths FROM student_feedback UNION ALL
  SELECT doubt_comfort_aniket_maths FROM student_feedback UNION ALL
  SELECT interest_aniket_maths FROM student_feedback UNION ALL
  SELECT vibe_russell_physics FROM student_feedback UNION ALL
  SELECT doubt_comfort_russell_physics FROM student_feedback UNION ALL
  SELECT interest_russell_physics FROM student_feedback UNION ALL
  SELECT vibe_vibha_bio FROM student_feedback UNION ALL
  SELECT doubt_comfort_vibha_bio FROM student_feedback UNION ALL
  SELECT interest_vibha_bio FROM student_feedback UNION ALL
  SELECT vibe_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT doubt_comfort_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT vibe_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT doubt_comfort_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT vibe_ashish_eng FROM student_feedback UNION ALL
  SELECT doubt_comfort_ashish_eng FROM student_feedback UNION ALL
  SELECT interest_ashish_eng FROM student_feedback UNION ALL
  SELECT vibe_ayushi_eng FROM student_feedback UNION ALL
  SELECT doubt_comfort_ayushi_eng FROM student_feedback UNION ALL
  SELECT interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT vibe_kapil_maths FROM student_feedback UNION ALL
  SELECT doubt_comfort_kapil_maths FROM student_feedback UNION ALL
  SELECT interest_kapil_maths FROM student_feedback UNION ALL
  SELECT vibe_kuldeep_maths FROM student_feedback UNION ALL
  SELECT doubt_comfort_kuldeep_maths FROM student_feedback UNION ALL
  SELECT interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT vibe_dhulesh_maths FROM student_feedback UNION ALL
  SELECT doubt_comfort_dhulesh_maths FROM student_feedback UNION ALL
  SELECT interest_dhulesh_maths FROM student_feedback
)
SELECT
  CAST(ROUND(rating, 0) AS INTEGER) AS rating,
  COUNT(*) AS rating_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS rating_percent
FROM rating_values
WHERE rating IS NOT NULL
GROUP BY CAST(ROUND(rating, 0) AS INTEGER)
ORDER BY rating DESC;

-- Shared normalized teacher ratings CTE for teacher, subject, heatmap, batch ranking, and department charts.
-- Copy this CTE with one of the SELECT statements below when running a query by itself.
WITH teacher_ratings AS (
  SELECT 'Asawari Ma''am' AS teacher, 'Chemistry' AS subject, class_batch, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
  SELECT 'Aniket Sir', 'Maths', class_batch, vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
  SELECT 'Russell Sir', 'Physics', class_batch, vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
  SELECT 'Vibha Ma''am', 'Bio', class_batch, vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
  SELECT 'Shreyash Sir', 'Hist/Pol Sci', class_batch, vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT 'Chetna Ma''am', 'Geo/Eco', class_batch, vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT 'Ashish Sir', 'English', class_batch, vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
  SELECT 'Ayushi Ma''am', 'English', class_batch, vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT 'Kapil Sir', 'Maths', class_batch, vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
  SELECT 'Kuldeep Sir', 'Maths', class_batch, vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT 'Dhulesh Sir', 'Maths', class_batch, vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
)
SELECT
  teacher,
  subject,
  ROUND(AVG(vibe), 2) AS vibe_avg,
  ROUND(AVG(approach), 2) AS approach_avg,
  ROUND(AVG(engage), 2) AS engage_avg,
  ROUND((AVG(vibe) + AVG(approach) + AVG(engage)) / 3.0, 2) AS overall_avg,
  COUNT(CASE WHEN vibe IS NOT NULL OR approach IS NOT NULL OR engage IS NOT NULL THEN 1 END) AS response_count,
  ROUND(COUNT(CASE WHEN vibe BETWEEN 4 AND 5 THEN 1 END) * 100.0 / COUNT(vibe), 1) AS promoter_percent,
  ROUND(COUNT(CASE WHEN vibe BETWEEN 1 AND 2 THEN 1 END) * 100.0 / COUNT(vibe), 1) AS detractor_percent
FROM teacher_ratings
GROUP BY teacher, subject
ORDER BY overall_avg DESC;

-- 5. Teacher x batch heatmap
WITH teacher_ratings AS (
  SELECT 'Asawari Ma''am' AS teacher, 'Chemistry' AS subject, class_batch, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
  SELECT 'Aniket Sir', 'Maths', class_batch, vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
  SELECT 'Russell Sir', 'Physics', class_batch, vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
  SELECT 'Vibha Ma''am', 'Bio', class_batch, vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
  SELECT 'Shreyash Sir', 'Hist/Pol Sci', class_batch, vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT 'Chetna Ma''am', 'Geo/Eco', class_batch, vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT 'Ashish Sir', 'English', class_batch, vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
  SELECT 'Ayushi Ma''am', 'English', class_batch, vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT 'Kapil Sir', 'Maths', class_batch, vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
  SELECT 'Kuldeep Sir', 'Maths', class_batch, vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT 'Dhulesh Sir', 'Maths', class_batch, vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
),
heatmap_values AS (
  SELECT teacher, subject, class_batch, vibe AS rating FROM teacher_ratings UNION ALL
  SELECT teacher, subject, class_batch, approach FROM teacher_ratings UNION ALL
  SELECT teacher, subject, class_batch, engage FROM teacher_ratings
)
SELECT
  teacher,
  subject,
  class_batch,
  ROUND(AVG(rating), 2) AS overall_avg,
  COUNT(rating) AS rating_count
FROM heatmap_values
WHERE class_batch IS NOT NULL
  AND rating IS NOT NULL
GROUP BY teacher, subject, class_batch
ORDER BY teacher, class_batch;

-- 6. Batch rankings and sentiment
WITH teacher_ratings AS (
  SELECT class_batch, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
  SELECT class_batch, vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
  SELECT class_batch, vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
  SELECT class_batch, vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
  SELECT class_batch, vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT class_batch, vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT class_batch, vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
  SELECT class_batch, vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT class_batch, vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
  SELECT class_batch, vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT class_batch, vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
),
batch_values AS (
  SELECT class_batch, vibe AS rating FROM teacher_ratings UNION ALL
  SELECT class_batch, approach FROM teacher_ratings UNION ALL
  SELECT class_batch, engage FROM teacher_ratings
)
SELECT
  class_batch,
  ROUND(AVG(rating), 2) AS avg_score,
  COUNT(rating) AS rating_count,
  ROUND((AVG(rating) - 1.0) / 4.0 * 100.0, 0) AS performance_percent
FROM batch_values
WHERE class_batch IS NOT NULL
  AND rating IS NOT NULL
GROUP BY class_batch
ORDER BY avg_score DESC;

-- 7. Subject wise ranking chart
WITH teacher_ratings AS (
  SELECT 'Chemistry' AS subject, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
  SELECT 'Maths', vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
  SELECT 'Physics', vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
  SELECT 'Bio', vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
  SELECT 'Hist/Pol Sci', vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT 'Geo/Eco', vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT 'English', vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
  SELECT 'English', vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT 'Maths', vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
  SELECT 'Maths', vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT 'Maths', vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
),
subject_values AS (
  SELECT subject, vibe AS rating FROM teacher_ratings UNION ALL
  SELECT subject, approach FROM teacher_ratings UNION ALL
  SELECT subject, engage FROM teacher_ratings
)
SELECT
  subject,
  ROUND(AVG(rating), 2) AS avg_score,
  COUNT(rating) AS rating_count
FROM subject_values
WHERE rating IS NOT NULL
GROUP BY subject
ORDER BY avg_score DESC;

-- 7a. Subject wise 9th vs 10th ranking chart
WITH teacher_ratings AS (
  SELECT 'Chemistry' AS subject, class_batch, vibe_asawari_chem AS vibe, doubt_comfort_asawari_chem AS approach, interest_asawari_chem AS engage FROM student_feedback UNION ALL
  SELECT 'Maths', class_batch, vibe_aniket_maths, doubt_comfort_aniket_maths, interest_aniket_maths FROM student_feedback UNION ALL
  SELECT 'Physics', class_batch, vibe_russell_physics, doubt_comfort_russell_physics, interest_russell_physics FROM student_feedback UNION ALL
  SELECT 'Bio', class_batch, vibe_vibha_bio, doubt_comfort_vibha_bio, interest_vibha_bio FROM student_feedback UNION ALL
  SELECT 'Hist/Pol Sci', class_batch, vibe_shreyash_history_pol, doubt_comfort_shreyash_history_pol, interest_shreyash_history_pol FROM student_feedback UNION ALL
  SELECT 'Geo/Eco', class_batch, vibe_chetna_geo_eco, doubt_comfort_chetna_geo_eco, interest_chetna_geo_eco FROM student_feedback UNION ALL
  SELECT 'English', class_batch, vibe_ashish_eng, doubt_comfort_ashish_eng, interest_ashish_eng FROM student_feedback UNION ALL
  SELECT 'English', class_batch, vibe_ayushi_eng, doubt_comfort_ayushi_eng, interest_ayushi_eng FROM student_feedback UNION ALL
  SELECT 'Maths', class_batch, vibe_kapil_maths, doubt_comfort_kapil_maths, interest_kapil_maths FROM student_feedback UNION ALL
  SELECT 'Maths', class_batch, vibe_kuldeep_maths, doubt_comfort_kuldeep_maths, interest_kuldeep_maths FROM student_feedback UNION ALL
  SELECT 'Maths', class_batch, vibe_dhulesh_maths, doubt_comfort_dhulesh_maths, interest_dhulesh_maths FROM student_feedback
),
subject_grade_values AS (
  SELECT subject, class_batch, vibe AS rating FROM teacher_ratings UNION ALL
  SELECT subject, class_batch, approach FROM teacher_ratings UNION ALL
  SELECT subject, class_batch, engage FROM teacher_ratings
)
SELECT
  subject,
  CASE
    WHEN class_batch LIKE '%10%' THEN '10th'
    WHEN class_batch LIKE '%9%' THEN '9th'
    ELSE 'Other'
  END AS grade,
  ROUND(AVG(rating), 2) AS avg_score,
  COUNT(rating) AS rating_count
FROM subject_grade_values
WHERE rating IS NOT NULL
GROUP BY subject, grade
ORDER BY subject, grade;

-- 8. Infrastructure and environmental metrics chart
SELECT
  class_batch,
  ROUND(AVG(tough_questions_approachability), 2) AS mentor_approachability,
  ROUND(AVG(classroom_peace_mgmt), 2) AS classroom_management,
  ROUND(AVG(hygiene_cleanliness), 2) AS hygiene,
  ROUND(AVG(admin_helpfulness), 2) AS admin_helpfulness,
  ROUND(AVG(class_energy_env), 2) AS class_energy
FROM student_feedback
WHERE class_batch IS NOT NULL
GROUP BY class_batch
ORDER BY class_batch;

-- 9. Home arrival timing chart
SELECT
  CASE
    WHEN lower(school_home_time_summer) LIKE '%10:%'
      OR lower(school_home_time_summer) LIKE '%9:%'
      OR lower(school_home_time_summer) LIKE '%8:%'
      OR (
        lower(school_home_time_summer) LIKE '%am%'
        AND lower(school_home_time_summer) NOT LIKE '%11:%'
        AND lower(school_home_time_summer) NOT LIKE '%12:%'
      )
      THEN 'Before 11am'
    WHEN lower(school_home_time_summer) LIKE '%11:%' THEN '11am-12pm'
    WHEN lower(school_home_time_summer) LIKE '%12:%' THEN '12pm-1pm'
    WHEN lower(school_home_time_summer) LIKE '%1:%' THEN '1pm-2pm'
    WHEN lower(school_home_time_summer) LIKE '%2:%' THEN '2pm-3pm'
    ELSE 'After 3pm'
  END AS timing_bucket,
  COUNT(*) AS student_count
FROM student_feedback
WHERE school_home_time_summer IS NOT NULL
GROUP BY timing_bucket
ORDER BY
  CASE timing_bucket
    WHEN 'Before 11am' THEN 1
    WHEN '11am-12pm' THEN 2
    WHEN '12pm-1pm' THEN 3
    WHEN '1pm-2pm' THEN 4
    WHEN '2pm-3pm' THEN 5
    ELSE 6
  END;

-- 10. Mentor approachability and class control chart
WITH mentor_join AS (
  SELECT
    trim(sm.class_batch) AS class_batch,
    sm.mentor,
    sf.tough_questions_approachability AS approachability,
    sf.classroom_peace_mgmt AS class_control
  FROM student_feedback sf
  LEFT JOIN mdb.student_mentor sm
    ON sf.class_batch = trim(sm.class_batch)
)
SELECT
  mentor,
  ROUND(AVG(approachability), 2) AS approachability_avg,
  ROUND(AVG(class_control), 2) AS class_control_avg,
  COUNT(*) AS feedback_count,
  ROUND(5.0 - (MAX(class_control) - MIN(class_control)), 2) AS consistency_score
FROM mentor_join
WHERE mentor IS NOT NULL
GROUP BY mentor
ORDER BY approachability_avg DESC;

-- 11. Mentor class control distribution chart
WITH mentor_join AS (
  SELECT
    sm.mentor,
    sf.classroom_peace_mgmt AS class_control
  FROM student_feedback sf
  LEFT JOIN mdb.student_mentor sm
    ON sf.class_batch = trim(sm.class_batch)
)
SELECT
  mentor,
  CAST(ROUND(class_control, 0) AS INTEGER) AS rating,
  COUNT(*) AS rating_count
FROM mentor_join
WHERE mentor IS NOT NULL
  AND class_control IS NOT NULL
GROUP BY mentor, CAST(ROUND(class_control, 0) AS INTEGER)
ORDER BY mentor, rating;
