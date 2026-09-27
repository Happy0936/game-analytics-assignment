-- Part 1(a): Daily health, split by platform
-- Metrics: DAU, gross revenue, ARPDAU, share of active players who purchased
--
-- Judgment calls:
--   1. purchase_id is NOT a reliable unique key (122 IDs repeat with different
--      event_ts -> genuine separate transactions, not duplicate rows). We sum
--      usd_amount over all rows rather than grouping by distinct purchase_id.
--   2. ~17% of purchase-(device,day) pairs have no matching player_day row
--      (a session-logging gap -- a purchase itself proves the player was
--      active). DAU is therefore defined as the union of player_day activity
--      and purchase activity for that day, not player_day alone.

WITH active AS (
    -- activity from player_day
    SELECT pd.device_id, pd.activity_date AS act_date, pp.platform
    FROM player_day pd
    JOIN player_profile pp ON pd.device_id = pp.device_id

    UNION

    -- activity implied by a purchase (covers the logging gap above)
    SELECT pu.device_id,
           CAST(strftime('%Y%m%d', pu.event_ts) AS INTEGER) AS act_date,
           pp.platform
    FROM purchase pu
    JOIN player_profile pp ON pu.device_id = pp.device_id
),
daily_revenue AS (
    SELECT pu.device_id,
           CAST(strftime('%Y%m%d', pu.event_ts) AS INTEGER) AS pay_date,
           pp.platform,
           pu.usd_amount
    FROM purchase pu
    JOIN player_profile pp ON pu.device_id = pp.device_id
),
dau AS (
    SELECT act_date, platform, COUNT(DISTINCT device_id) AS dau
    FROM active
    GROUP BY act_date, platform
),
rev AS (
    SELECT pay_date, platform,
           SUM(usd_amount) AS gross_revenue,
           COUNT(DISTINCT device_id) AS paying_players
    FROM daily_revenue
    GROUP BY pay_date, platform
)
SELECT
    d.act_date AS date,
    d.platform,
    d.dau,
    COALESCE(r.gross_revenue, 0) AS gross_revenue,
    ROUND(COALESCE(r.gross_revenue, 0) * 1.0 / d.dau, 4) AS arpdau,
    ROUND(COALESCE(r.paying_players, 0) * 1.0 / d.dau, 4) AS pct_active_who_paid
FROM dau d
LEFT JOIN rev r ON d.act_date = r.pay_date AND d.platform = r.platform
ORDER BY d.platform, d.act_date;
