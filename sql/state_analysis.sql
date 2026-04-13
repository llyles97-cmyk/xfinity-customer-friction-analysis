-- ============================================================
-- state_analysis.sql
-- Geographic distribution of complaints: raw volume rankings,
-- category mix by state, and cross-state issue comparisons.
--
-- Limitation: raw complaint counts correlate with subscriber
-- base size, not complaint propensity. Georgia (#1 by volume)
-- is also one of Comcast's largest markets. For a proper
-- comparison, normalize by estimated subscribers per state.
-- ============================================================


-- Top states by raw complaint volume
SELECT
    state,
    COUNT(*)  AS complaint_count
FROM comcast_complaints
GROUP BY state
ORDER BY complaint_count DESC
LIMIT 15;


-- Complaint volume and category mix for top 10 states
-- Pivoting in application layer is preferable for wide schemas,
-- but this gives a flat view for quick ad-hoc analysis.
SELECT
    state,
    primary_category,
    COUNT(*)  AS complaint_count
FROM comcast_complaints
WHERE state IN (
    SELECT state
    FROM comcast_complaints
    GROUP BY state
    ORDER BY COUNT(*) DESC
    LIMIT 10
)
GROUP BY state, primary_category
ORDER BY state, complaint_count DESC;


-- Dominant issue category per state
-- For each state, returns the primary_category that appears most often.
-- States where 'billing_issue' is not dominant may have distinct
-- infrastructure or service quality problems worth investigating.
SELECT
    state,
    primary_category                                          AS dominant_category,
    complaint_count
FROM (
    SELECT
        state,
        primary_category,
        COUNT(*)                                              AS complaint_count,
        ROW_NUMBER() OVER (
            PARTITION BY state ORDER BY COUNT(*) DESC
        )                                                     AS rn
    FROM comcast_complaints
    GROUP BY state, primary_category
) ranked
WHERE rn = 1
ORDER BY complaint_count DESC;


-- Unresolved complaint concentration by state
-- States with high unresolved counts may indicate regional
-- service quality issues or customer care capacity constraints.
SELECT
    state,
    COUNT(*)                                                  AS total_complaints,
    SUM(CASE WHEN status IN ('open', 'pending') THEN 1 ELSE 0 END)
                                                              AS unresolved_count,
    ROUND(
        SUM(CASE WHEN status IN ('open', 'pending') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                         AS unresolved_rate_pct
FROM comcast_complaints
GROUP BY state
HAVING COUNT(*) >= 20   -- filter out low-volume states to reduce noise
ORDER BY unresolved_count DESC
LIMIT 15;
