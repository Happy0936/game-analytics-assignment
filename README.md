# Analyst Intern Take-Home — Game Analytics

## Overview

This project analyzes player behaviour, monetization, retention, acquisition channels, rewarded-ad engagement, churn risk, and long-term player value for a mobile game.

The analysis combines SQL-based product metrics with Python-based statistical analysis and predictive modelling. The overall business objective is to identify opportunities to grow revenue without increasing marketing spend.

---

## Setup

```bash
python -m venv venv

# Activate environment
# Windows:
venv\Scripts\activate

# macOS / Linux:
source venv/bin/activate

pip install -r requirements.txt

# Build SQLite database from the raw CSV files
python db/build_db.py
```

Then open `notebooks/` in VS Code with the Jupyter extension and run the notebooks in order.

---

## Project Structure

```text
data/raw/          Original 5 CSV files, kept unchanged
db/                SQLite database and database build script
sql/               Part 1 SQL queries (1a–1d)
notebooks/         Data quality checks, analysis, modelling, and visualizations
src/               Shared database/helper code used by notebooks
outputs/tables/    Analysis outputs and model results exported as CSV
outputs/figures/   Figures generated for analysis and final presentation
notes/             Data quality findings and analysis summary
deck/              Final presentation / readout deck
README.md          Project setup, structure, and analysis summary
```

---

## Analysis Workflow

The project is organized into the following analytical components:

### Part 1 — Core Product Metrics

- **1(a) Daily Health:** DAU, gross IAP revenue, ARPDAU, and daily payer share by platform.
- **1(b) Retention Cohorts:** D1, D7, D14, and D30 retention by install-week cohort.
- **1(c) Spender Behaviour:** Revenue concentration, time to first purchase, never-pay share, and repeat-purchase behaviour.
- **1(d) Rewarded Ads:** Ad-cap engagement, daily ad views, and tracking anomalies.

### Part 2 — ARPDAU Deep-Dive

Investigates the decline in blended ARPDAU and separates within-segment performance from changes in player composition.

### Part 3 — Acquisition Channel Comparison

Compares Organic, Paid Social, and Paid Video using retention and revenue metrics, confidence intervals, statistical testing, and country-tier composition.

### Part 4 — Churn Prediction

Builds a time-based churn prediction model using recent player engagement behaviour and evaluates targeting trade-offs using ROC-AUC, PR-AUC, precision, recall, F1, and retention-offer waste.

### Part 4b — 90-Day Player Value

Predicts 90-day IAP value using early player behaviour while explicitly handling incomplete 90-day observation windows. The model is evaluated both on prediction error and its ability to rank high-value players.

---

## Status

- [x] Project scaffolded, data loaded, and database verified
- [x] Data quality analysis
- [x] Part 1(a) Daily health
- [x] Part 1(b) Retention cohorts
- [x] Part 1(c) Spender behaviour
- [x] Part 1(d) Rewarded-ad engagement
- [x] Part 2 ARPDAU deep-dive
- [x] Part 3 Acquisition channel comparison
- [x] Part 4 Churn prediction
- [x] Part 4b 90-day player value model
- [x] Analysis summary and data-quality notes
- [x] Part 5 Final readout deck

---

## Key Findings

### Data Quality

Several data-quality and interpretation issues were identified before analysis:

- `purchase_id` is not fully unique, so transaction analysis avoids relying on it as a unique event identifier.
- Some purchase-days do not have matching `player_day` activity records.
- Install volume increases substantially during the observation period rather than remaining constant.
- A meaningful share of players installed before the analysis window, limiting retention observability for those players.
- A small number of purchases occur before the recorded install date.
- Rewarded-ad data contains recurring hourly gaps and a full-day tracking gap.

See `notes/data_quality_log.md` for the complete investigation and handling decisions.

### Product and Revenue

Install volume increased substantially over the 120-day observation window, while DAU grew approximately **6x**. Therefore, blended metrics must be interpreted carefully because the underlying player population changed substantially over time.

Overall ARPDAU declines by approximately **16%** between the first and last 30-day periods, even though ARPDAU within individual country tiers is generally stable or improving.

The analysis indicates that the decline is primarily associated with a **player-mix shift toward lower-monetizing country tiers**, rather than a broad deterioration in monetization within tiers.

Paid Video grows substantially as a share of new installs and contains a much larger Tier-4 player mix than Organic or Paid Social. Because marketing cost/CPI data is unavailable, channel profitability or ROAS cannot be determined directly.

### Churn

The churn model uses a time-based holdout and only information available at the prediction date to avoid future-data leakage.

The model provides useful ranking power for identifying players at elevated churn risk. The final production targeting threshold should depend on retention-offer cost, intervention uplift, and retained-player value rather than classification performance alone.

### 90-Day Player Value

Only players with fully observable early features and 90-day revenue outcomes are used for model training and evaluation to avoid right-censoring.

A two-stage approach estimates:

1. Probability that a player becomes a payer.
2. Expected revenue conditional on becoming a payer.

The resulting expected-value score is primarily intended to **rank players by future value**, supporting prioritization of high-value users rather than relying only on average revenue prediction accuracy.

---

## Important Limitations

- Marketing spend and CPI are unavailable, so channel profitability and ROAS cannot be calculated.
- Rewarded-ad revenue is unavailable; rewarded-ad rewards are not treated as revenue.
- Retention-intervention cost and uplift are unavailable, so an economically optimal churn-targeting threshold cannot be calculated directly.
- Only sufficiently early installs have complete 90-day revenue labels for the long-term value model.
- Several telemetry and attribution anomalies identified during data-quality analysis should be considered when interpreting results.

---

## Reproducibility

All major analysis outputs are saved under:

```text
outputs/tables/
outputs/figures/
```

Part 1 SQL is available separately under:

```text
sql/
```

The notebooks contain the analysis, validation checks, modelling steps, and figures used to support the final business recommendations.

For a concise summary of the main analytical findings, business implications, and recommendations, see `notes/analysis_summary.md`.