-- Define a Common Table Expression (CTE) named UniqueEvents.
-- This CTE is used to identify the first occurrence of specific event types for each user within each category.
WITH UniqueEvents AS (
SELECT
category, -- The category of the event
event_name, -- The name of the event (e.g., page_view, view_item)
user_pseudo_id, -- The identifier for the user
-- Assign a unique row number for each event per user per category, ordered by the timestamp of the event.
-- This row number helps in identifying the first occurrence of each event type for each user within a category.
ROW_NUMBER() OVER(PARTITION BY category, user_pseudo_id, event_name ORDER BY event_timestamp ASC) as rn
FROM
`tc-da-1.turing_data_analytics.raw_events` -- The table containing the raw events data.
WHERE
-- Filter events to only include those that are relevant to our analysis.
event_name IN ('page_view', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
),

-- Define another CTE named FilteredUniqueEvents.
-- This filters to include only the first occurrence of each event for each user in each category.
FilteredUniqueEvents AS (
SELECT
category, -- The category of the event
event_name, -- The name of the event
-- Count the number of unique first occurrences of each event by category and event_name.
COUNT(*) AS unique_event_count
FROM
UniqueEvents
WHERE
rn = 1 -- Only consider the row number 1, indicating the first occurrence of the event.
GROUP BY
category, event_name
),

-- Define a third CTE named CategoryFunnel.
-- This CTE is used to assign a numeric order to each event type within the funnel analysis.
CategoryFunnel AS (
SELECT
category, -- The category of the event
event_name, -- The name of the event
unique_event_count, -- The count of unique first occurrences of the event
-- Assign a numeric order to each event based on its position in the conversion funnel.
CASE event_name
WHEN 'page_view' THEN 1
WHEN 'view_item' THEN 2
WHEN 'add_to_cart' THEN 3
WHEN 'begin_checkout' THEN 4
WHEN 'purchase' THEN 5
END AS event_order
FROM
FilteredUniqueEvents
)

-- Final SELECT to output the analysis results.
SELECT
event_order, -- The numeric order of the event in the funnel
event_name, -- The name of the event
category, -- The category of the event
unique_event_count -- The count of unique events
FROM
CategoryFunnel
ORDER BY
category, -- Order the results first by category
event_order -- Then order by the event order within each category to follow the funnel sequence