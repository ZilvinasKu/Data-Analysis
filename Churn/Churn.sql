-- This SQL query is designed to analyze subscription data, specifically focusing on user retention over a 6-week period.
-- It examines how many users start a subscription in a given week and tracks how many remain subscribed in subsequent weeks.

WITH subscription_data AS (
    -- The first CTE, subscription_data, prepares the subscription information,
    -- including the start and end dates truncated to the beginning of the week.
    SELECT *,
           DATE_TRUNC(subscription_start, WEEK) AS start_week, -- Aligns subscription start dates to the start of their respective weeks.
           DATE_TRUNC(subscription_end, WEEK) AS end_week -- Similarly aligns subscription end dates.
    FROM turing_data_analytics.subscriptions
),
user_counts AS (
    -- The second CTE, user_counts, calculates the initial count of new subscriptions for each week.
    SELECT start_week,
           COUNT(user_pseudo_id) AS number_users -- Counts unique users starting subscriptions each week.
    FROM subscription_data
    GROUP BY start_week
)
SELECT uc.start_week,
       uc.number_users as week_0_users, -- Represents the number of users at the start of the period (week 0).
       -- The following lines count the number of users whose subscriptions extend beyond each subsequent week,
       -- indicating ongoing subscriptions. If an end date is NULL, it's assumed the subscription is still active.
       COUNT(CASE WHEN DATE_ADD(uc.start_week, INTERVAL 0 WEEK) < sd.end_week OR sd.end_week IS NULL THEN sd.user_pseudo_id END) AS week_1_users,
       COUNT(CASE WHEN DATE_ADD(uc.start_week, INTERVAL 1 WEEK) < sd.end_week OR sd.end_week IS NULL THEN sd.user_pseudo_id END) AS week_2_users,
       COUNT(CASE WHEN DATE_ADD(uc.start_week, INTERVAL 2 WEEK) < sd.end_week OR sd.end_week IS NULL THEN sd.user_pseudo_id END) AS week_3_users,
       COUNT(CASE WHEN DATE_ADD(uc.start_week, INTERVAL 3 WEEK) < sd.end_week OR sd.end_week IS NULL THEN sd.user_pseudo_id END) AS week_4_users,
       COUNT(CASE WHEN DATE_ADD(uc.start_week, INTERVAL 4 WEEK) < sd.end_week OR sd.end_week IS NULL THEN sd.user_pseudo_id END) AS week_5_users,
       COUNT(CASE WHEN DATE_ADD(uc.start_week, INTERVAL 5 WEEK) < sd.end_week OR sd.end_week IS NULL THEN sd.user_pseudo_id END) AS week_6_users
FROM user_counts uc
LEFT JOIN subscription_data sd ON uc.start_week = sd.start_week -- Joins the initial user count with subscription details to track retention.
GROUP BY uc.start_week, uc.number_users
ORDER BY uc.start_week; -- Orders the results chronologically by subscription start week.
