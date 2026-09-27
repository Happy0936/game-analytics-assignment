-- Part 1(c): Spender behaviour
--
-- Judgment calls:
--   1. Revenue concentration is reported BOTH ways -- ranked among payers
--      only, and ranked among all players -- because they answer different
--      business questions.
--
--   2. Exact population cutoffs are implemented using ROW_NUMBER() and
--      COUNT(). This prevents revenue ties from expanding the intended
--      top 1%, 10%, or 50% population.
--
--   3. 110 players (~1% of payers) show a first-purchase date 1-4 days
--      BEFORE their recorded install_date. These cases are excluded from
--      the time-to-first-purchase distribution and documented as a
--      data-quality issue.


-- ============================================================
-- Query 1: Revenue concentration
-- Reported among:
--   A) payers only
--   B) all players
-- ============================================================

WITH payer_revenue AS (
    SELECT
        device_id,
        SUM(usd_amount) AS total_revenue
    FROM purchase
    GROUP BY device_id
),

payers_ranked AS (
    SELECT
        device_id,
        total_revenue,
        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC, device_id
        ) AS rn,
        COUNT(*) OVER () AS n_players
    FROM payer_revenue
),

payers_result AS (
    SELECT
        'payers_only' AS population,

        ROUND(
            SUM(
                CASE
                    WHEN rn <= ((n_players + 99) / 100)
                    THEN total_revenue
                    ELSE 0
                END
            ) * 1.0 / SUM(total_revenue),
            4
        ) AS share_top_1pct,

        ROUND(
            SUM(
                CASE
                    WHEN rn <= ((n_players + 9) / 10)
                    THEN total_revenue
                    ELSE 0
                END
            ) * 1.0 / SUM(total_revenue),
            4
        ) AS share_top_10pct,

        ROUND(
            SUM(
                CASE
                    WHEN rn <= ((n_players + 1) / 2)
                    THEN total_revenue
                    ELSE 0
                END
            ) * 1.0 / SUM(total_revenue),
            4
        ) AS share_top_50pct

    FROM payers_ranked
),

all_player_revenue AS (
    SELECT
        pp.device_id,
        COALESCE(SUM(pu.usd_amount), 0) AS total_revenue
    FROM player_profile pp
    LEFT JOIN purchase pu
        ON pp.device_id = pu.device_id
    GROUP BY pp.device_id
),

all_players_ranked AS (
    SELECT
        device_id,
        total_revenue,
        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC, device_id
        ) AS rn,
        COUNT(*) OVER () AS n_players
    FROM all_player_revenue
),

all_players_result AS (
    SELECT
        'all_players' AS population,

        ROUND(
            SUM(
                CASE
                    WHEN rn <= ((n_players + 99) / 100)
                    THEN total_revenue
                    ELSE 0
                END
            ) * 1.0 / SUM(total_revenue),
            4
        ) AS share_top_1pct,

        ROUND(
            SUM(
                CASE
                    WHEN rn <= ((n_players + 9) / 10)
                    THEN total_revenue
                    ELSE 0
                END
            ) * 1.0 / SUM(total_revenue),
            4
        ) AS share_top_10pct,

        ROUND(
            SUM(
                CASE
                    WHEN rn <= ((n_players + 1) / 2)
                    THEN total_revenue
                    ELSE 0
                END
            ) * 1.0 / SUM(total_revenue),
            4
        ) AS share_top_50pct

    FROM all_players_ranked
)

SELECT * FROM payers_result

UNION ALL

SELECT * FROM all_players_result;


-- ============================================================
-- Query 2: Time to first purchase
-- Distribution among players who ever pay.
-- Negative install-to-purchase gaps are excluded.
-- ============================================================

WITH first_purchase AS (
    SELECT
        device_id,
        MIN(event_ts) AS first_purchase_ts
    FROM purchase
    GROUP BY device_id
),

days_to_first AS (
    SELECT
        pp.device_id,

        CAST(
            julianday(substr(fp.first_purchase_ts, 1, 10))
            - julianday(pp.install_date)
            AS INTEGER
        ) AS days_to_purchase

    FROM player_profile pp

    JOIN first_purchase fp
        ON pp.device_id = fp.device_id

    WHERE
        julianday(substr(fp.first_purchase_ts, 1, 10))
        - julianday(pp.install_date) >= 0
)

SELECT
    CASE
        WHEN days_to_purchase = 0
            THEN '0 (day of install)'

        WHEN days_to_purchase = 1
            THEN '1 day'

        WHEN days_to_purchase BETWEEN 2 AND 3
            THEN '2-3 days'

        WHEN days_to_purchase BETWEEN 4 AND 7
            THEN '4-7 days'

        WHEN days_to_purchase BETWEEN 8 AND 14
            THEN '8-14 days'

        WHEN days_to_purchase BETWEEN 15 AND 30
            THEN '15-30 days'

        WHEN days_to_purchase BETWEEN 31 AND 60
            THEN '31-60 days'

        ELSE '60+ days'

    END AS bucket,

    COUNT(*) AS n_players,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM days_to_first),
        1
    ) AS pct_of_payers

FROM days_to_first

GROUP BY bucket

ORDER BY MIN(days_to_purchase);


-- ============================================================
-- Query 2b: Never-pay share
-- Denominator = ALL players
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM player_profile) AS total_players,

    (SELECT COUNT(DISTINCT device_id)
     FROM purchase) AS ever_paid,

    ROUND(
        1.0 -
        (
            (SELECT COUNT(DISTINCT device_id)
             FROM purchase) * 1.0
            /
            (SELECT COUNT(*)
             FROM player_profile)
        ),
        4
    ) AS pct_never_pay;


-- ============================================================
-- Query 3: Repeat purchase gap
-- Among repeat purchasers, calculate time between consecutive
-- purchase events using LAG().
-- ============================================================

WITH ordered AS (
    SELECT
        device_id,
        event_ts,

        LAG(event_ts) OVER (
            PARTITION BY device_id
            ORDER BY event_ts
        ) AS prev_ts

    FROM purchase
),

gaps AS (
    SELECT
        device_id,

        julianday(event_ts)
        - julianday(prev_ts) AS gap_days

    FROM ordered

    WHERE prev_ts IS NOT NULL
)

SELECT
    CASE
        WHEN gap_days < 1
            THEN 'same day'

        WHEN gap_days BETWEEN 1 AND 3
            THEN '1-3 days'

        WHEN gap_days BETWEEN 4 AND 7
            THEN '4-7 days'

        WHEN gap_days BETWEEN 8 AND 14
            THEN '8-14 days'

        WHEN gap_days BETWEEN 15 AND 30
            THEN '15-30 days'

        ELSE '30+ days'

    END AS gap_bucket,

    COUNT(*) AS n_gaps,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM gaps),
        1
    ) AS pct_of_gaps,

    ROUND(
        AVG(gap_days),
        1
    ) AS avg_days_in_bucket

FROM gaps

GROUP BY gap_bucket

ORDER BY MIN(gap_days);