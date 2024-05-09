-- This query calculates the purchase count based on the weekday
SELECT
    FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', CAST(event_date AS STRING))) AS day_of_week,
    COUNT(*) AS purchase_count
FROM
    `tc-da-1.turing_data_analytics.raw_events`
WHERE
    event_name = 'purchase'
GROUP BY
    day_of_week
ORDER BY
    purchase_count DESC;
