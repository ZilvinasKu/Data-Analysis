-- This query calculates the daily conversion rate from page views to purchases
WITH EventCounts AS (
    SELECT
        FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', CAST(event_date AS STRING))) AS formatted_event_date,  -- Format the event date
        SUM(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END) AS page_views,  -- Count of page views
        SUM(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchases  -- Count of purchases
    FROM
        `tc-da-1.turing_data_analytics.raw_events`
    GROUP BY
        event_date
)

SELECT
    formatted_event_date AS event_date,
    purchases,
    page_views,
    (purchases / page_views) * 100 AS conversion_rate  -- Calculate conversion rate percentage
FROM
    EventCounts
ORDER BY
    formatted_event_date;
