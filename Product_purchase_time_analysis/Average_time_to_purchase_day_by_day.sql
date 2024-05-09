-- This query computes the average time taken to purchase each day across all users
WITH TimeToPurchase AS (
    SELECT
        user_pseudo_id,
        FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', CAST(event_date AS STRING))) AS formatted_event_date,
        TIMESTAMP_DIFF(TIMESTAMP_MICROS(first_purchase_time), TIMESTAMP_MICROS(first_page_view_time), MINUTE) AS time_to_purchase  -- Calculate time in minutes
    FROM (
        SELECT
            user_pseudo_id,
            event_date,
            MIN(CASE WHEN event_name = 'page_view' THEN event_timestamp ELSE NULL END) AS first_page_view_time,
            MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp ELSE NULL END) AS first_purchase_time
        FROM
            `tc-da-1.turing_data_analytics.raw_events`
        WHERE
            event_name IN ('page_view', 'purchase')
        GROUP BY
            user_pseudo_id,
            event_date
    )
    WHERE
        first_page_view_time IS NOT NULL AND first_purchase_time IS NOT NULL
)

SELECT
    formatted_event_date,
    AVG(time_to_purchase) AS avg_time_to_purchase  -- Compute average purchase time
FROM
    TimeToPurchase
GROUP BY
    formatted_event_date
ORDER BY
    formatted_event_date;