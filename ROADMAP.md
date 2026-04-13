# Roadmap

Planned improvements and open questions for future iterations.

---

## Classifier Improvements

**Replace keyword matching with a trained text classifier**  
The current rule-based approach produces high `category_count` values (median 5–6/9) due to keyword overlap. A logistic regression or lightweight transformer model trained on a labeled subset would produce more reliable multi-label outputs and a cleaner primary category split. Even 200–300 hand-labeled examples would materially improve precision.

**Strip FCC boilerplate from complaint text**  
The FCC appends a standard case notice to every complaint description (beginning "this constitutes a notice of informal complaint filed with the fcc…"). This boilerplate contains terms like "contact", "disconnect", and "carrier" that may trigger false positives in the keyword classifier. Removing it before classification is a quick win.

**Normalize `state` field upstream**  
Two variants of "District of Columbia" appear in the data (`District Of Columbia` vs `District of Columbia`). This is handled in cleaning, but worth fixing at the source if raw data is ever refreshed.

---

## Analysis Extensions

**Normalize complaint volume by subscriber base**  
Raw state-level complaint counts correlate with subscriber density, not complaint propensity. Dividing by estimated subscriber counts per state (available from FCC Form 477 data) would enable a fairer geographic comparison.

**Resolution time analysis**  
If a "resolved date" field becomes available, time-to-resolution by category and state would be a high-value addition. Currently only status (open/closed/solved/pending) is available.

**Keyword co-occurrence network**  
A graph of which complaint keywords tend to appear together could surface compound issue patterns (e.g., billing disputes that co-occur with service cancellation) that the flat category taxonomy misses.

---

## Infrastructure

**Add a data sample for reproducibility**  
Include a 200-row anonymized sample in `data/raw/` so reviewers can run the full pipeline without sourcing the original FCC file.

**Add `__init__.py` and package structure to `src/`**  
Low lift; makes `from src.classify import ...` work cleanly across environments without `sys.path` manipulation in notebooks.
