# Analysis Summary

This document summarizes the main findings from the game analytics analysis.

## 1. Daily Health and Retention

- Player activity and install volume increased substantially across the
  analysis window.
- DAU uses the union of `player_day` and purchase activity because some
  purchase-days are missing from `player_day`.
- Install-week retention is broadly stable across eligible cohorts:
  ~48% D1, ~25% D7, ~20% D14, and ~13% D30.
- Recent cohorts without sufficient observation time are reported as NULL
  rather than zero.

## 2. Spender Behaviour

- 11,054 of 80,295 players made at least one purchase, giving an observed
  payer rate of approximately 13.8%.
- Revenue is concentrated among payers:
  - Top 1%: 9.44% of payer revenue
  - Top 10%: 48.08%
  - Top 50%: 90.23%
- 110 invalid negative time-to-first-purchase observations are excluded from
  the timing distribution.
- Among valid payers, 27.9% make their first purchase more than 60 days after
  install.
- The 30+ day bucket is the largest repeat-purchase-gap group at 36.3%.

## 3. Rewarded Ads

- Only 1.06% of ad-watching player-days with cap 5 and 0.02% with cap 8
  reach the configured daily cap.
- TObserved cap-hit rates are very low, although telemetry gaps limit strong conclusions about whether the current caps constrain rewarded-ad engagement.
- `ad_view` contains a recurring 08:00–13:59 gap and a full-day gap on
  2026-03-06.
- These gaps are treated as telemetry/availability issues rather than genuine
  engagement declines.
- `reward_amount` is not treated as advertising revenue.

## 4. ARPDAU Deep-Dive

- Overall ARPDAU falls from $0.3497 in the first 30 days to $0.2922 in the
  last 30 days, a decline of approximately 16.4%.
- ARPDAU within all four country tiers is stable or improving.
- Tier 4 grows from 17.62% to 45.90% of the active-player mix.
- Decomposition gives:
  - Within-tier effect: +0.0263
  - Mix effect: -0.0838
  - Net change: -0.0575
- The decline in blended ARPDAU is therefore primarily associated with a
  shift toward lower-monetizing country tiers, especially Tier 4.

## 5. Acquisition Channels

- D7 retention is 26.41% for Organic, 25.52% for Paid Social, and 24.89%
  for Paid Video.
- The channel differences are statistically significant, but their absolute
  magnitude is small.
- Raw D30 revenue/install is $2.4449 Organic, $2.2159 Paid Social, and
  $1.5324 Paid Video.
- After adjusting Paid Video and Paid Social to the same country-tier mix,
  their D30 revenue difference is only +$0.0632 per install.
- The adjusted 95% CI is -$0.2243 to $0.3582 and includes zero.
- Without marketing spend/CPI, the data does not support a budget-allocation
  decision between the two paid channels.

## 6. Churn Model

- The final test set contains 9,617 active players with a 13.90% churn rate.
- Model ROC-AUC is 0.7334 and PR-AUC is 0.2811.
- At the reference 0.50 threshold, precision is 27.57% and recall is 61.48%.
- The threshold should not be treated as economically optimal because
  intervention cost, treatment uplift, and retained-player value are
  unavailable.

## 7. 90-Day Player Value

- 9,809 players have complete 90-day outcomes and first-7-day features.
- The Stage-1 payer model achieves ROC-AUC 0.7273 and PR-AUC 0.5471.
- The two-stage value model achieves MAE 4.9583 and RMSE 15.4469.
- The top predicted 10% of players capture 42.18% of actual test revenue.
- Mean predicted revenue is $2.84 versus $4.51 actual, so the model is useful
  for ranking but is not yet a fully calibrated revenue forecast.

## 8. Recommendations and Limitations

- Monitor and investigate the growing Tier 4 acquisition mix associated with the blended ARPDAU decline
- Combine CPI/marketing spend with retention and D30 revenue before changing
  paid-channel budgets.
- Investigate the `ad_view` telemetry gaps before making ad-engagement
  decisions.
- Use churn and player-value scores for prioritization/testing rather than
  direct production decisions without economic validation.
- Key limitations are missing CPI/marketing spend, missing ad revenue,
  unavailable churn-intervention economics, and incomplete 90-day outcomes
  for later installs.