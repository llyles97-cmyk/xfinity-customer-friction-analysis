# Xfinity Customer Friction Analysis

An end-to-end analysis of 2,225 FCC informal complaints filed against Comcast/Xfinity in 2015. The project spans data cleaning, keyword-based issue classification, geographic and temporal trend analysis, and SQL-based aggregation — structured to mirror how a CX analytics team would approach complaint data in a warehouse environment.

---

## Business Question

What is driving Comcast customers to escalate complaints to the FCC, and where are those complaints concentrated geographically? Can we identify patterns — by issue type, resolution status, and complaint complexity — that a CX or operations team could act on?

---

## Dataset

**Source:** [FCC Informal Complaints — Comcast 2015](https://www.kaggle.com/datasets/extralime/comcast-telecom-complaints-data) (Kaggle mirror of public FCC consumer complaint data)  
**Rows:** 2,225 complaints  
**Period:** April – August 2015  
**Fields:** ticket ID, complaint narrative, date, channel, city, state, zip, resolution status, filing method

Raw data is not committed to this repo. Download the source file and place it at `data/raw/comcast_fcc_complaints_2015.csv` before running the notebooks.

---

## Key Findings

- **Billing issues are the dominant complaint driver**, representing ~72% of primary classifications. This is likely an upper bound due to broad keyword overlap in the rule-based classifier — but billing friction is genuinely the leading complaint category in telecom CX data broadly.
- **Georgia, Florida, and California** lead by raw volume (289, 240, and 220 complaints respectively), consistent with Comcast's largest subscriber markets. Without subscriber-normalized rates, this reflects footprint size as much as service quality.
- **Complaint volume peaks in June–July 2015**, a period that coincides with FCC net neutrality scrutiny and Comcast's active data cap trials in select markets (notably Atlanta).
- **~14% of complaints remain open or pending**, with billing and network issues representing the largest unresolved pools — suggesting these categories are harder to close at first contact.
- **Median `category_count` is 5–6 out of 9** possible labels per complaint. This reflects keyword overlap in the classifier rather than genuinely multi-issue complaints. See `02_classification.ipynb` for full methodology notes.

---

## Repo Structure

```
xfinity-customer-friction-analysis/
├── data/
│   ├── raw/                         ← gitignored; download from source (see above)
│   └── processed/
│       └── cleaned_comcast_complaints.csv
├── notebooks/
│   ├── 01_data_cleaning.ipynb       ← column standardization, text normalization, date parsing
│   ├── 02_classification.ipynb      ← multi-label classification, validation, export
│   └── 03_eda_and_insights.ipynb    ← volume trends, geographic analysis, visualizations
├── sql/
│   ├── volume_trends.sql            ← monthly trends, status breakdown, channel mix
│   ├── category_breakdown.sql       ← category distribution, resolution rates by category
│   ├── state_analysis.sql           ← geographic ranking, dominant issues by state
│   └── complexity_analysis.sql      ← category_count distribution, complexity vs. resolution
├── src/
│   └── classify.py                  ← keyword taxonomy + classification functions
├── visuals/                         ← exported charts (PNG)
├── ROADMAP.md
├── requirements.txt
└── .gitignore
```

---

## How to Run

```bash
# Install dependencies
pip install -r requirements.txt

# Place raw data file at:
# data/raw/comcast_fcc_complaints_2015.csv

# Run notebooks in order:
# 1. notebooks/01_data_cleaning.ipynb
# 2. notebooks/02_classification.ipynb
# 3. notebooks/03_eda_and_insights.ipynb
```

The SQL files in `sql/` are written for standard SQL (tested against SQLite and BigQuery syntax). Load the processed CSV into a table named `comcast_complaints` before running.

---

## Methodology Notes

**Classification approach:** Rule-based keyword matching against lowercased complaint text. Each complaint is tagged with all matching categories (multi-label), and `primary_category` is resolved via a priority ordering weighted toward more specific issue types (billing, contract) over broad ones (customer service).

**Limitations:**
- Keyword overlap is significant. Most complaints contain generic terms (modem, disconnect, service, contact) that trigger multiple categories simultaneously. `category_count` is best used as a relative complexity signal.
- The FCC appends a standard boilerplate notice to every complaint narrative. This text contains terms that may trigger false positives.
- State-level complaint counts reflect subscriber base size, not complaint rate per customer.

---

## Potential Next Steps

See [ROADMAP.md](ROADMAP.md) for a full list. Top priorities: strip FCC boilerplate before classification, normalize state volume by subscriber base, and replace keyword matching with a trained text classifier.
