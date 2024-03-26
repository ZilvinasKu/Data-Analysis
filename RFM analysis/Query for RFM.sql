-- Initial data preparation filters transactions based on date, existence of CustomerID, and positive quantities.
WITH filtered_data AS (
  SELECT
    CustomerID,  -- Unique identifier for each customer.
    Country,  -- Country of the customer.
    InvoiceDate,  -- Date when the transaction was made.
    InvoiceNo,  -- Unique identifier for each transaction.
    Quantity,  -- Number of items purchased in the transaction.
    UnitPrice  -- Price of each item.
  FROM
    `tc-da-1.turing_data_analytics.rfm`  -- Specified dataset and table in BigQuery.
  WHERE
    DATE(InvoiceDate) BETWEEN '2010-12-01' AND '2011-12-01'  -- Filters transactions within a specific date range.
    AND CustomerID IS NOT NULL  -- Excludes transactions without a customer ID.
    AND Quantity > 0  -- Excludes transactions with negative quantities, indicating returns or corrections.
),

-- Calculate RFM metrics for each customer from the filtered data.
rfm_metrics AS (
  SELECT
    CustomerID,
    Country,
    DATE_DIFF(DATE '2011-12-01', MAX(DATE(InvoiceDate)), DAY) AS Recency,  -- Calculates how many days ago was the last purchase.
    COUNT(DISTINCT InvoiceNo) AS Frequency,  -- Counts unique invoices for each customer as the purchase frequency.
    ROUND(SUM(Quantity * UnitPrice), 2) AS MonetaryValue  -- Calculates total spend per customer, rounded to 2 decimal places.
  FROM
    filtered_data
  GROUP BY
    CustomerID, Country
),

-- Calculate quartile thresholds for Recency, Frequency, and MonetaryValue metrics.
thresholds AS (
  SELECT
    PERCENTILE_CONT(Recency, 0.25) OVER () AS R_Q1,  -- 25th percentile of Recency.
    PERCENTILE_CONT(Recency, 0.5) OVER () AS R_Q2,  -- Median of Recency.
    PERCENTILE_CONT(Recency, 0.75) OVER () AS R_Q3,  -- 75th percentile of Recency.
    PERCENTILE_CONT(Frequency, 0.25) OVER () AS F_Q1,  -- 25th percentile of Frequency.
    PERCENTILE_CONT(Frequency, 0.5) OVER () AS F_Q2,  -- Median of Frequency.
    PERCENTILE_CONT(Frequency, 0.75) OVER () AS F_Q3,  -- 75th percentile of Frequency.
    PERCENTILE_CONT(MonetaryValue, 0.25) OVER () AS M_Q1,  -- 25th percentile of MonetaryValue.
    PERCENTILE_CONT(MonetaryValue, 0.5) OVER () AS M_Q2,  -- Median of MonetaryValue.
    PERCENTILE_CONT(MonetaryValue, 0.75) OVER () AS M_Q3  -- 75th percentile of MonetaryValue.
  FROM
    rfm_metrics
  LIMIT 1  -- Ensures only a single row of thresholds is produced for the entire dataset.
),

-- Assign scores for Recency, Frequency, and MonetaryValue based on calculated quartiles.
rfm_scores AS (
  SELECT
    r.*,
    CASE
      WHEN Recency <= (SELECT R_Q1 FROM thresholds) THEN 4
      WHEN Recency <= (SELECT R_Q2 FROM thresholds) THEN 3
      WHEN Recency <= (SELECT R_Q3 FROM thresholds) THEN 2
      ELSE 1
    END AS R_Score,  -- Scores are inversely related to Recency; less recency results in higher score.
    CASE
      WHEN Frequency > (SELECT F_Q3 FROM thresholds) THEN 4
      WHEN Frequency > (SELECT F_Q2 FROM thresholds) THEN 3
      WHEN Frequency > (SELECT F_Q1 FROM thresholds) THEN 2
      ELSE 1
    END AS F_Score,  -- Scores directly relate to Frequency; more frequency results in higher score.
    CASE
      WHEN MonetaryValue > (SELECT M_Q3 FROM thresholds) THEN 4
      WHEN MonetaryValue > (SELECT M_Q2 FROM thresholds) THEN 3
      WHEN MonetaryValue > (SELECT M_Q1 FROM thresholds) THEN 2
      ELSE 1
    END AS M_Score  -- Scores directly relate to MonetaryValue; higher spending results in higher score.
  FROM
    rfm_metrics r
),

-- Calculate FM score as the average of F and M scores for further segmentation.
fm_scores_and_segmentation AS (
  SELECT
    *,
    (F_Score + M_Score) / 2 AS FM_Score  -- Average of F and M scores.
  FROM
    rfm_scores
),

-- Segment customers based on R and FM scores using predefined logic.
customer_segments AS (
  SELECT
    CustomerID,
    Country,
    Recency,
    Frequency,
    MonetaryValue,
    R_Score,
    F_Score,
    M_Score,
    FM_Score,
    CASE 
      WHEN (R_Score = 4 AND FM_Score >= 3.5) THEN 'Champions'  -- Best customers with recent transactions and high FM score.
      WHEN (R_Score >= 3 AND FM_Score >= 2.5) THEN 'Loyal Customers'  -- Regular and valuable customers.
      WHEN (R_Score >= 3 AND FM_Score BETWEEN 2 AND 2.5) THEN 'Potential Loyalists'  -- Customers with potential to become more valuable.
      WHEN R_Score = 4 AND FM_Score < 2 THEN 'Recent Customers'  -- New customers with low FM score.
      WHEN R_Score BETWEEN 2 AND 3 AND FM_Score < 2 THEN 'Promising'  -- Newer customers with potential.
      WHEN R_Score <= 3 AND FM_Score BETWEEN 2 AND 3 THEN 'Customers Needing Attention'  -- Medium value customers at risk.
      WHEN R_Score = 2 AND FM_Score < 2 THEN 'About to Sleep'  -- Inactive customers.
      WHEN R_Score <= 2 AND FM_Score >= 3.5 THEN 'At Risk'  -- Previously valuable customers who haven't purchased recently.
      WHEN R_Score = 1 AND FM_Score >= 2 THEN 'Cant Lose Them'  -- High-value customers at risk of churning.
      WHEN R_Score = 1 AND FM_Score < 2 THEN 'Hibernating'  -- Low activity, low value.
      WHEN R_Score = 1 AND FM_Score = 1 THEN 'Lost'  -- Lowest value and engagement.
      ELSE 'Other'  -- Any other customers not fitting the above categories.
    END AS RFM_Segment  -- Assigns a segment label based on R_Score and FM_Score criteria.
  FROM
    fm_scores_and_segmentation
)

-- Output the final customer segments
SELECT * FROM customer_segments;
