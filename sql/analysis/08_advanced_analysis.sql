-- ============================================================================
-- Script Name:   08_advanced_analysis.sql
-- Task Number:   Task 8.8 - Advanced SQL Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Purpose:       Demonstrates portfolio-quality advanced analytical SQL techniques
--                applied to the enterprise star schema. Includes running totals,
--                month-over-month LAG analysis, rolling moving averages, intra-category
--                and intra-regional ROW_NUMBER partitions, customer cumulative spend
--                distributions, category revenue contribution window calculations,
--                conditional aggregation across promotional discount tiers, and customer
--                lifecycle/first-transaction sequencing.
-- Target Tables: dbo.FactSales, dbo.DimCustomer, dbo.DimProduct, dbo.DimStore, dbo.DimDate
-- Execution Note: All queries are strictly READ-ONLY analytical SELECT queries.
--                 No database modification (INSERT/UPDATE/DELETE/ALTER/DROP) is performed.
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. Monthly Sales Trend with Running Total
-- Analytical Question: What is the cumulative top-line revenue and net profit trajectory
--                      as monthly sales accumulate chronologically across the reporting horizon?
-- What It Calculates: Monthly revenue, monthly net profit, and progressive cumulative
--                     running totals across months for both revenue and profit.
-- Advanced Technique Demonstrated: 
--   - Single-stage CTE separating base aggregation from window calculations.
--   - Window Frame Specification: 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW'
--     causes the SUM() aggregate function to accumulate all values from the start of the
--     partition up to the current row, producing a strict chronological running total.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlySalesBase AS (
    SELECT 
        d.[Year],
        d.[Month],
        d.MonthName,
        SUM(f.SalesAmount) AS MonthlyRevenue,
        SUM(f.Profit) AS MonthlyProfit
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d 
        ON f.DateKey = d.DateKey
    GROUP BY 
        d.[Year],
        d.[Month],
        d.MonthName
)
SELECT 
    [Year],
    [Month],
    MonthName,
    MonthlyRevenue,
    MonthlyProfit,
    SUM(MonthlyRevenue) OVER (
        ORDER BY [Year] ASC, [Month] ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeRevenue,
    SUM(MonthlyProfit) OVER (
        ORDER BY [Year] ASC, [Month] ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeProfit
FROM MonthlySalesBase
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 2. Month-over-Month (MoM) Revenue Change
-- Analytical Question: By how much did net sales revenue increase or decrease compared
--                      to the immediately preceding calendar month in absolute and percentage terms?
-- What It Calculates: Current monthly revenue, prior month revenue, monetary variance,
--                     and percentage growth rate.
-- Advanced Technique Demonstrated:
--   - Multiple CTE pipeline ('MonthlyRevenueBase' -> 'MonthlyRevenueWithLag').
--   - LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month) looks back exactly one row
--     in chronological sequence without requiring self-joins.
--   - First calendar month safely evaluates to NULL for PreviousMonthRevenue and percentage change.
--   - NULLIF() prevents division-by-zero errors in growth rate calculations.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyRevenueBase AS (
    SELECT 
        d.[Year],
        d.[Month],
        d.MonthName,
        SUM(f.SalesAmount) AS MonthlyRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d 
        ON f.DateKey = d.DateKey
    GROUP BY 
        d.[Year],
        d.[Month],
        d.MonthName
),
MonthlyRevenueWithLag AS (
    SELECT 
        [Year],
        [Month],
        MonthName,
        MonthlyRevenue,
        LAG(MonthlyRevenue, 1) OVER (
            ORDER BY [Year] ASC, [Month] ASC
        ) AS PreviousMonthRevenue
    FROM MonthlyRevenueBase
)
SELECT 
    [Year],
    [Month],
    MonthName,
    MonthlyRevenue,
    PreviousMonthRevenue,
    (MonthlyRevenue - PreviousMonthRevenue) AS RevenueChange,
    ROUND(((MonthlyRevenue - PreviousMonthRevenue) * 100.0) / NULLIF(PreviousMonthRevenue, 0), 2) AS RevenueChangePercentage
FROM MonthlyRevenueWithLag
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 3. Month-over-Month (MoM) Profit Change
-- Analytical Question: How does net gross profit fluctuate month-over-month, and what is
--                      the percentage velocity of profit expansion or contraction?
-- What It Calculates: Monthly net profit, previous month profit, dollar profit variance,
--                     and MoM percentage profit growth rate.
-- Advanced Technique Demonstrated:
--   - Multi-stage CTE pattern isolating monthly aggregation and temporal lead/lag evaluation.
--   - LAG(MonthlyProfit, 1) to inspect previous period profit without complex temporal join keys.
--   - NULLIF() defensive arithmetic preventing division-by-zero crashes when previous profit is 0.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyProfitBase AS (
    SELECT 
        d.[Year],
        d.[Month],
        d.MonthName,
        SUM(f.Profit) AS MonthlyProfit
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d 
        ON f.DateKey = d.DateKey
    GROUP BY 
        d.[Year],
        d.[Month],
        d.MonthName
),
MonthlyProfitWithLag AS (
    SELECT 
        [Year],
        [Month],
        MonthName,
        MonthlyProfit,
        LAG(MonthlyProfit, 1) OVER (
            ORDER BY [Year] ASC, [Month] ASC
        ) AS PreviousMonthProfit
    FROM MonthlyProfitBase
)
SELECT 
    [Year],
    [Month],
    MonthName,
    MonthlyProfit,
    PreviousMonthProfit,
    (MonthlyProfit - PreviousMonthProfit) AS ProfitChange,
    ROUND(((MonthlyProfit - PreviousMonthProfit) * 100.0) / NULLIF(PreviousMonthProfit, 0), 2) AS ProfitChangePercentage
FROM MonthlyProfitWithLag
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 4. Rolling 3-Month Moving Average of Revenue
-- Analytical Question: What is the smoothed medium-term revenue trend after filtering out
--                      short-term monthly volatility and seasonality?
-- What It Calculates: Actual monthly revenue alongside a trailing 3-month simple moving average.
-- Advanced Technique Demonstrated:
--   - Moving Window Frame: 'ROWS BETWEEN 2 PRECEDING AND CURRENT ROW'
--     Instructs SQL Server to average the current monthly value and the 2 immediately prior rows
--     (3 monthly points in total). For the first two months, the window dynamically sizes
--     to available rows (1 row for Month 1, 2 rows for Month 2) without producing NULLs.
--   - ROUND() ensures clean financial presentation.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyRevenueBase AS (
    SELECT 
        d.[Year],
        d.[Month],
        d.MonthName,
        SUM(f.SalesAmount) AS MonthlyRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d 
        ON f.DateKey = d.DateKey
    GROUP BY 
        d.[Year],
        d.[Month],
        d.MonthName
)
SELECT 
    [Year],
    [Month],
    MonthName,
    MonthlyRevenue,
    ROUND(AVG(MonthlyRevenue) OVER (
        ORDER BY [Year] ASC, [Month] ASC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS ThreeMonthMovingAverage
FROM MonthlyRevenueBase
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 5. Top Product per Category (Intra-Category Leader)
-- Analytical Question: Which specific merchandise product SKU generates the single highest
--                      revenue within each distinct product category?
-- What It Calculates: Category name, product ID, product name, total revenue, and ranking = 1.
-- Advanced Technique Demonstrated:
--   - PARTITION BY: Divides the dataset into distinct independent groups (by Category).
--   - ROW_NUMBER(): Generates sequential integers (1, 2, 3...) restarting at 1 for each
--     category partition, ordered by TotalRevenue descending with ProductID tie-breaker.
--   - CTE Filtering: Outer query filters 'WHERE RevenueRankWithinCategory = 1', dynamically
--     extracting category leaders without hard-coded catalog lookups.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
WITH ProductRevenueByCategory AS (
    SELECT 
        p.Category,
        p.ProductID,
        p.ProductName,
        SUM(f.SalesAmount) AS TotalRevenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.Category 
            ORDER BY SUM(f.SalesAmount) DESC, p.ProductID ASC
        ) AS RevenueRankWithinCategory
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.Category,
        p.ProductID,
        p.ProductName
)
SELECT 
    Category,
    ProductID,
    ProductName,
    TotalRevenue,
    RevenueRankWithinCategory
FROM ProductRevenueByCategory
WHERE 
    RevenueRankWithinCategory = 1
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 6. Top Store per Geographic Region (Intra-Regional Leader)
-- Analytical Question: Which individual retail store or channel generates the highest total
--                      revenue in each geographic operating sales region?
-- What It Calculates: Region name, store ID, store name, total revenue, and regional rank = 1.
-- Advanced Technique Demonstrated:
--   - PARTITION BY s.Region: Partitions store sales data by geographic sales region.
--   - ROW_NUMBER() OVER (PARTITION BY s.Region ORDER BY TotalRevenue DESC, StoreID ASC)
--     assigns unique ranks per region, resetting back to 1 across regional boundaries.
--   - Outer filter 'WHERE StoreRankWithinRegion = 1' retrieves top store per region.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
WITH StoreRevenueByRegion AS (
    SELECT 
        s.Region,
        s.StoreID,
        s.StoreName,
        SUM(f.SalesAmount) AS TotalRevenue,
        ROW_NUMBER() OVER (
            PARTITION BY s.Region 
            ORDER BY SUM(f.SalesAmount) DESC, s.StoreID ASC
        ) AS StoreRankWithinRegion
    FROM dbo.FactSales f
    INNER JOIN dbo.DimStore s 
        ON f.StoreID = s.StoreID
    GROUP BY 
        s.Region,
        s.StoreID,
        s.StoreName
)
SELECT 
    Region,
    StoreID,
    StoreName,
    TotalRevenue,
    StoreRankWithinRegion
FROM StoreRevenueByRegion
WHERE 
    StoreRankWithinRegion = 1
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 7. Customer Purchase Ranking
-- Analytical Question: How do individual retail customers rank across the entire enterprise
--                      based on total historical purchasing spend?
-- What It Calculates: Global customer revenue rank, customer ID, full customer name,
--                     and total historical spend.
-- Advanced Technique Demonstrated:
--   - DENSE_RANK() OVER (ORDER BY TotalRevenue DESC): Assigns consecutive rank positions
--     based on total spend without skipping numbers in the event of tied revenue figures.
--   - Multi-column deterministic sorting: ORDER BY RevenueRank ASC, CustomerID ASC.
-- Target Tables: dbo.FactSales, dbo.DimCustomer
-- ============================================================================
WITH CustomerRevenueBase AS (
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        SUM(f.SalesAmount) AS TotalRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimCustomer c 
        ON f.CustomerID = c.CustomerID
    GROUP BY 
        c.CustomerID,
        c.FirstName,
        c.LastName
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,
    CustomerID,
    CustomerName,
    TotalRevenue
FROM CustomerRevenueBase
ORDER BY 
    RevenueRank ASC,
    CustomerID ASC;
GO

-- ============================================================================
-- 8. Customer Cumulative Running Revenue & Contribution Percentage
-- Analytical Question: What is the cumulative Pareto revenue concentration curve across customers,
--                      and what percentage of enterprise revenue is contributed as we progress down the customer ranking?
-- What It Calculates: Customer ID, customer name, individual spend, cumulative running spend,
--                     and cumulative percentage of enterprise revenue contributed.
-- Advanced Technique Demonstrated:
--   - Multiple CTE pipeline structuring data layers.
--   - Running total window function: SUM(TotalRevenue) OVER (ORDER BY TotalRevenue DESC, CustomerID ASC
--     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW).
--   - Unpartitioned window aggregate: SUM(TotalRevenue) OVER () evaluates total enterprise revenue
--     across the entire dataset on every row without collapsing row granularity.
--   - Protected percentage ratio: ROUND((CumulativeRevenue * 100.0) / NULLIF(EnterpriseTotalRevenue, 0), 4).
-- Target Tables: dbo.FactSales, dbo.DimCustomer
-- ============================================================================
WITH CustomerRevenueBase AS (
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        SUM(f.SalesAmount) AS TotalRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimCustomer c 
        ON f.CustomerID = c.CustomerID
    GROUP BY 
        c.CustomerID,
        c.FirstName,
        c.LastName
),
CustomerRunningRevenueBase AS (
    SELECT 
        CustomerID,
        CustomerName,
        TotalRevenue,
        SUM(TotalRevenue) OVER (
            ORDER BY TotalRevenue DESC, CustomerID ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeRevenue,
        SUM(TotalRevenue) OVER () AS EnterpriseTotalRevenue
    FROM CustomerRevenueBase
)
SELECT 
    CustomerID,
    CustomerName,
    TotalRevenue,
    CumulativeRevenue,
    ROUND((CumulativeRevenue * 100.0) / NULLIF(EnterpriseTotalRevenue, 0), 4) AS CumulativeRevenuePercentage
FROM CustomerRunningRevenueBase
ORDER BY 
    TotalRevenue DESC,
    CustomerID ASC;
GO

-- ============================================================================
-- 9. Revenue Contribution by Merchandise Category
-- Analytical Question: What proportion of total company-wide revenue does each product
--                      category represent?
-- What It Calculates: Category name, total category revenue, and percentage share of enterprise sales.
-- Advanced Technique Demonstrated:
--   - Dynamic Grand Total Windowing: SUM(CategoryRevenue) OVER () calculates total enterprise sales
--     across all categories on the fly, eliminating the need for hard-coded denominators or subqueries.
--   - NULLIF() protection against zero denominators.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
WITH CategoryRevenueBase AS (
    SELECT 
        p.Category,
        SUM(f.SalesAmount) AS CategoryRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.Category
)
SELECT 
    Category,
    CategoryRevenue,
    ROUND((CategoryRevenue * 100.0) / NULLIF(SUM(CategoryRevenue) OVER (), 0), 2) AS RevenuePercentage
FROM CategoryRevenueBase
ORDER BY 
    CategoryRevenue DESC;
GO

-- ============================================================================
-- 10. Conditional Aggregation across Promotional Discount Tiers
-- Analytical Question: How is revenue distributed across promotional discount tiers
--                      (No Discount, Low, Medium, High) across geographic sales regions?
-- What It Calculates: Regional transaction volume, total regional revenue, and revenue broken
--                     down into four discrete discount tiers using inline boolean conditions.
-- Advanced Technique Demonstrated:
--   - Conditional Aggregation: SUM(CASE WHEN predicate THEN fact ELSE 0 END) aggregates
--     only rows satisfying specific conditions into separate columns in a single scan of the table.
--   - Uses the verified decimal discount representation:
--       - No Discount: Discount = 0.00
--       - Low Discount (1% - 10%): Discount > 0.00 AND Discount <= 0.10
--       - Medium Discount (11% - 20%): Discount > 0.10 AND Discount <= 0.20
--       - High Discount (> 20%): Discount > 0.20
--   - Computes percentage of regional revenue sold under discount promotions.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
SELECT 
    s.Region,
    COUNT(DISTINCT f.SalesID) AS TotalTransactions,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(CASE WHEN f.Discount = 0.00 THEN f.SalesAmount ELSE 0.00 END) AS NoDiscountRevenue,
    SUM(CASE WHEN f.Discount > 0.00 AND f.Discount <= 0.10 THEN f.SalesAmount ELSE 0.00 END) AS LowDiscountRevenue,
    SUM(CASE WHEN f.Discount > 0.10 AND f.Discount <= 0.20 THEN f.SalesAmount ELSE 0.00 END) AS MediumDiscountRevenue,
    SUM(CASE WHEN f.Discount > 0.20 THEN f.SalesAmount ELSE 0.00 END) AS HighDiscountRevenue,
    ROUND(SUM(CASE WHEN f.Discount > 0.00 THEN f.SalesAmount ELSE 0.00 END) * 100.0 / NULLIF(SUM(f.SalesAmount), 0), 2) AS DiscountedRevenuePercentage
FROM dbo.FactSales f
INNER JOIN dbo.DimStore s 
    ON f.StoreID = s.StoreID
GROUP BY 
    s.Region
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 11. Customer First and Last Purchase (Tenure & Activity Lifespan)
-- Analytical Question: What is the purchase activity window for each customer, and how many
--                      days elapsed between their very first purchase and their most recent order?
-- What It Calculates: Customer ID, customer name, first order date, last order date,
--                     days between first and last purchase, total order frequency, and total spend.
-- Advanced Technique Demonstrated:
--   - MIN(OrderDate) and MAX(OrderDate) aggregated per customer.
--   - DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)): Measures customer active relationship duration.
--   - WHERE EXISTS (correlated subquery): Enforces analytical safety ensuring only customers
--     with confirmed transaction records in FactSales are processed.
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
SELECT 
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    MIN(f.OrderDate) AS FirstPurchaseDate,
    MAX(f.OrderDate) AS LastPurchaseDate,
    DATEDIFF(DAY, MIN(f.OrderDate), MAX(f.OrderDate)) AS DaysBetweenFirstAndLastPurchase,
    COUNT(DISTINCT f.SalesID) AS TotalTransactions,
    SUM(f.SalesAmount) AS TotalCustomerSpend
FROM dbo.DimCustomer c
INNER JOIN dbo.FactSales f 
    ON c.CustomerID = f.CustomerID
WHERE EXISTS (
    SELECT 1 
    FROM dbo.FactSales fs 
    WHERE fs.CustomerID = c.CustomerID
)
GROUP BY 
    c.CustomerID,
    c.FirstName,
    c.LastName
ORDER BY 
    TotalCustomerSpend DESC,
    c.CustomerID ASC;
GO

-- ============================================================================
-- 12. First Transaction per Customer
-- Analytical Question: What was the exact initial transaction (SalesID, date, and sales amount)
--                      for every customer?
-- What It Calculates: Customer ID, the first transaction's SalesID, the initial transaction date,
--                     and the initial order monetary spend.
-- Advanced Technique Demonstrated:
--   - ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate ASC, SalesID ASC)
--     partitions all sales records per customer and ranks them sequentially from oldest to newest.
--   - Outer query filters 'WHERE TransactionSequenceNumber = 1' to isolate each customer's
--     true initial purchase event.
-- Target Table: dbo.FactSales
-- ============================================================================
WITH CustomerTransactionsRanked AS (
    SELECT 
        f.CustomerID,
        f.SalesID,
        f.OrderDate AS FirstTransactionDate,
        f.SalesAmount,
        ROW_NUMBER() OVER (
            PARTITION BY f.CustomerID 
            ORDER BY f.OrderDate ASC, f.SalesID ASC
        ) AS TransactionSequenceNumber
    FROM dbo.FactSales f
)
SELECT 
    CustomerID,
    SalesID,
    FirstTransactionDate,
    SalesAmount
FROM CustomerTransactionsRanked
WHERE 
    TransactionSequenceNumber = 1
ORDER BY 
    FirstTransactionDate ASC,
    SalesID ASC;
GO
