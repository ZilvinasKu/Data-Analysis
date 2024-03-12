-- This CTE identifies the first occurrence of specific event types for each user in each country.
WITH UniqueEventCounts AS (
SELECT
country, -- The country where the event occurred
event_name, -- The name of the event (e.g., page_view, view_item)
user_pseudo_id, -- The identifier for the user
-- Assign a unique row number for each event per user per country, ordered by the event timestamp.
-- This helps in identifying the first occurrence of each event type for each user.
ROW_NUMBER() OVER(PARTITION BY country, user_pseudo_id, event_name ORDER BY event_timestamp ASC) as rn
FROM
`tc-da-1.turing_data_analytics.raw_events`
WHERE
-- Filter events to only include specific types that are of interest.
event_name IN ('page_view', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
),

-- Create another CTE named FilteredUniqueEvents.
-- This filters out only the first occurrence of each event for each user in each country.
FilteredUniqueEvents AS (
SELECT
country, -- The country of the event
event_name, -- The name of the event
-- Count the number of unique first occurrences of each event by country and event_name.
COUNT(*) AS unique_event_count
FROM
UniqueEventCounts
WHERE
rn = 1 -- Only consider the row number 1, which indicates the first occurrence of the event.
GROUP BY
country, event_name
),

-- Create a third CTE named CountryRankings.
-- This CTE ranks countries based on the total number of unique events.
CountryRankings AS (
SELECT
country, -- The country
-- Calculate the total number of unique events for each country.
SUM(unique_event_count) AS total_unique_events,
-- Assign a rank to each country based on the total number of unique events, in descending order.
ROW_NUMBER() OVER(ORDER BY SUM(unique_event_count) DESC) AS country_rank
FROM
FilteredUniqueEvents
GROUP BY
country
)

-- Final SELECT to output the results.
SELECT
f.country, -- Country from the FilteredUniqueEvents CTE
f.event_name, -- Event name from the FilteredUniqueEvents CTE
f.unique_event_count -- Count of unique events from the FilteredUniqueEvents CTE
FROM
FilteredUniqueEvents f
JOIN
-- Join with the CountryRankings CTE to include country ranking information.
CountryRankings cr ON f.country = cr.country
WHERE
-- Filter to only include countries that are ranked in the top 3 based on the unique event count.
cr.country_rank <= 3
ORDER BY
-- Order the results first by the country rank in ascending order and then by event name.
cr.country_rank ASC, f.event_name