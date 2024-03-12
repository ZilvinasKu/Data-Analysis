-- Common Table Expression (CTE): MonthlySalesCTE
-- Purpose: Extracts monthly sales information, including the order year, order month, region details,
-- and aggregated metrics such as the number of orders, number of customers, number of salespersons,
-- and total sales with tax.
-- Result: Temporary table MonthlySalesCTE with columns order_year, order_month, CountryRegionCode, Region,
-- number_orders, number_customers, no_salesPersons, Total_w_tax.
WITH MonthlySalesCTE AS (
    SELECT
        EXTRACT(YEAR FROM TIMESTAMP(soh.OrderDate)) AS order_year,
        EXTRACT(MONTH FROM TIMESTAMP(soh.OrderDate)) AS order_month,
        sr.CountryRegionCode,
        sr.Name AS Region,
        COUNT(DISTINCT soh.SalesOrderID) AS number_orders,
        COUNT(DISTINCT soh.CustomerID) AS number_customers,
        COUNT(DISTINCT soh.SalesPersonID) AS no_salesPersons,
        ROUND(SUM(soh.TotalDue), 2) AS Total_w_tax
    FROM
        `adwentureworks_db.salesorderheader` soh
    JOIN
        `adwentureworks_db.salesterritory` sr ON soh.TerritoryID = sr.TerritoryID
    -- Removed JOIN with address table
    GROUP BY
        order_year,
        order_month,
        sr.CountryRegionCode,
        Region
),

-- Common Table Expression (CTE): MaxTaxRates
-- Purpose: Calculates the maximum tax rate for each state/province within a country/region.
-- Result: Temporary table MaxTaxRates with columns CountryRegionCode, StateProvinceID, and max_tax_rate.
MaxTaxRates AS (
    SELECT
        sr.CountryRegionCode,
        st.StateProvinceID,
        MAX(str.TaxRate) AS max_tax_rate
    FROM
        `adwentureworks_db.salesterritory` sr
    JOIN
        `adwentureworks_db.stateprovince` st ON sr.CountryRegionCode = st.CountryRegionCode
    JOIN
        `adwentureworks_db.salestaxrate` str ON st.StateProvinceID = str.StateProvinceID
    GROUP BY
        sr.CountryRegionCode,
        st.StateProvinceID
),

-- Common Table Expression (CTE): ProvincesWithTax
-- Purpose: Counts the total number of provinces and the number of provinces with tax for each country/region.
-- Result: Temporary table ProvincesWithTax with columns CountryRegionCode, total_provinces, and provinces_with_tax.
ProvincesWithTax AS (
    SELECT
        sr.CountryRegionCode,
        COUNT(DISTINCT st.StateProvinceID) AS total_provinces,
        COUNT(DISTINCT str.StateProvinceID) AS provinces_with_tax
    FROM
        `adwentureworks_db.salesterritory` sr
    LEFT JOIN
        `adwentureworks_db.stateprovince` st ON sr.CountryRegionCode = st.CountryRegionCode
    LEFT JOIN
        `adwentureworks_db.salestaxrate` str ON st.StateProvinceID = str.StateProvinceID
    GROUP BY
        sr.CountryRegionCode
)

-- Main Query
-- Purpose: Combines the results from MonthlySalesCTE, MaxTaxRates, and ProvincesWithTax to generate a report
-- on monthly sales performance, including ranking, cumulative sum, mean tax rate, and the percentage of provinces with tax.
SELECT
    order_year,
    order_month,
    msc.CountryRegionCode,
    msc.Region,
    msc.number_orders,
    msc.number_customers,
    msc.no_salesPersons,
    ROUND(msc.Total_w_tax, 2) AS Total_w_tax,
    RANK() OVER (PARTITION BY msc.CountryRegionCode ORDER BY msc.Total_w_tax DESC) AS sales_rank,
    ROUND(SUM(msc.Total_w_tax) OVER (PARTITION BY msc.CountryRegionCode ORDER BY msc.order_year, msc.order_month), 2) AS cumulative_sum,
    COALESCE(ROUND(AVG(tr.max_tax_rate), 2), 0) AS mean_tax_rate,
    COALESCE(ROUND((pw.provinces_with_tax / pw.total_provinces), 2), 0) AS perc_provinces_w_tax
FROM
    MonthlySalesCTE msc
LEFT JOIN
    MaxTaxRates tr ON msc.CountryRegionCode = tr.CountryRegionCode
LEFT JOIN
    ProvincesWithTax pw ON msc.CountryRegionCode = pw.CountryRegionCode
GROUP BY
    order_year,
    order_month,
    msc.CountryRegionCode,
    msc.Region,
    msc.number_orders,
    msc.number_customers,
    msc.no_salesPersons,
    msc.Total_w_tax,
    pw.provinces_with_tax,
    pw.total_provinces

-- ORDER BY Clause: Sorts the results based on CountryRegionCode and Region.
ORDER BY
    CountryRegionCode,
    Region;
