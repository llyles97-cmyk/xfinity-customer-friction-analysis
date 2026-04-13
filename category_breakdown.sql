-- ============================================================
-- category_breakdown.sql
-- Issue category distribution and cross-cuts with resolution
-- status. Answers: "what are customers complaining about,
-- and which categories have the worst resolution rates?"
--
-- Note: primary_category is derived from a keyword-based
-- multi-label classifier. Billing_issue dominance (~72%)
-- is partly an artifact of broad keyword overlap — treat
-- percentages as directional signals, not precise splits.
-- ============================================================


-- Primary category distribution — count and share of total
SELECT
    primary_category,
    COUNT(*)                                                  AS complaint_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)       AS pct_of_total
FROM comcast_complaints
GROUP BY primary_category
ORDER BY complaint_count DESC;


-- Category distribution broken out by resolution status
-- Useful for identifying which issue types are hardest to close.
-- High open/pending share within a category suggests systemic friction.
SELECT
    primary_category,
    status,
    COUNT(*)                                                  AS complaint_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (PARTITION BY primary_category), 2
    )                                                         AS pct_within_category
FROM comcast_complaints
GROUP BY primary_category, status
ORDER BY primary_category, complaint_count DESC;


-- Unresolved rate by category (open + pending as a share of category total)
-- Rank categories by escalation burden.
SELECT
    primary_category,
    COUNT(*)                                                  AS total_complaints,
    SUM(CASE WHEN status IN ('open', 'pending') THEN 1 ELSE 0 END)
                                                              AS unresolved_count,
    ROUND(
        SUM(CASE WHEN status IN ('open', 'pending') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                         AS unresolved_rate_pct
FROM comcast_complaints
GROUP BY primary_category
ORDER BY unresolved_rate_pct DESC;


-- Third-party filing rate by category
-- Elevated on_behalf rates may indicate consumer advocacy involvement
-- or customers too frustrated to engage directly.
SELECT
    primary_category,
    COUNT(*)                                                  AS total_complaints,
    SUM(CASE WHEN on_behalf = 'Yes' THEN 1 ELSE 0 END)       AS filed_on_behalf,
    ROUND(
        SUM(CASE WHEN on_behalf = 'Yes' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                         AS on_behalf_rate_pct
FROM comcast_complaints
GROUP BY primary_category
ORDER BY on_behalf_rate_pct DESC;
