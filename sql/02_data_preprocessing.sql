-- ============================================================
-- 02. 데이터 전처리
-- 목적:
-- 1) 날짜 및 월 파생변수 생성
-- 2) 전환 여부를 문자형 변수로 구분
-- 3) 연령대 파생변수 생성
-- 4) 분석용 정제 테이블 구축
--
-- 원본 테이블: ab_test_raw
-- 결과 테이블: ab_test_clean
-- ============================================================


CREATE OR REPLACE TABLE
  `landing-page-ab-test.landing_page_ab_test.ab_test_clean` AS

SELECT
  user_id,
  timestamp,

  -- 날짜 및 월 파생변수
  DATE(timestamp) AS event_date,
  DATE_TRUNC(DATE(timestamp), MONTH) AS event_month,

  -- 실험 정보
  `group`,
  landing_page AS page,
  converted,

  -- 전환 여부 구분
  CASE
    WHEN converted = 1 THEN 'Converter'
    ELSE 'Non-converter'
  END AS is_converter,

  -- 사용자 특성
  age,

  CASE
    WHEN age < 20 THEN '10대'
    WHEN age < 30 THEN '20대'
    WHEN age < 40 THEN '30대'
    WHEN age < 50 THEN '40대'
    WHEN age < 60 THEN '50대'
    ELSE '60대 이상'
  END AS age_group,

  gender,
  location,

  -- 사용자 행동 및 구매 지표
  session_duration,
  pages_visited,
  device_type,
  purchase_amount

FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 1. 정제 테이블 행 수, 사용자 수, 분석 기간 확인
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT user_id) AS unique_users,
  MIN(event_date) AS start_date,
  MAX(event_date) AS end_date
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_clean`;


-- 2. 연령대별 사용자 수 확인
SELECT
  age_group,
  COUNT(DISTINCT user_id) AS users
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
GROUP BY
  age_group
ORDER BY
  CASE age_group
    WHEN '10대' THEN 1
    WHEN '20대' THEN 2
    WHEN '30대' THEN 3
    WHEN '40대' THEN 4
    WHEN '50대' THEN 5
    WHEN '60대 이상' THEN 6
  END;


-- 3. 그룹과 페이지 매칭 재확인
SELECT
  `group`,
  page,
  COUNT(DISTINCT user_id) AS users
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_clean`
GROUP BY
  `group`,
  page
ORDER BY
  `group`,
  page;