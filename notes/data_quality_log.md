# Data Quality Log

Running list of material data-quality issues identified during the analysis
and how each was handled.

This supports the Part 1 data-quality notes and the final deck appendix.

## 1. `purchase_id` is not a unique key

- 122 `purchase_id` values appear on 2 rows each.
- These are not exact duplicate rows; `event_ts` and sometimes other fields differ.
- They appear to be separate transactions assigned the same ID rather than
  duplicate event delivery.
- **Handling:** Do not use `COUNT(DISTINCT purchase_id)` as transaction count.
  Revenue and transaction summaries use raw rows with `SUM(usd_amount)` or
  `COUNT(*)`.

## 2. `player_day` has a session-logging gap on purchase days

- ~17% of `(device_id, date)` purchase-days have no matching `player_day` row.
- Since a purchase implies activity, these cases are treated as missing
  activity/session telemetry rather than genuine inactivity.
- **Handling:** Activity-based metrics use the union of `player_day` and
  `purchase` activity where appropriate.
- This definition is used for DAU, retention activity, and churn labels.
- Session, playtime, and level features still use `player_day`.

## 3. Install volume is not flat across the window

- Daily installs increase from ~275/day near Jan 1 to ~950/day near Apr 30,
  roughly a 3.5x increase.
- Total DAU grows ~6x over the same period.
- **Implication:** Changing cohort sizes and player composition can distort
  pooled retention and blended monetization metrics.
- **Handling:** Retention is reported by install-week cohort with explicit
  observation eligibility.
- ARPDAU is separately analyzed by country tier and player-mix effects.

## 4. Some players installed before the activity window

- `install_date` begins in 2025, while available activity starts on
  2026-01-01.
- ~16,000 of 80,295 players (~20%) installed before the activity window.
- Their early-life D1/D7/D14/D30 retention cannot be reconstructed from the
  available data.
- **Handling:** These players are excluded from install-week retention rather
  than being assigned zero retention.

## 5. Retention is broadly stable across cohorts

*Context finding, not a data-quality issue.*

- Cohort size grows substantially across the analysis window.
- Eligible cohorts nevertheless show broadly stable retention:
  ~48% D1, ~25% D7, ~20% D14, and ~13% D30.
- Recent cohorts without enough observation time have later retention
  milestones reported as NULL rather than zero.
- **Implication for Part 2:** The blended ARPDAU decline is not explained by
  a broad deterioration in retention.
- The ARPDAU deep-dive instead shows a shift in active-player composition
  toward lower-monetizing country tiers, especially Tier 4.

## 6. Some purchases occur before recorded `install_date`

- 110 players (~1% of payers) have a first purchase 1–4 days before their
  recorded `install_date`.
- `original_device_id` is NULL for all 110 cases, so the available data does
  not support a reinstall/device-linking explanation.
- The pattern may reflect install-date or attribution lag, but the exact
  cause cannot be established from the available data.
- **Handling:** These observations are excluded from the time-to-first-
  purchase distribution rather than clipped to zero.
- The valid timing distribution uses 10,944 payers, while the overall payer
  calculation retains all 11,054 observed payers.

## 7. `ad_view` has recurring logging gaps

- Every day has no recorded `ad_view` events between approximately
  08:00 and 13:59, while other event tables remain active.
- 2026-03-06 has zero `ad_view` rows for the entire day, while `player_day`,
  `purchase`, and `currency_spend` still contain activity.
- Adjacent days also have lower ad-view activity than surrounding days.
- **Implication:** These patterns are more consistent with an ad-specific
  telemetry/export or availability issue than a genuine engagement decline,
  although the exact cause cannot be determined.
- **Handling:** Missing ad activity is not interpolated.
- A generated calendar with `LEFT JOIN` keeps 2026-03-06 as an explicit zero
  in the daily series.
- `reward_amount` is treated as an in-game reward, not advertising revenue.

## Payer Rate

*Context finding, not a data-quality issue.*

- 11,054 of 80,295 players (13.8%) made at least one observed purchase.
- This is higher than the "a few percent" framing in the assignment brief.
- The analysis reports the observed payer rate directly rather than adjusting
  it to match the brief's illustrative wording.