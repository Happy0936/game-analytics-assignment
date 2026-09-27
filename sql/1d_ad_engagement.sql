-- Part 1(d): Rewarded ad engagement
--
-- Data quality findings:
--   1. ad_view has a systematic ~6-hour gap every single day (08:00-13:59,
--      confirmed across multiple days checked across the whole window, with
--      zero exceptions) while other event tables (currency_spend, purchase)
--      have activity across all hours. Too precise and consistent to be
--      organic behavior -- looks like a mechanical gap (batch export
--      schedule, ETL job window, or ad-network SDK downtime). The last
--      day's cycle also spills ~8 hours into 2026-05-01 (hours 00-07),
--      consistent with the same daily on/off pattern continuing past
--      midnight.
--   2. 2026-03-06 has ZERO ad_view rows for the entire day, while
--      player_day, purchase, and currency_spend all show normal activity
--      that day -- this is an ad_view-specific outage, not a real-game
--      event. 2026-03-05 and 2026-03-07 are also lower than the days
--      around them, suggesting a gradual drop-off/recovery around a
--      ~1-day outage rather than an instant on/off.
--
-- Handling: rows past the stated window (2026-05-01) are excluded from the
-- daily totals below. Every calendar day is shown explicitly, including
-- 2026-03-06 as a true 0, via a generated calendar joined against ad_view --
-- a naive GROUP BY would silently drop that day instead of showing the
-- outage. Neither gap is patched or interpolated -- both are flagged here
-- and in the write-up as questions for the team, since telemetry alone
-- can't distinguish a logging outage from ads genuinely being unavailable.

-- ============================================================
-- Query 1: Share of ad-watching player-days that hit the cap,
-- broken out by cap value.
-- "Hit the cap" = that player-day's max ad_daily_count == their ad_daily_cap
-- (ad_daily_count is a running counter within the day, so its daily max is
-- the count actually reached).
-- ============================================================
WITH player_day_caps AS (
    SELECT
        device_id,
        substr(event_ts,1,10) AS ad_date,
        ad_daily_cap,
        MAX(ad_daily_count) AS max_count_that_day
    FROM ad_view
    WHERE substr(event_ts,1,10) <= '2026-04-30'
    GROUP BY device_id, ad_date, ad_daily_cap
)
SELECT
    ad_daily_cap,
    COUNT(*) AS ad_watching_player_days,
    SUM(CASE WHEN max_count_that_day >= ad_daily_cap THEN 1 ELSE 0 END) AS days_hit_cap,
    ROUND(SUM(CASE WHEN max_count_that_day >= ad_daily_cap THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4) AS pct_hit_cap
FROM player_day_caps
GROUP BY ad_daily_cap
ORDER BY ad_daily_cap;


-- ============================================================
-- Query 2: Total daily ad views across the window.
-- Excludes the 2026-05-01 spillover (outside the stated 120-day window).
-- Uses a generated calendar + LEFT JOIN so a day with zero ad_view rows
-- (2026-03-06) shows as an explicit 0 instead of silently disappearing
-- from a plain GROUP BY.
-- ============================================================
WITH RECURSIVE calendar(date) AS (
    SELECT '2026-01-01'
    UNION ALL
    SELECT date(date, '+1 day') FROM calendar WHERE date < '2026-04-30'
),
daily AS (
    SELECT substr(event_ts,1,10) AS date,
           COUNT(*) AS total_ad_views,
           COUNT(DISTINCT device_id) AS distinct_viewers
    FROM ad_view
    WHERE substr(event_ts,1,10) BETWEEN '2026-01-01' AND '2026-04-30'
    GROUP BY date
)
SELECT
    c.date,
    COALESCE(d.total_ad_views, 0) AS total_ad_views,
    COALESCE(d.distinct_viewers, 0) AS distinct_viewers
FROM calendar c
LEFT JOIN daily d ON c.date = d.date
ORDER BY c.date;