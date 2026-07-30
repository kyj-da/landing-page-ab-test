-- ============================================================
-- 05. 사용자 세그먼트 분석
-- 목적:
-- 신규 랜딩페이지의 효과가 연령대, 성별, 기기 유형,
-- 국가에 따라 다르게 나타나는지 비교한다.
--
-- 대상 테이블: ab_test_clean
-- 결과 테이블: ab_test_segment
-- ============================================================


CREATE OR REPLACE TABLE
  `landing-page-ab-test.landing_page_ab_test.ab_test_segment` AS

WITH segment_base AS (

  -- 1. 연령대 세그먼트
  SELECT
    'Age group' AS segment_type,
    age_group AS segment_value,
    `group`,
    user_id,
    converted,
    purchase_amount
  FROM
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`

  UNION ALL

  -- 2. 성별 세그먼트
  SELECT
    'Gender' AS segment_type,
    gender AS segment_value,
    `group`,
    user_id,
    converted,
    purchase_amount
  FROM
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`

  UNION ALL

  -- 3. 기기 유형 세그먼트
  SELECT
    'Device type' AS segment_type,
    device_type AS segment_value,
    `group`,
    user_id,
    converted,
    purchase_amount
  FROM
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`

  UNION ALL

  -- 4. 국가 세그먼트
  SELECT
    'Location' AS segment_type,
    location AS segment_value,
    `group`,
    user_id,
    converted,
    purchase_amount
  FROM
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
),

segment_group_summary AS (
  SELECT
    segment_type,
    segment_value,
    `group`,

    COUNT(DISTINCT user_id) AS users,
    SUM(converted) AS conversions,

    SAFE_DIVIDE(
      SUM(converted),
      COUNT(DISTINCT user_id)
    ) AS conversion_rate,

    SUM(purchase_amount) AS total_revenue,

    SAFE_DIVIDE(
      SUM(purchase_amount),
      COUNT(DISTINCT user_id)
    ) AS revenue_per_user

  FROM
    segment_base
  GROUP BY
    segment_type,
    segment_value,
    `group`
),

segment_pivot AS (
  SELECT
    segment_type,
    segment_value,

    MAX(IF(`group` = 'control', users, NULL))
      AS control_users,

    MAX(IF(`group` = 'treatment', users, NULL))
      AS treatment_users,

    MAX(IF(`group` = 'control', conversions, NULL))
      AS control_conversions,

    MAX(IF(`group` = 'treatment', conversions, NULL))
      AS treatment_conversions,

    MAX(IF(`group` = 'control', conversion_rate, NULL))
      AS control_conversion_rate,

    MAX(IF(`group` = 'treatment', conversion_rate, NULL))
      AS treatment_conversion_rate,

    MAX(IF(`group` = 'control', revenue_per_user, NULL))
      AS control_revenue_per_user,

    MAX(IF(`group` = 'treatment', revenue_per_user, NULL))
      AS treatment_revenue_per_user

  FROM
    segment_group_summary
  GROUP BY
    segment_type,
    segment_value
)

SELECT
  segment_type,
  segment_value,
  control_users,
  treatment_users,
  control_conversions,
  treatment_conversions,
  control_conversion_rate,
  treatment_conversion_rate,

  treatment_conversion_rate
    - control_conversion_rate
    AS absolute_lift,

  SAFE_DIVIDE(
    treatment_conversion_rate
      - control_conversion_rate,
    control_conversion_rate
  ) AS relative_lift,

  control_revenue_per_user,
  treatment_revenue_per_user

FROM
  segment_pivot
ORDER BY
  segment_type,
  segment_value;


-- 생성 결과 확인
SELECT
  *
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_segment`
ORDER BY
  segment_type,
  segment_value;


-- 해석 시 주의:
-- 1) 60대 이상은 표본 수가 작으므로 제한적으로 해석한다.
-- 2) Other 성별 범주는 Female과 Male 이외의 응답을 통합한 값이며,
--    원본 데이터에 세부 정의가 제공되지 않았다.