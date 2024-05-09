-- This query calculates the time from the first page view to the first purchase for each user on each day
WITH FirstEvents AS (
    SELECT
        user_pseudo_id,  -- Unique identifier for each user
        FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', CAST(event_date AS STRING))) AS formatted_event_date,  -- Format event date
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

SELECT
    formatted_event_date AS event_date,
    user_pseudo_id,
    first_page_view_time,
    first_purchase_time,
    TIMESTAMP_DIFF(TIMESTAMP_MICROS(first_purchase_time), TIMESTAMP_MICROS(first_page_view_time), MINUTE) AS time_to_purchase  -- Calculate time to purchase in minutes
FROM
    FirstEvents
WHERE
    first_page_view_time IS NOT NULL AND
    first_purchase_time IS NOT NULL  -- Ensure valid timestamps for calculation
ORDER BY
    formatted_event_date, user_pseudo_id;  -- Order results by date and user ID
