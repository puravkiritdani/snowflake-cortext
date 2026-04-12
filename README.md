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

---

## Deep Dive: Key Concepts

### 1. Building Baselines with Aggregates

A **baseline** is a statistical snapshot of a user's normal behavior computed from historical data. In fraud detection, it answers: *"what does this user's typical activity look like?"* — so that today's transactions can be compared against it.

The `baseline` CTE uses standard SQL aggregates over each user's past transactions:

| Aggregate | What it captures |
|---|---|
| `AVG(amount)` | Typical spend level |
| `STDDEV(amount)` | How much the spend naturally varies |
| `MAX(amount)` | The ceiling of normal behavior |
| `COUNT(DISTINCT merchant_id)` | Breadth of normal merchant activity |
| `COUNT(DISTINCT country)` | Geographic footprint |
| `SUM(CASE WHEN status = 'FLAGGED' ...)` | Prior fraud signals embedded in history |

**Why STDDEV matters:** A user who regularly spends $5,000–$10,000 should not be flagged for a $6,000 transaction. STDDEV captures variability so the z-score formula can normalise the amount relative to *that user's own range*, not a global threshold.

**Design note:** The baseline window (`txn_ts < CURRENT_DATE()`) is deliberately exclusive of today. This prevents today's potentially fraudulent transactions from polluting the reference distribution used to score them.

```sql
-- Safe pattern: historical only
WHERE t.txn_ts < CURRENT_DATE()

-- Avoid: mixing today's events into the baseline
-- WHERE t.txn_ts >= DATEADD('day', -30, CURRENT_TIMESTAMP())  -- includes today
```

---

### 2. Combining Multiple Weak Signals into a Triage Cut

No single signal reliably separates fraud from legitimate activity. A large transaction amount could be a legitimate purchase. A foreign country flag could be a traveller. Each signal alone has high false-positive rates. The solution is to **combine weak signals into a composite score** and apply thresholds to create a triage cut.

This query uses a **weighted additive model**:

```
fraud_score =
    amount_anomaly_score   (0–40)   ← statistical signal
  + user_risk_score        (0–30)   ← profile-level prior
  + foreign_country_flag   (0–15)   ← geo signal
  + exceeds_hist_max       (0–15)   ← absolute ceiling signal
```

**Why this works:**
- A user with a low risk score transacting abroad for an unusual amount scores across multiple dimensions simultaneously, compounding the signal.
- A high-risk user (`risk_score = 80`) making a normal domestic transaction scores only `0.8 × 30 = 24` — below both thresholds.
- A low-risk user (`risk_score = 10`) making a 5-sigma foreign transaction that exceeds their historical max scores `40 + 3 + 15 + 15 = 73` — triggering BLOCK.

**Triage cut thresholds:**

| Score | Action | Rationale |
|---|---|---|
| ≥ 70 | **BLOCK** | Multiple strong signals align — high confidence fraud |
| 45–69 | **REVIEW** | Ambiguous — route to a human analyst |
| < 45 | **PASS** | Low risk — approve automatically |

The thresholds are tunable. Lowering the REVIEW threshold increases catch rate but increases analyst workload. This is the core precision/recall trade-off in fraud triage.

---

### 3. QUALIFY for Post-Window Filtering

`QUALIFY` is a Snowflake clause that filters rows **after** a window function is evaluated — analogous to how `HAVING` filters after `GROUP BY`. Without it, you need a subquery or CTE to filter on a window result.

**Without QUALIFY (verbose):**
```sql
SELECT * FROM (
    SELECT
        txn_id,
        user_id,
        amount,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY txn_ts DESC) AS rn
    FROM TRANSACTIONS
)
WHERE rn = 1;
```

**With QUALIFY (clean):**
```sql
SELECT txn_id, user_id, amount
FROM TRANSACTIONS
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY txn_ts DESC) = 1;
```

**Where it applies to this project:** If you extend the scoring query to look at the user's *most recent* prior transaction, or flag users whose last N transactions were all flagged, `QUALIFY` lets you filter on those window results inline without wrapping the scored CTE in another subquery.

**Common patterns:**
```sql
-- Latest transaction per user
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY txn_ts DESC) = 1

-- Only users whose current transaction exceeds their rolling 7-day max
QUALIFY amount > MAX(amount) OVER (
    PARTITION BY user_id
    ORDER BY txn_ts
    ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
)

-- Top 3 highest-value transactions per user
QUALIFY RANK() OVER (PARTITION BY user_id ORDER BY amount DESC) <= 3
```

> `QUALIFY` is evaluated after `WHERE`, `GROUP BY`, and `HAVING` but before `ORDER BY` and `LIMIT` — it sits at the very end of the logical query processing order.

---

### 4. Where to Compute Features: CTEs vs Views vs Materialized Views

Feature computation is the costliest part of a scoring pipeline. Where you place the logic determines freshness, performance, and maintainability.

| | CTE | View | Materialized View |
|---|---|---|---|
| **Storage** | None (inline) | None (stored query) | Yes (stored result) |
| **Freshness** | Always current | Always current | Lags until refresh |
| **Reuse** | This query only | Any query | Any query |
| **Compute cost** | Every execution | Every execution | Paid at refresh time |
| **Best for** | One-off / dev / ad hoc | Shared logic, always-fresh | High-frequency reads on slow-changing data |

#### CTEs — used in this file
```sql
WITH baseline AS (...),
     today_txns AS (...),
     scored AS (...)
SELECT * FROM scored;
```
Best for exploratory work and keeping a multi-step pipeline readable in a single script. The `baseline` and `scored` logic runs fresh every time the query executes. No persistence.

#### Views — next step for shared use
```sql
CREATE OR REPLACE VIEW SUPPORT.USER_BASELINE AS
SELECT user_id, AVG(amount) AS avg_amount, STDDEV(amount) AS stddev_amount, ...
FROM TRANSACTIONS
WHERE txn_ts < CURRENT_DATE()
GROUP BY user_id;
```
Any downstream query can join against `USER_BASELINE` without duplicating the aggregation logic. Always reflects the latest data. The trade-off: every consumer re-executes the aggregation from scratch.

#### Materialized Views — for production scoring
```sql
CREATE OR REPLACE MATERIALIZED VIEW SUPPORT.USER_BASELINE_MV AS
SELECT user_id, AVG(amount) AS avg_amount, STDDEV(amount) AS stddev_amount, ...
FROM TRANSACTIONS
WHERE txn_ts < CURRENT_DATE()
GROUP BY user_id;
```
Snowflake pre-computes and stores the result. Reads are instant — the real-time scoring join against the baseline becomes a fast key lookup rather than a full aggregation. Snowflake automatically refreshes the MV when the underlying `TRANSACTIONS` table changes (within the constraints of the MV definition).

**Recommended progression for this project:**

```
Development  →  CTEs (this file)
Shared logic →  View (USER_BASELINE)
Production   →  Materialized View (USER_BASELINE_MV)
Real-time    →  Dynamic Tables (Snowflake-native streaming alternative to MVs)
```

> **Dynamic Tables** are Snowflake's modern replacement for complex MV pipelines. They let you define a target lag (e.g., `TARGET_LAG = '1 minute'`) and Snowflake incrementally refreshes the result — ideal for a near-real-time fraud baseline that needs to reflect transactions from the last hour.
