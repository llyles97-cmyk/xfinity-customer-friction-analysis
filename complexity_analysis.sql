-- ============================================================
-- complexity_analysis.sql
-- Multi-label complaint complexity: how many issue types are
-- present per complaint, and what does that signal about
-- the customer experience?
--
-- context: category_count reflects the number of keyword-matched
-- issue categories per complaint. High counts (5+) likely
-- reflect keyword overlap in the classifier rather than
-- genuinely complex multi-issue cases. Treat as a rough
-- complexity proxy. Complaints with category_count = 1 are
-- the cleanest signal; those with 7+ warrant manual review.
-- ============================================================


-- Distribution of category_count across all complaints
SELECT
    category_count,
    COUNT(*)                                                  AS complaint_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)       AS pct_of_total
FROM comcast_complaints
GROUP BY category_count
ORDER BY category_count;


-- Average complexity score by primary category
-- Categories with high avg category_count may have broad,
-- narrative-heavy complaints; lower scores suggest focused issues.
SELECT
    primary_category,
    COUNT(*)                                                  AS complaint_count,
    ROUND(AVG(category_count), 2)                             AS avg_category_count,
    MIN(category_count)                                       AS min_count,
    MAX(category_count)                                       AS max_count
FROM comcast_complaints
GROUP BY primary_category
ORDER BY avg_category_count DESC;


-- High-complexity complaints (category_count >= 6)
-- These are candidates for escalation review or qualitative
-- analysis to identify patterns the classifier may be missing.
SELECT
    ticket_id,
    state,
    primary_category,
    category_count,
    status,
    LEFT(complaint_text, 300)                                 AS complaint_excerpt
FROM comcast_complaints
WHERE category_count >= 6
ORDER BY category_count DESC, primary_category
LIMIT 25;


-- Single-category complaints — cleanest signal from the classifier
-- If one of these is misclassified, it's a keyword taxonomy issue,
-- not an overlap issue. Good sample for classifier quality review.
SELECT
    ticket_id,
    state,
    primary_category,
    status,
    LEFT(complaint_text, 300)                                 AS complaint_excerpt
FROM comcast_complaints
WHERE category_count = 1
ORDER BY primary_category, ticket_id
LIMIT 25;


-- Complexity vs. resolution status
-- Do more complex (multi-issue) complaints take longer to resolve?
-- Unresolved rate by complexity band.
SELECT
    CASE
        WHEN category_count = 1       THEN '1 (single issue)'
        WHEN category_count BETWEEN 2 AND 3 THEN '2-3 (moderate)'
        WHEN category_count BETWEEN 4 AND 5 THEN '4-5 (elevated)'
        ELSE '6+ (high overlap / complex)'
    END                                                       AS complexity_band,
    COUNT(*)                                                  AS complaint_count,
    SUM(CASE WHEN status IN ('open', 'pending') THEN 1 ELSE 0 END)
                                                              AS unresolved_count,
    ROUND(
        SUM(CASE WHEN status IN ('open', 'pending') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                         AS unresolved_rate_pct
FROM comcast_complaints
GROUP BY complexity_band
ORDER BY MIN(category_count);
