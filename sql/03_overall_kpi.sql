-- ============================================================
-- 03. 전체 A/B 성과 분석
-- 목적:
-- 1) Control과 Treatment의 구매 전환 성과 비교
-- 2) 매출 및 사용자 행동 지표 비교
-- 3) 신규 페이지 적용에 따른 추가 전환과 매출 추정
--
-- 대상 테이블: ab_test_clean
-- ============================================================


-- 1. 그룹별 전체 KPI
SELECT
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
  ) AS revenue_per_user,

  AVG(
    IF(converted = 1, purchase_amount, NULL)
  ) AS avg_purchase_amount_buyer,

  AVG(session_duration) AS avg_session_duration,
  AVG(pages_visited) AS avg_pages_visited

FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
GROUP BY
  `group`
ORDER BY
  `group`;


-- 2. Tableau KPI 카드용 요약 테이블 생성
CREATE OR REPLACE TABLE
  `landing-page-ab-test.landing_page_ab_test.ab_test_dashboard_summary` AS

WITH group_summary AS (
  SELECT
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
    ) AS revenue_per_user,

    AVG(
      IF(converted = 1, purchase_amount, NULL)
    ) AS avg_purchase_amount_buyer,

    AVG(session_duration) AS avg_session_duration,
    AVG(pages_visited) AS avg_pages_visited

  FROM
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
  GROUP BY
    `group`
)

SELECT
  *
FROM
  group_summary
ORDER BY
  `group`;


-- 3. 예상 추가 전환 수와 추가 매출 추정
WITH group_summary AS (
  SELECT
    `group`,
    COUNT(DISTINCT user_id) AS users,
    SUM(converted) AS conversions,

    SAFE_DIVIDE(
      SUM(converted),
      COUNT(DISTINCT user_id)
    ) AS conversion_rate,

    AVG(
      IF(converted = 1, purchase_amount, NULL)
    ) AS avg_purchase_amount_buyer

  FROM
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
  GROUP BY
    `group`
),

pivoted AS (
  SELECT
    MAX(IF(`group` = 'control', users, NULL))
      AS control_users,

    MAX(IF(`group` = 'treatment', users, NULL))
      AS treatment_users,

    MAX(IF(`group` = 'control', conversion_rate, NULL))
      AS control_conversion_rate,

    MAX(IF(`group` = 'treatment', conversion_rate, NULL))
      AS treatment_conversion_rate,

    MAX(IF(`group` = 'treatment', conversions, NULL))
      AS treatment_actual_conversions,

    MAX(
      IF(
        `group` = 'treatment',
        avg_purchase_amount_buyer,
        NULL
      )
    ) AS treatment_avg_purchase_amount_buyer

  FROM
    group_summary
)

SELECT
  treatment_users,

  treatment_users * control_conversion_rate
    AS expected_conversions_with_control_page,

  treatment_actual_conversions,

  treatment_users
    * (treatment_conversion_rate - control_conversion_rate)
    AS incremental_conversions,

  treatment_avg_purchase_amount_buyer,

  treatment_users
    * (treatment_conversion_rate - control_conversion_rate)
    * treatment_avg_purchase_amount_buyer
    AS incremental_revenue

FROM
  pivoted;


-- 4. 평균과 중앙값 비교
SELECT
  `group`,

  AVG(session_duration) AS avg_session_duration,

  APPROX_QUANTILES(
    session_duration,
    100
  )[OFFSET(50)] AS median_session_duration,

  AVG(pages_visited) AS avg_pages_visited,

  APPROX_QUANTILES(
    pages_visited,
    100
  )[OFFSET(50)] AS median_pages_visited,

  AVG(
    IF(converted = 1, purchase_amount, NULL)
  ) AS avg_purchase_amount_buyer,

  APPROX_QUANTILES(
    IF(converted = 1, purchase_amount, NULL),
    100
  )[OFFSET(50)] AS median_purchase_amount_buyer

FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
GROUP BY
  `group`
ORDER BY
  `group`;