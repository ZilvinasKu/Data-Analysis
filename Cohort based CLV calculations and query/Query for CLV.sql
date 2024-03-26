-- CTE to calculate the first registration week for each user
WITH UserRegistration AS (
SELECT
user_pseudo_id AS UserID, -- Unique identifier for each user
DATE_TRUNC(DATE(TIMESTAMP_MICROS(MIN(event_timestamp))), WEEK) AS RegistrationWeekStart -- The week when the user first registered, calculated from the earliest event timestamp
FROM
`turing_data_analytics.raw_events`
GROUP BY
UserID
),

-- CTE to calculate the week of purchase and revenue for purchase events
UserPurchase AS (
SELECT
user_pseudo_id AS UserID, -- Unique identifier for the user making a purchase
DATE_TRUNC(DATE(TIMESTAMP_MICROS(event_timestamp)), WEEK) AS PurchaseWeekStart, -- The week when the purchase was made
purchase_revenue_in_usd AS RevenueUSD -- The revenue from each purchase in USD
FROM
`turing_data_analytics.raw_events`
WHERE
event_name = "purchase" -- Filters for purchase events only
)

-- Main SELECT statement to calculate revenue by week since registration
SELECT
ur.RegistrationWeekStart, -- The start of the registration week for grouping results
COUNT(DISTINCT ur.UserID) AS TotalRegistrations, -- Total number of users who registered in each week
-- The following lines calculate the total revenue generated from users in their respective registration week (week 0) and the subsequent 12 weeks.
-- Each SUM/CASE combination checks if the purchase occurred in the same week as the registration (for week0_revenue),
-- or in one of the 12 weeks following registration (for week1_revenue through week12_revenue),
-- and sums the revenue for those purchases.
SUM(CASE WHEN up.PurchaseWeekStart = ur.RegistrationWeekStart THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek0,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 1 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek1,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 2 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek2,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 3 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek3,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 4 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek4,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 5 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek5,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 6 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek6,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 7 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek7,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 8 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek8,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 9 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek9,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 10 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek10,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 11 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek11,
SUM(CASE WHEN up.PurchaseWeekStart = DATE_ADD(ur.RegistrationWeekStart, INTERVAL 12 WEEK) THEN up.RevenueUSD ELSE 0 END) AS RevenueWeek12
FROM
UserRegistration ur -- From the UserRegistration CTE
LEFT JOIN UserPurchase up ON ur.UserID = up.UserID -- Joining on UserID to match registration records with purchase records
GROUP BY
ur.RegistrationWeekStart -- Grouping results by the registration week
ORDER BY
ur.RegistrationWeekStart -- Ordering the results by the registration week