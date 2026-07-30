-- ============================================================
-- 04. 월별 성과 분석
-- 목적:
-- 1) 월별 Control과 Treatment의 전환율 비교
-- 2) 월별 사용자당 매출 비교
-- 3) 월별 전환율 절대 차이와 상대 개선율 산출
-- 4) Tableau 월별 추이 시각화용 테이블 생성
--
-- 대상 테이블: ab_test_clean
-- 결과 테이블: ab_test_monthly
-- ============================================================


CREATE OR REPLACE TABLE
  `landing-page-ab-test.landing_page_ab_test.ab_test_monthly` AS

WITH monthly_group_summary AS (
  SELECT
    event_month,
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
    `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
  GROUP BY
    event_month,
    `group`
),

monthly_pivot AS (
  SELECT
    event_month,

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
    monthly_group_summary
  GROUP BY
    event_month
)

SELECT
  event_month,
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
  monthly_pivot
ORDER BY
  event_month;


-- 생성 결과 확인
SELECT
  *
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_monthly`
ORDER BY
  event_month;


-- 주의:
-- 2023년 8월은 2023년 8월 30일부터 수집된 부분 월로,
-- 다른 월보다 표본 수가 작으므로 해석 시 주의한다.