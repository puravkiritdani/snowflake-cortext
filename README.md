# Snowflake Cortex Labs — Fraud Scoring Example

This SQL file sets up a Snowflake environment to simulate real-time transaction fraud scoring using behavioral baselines and a composite risk formula.

---

## Database & Schema

```
TD_CORTEX_LABS_PURAV
└── SUPPORT
    ├── USERS
    ├── TRANSACTIONS
    ├── DISPUTES
    └── CASE_NOTES
```

---

## Tables

### USERS
Core user profile table. Key fields:

| Column | Description |
|---|---|
| `user_id` | Primary key |
| `kyc_tier` | KYC verification level (`TIER_1` = lowest, `TIER_3` = highest trust) |
| `home_country` | User's registered country — used to detect foreign transactions |
| `risk_score` | Pre-computed risk score `0–100`; higher = riskier |

### TRANSACTIONS
Each financial event. Key fields:

| Column | Description |
|---|---|
| `txn_ts` | Transaction timestamp (`TIMESTAMP_NTZ`) |
| `channel` | `WEB`, `MOBILE`, or `POS` |
| `status` | `APPROVED`, `FLAGGED`, or `DECLINED` |
| `country` | Country where the transaction occurred |

### DISPUTES
Disputes raised against transactions. Reasons include `UNAUTHORIZED_TRANSACTION`, `ACCOUNT_TAKEOVER`, `DUPLICATE_CHARGE`, and `MERCHANT_FRAUD`. Outcomes: `PENDING`, `REFUNDED`, `UNDER_REVIEW`, `ESCALATED`, `DENIED`.

### CASE_NOTES
Free-text support agent notes linked to transactions, capturing investigation details.

---

## Sample Data

- **15 users** across US, GB, DE, NG, IN, JP, PH, BR, CA, FR, AU, MX
- **33 transactions** — 25 historical, plus 8 seeded as today's transactions using `DATEADD('minute', N, CURRENT_DATE()::TIMESTAMP_NTZ)` to simulate a live feed
- **10 disputes** and **12 case notes** covering fraud patterns like account takeover, SIM swap, and velocity attacks

---

## Query 1 — Per-User Behavioral Baseline

```sql
-- build a per user baseline for last 30 days
SELECT user_id, COUNT(*), AVG(amount), STDDEV(amount), ...
FROM TRANSACTIONS
GROUP BY user_id;
```

Aggregates each user's transaction history to establish a behavioral fingerprint:

| Metric | Purpose |
|---|---|
| `avg_amount`, `stddev_amount` | Typical spend level and variability |
| `max_amount` | Absolute ceiling for normal behavior |
| `median_amount` | Robust central tendency, less skewed by outliers |
| `distinct_merchants`, `distinct_countries`, `distinct_channels` | Breadth of normal activity |
| `flagged_count`, `declined_count` | Prior fraud signals |
| `avg_hours_between_txns` | Transaction velocity (`DATEDIFF / NULLIF(COUNT-1, 0)` avoids divide-by-zero) |

> The `WHERE` clause filtering to the last 30 days is commented out so the demo runs against all data.

---

## Query 2 — Real-Time Fraud Scoring (CTE Pipeline)

The main query uses three CTEs chained together:

### CTE 1: `baseline`
Computes each user's historical stats from **all transactions before today** (`txn_ts < CURRENT_DATE()`). This is the reference window for anomaly detection.

### CTE 2: `today_txns`
Selects only **today's transactions** (`txn_ts >= CURRENT_DATE() AND < CURRENT_DATE() + 1 day`). These are the events being evaluated.

### CTE 3: `scored`
Joins `today_txns` with `USERS` (for profile data) and `baseline` (for historical stats), then computes three signals and one composite score:

#### Signal 1 — Amount Z-Score
```sql
(tt.amount - b.avg_amount) / b.stddev_amount
```
Measures how many standard deviations today's transaction amount is from the user's normal spend. A z-score of 3+ indicates a statistical outlier.

#### Signal 2 — Exceeds Historical Max
```sql
CASE WHEN tt.amount > b.max_amount THEN 1 ELSE 0 END
```
Binary flag: `1` if the transaction is the largest ever seen for this user.

#### Signal 3 — Foreign Country Flag
```sql
CASE WHEN tt.country != u.home_country THEN 1 ELSE 0 END
```
Binary flag: `1` if the transaction occurs outside the user's registered country.

---

### Fraud Score Formula

```
fraud_score =
    (LEAST(ABS(z_score), 5) / 5.0) × 40   -- Amount anomaly    (0–40 pts)
  + (user_risk_score / 100.0)    × 30      -- User risk profile (0–30 pts)
  + foreign_country_flag         × 15      -- Geo mismatch      (0–15 pts)
  + exceeds_hist_max             × 15      -- New max amount    (0–15 pts)
```

**Total range: 0–100.**

- The z-score contribution is **capped at 5** (`LEAST(ABS(z_score), 5)`) so extreme outliers don't dominate.
- `user_risk_score` feeds directly from the `USERS` table, acting as a prior on the user's trustworthiness.

---

### Recommended Action

| Threshold | Action |
|---|---|
| `fraud_score >= 70` | **BLOCK** — high confidence fraud |
| `fraud_score >= 45` | **REVIEW** — manual investigation needed |
| `fraud_score < 45` | **PASS** — low risk, approve |

---

## Key Snowflake / SQL Concepts Used

| Concept | Where |
|---|---|
| `CREATE OR REPLACE DATABASE / SCHEMA` | Initial setup |
| `FOREIGN KEY` references | Table relationships |
| `TIMESTAMP_NTZ` | Timezone-naive timestamps (Snowflake best practice) |
| `DATEADD` + `CURRENT_DATE()` | Seeding live-looking data without hardcoding dates |
| `NULLIF(expr, 0)` | Safe division to avoid divide-by-zero |
| `LEAST` / `ABS` | Capping and normalizing the z-score |
| `STDDEV` / `MEDIAN` | Statistical aggregates for behavioral profiling |
| CTEs (`WITH ... AS`) | Modular, readable multi-step query pipeline |
| `UNION ALL` | Row-count verification across all tables |
