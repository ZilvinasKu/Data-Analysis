-- Common Table Expression (CTE): MaxOrderDate
-- Purpose: Calculates the maximum order date from the salesorderheader table.
-- Result: Temporary table MaxOrderDate with a single column LatestOrderDate.
WITH MaxOrderDate AS (
    SELECT MAX(OrderDate) AS LatestOrderDate
    FROM `tc-da-1.adwentureworks_db.salesorderheader`
),

-- Common Table Expression (CTE): LatestAddress
-- Purpose: Identifies the latest address for each customer based on the maximum AddressID.
-- Result: Temporary table LatestAddress with columns CustomerID and LatestAddressID.
LatestAddress AS (
    SELECT
        ca.CustomerID,
        MAX(ca.AddressID) AS LatestAddressID
    FROM `tc-da-1.adwentureworks_db.customeraddress` ca
    GROUP BY ca.CustomerID
),

-- Common Table Expression (CTE): CustomerActivity
-- Purpose: Determines the activity status of each customer based on their order history.
-- Result: Temporary table CustomerActivity with columns CustomerID and CustomerStatus.
CustomerActivity AS (
    SELECT
        cust.CustomerID,
        CASE WHEN MAX(so.OrderDate) >= TIMESTAMP(DATE_SUB((SELECT LatestOrderDate FROM MaxOrderDate), INTERVAL 365 DAY))
            THEN 'Active'
            ELSE 'Inactive'
        END AS CustomerStatus
    FROM
        `tc-da-1.adwentureworks_db.customer` cust
    LEFT JOIN
        `tc-da-1.adwentureworks_db.salesorderheader` so ON cust.CustomerID = so.CustomerID
    WHERE
        cust.CustomerType = 'I'
    GROUP BY
        cust.CustomerID
)

-- Main Query
-- Purpose: Retrieves detailed information about individual customers, including their latest address,
-- contact details, order history, and activity status from the AdventureWorks database.
SELECT
    cust.CustomerID,
    cont.FirstName,
    cont.LastName,
    cont.FirstName || ' ' || cont.LastName AS FullName,
    CONCAT(CASE WHEN cont.Title IS NOT NULL THEN cont.Title ELSE 'Dear' END, ' ', cont.LastName) AS addressing_title,
    cont.EmailAddress,
    cont.Phone,
    cust.AccountNumber,
    addr.City,
    addr.AddressLine1,
    CAST(REGEXP_EXTRACT(addr.AddressLine1, r'^(\d+)') AS INT64) AS address_no,
    REGEXP_REPLACE(addr.AddressLine1, r'^\d+\s*', '') AS address_st,
    sp.Name AS State,
    cr.Name AS Country,
    COUNT(so.SalesOrderID) AS NumberOfOrders,
    SUM(so.TotalDue) AS TotalAmountWithTax,
    MAX(so.OrderDate) AS LastOrderDate
FROM
    `tc-da-1.adwentureworks_db.customer` cust
JOIN
    `tc-da-1.adwentureworks_db.individual` ind ON cust.CustomerID = ind.CustomerID
JOIN
    `tc-da-1.adwentureworks_db.contact` cont ON ind.ContactID = cont.ContactID
JOIN
    LatestAddress ON cust.CustomerID = LatestAddress.CustomerID
JOIN
    `tc-da-1.adwentureworks_db.address` addr ON LatestAddress.LatestAddressID = addr.AddressID
JOIN
    `tc-da-1.adwentureworks_db.stateprovince` sp ON addr.StateProvinceID = sp.StateProvinceID
JOIN
    `tc-da-1.adwentureworks_db.countryregion` cr ON sp.CountryRegionCode = cr.CountryRegionCode
JOIN
    `tc-da-1.adwentureworks_db.salesterritory` st ON sp.TerritoryID = st.TerritoryID
LEFT JOIN
    `tc-da-1.adwentureworks_db.salesorderheader` so ON cust.CustomerID = so.CustomerID
LEFT JOIN
    CustomerActivity ca ON cust.CustomerID = ca.CustomerID
WHERE
    st.Group = 'North America'
    AND ca.CustomerStatus = 'Active'
    AND country IN ('Canada', 'United States')
GROUP BY
    cust.CustomerID,
    cont.FirstName,
    cont.LastName,
    cont.Title,
    cont.EmailAddress,
    cont.Phone,
    cust.AccountNumber,
    addr.City,
    sp.Name,
    cr.Name,
    addr.AddressLine1

-- HAVING Clause: Filters the results based on specific conditions for total due and sales order count.
HAVING
    SUM(so.TotalDue) >= 2500 OR COUNT(so.SalesOrderID) >= 5

-- ORDER BY Clause: Sorts the results based on country, state, and last order date in descending order.
ORDER BY
    cr.Name, sp.Name, LastOrderDate DESC

-- LIMIT Clause: Limits the output to the top 500 results.
LIMIT
    500;