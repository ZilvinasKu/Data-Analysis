-- This query segments users based on the time taken from first page view to purchase
WITH PurchaseTimes AS (
    SELECT
        user_pseudo_id,  -- Unique identifier for each user
        FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', CAST(event_date AS STRING))) AS formatted_event_date,  -- Format the event date
        TIMESTAMP_DIFF(TIMESTAMP_MICROS(first_purchase_time), TIMESTAMP_MICROS(first_page_view_time), MINUTE) AS time_to_purchase  -- Calculate time in minutes
    FROM (
        SELECT
            user_pseudo_id,
            event_date,
            MIN(CASE WHEN event_name = 'page_view' THEN event_timestamp ELSE NULL END) AS first_page_view_time,  -- Time of first page view
            MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp ELSE NULL END) AS first_purchase_time  -- Time of first purchase
        FROM
            `tc-da-1.turing_data_analytics.raw_events`
        WHERE
            event_name IN ('page_view', 'purchase')  -- Filter for relevant events
        GROUP BY
            user_pseudo_id,
            event_date
    )
    WHERE
        first_page_view_time IS NOT NULL AND first_purchase_time IS NOT NULL  -- Ensure valid timestamps for calculation
)

SELECT
    CASE
        WHEN time_to_purchase <= 15 THEN 'Fast'  -- Segment 'Fast' for users who purchase within 15 minutes
        WHEN time_to_purchase <= 60 THEN 'Moderate'  -- Segment 'Moderate' for users who take up to an hour
        ELSE 'Slow'  -- Segment 'Slow' for users taking longer than an hour
    END AS purchase_speed_category,  -- Purchase speed category
    COUNT(user_pseudo_id) AS user_count,  -- Count of users in each category
    AVG(time_to_purchase) AS avg_time_to_purchase  -- Average time to purchase within each category
FROM
    PurchaseTimes
GROUP BY
    purchase_speed_category  -- Group by the speed category
ORDER BY
    purchase_speed_category;
