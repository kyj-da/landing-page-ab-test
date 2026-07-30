-- ============================================================
-- 01. 데이터 품질 점검
-- 목적:
-- 1) 데이터 규모와 분석 기간 확인
-- 2) 사용자 중복 및 결측치 확인
-- 3) 실험 그룹과 랜딩페이지 매칭 확인
-- 4) 전환 여부와 구매금액 간 논리적 일관성 확인
-- 5) 주요 변수의 범위와 범주 확인
--
-- 대상 테이블:
-- landing-page-ab-test.landing_page_ab_test.ab_test_raw
-- ============================================================


-- 1. 전체 행 수와 고유 사용자 수 확인
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT user_id) AS unique_users
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 2. 중복 사용자 확인
SELECT
  user_id,
  COUNT(*) AS row_count
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`
GROUP BY
  user_id
HAVING
  COUNT(*) > 1
ORDER BY
  row_count DESC;


-- 3. 데이터 수집 기간 확인
SELECT
  MIN(timestamp) AS start_timestamp,
  MAX(timestamp) AS end_timestamp
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 4. 컬럼별 결측치 확인
SELECT
  COUNTIF(user_id IS NULL) AS user_id_nulls,
  COUNTIF(timestamp IS NULL) AS timestamp_nulls,
  COUNTIF(`group` IS NULL) AS group_nulls,
  COUNTIF(landing_page IS NULL) AS landing_page_nulls,
  COUNTIF(converted IS NULL) AS converted_nulls,
  COUNTIF(age IS NULL) AS age_nulls,
  COUNTIF(gender IS NULL) AS gender_nulls,
  COUNTIF(location IS NULL) AS location_nulls,
  COUNTIF(session_duration IS NULL) AS session_duration_nulls,
  COUNTIF(pages_visited IS NULL) AS pages_visited_nulls,
  COUNTIF(device_type IS NULL) AS device_type_nulls,
  COUNTIF(purchase_amount IS NULL) AS purchase_amount_nulls
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 5. 실험 그룹별 사용자 수와 비중 확인
SELECT
  `group`,
  COUNT(*) AS users,
  ROUND(
    SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100,
    2
  ) AS user_share_pct
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`
GROUP BY
  `group`
ORDER BY
  `group`;


-- 6. 실험 그룹과 랜딩페이지 조합 확인
SELECT
  `group`,
  landing_page,
  COUNT(*) AS users,
  ROUND(
    SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100,
    2
  ) AS user_share_pct
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`
GROUP BY
  `group`,
  landing_page
ORDER BY
  `group`,
  landing_page;


-- 7. Control-old_page, Treatment-new_page 매칭 오류 확인
SELECT
  COUNTIF(
    (`group` = 'control' AND landing_page != 'old_page')
    OR
    (`group` = 'treatment' AND landing_page != 'new_page')
  ) AS invalid_group_page_rows
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 8. converted 값 범위와 유효성 확인
SELECT
  MIN(converted) AS min_converted,
  MAX(converted) AS max_converted,
  COUNTIF(converted NOT IN (0, 1)) AS invalid_converted_rows
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 9. 전환 여부와 구매금액 간 논리적 오류 확인
SELECT
  COUNTIF(
    converted = 0
    AND purchase_amount > 0
  ) AS non_converter_with_purchase,

  COUNTIF(
    converted = 1
    AND purchase_amount <= 0
  ) AS converter_without_positive_purchase
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 10. 주요 수치형 변수의 범위 확인
SELECT
  MIN(age) AS min_age,
  MAX(age) AS max_age,
  MIN(session_duration) AS min_session_duration,
  MAX(session_duration) AS max_session_duration,
  MIN(pages_visited) AS min_pages_visited,
  MAX(pages_visited) AS max_pages_visited,
  MIN(purchase_amount) AS min_purchase_amount,
  MAX(purchase_amount) AS max_purchase_amount
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`;


-- 11. 성별 범주 확인
SELECT
  gender,
  COUNT(*) AS users
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`
GROUP BY
  gender
ORDER BY
  users DESC;


-- 12. 기기 유형 범주 확인
SELECT
  device_type,
  COUNT(*) AS users
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`
GROUP BY
  device_type
ORDER BY
  users DESC;


-- 13. 국가 범주 확인
SELECT
  location,
  COUNT(*) AS users
FROM
  `landing-page-ab-test.landing_page_ab_test.ab_test_raw`
GROUP BY
  location
ORDER BY
  users DESC;