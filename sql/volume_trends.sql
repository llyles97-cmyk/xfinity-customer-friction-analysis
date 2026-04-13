-- ============================================================
-- volume_trends.sql
-- Complaint volume analysis: total counts, monthly trends,
-- and resolution status breakdown.
--
-- Context: Used to answer "how many complaints did Comcast
-- receive and how did volume change over the filing period?"
-- Complaint volume peaked in June-July 2015, coinciding with
-- heightened FCC scrutiny following net neutrality proceedings.
-- ============================================================


-- Total complaint count — baseline for all percentage calculations downstream
SELECT COUNT(*) AS total_complaints
FROM comcast_complaints;


-- Monthly complaint trend
-- Useful for spotting seasonal spikes or event-driven surges.
-- Months are stored as integers (1-12); join to a date dimension
-- for calendar-year labeling in a warehouse context.
SELECT
    month,
    COUNT(*)                                                  AS complaint_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)       AS pct_of_total
FROM comcast_complaints
GROUP BY month
ORDER BY month;


-- Complaint volume by resolution status
-- 'closed' and 'solved' represent resolved complaints;
-- 'open' and 'pending' are escalated or unresolved.
-- Unresolved rate > 15% is a common CX escalation threshold.
SELECT
    status,
    COUNT(*)                                                  AS complaint_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)       AS pct_of_total
FROM comcast_complaints
GROUP BY status
ORDER BY complaint_count DESC;


-- Complaint volume by intake channel (Internet vs. postal mail)
-- Channel mix informs where to focus self-service deflection efforts.
SELECT
    channel,
    COUNT(*) AS complaint_count
FROM comcast_complaints
GROUP BY channel
ORDER BY complaint_count DESC;


-- Filed on behalf of someone else vs. direct filer
-- Third-party filings can indicate advocacy group involvement
-- or cases where the customer could not engage directly.
SELECT
    on_behalf,
    COUNT(*) AS complaint_count
FROM comcast_complaints
GROUP BY on_behalf
ORDER BY complaint_count DESC;
