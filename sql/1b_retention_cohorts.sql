-- Part 1(b): Retention cohort table
--
-- Cohorts = 7-day install buckets starting 2026-01-01.
-- Retention = activity exactly on D1, D7, D14, and D30.
--
-- Activity evidence comes from either player_day or purchase because
-- some purchase-days do not have a matching player_day record.
--
-- Recent cohorts that have not been fully observed by 2026-04-30
-- are reported as NULL rather than 0.


WITH base AS (

    SELECT
        device_id,
        install_date,

        date(
            '2026-01-01',
            '+' ||
            (
                CAST(
                    (julianday(install_date) - julianday('2026-01-01')) / 7
                    AS INTEGER
                ) * 7
            ) ||
            ' days'
        ) AS cohort_week,

        date(install_date, '+1 day')  AS day1_date,
        date(install_date, '+7 day')  AS day7_date,
        date(install_date, '+14 day') AS day14_date,
        date(install_date, '+30 day') AS day30_date

    FROM player_profile

    WHERE install_date BETWEEN '2026-01-01' AND '2026-04-30'
),


activity AS (

    SELECT
        device_id,
        activity_date
    FROM player_day

    UNION

    SELECT
        device_id,
        CAST(strftime('%Y%m%d', event_ts) AS INTEGER) AS activity_date
    FROM purchase
),


flags AS (

    SELECT
        b.device_id,
        b.cohort_week,

        b.day1_date,
        b.day7_date,
        b.day14_date,
        b.day30_date,

        MAX(
            CASE
                WHEN a.activity_date =
                     CAST(strftime('%Y%m%d', b.day1_date) AS INTEGER)
                THEN 1 ELSE 0
            END
        ) AS active_d1,

        MAX(
            CASE
                WHEN a.activity_date =
                     CAST(strftime('%Y%m%d', b.day7_date) AS INTEGER)
                THEN 1 ELSE 0
            END
        ) AS active_d7,

        MAX(
            CASE
                WHEN a.activity_date =
                     CAST(strftime('%Y%m%d', b.day14_date) AS INTEGER)
                THEN 1 ELSE 0
            END
        ) AS active_d14,

        MAX(
            CASE
                WHEN a.activity_date =
                     CAST(strftime('%Y%m%d', b.day30_date) AS INTEGER)
                THEN 1 ELSE 0
            END
        ) AS active_d30

    FROM base b

    LEFT JOIN activity a
        ON a.device_id = b.device_id
       AND a.activity_date IN (
            CAST(strftime('%Y%m%d', b.day1_date) AS INTEGER),
            CAST(strftime('%Y%m%d', b.day7_date) AS INTEGER),
            CAST(strftime('%Y%m%d', b.day14_date) AS INTEGER),
            CAST(strftime('%Y%m%d', b.day30_date) AS INTEGER)
       )

    GROUP BY
        b.device_id,
        b.cohort_week,
        b.day1_date,
        b.day7_date,
        b.day14_date,
        b.day30_date
),


cohort_agg AS (

    SELECT
        cohort_week,
        COUNT(*) AS cohort_size,

        MAX(day1_date)  AS max_day1_date,
        MAX(day7_date)  AS max_day7_date,
        MAX(day14_date) AS max_day14_date,
        MAX(day30_date) AS max_day30_date,

        SUM(active_d1)  AS n_active_d1,
        SUM(active_d7)  AS n_active_d7,
        SUM(active_d14) AS n_active_d14,
        SUM(active_d30) AS n_active_d30

    FROM flags

    GROUP BY cohort_week
)


SELECT
    cohort_week,
    cohort_size,

    CASE
        WHEN max_day1_date <= '2026-04-30'
        THEN ROUND(n_active_d1 * 1.0 / cohort_size, 4)
    END AS retention_d1,

    CASE
        WHEN max_day7_date <= '2026-04-30'
        THEN ROUND(n_active_d7 * 1.0 / cohort_size, 4)
    END AS retention_d7,

    CASE
        WHEN max_day14_date <= '2026-04-30'
        THEN ROUND(n_active_d14 * 1.0 / cohort_size, 4)
    END AS retention_d14,

    CASE
        WHEN max_day30_date <= '2026-04-30'
        THEN ROUND(n_active_d30 * 1.0 / cohort_size, 4)
    END AS retention_d30

FROM cohort_agg

ORDER BY cohort_week;