CREATE OR REPLACE DATABASE TD_CORTEX_LABS_PURAV;

CREATE OR REPLACE SCHEMA TD_CORTEX_LABS_PURAV.SUPPORT;

CREATE TABLE IF NOT EXISTS TD_CORTEX_LABS_PURAV.SUPPORT.USERS (
    user_id VARCHAR NOT NULL PRIMARY KEY,
    signup_date DATE,
    kyc_tier VARCHAR,
    home_country VARCHAR,
    risk_score NUMBER(10,2)
);




CREATE TABLE IF NOT EXISTS TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS (
    txn_id VARCHAR NOT NULL PRIMARY KEY,
    user_id VARCHAR,
    merchant_id VARCHAR,
    amount NUMBER(18,2),
    currency VARCHAR,
    txn_ts TIMESTAMP_NTZ,
    channel VARCHAR,
    country VARCHAR,
    status VARCHAR,
    FOREIGN KEY (user_id) REFERENCES TD_CORTEX_LABS_PURAV.SUPPORT.USERS(user_id)
)

CREATE TABLE IF NOT EXISTS TD_CORTEX_LABS_PURAV.SUPPORT.CASE_NOTES (
    case_id VARCHAR NOT NULL PRIMARY KEY,
    txn_id VARCHAR,
    note_ts TIMESTAMP_NTZ,
    note_text VARCHAR,
    FOREIGN KEY (txn_id) REFERENCES TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS(txn_id)
)

CREATE TABLE IF NOT EXISTS TD_CORTEX_LABS_PURAV.SUPPORT.DISPUTES (
    dispute_id VARCHAR NOT NULL PRIMARY KEY,
    txn_id VARCHAR,
    dispute_ts TIMESTAMP_NTZ,
    dispute_reason VARCHAR,
    outcome VARCHAR,
    FOREIGN KEY (txn_id) REFERENCES TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS(txn_id)
)

INSERT INTO TD_CORTEX_LABS_PURAV.SUPPORT.USERS (user_id, signup_date, kyc_tier, home_country, risk_score)
VALUES
  ('U001', '2022-03-15', 'TIER_3', 'US', 12.50),
  ('U002', '2023-01-20', 'TIER_2', 'GB', 35.00),
  ('U003', '2021-07-08', 'TIER_3', 'DE', 8.75),
  ('U004', '2024-06-01', 'TIER_1', 'NG', 72.00),
  ('U005', '2023-11-10', 'TIER_2', 'IN', 45.30),
  ('U006', '2022-09-25', 'TIER_3', 'US', 15.00),
  ('U007', '2024-02-14', 'TIER_1', 'BR', 68.20),
  ('U008', '2023-05-30', 'TIER_2', 'CA', 28.90),
  ('U009', '2021-12-01', 'TIER_3', 'JP', 5.40),
  ('U010', '2024-08-18', 'TIER_1', 'PH', 81.00),
  ('U011', '2023-03-22', 'TIER_2', 'FR', 40.10),
  ('U012', '2022-11-05', 'TIER_3', 'AU', 11.25),
  ('U013', '2024-01-09', 'TIER_1', 'NG', 77.50),
  ('U014', '2023-08-17', 'TIER_2', 'MX', 52.00),
  ('U015', '2022-04-30', 'TIER_3', 'US', 9.80);


INSERT INTO TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS (txn_id, user_id, merchant_id, amount, currency, txn_ts, channel, country, status)
VALUES
  ('TXN001', 'U001', 'M100', 250.00, 'USD', '2025-10-01 09:15:00', 'WEB', 'US', 'APPROVED'),
  ('TXN002', 'U001', 'M101', 1500.00, 'USD', '2025-10-01 14:30:00', 'MOBILE', 'US', 'APPROVED'),
  ('TXN003', 'U002', 'M200', 89.99, 'GBP', '2025-10-02 11:00:00', 'WEB', 'GB', 'APPROVED'),
  ('TXN004', 'U003', 'M300', 3200.00, 'EUR', '2025-10-02 16:45:00', 'POS', 'DE', 'APPROVED'),
  ('TXN005', 'U004', 'M400', 15000.00, 'USD', '2025-10-03 02:10:00', 'MOBILE', 'NG', 'FLAGGED'),
  ('TXN006', 'U004', 'M401', 12000.00, 'USD', '2025-10-03 02:15:00', 'MOBILE', 'NG', 'DECLINED'),
  ('TXN007', 'U005', 'M500', 475.50, 'INR', '2025-10-04 08:20:00', 'WEB', 'IN', 'APPROVED'),
  ('TXN008', 'U006', 'M100', 62.30, 'USD', '2025-10-04 19:00:00', 'POS', 'US', 'APPROVED'),
  ('TXN009', 'U007', 'M600', 8500.00, 'BRL', '2025-10-05 03:45:00', 'MOBILE', 'BR', 'FLAGGED'),
  ('TXN010', 'U008', 'M700', 199.99, 'CAD', '2025-10-05 12:30:00', 'WEB', 'CA', 'APPROVED'),
  ('TXN011', 'U009', 'M800', 55000.00, 'JPY', '2025-10-06 07:00:00', 'POS', 'JP', 'APPROVED'),
  ('TXN012', 'U010', 'M900', 22000.00, 'PHP', '2025-10-06 23:55:00', 'MOBILE', 'PH', 'FLAGGED'),
  ('TXN013', 'U002', 'M201', 4500.00, 'GBP', '2025-10-07 10:15:00', 'WEB', 'GB', 'DECLINED'),
  ('TXN014', 'U011', 'M110', 320.00, 'EUR', '2025-10-07 14:00:00', 'POS', 'FR', 'APPROVED'),
  ('TXN015', 'U012', 'M120', 780.00, 'AUD', '2025-10-08 09:30:00', 'WEB', 'AU', 'APPROVED'),
  ('TXN016', 'U013', 'M402', 9500.00, 'USD', '2025-10-08 01:20:00', 'MOBILE', 'NG', 'FLAGGED'),
  ('TXN017', 'U014', 'M130', 1100.00, 'MXN', '2025-10-09 17:45:00', 'POS', 'MX', 'APPROVED'),
  ('TXN018', 'U015', 'M100', 45.00, 'USD', '2025-10-09 20:10:00', 'WEB', 'US', 'APPROVED'),
  ('TXN019', 'U005', 'M501', 2800.00, 'INR', '2025-10-10 06:30:00', 'MOBILE', 'IN', 'APPROVED'),
  ('TXN020', 'U001', 'M102', 9999.99, 'USD', '2025-10-10 23:59:00', 'MOBILE', 'RU', 'FLAGGED'),
  ('TXN021', 'U003', 'M301', 150.00, 'EUR', '2025-10-11 13:00:00', 'WEB', 'DE', 'APPROVED'),
  ('TXN022', 'U007', 'M601', 7200.00, 'BRL', '2025-10-11 04:00:00', 'MOBILE', 'BR', 'DECLINED'),
  ('TXN023', 'U010', 'M901', 18000.00, 'PHP', '2025-10-12 22:30:00', 'MOBILE', 'PH', 'FLAGGED'),
  ('TXN024', 'U008', 'M701', 3400.00, 'CAD', '2025-10-12 15:20:00', 'WEB', 'CA', 'APPROVED'),
  ('TXN025', 'U006', 'M103', 125.00, 'USD', '2025-10-13 10:45:00', 'POS', 'US', 'APPROVED');

INSERT INTO TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS (txn_id, user_id, merchant_id, amount, currency, txn_ts, channel, country, status)
VALUES
  ('TXN026', 'U004', 'M999', 48000.00, 'USD', DATEADD('minute', 133, CURRENT_DATE()::TIMESTAMP_NTZ), 'MOBILE', 'KE', 'FLAGGED'),
  ('TXN027', 'U001', 'M998', 25000.00, 'USD', DATEADD('minute', 185, CURRENT_DATE()::TIMESTAMP_NTZ), 'MOBILE', 'CN', 'FLAGGED'),
  ('TXN028', 'U010', 'M997', 95000.00, 'PHP', DATEADD('minute', 105, CURRENT_DATE()::TIMESTAMP_NTZ), 'MOBILE', 'RU', 'FLAGGED'),
  ('TXN029', 'U013', 'M996', 32000.00, 'USD', DATEADD('minute', 270, CURRENT_DATE()::TIMESTAMP_NTZ), 'MOBILE', 'AE', 'FLAGGED'),
  ('TXN030', 'U007', 'M995', 19500.00, 'BRL', DATEADD('minute', 310, CURRENT_DATE()::TIMESTAMP_NTZ), 'MOBILE', 'NG', 'FLAGGED'),
  ('TXN031', 'U002', 'M994', 120.00,   'GBP', DATEADD('minute', 540, CURRENT_DATE()::TIMESTAMP_NTZ), 'WEB',    'GB', 'APPROVED'),
  ('TXN032', 'U006', 'M100', 55.00,    'USD', DATEADD('minute', 615, CURRENT_DATE()::TIMESTAMP_NTZ), 'POS',    'US', 'APPROVED'),
  ('TXN033', 'U003', 'M300', 180.00,   'EUR', DATEADD('minute', 690, CURRENT_DATE()::TIMESTAMP_NTZ), 'WEB',    'DE', 'APPROVED');

  INSERT INTO TD_CORTEX_LABS_PURAV.SUPPORT.DISPUTES (dispute_id, txn_id, dispute_ts, dispute_reason, outcome)
VALUES
  ('D001', 'TXN005', '2025-10-04 10:00:00', 'UNAUTHORIZED_TRANSACTION', 'PENDING'),
  ('D002', 'TXN006', '2025-10-04 10:05:00', 'UNAUTHORIZED_TRANSACTION', 'REFUNDED'),
  ('D003', 'TXN009', '2025-10-06 09:00:00', 'ACCOUNT_TAKEOVER', 'UNDER_REVIEW'),
  ('D004', 'TXN013', '2025-10-08 12:00:00', 'DUPLICATE_CHARGE', 'REFUNDED'),
  ('D005', 'TXN012', '2025-10-07 14:30:00', 'UNAUTHORIZED_TRANSACTION', 'PENDING'),
  ('D006', 'TXN016', '2025-10-09 08:00:00', 'ACCOUNT_TAKEOVER', 'UNDER_REVIEW'),
  ('D007', 'TXN020', '2025-10-11 11:15:00', 'UNAUTHORIZED_TRANSACTION', 'ESCALATED'),
  ('D008', 'TXN022', '2025-10-12 06:30:00', 'MERCHANT_FRAUD', 'DENIED'),
  ('D009', 'TXN023', '2025-10-13 09:45:00', 'UNAUTHORIZED_TRANSACTION', 'PENDING'),
  ('D010', 'TXN002', '2025-10-03 16:00:00', 'NOT_AS_DESCRIBED', 'REFUNDED');

  INSERT INTO TD_CORTEX_LABS_PURAV.SUPPORT.CASE_NOTES (case_id, txn_id, note_ts, note_text)
VALUES
  ('C001', 'TXN005', '2025-10-04 10:30:00', 'Customer reported unauthorized purchase of electronics. Device fingerprint mismatch confirmed.'),
  ('C002', 'TXN005', '2025-10-04 14:00:00', 'Escalated to fraud team. IP geolocation shows access from unusual region.'),
  ('C003', 'TXN006', '2025-10-04 10:35:00', 'Companion transaction to TXN005. Auto-declined by velocity rule. Refund processed.'),
  ('C004', 'TXN009', '2025-10-06 09:30:00', 'Customer claims account was compromised. Password reset initiated.'),
  ('C005', 'TXN009', '2025-10-07 11:00:00', 'SIM swap confirmed by carrier. Account frozen pending investigation.'),
  ('C006', 'TXN013', '2025-10-08 12:30:00', 'Merchant confirmed duplicate billing error. Refund issued within 24h.'),
  ('C007', 'TXN012', '2025-10-07 15:00:00', 'Multiple high-value mobile transactions at odd hours. Customer unresponsive.'),
  ('C008', 'TXN016', '2025-10-09 08:30:00', 'Pattern matches known fraud ring operating out of West Africa. Referred to compliance.'),
  ('C009', 'TXN020', '2025-10-11 12:00:00', 'Transaction originated from Russia but customer is US-based. Travel not confirmed.'),
  ('C010', 'TXN020', '2025-10-12 09:00:00', 'Customer confirmed they did not travel. Provisional credit issued. Card replaced.'),
  ('C011', 'TXN022', '2025-10-12 07:00:00', 'Customer disputes charge but merchant provided valid proof of delivery.'),
  ('C012', 'TXN023', '2025-10-13 10:00:00', 'Late-night high-value mobile transaction. Pending customer callback for verification.');

  SELECT 'USERS' AS table_name, COUNT(*) AS row_count FROM TD_CORTEX_LABS_PURAV.SUPPORT.USERS
UNION ALL
SELECT 'TRANSACTIONS', COUNT(*) FROM TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS
UNION ALL
SELECT 'DISPUTES', COUNT(*) FROM TD_CORTEX_LABS_PURAV.SUPPORT.DISPUTES
UNION ALL
SELECT 'CASE_NOTES', COUNT(*) FROM TD_CORTEX_LABS_PURAV.SUPPORT.CASE_NOTES;


-- build a per user baseline for last 30 days
SELECT
    t.user_id,
    COUNT(*)                                        AS txn_count,
    SUM(t.amount)                                   AS total_amount,
    AVG(t.amount)                                   AS avg_amount,
    STDDEV(t.amount)                                AS stddev_amount,
    MAX(t.amount)                                   AS max_amount,
    MEDIAN(t.amount)                                AS median_amount,
    COUNT(DISTINCT t.merchant_id)                   AS distinct_merchants,
    COUNT(DISTINCT t.country)                       AS distinct_countries,
    COUNT(DISTINCT t.channel)                       AS distinct_channels,
    SUM(CASE WHEN t.status = 'FLAGGED'  THEN 1 ELSE 0 END) AS flagged_count,
    SUM(CASE WHEN t.status = 'DECLINED' THEN 1 ELSE 0 END) AS declined_count,
    MIN(t.txn_ts)                                   AS first_txn_ts,
    MAX(t.txn_ts)                                   AS last_txn_ts,
    DATEDIFF('hour', MIN(t.txn_ts), MAX(t.txn_ts))
        / NULLIF(COUNT(*) - 1, 0)                  AS avg_hours_between_txns
FROM TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS t
--WHERE t.txn_ts >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY t.user_id
ORDER BY total_amount DESC;

-- Score today's transactions against 30-day baseline + user risk
WITH baseline AS (
    SELECT
        t.user_id,
        COUNT(*)                                              AS txn_count_30d,
        AVG(t.amount)                                         AS avg_amount,
        STDDEV(t.amount)                                      AS stddev_amount,
        MAX(t.amount)                                         AS max_amount,
        COUNT(DISTINCT t.merchant_id)                         AS distinct_merchants,
        COUNT(DISTINCT t.country)                             AS distinct_countries,
        SUM(CASE WHEN t.status = 'FLAGGED'  THEN 1 ELSE 0 END) AS flagged_count,
        SUM(CASE WHEN t.status = 'DECLINED' THEN 1 ELSE 0 END) AS declined_count
    FROM TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS t
    --WHERE t.txn_ts >= DATEADD('day', -30, CURRENT_TIMESTAMP())
      WHERE t.txn_ts <  CURRENT_DATE()
    GROUP BY t.user_id
),

today_txns AS (
    SELECT *
    FROM TD_CORTEX_LABS_PURAV.SUPPORT.TRANSACTIONS
    WHERE txn_ts >= CURRENT_DATE()
      AND txn_ts <  DATEADD('day', 1, CURRENT_DATE())
),

scored AS (
    SELECT
        tt.txn_id,
        tt.user_id,
        tt.amount,
        tt.currency,
        tt.txn_ts,
        tt.channel,
        tt.country                                            AS txn_country,
        tt.status,
        u.risk_score                                          AS user_risk_score,
        u.kyc_tier,
        u.home_country,
        b.avg_amount                                          AS baseline_avg,
        b.stddev_amount                                       AS baseline_stddev,
        b.max_amount                                          AS baseline_max,
        b.txn_count_30d,

        CASE WHEN b.stddev_amount > 0
             THEN (tt.amount - b.avg_amount) / b.stddev_amount
             ELSE 0
        END                                                   AS amount_zscore,

        CASE WHEN tt.amount > b.max_amount THEN 1 ELSE 0
        END                                                   AS exceeds_hist_max,

        CASE WHEN tt.country != u.home_country THEN 1 ELSE 0
        END                                                   AS foreign_country_flag,

        ROUND(
            (LEAST(ABS(
                CASE WHEN b.stddev_amount > 0
                     THEN (tt.amount - b.avg_amount) / b.stddev_amount
                     ELSE 0
                END
            ), 5) / 5.0) * 40
          + (u.risk_score / 100.0) * 30
          + (CASE WHEN tt.country != u.home_country THEN 1 ELSE 0 END) * 15
          + (CASE WHEN tt.amount > b.max_amount THEN 1 ELSE 0 END) * 15
        , 2)                                                  AS fraud_score,

        CASE
            WHEN (LEAST(ABS(
                    CASE WHEN b.stddev_amount > 0
                         THEN (tt.amount - b.avg_amount) / b.stddev_amount
                         ELSE 0
                    END
                 ), 5) / 5.0) * 40
               + (u.risk_score / 100.0) * 30
               + (CASE WHEN tt.country != u.home_country THEN 1 ELSE 0 END) * 15
               + (CASE WHEN tt.amount > b.max_amount THEN 1 ELSE 0 END) * 15
                 >= 70 THEN 'BLOCK'
            WHEN (LEAST(ABS(
                    CASE WHEN b.stddev_amount > 0
                         THEN (tt.amount - b.avg_amount) / b.stddev_amount
                         ELSE 0
                    END
                 ), 5) / 5.0) * 40
               + (u.risk_score / 100.0) * 30
               + (CASE WHEN tt.country != u.home_country THEN 1 ELSE 0 END) * 15
               + (CASE WHEN tt.amount > b.max_amount THEN 1 ELSE 0 END) * 15
                 >= 45 THEN 'REVIEW'
            ELSE 'PASS'
        END                                                   AS recommended_action

    FROM today_txns tt
    JOIN TD_CORTEX_LABS_PURAV.SUPPORT.USERS u ON u.user_id = tt.user_id
    LEFT JOIN baseline b ON b.user_id = tt.user_id
)

SELECT
    txn_id,
    user_id,
    amount,
    currency,
    txn_ts,
    channel,
    txn_country,
    status,
    kyc_tier,
    home_country,
    user_risk_score,
    baseline_avg,
    baseline_stddev,
    baseline_max,
    txn_count_30d,
    ROUND(amount_zscore, 2)                                   AS amount_zscore,
    exceeds_hist_max,
    foreign_country_flag,
    fraud_score,
    recommended_action
FROM scored
ORDER BY fraud_score DESC;

