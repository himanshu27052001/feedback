SELECT
  SUM(
    (vibe_asawari_chem IS NOT NULL) +
    (vibe_aniket_maths IS NOT NULL) +
    (vibe_russell_physics IS NOT NULL) +
    (vibe_vibha_bio IS NOT NULL) +
    (vibe_shreyash_history_pol IS NOT NULL) +
    (vibe_chetna_geo_eco IS NOT NULL) +
    (vibe_ashish_eng IS NOT NULL) +
    (vibe_ayushi_eng IS NOT NULL) +
    (vibe_kapil_maths IS NOT NULL) +
    (vibe_kuldeep_maths IS NOT NULL) +
    (vibe_dhulesh_maths IS NOT NULL) +
    (doubt_comfort_asawari_chem IS NOT NULL) +
    (doubt_comfort_aniket_maths IS NOT NULL) +
    (doubt_comfort_russell_physics IS NOT NULL) +
    (doubt_comfort_vibha_bio IS NOT NULL) +
    (doubt_comfort_shreyash_history_pol IS NOT NULL) +
    (doubt_comfort_chetna_geo_eco IS NOT NULL) +
    (doubt_comfort_ashish_eng IS NOT NULL) +
    (doubt_comfort_ayushi_maths IS NOT NULL) +
    (doubt_comfort_kapil_maths IS NOT NULL) +
    (doubt_comfort_kuldeep_maths IS NOT NULL) +
    (doubt_comfort_dhulesh_maths IS NOT NULL) +
    (interest_asawari_chem IS NOT NULL) +
    (interest_aniket_maths IS NOT NULL) +
    (interest_russell_physics IS NOT NULL) +
    (interest_vibha_bio IS NOT NULL) +
    (interest_shreyash_history_pol IS NOT NULL) +
    (interest_chetna_geo_eco IS NOT NULL) +
    (interest_ashish_eng IS NOT NULL) +
    (interest_ayushi_eng IS NOT NULL) +
    (interest_kapil_maths IS NOT NULL) +
    (interest_kuldeep_maths IS NOT NULL) +
    (interest_dhulesh_maths IS NOT NULL)
  ) AS total_non_null_values
FROM student_feedback;
