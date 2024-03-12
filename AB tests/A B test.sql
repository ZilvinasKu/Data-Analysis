-- Define a temporary table to estimate unique clicks for specific campaigns
WITH EstimatedClicks AS (
SELECT
r.campaign, -- The name of the campaign
COUNT(DISTINCT r.user_pseudo_id) AS unique_clicks -- Count unique users as estimated clicks
FROM
`tc-da-1.turing_data_analytics.raw_events` r -- From the raw_events table
WHERE
r.event_name = 'page_view' -- Consider only page view events
AND (r.campaign LIKE '%NewYear%' OR r.campaign LIKE '%BlackFriday%') -- Filter for NewYear and BlackFriday campaigns
GROUP BY
r.campaign -- Group the results by campaign
)

-- Main SELECT statement to retrieve campaign performance data
SELECT
a.Month, -- The month of the campaign
a.Campaign, -- The name of the campaign
a.Impressions, -- The number of impressions from the adsense_monthly table
e.unique_clicks AS EstimatedClicks -- The estimated clicks derived from the unique user counts
FROM
`tc-da-1.turing_data_analytics.adsense_monthly` a -- The adsense_monthly table with campaign data
JOIN
EstimatedClicks e ON a.Campaign = e.campaign -- Join with the EstimatedClicks table on campaign name
WHERE
a.Campaign IN ('NewYear_V1', 'NewYear_V2', 'BlackFriday_V1', 'BlackFriday_V2') -- Filter for specific campaigns
AND NOT (a.Month = 202111 AND a.Campaign = 'BlackFriday_V1') -- Exclude an unwanted specific row
ORDER BY
a.Month, a.Campaign; -- Order the results by month and campaign for readability