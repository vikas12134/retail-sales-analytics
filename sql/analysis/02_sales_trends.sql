-- ============================================================================
-- Script Name:   02_sales_trends.sql
-- Task Number:   Task 8.2 - Sales Trends Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Purpose:       Comprehensive longitudinal sales trends analysis evaluating revenue,
--                profit, unit volume, and order velocity across calendar dimensions.
--                Includes monthly, quarterly, and annual performance trends,
--                period-over-period growth rates (MoM and YoY), running cumulative
--                totals, monthly seasonality indices, and peak/trough sales identification.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- Execution Note: All queries are strictly READ-ONLY analytical SELECT queries.
--                 No database modification (INSERT/UPDATE/DELETE/ALTER/DROP) is performed.
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. Monthly Sales Trend
-- Analytical Question: How do revenue, net profit, unit sales volume, and transaction
--                      frequency trend on a month-by-month basis?
-- What It Calculates: Monthly revenue, monthly net profit, total units sold, and distinct
--                     transaction count for each chronological year and month.
-- SQL Technique: Relational INNER JOIN between FactSales and DimDate, multi-measure
--                aggregations (SUM, COUNT DISTINCT), multi-column GROUP BY, and chronological sorting.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
SELECT 
    d.[Year],
    d.[Month],
    d.MonthName,
    SUM(f.SalesAmount) AS MonthlyRevenue,
    SUM(f.Profit) AS MonthlyProfit,
    SUM(f.Quantity) AS MonthlyQuantitySold,
    COUNT(DISTINCT f.SalesID) AS TransactionCount
FROM dbo.FactSales f
INNER JOIN dbo.DimDate d 
    ON f.DateKey = d.DateKey
GROUP BY 
    d.[Year],
    d.[Month],
    d.MonthName
ORDER BY 
    d.[Year] ASC,
    d.[Month] ASC;
GO

-- ============================================================================
-- 2. Yearly Sales Trend
-- Analytical Question: What is the high-level annual macro performance across revenue,
--                      profitability, unit volume, and transaction scale?
-- What It Calculates: Annual aggregated revenue, annual net profit, annual physical
--                     units sold, and annual distinct transaction volume.
-- SQL Technique: Calendar year aggregation, SUM() and COUNT(DISTINCT) aggregations,
--                GROUP BY d.[Year], and ascending chronological ordering.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
SELECT 
    d.[Year],
    SUM(f.SalesAmount) AS Revenue,
    SUM(f.Profit) AS Profit,
    SUM(f.Quantity) AS QuantitySold,
    COUNT(DISTINCT f.SalesID) AS TransactionCount
FROM dbo.FactSales f
INNER JOIN dbo.DimDate d 
    ON f.DateKey = d.DateKey
GROUP BY 
    d.[Year]
ORDER BY 
    d.[Year] ASC;
GO

-- ============================================================================
-- 3. Quarterly Sales Trend
-- Analytical Question: How does business performance fluctuate across commercial quarters?
-- What It Calculates: Quarterly sales revenue, quarterly net profit, and physical units sold.
-- SQL Technique: Multi-level aggregation grouping by calendar year and fiscal quarter,
--                incorporating DimDate.QuarterName for standardized quarterly labeling.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
SELECT 
    d.[Year],
    d.[Quarter],
    d.QuarterName,
    SUM(f.SalesAmount) AS Revenue,
    SUM(f.Profit) AS Profit,
    SUM(f.Quantity) AS QuantitySold
FROM dbo.FactSales f
INNER JOIN dbo.DimDate d 
    ON f.DateKey = d.DateKey
GROUP BY 
    d.[Year],
    d.[Quarter],
    d.QuarterName
ORDER BY 
    d.[Year] ASC,
    d.[Quarter] ASC;
GO

-- ============================================================================
-- 4. Month-over-Month (MoM) Sales Growth
-- Analytical Question: What is the monthly top-line revenue growth or contraction
--                      compared to the immediately preceding month?
-- What It Calculates: Current monthly revenue, previous month revenue, dollar revenue
--                     variance, and percentage growth rate.
-- SQL Technique: Common Table Expression (CTE) isolating monthly aggregation,
--                LAG(MonthlyRevenue, 1) window function to retrieve prior row's revenue,
--                first-period NULL handling, and NULLIF() division-by-zero protection.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlySalesBase AS (
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
MonthlySalesLag AS (
    SELECT 
        [Year],
        [Month],
        MonthName,
        MonthlyRevenue,
        LAG(MonthlyRevenue, 1) OVER (
            ORDER BY [Year] ASC, [Month] ASC
        ) AS PreviousMonthRevenue
    FROM MonthlySalesBase
)
SELECT 
    [Year],
    [Month],
    MonthName,
    MonthlyRevenue,
    PreviousMonthRevenue,
    (MonthlyRevenue - PreviousMonthRevenue) AS MoMRevenueGrowth,
    ROUND(((MonthlyRevenue - PreviousMonthRevenue) * 100.0) / NULLIF(PreviousMonthRevenue, 0), 2) AS MoMRevenueGrowthPct
FROM MonthlySalesLag
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 5. Month-over-Month (MoM) Profit Growth
-- Analytical Question: By what magnitude and percentage does net profit increase
--                      or decrease between consecutive calendar months?
-- What It Calculates: Monthly profit, previous month profit, dollar profit variance,
--                     and MoM percentage profit growth rate.
-- SQL Technique: CTE separating aggregation from analytical offset calculation,
--                LAG(MonthlyProfit, 1) over chronological order, and NULLIF() safe division.
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
MonthlyProfitLag AS (
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
    (MonthlyProfit - PreviousMonthProfit) AS MoMProfitGrowth,
    ROUND(((MonthlyProfit - PreviousMonthProfit) * 100.0) / NULLIF(PreviousMonthProfit, 0), 2) AS MoMProfitGrowthPct
FROM MonthlyProfitLag
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 6. Running / Cumulative Revenue Over Time
-- Analytical Question: What is the cumulative revenue accumulated from the beginning
--                      of the historical dataset to each monthly milestone?
-- What It Calculates: Monthly net revenue alongside a progressive chronological running total.
-- SQL Technique: CTE aggregating monthly revenue, followed by window aggregate
--                SUM(MonthlyRevenue) OVER (ORDER BY Year, Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW).
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyRevenueSummary AS (
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
    SUM(MonthlyRevenue) OVER (
        ORDER BY [Year] ASC, [Month] ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeRevenue
FROM MonthlyRevenueSummary
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 7. Running / Cumulative Profit Over Time
-- Analytical Question: What is the cumulative net profit generated by the business
--                      as time progresses through the entire reporting period?
-- What It Calculates: Monthly net profit alongside an unbroken cumulative running total.
-- SQL Technique: CTE pre-aggregation, window frame specification
--                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW on SUM(MonthlyProfit).
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyProfitSummary AS (
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
)
SELECT 
    [Year],
    [Month],
    MonthName,
    MonthlyProfit,
    SUM(MonthlyProfit) OVER (
        ORDER BY [Year] ASC, [Month] ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeProfit
FROM MonthlyProfitSummary
ORDER BY 
    [Year] ASC,
    [Month] ASC;
GO

-- ============================================================================
-- 8. Seasonality Analysis
-- Analytical Question: Which calendar months historically demonstrate higher vs. lower
--                      commercial sales and profit performance across years?
-- What It Calculates: Aggregated revenue, profit, units sold, transaction count,
--                     relative revenue rank (1 = highest sales month), and seasonal classification tier.
-- SQL Technique: Grouping across multi-year data strictly by calendar month number and name,
--                DENSE_RANK() OVER (ORDER BY SUM(SalesAmount) DESC) for seasonality ranking,
--                and conditional CASE classification for peak vs. trough identification.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlySeasonalityBase AS (
    SELECT 
        d.[Month],
        d.MonthName,
        SUM(f.SalesAmount) AS TotalRevenue,
        SUM(f.Profit) AS TotalProfit,
        SUM(f.Quantity) AS TotalQuantitySold,
        COUNT(DISTINCT f.SalesID) AS TransactionCount
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d 
        ON f.DateKey = d.DateKey
    GROUP BY 
        d.[Month],
        d.MonthName
)
SELECT 
    [Month],
    MonthName,
    TotalRevenue,
    TotalProfit,
    TotalQuantitySold,
    TransactionCount,
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS SeasonalityRevenueRank,
    CASE 
        WHEN DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) <= 3 THEN 'High Season (Peak Months)'
        WHEN DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) >= 10 THEN 'Low Season (Trough Months)'
        ELSE 'Moderate Season'
    END AS SeasonalityTier
FROM MonthlySeasonalityBase
ORDER BY 
    [Month] ASC;
GO

-- ============================================================================
-- 9. Year-over-Year (YoY) Comparison
-- Analytical Question: How does commercial revenue and net profit compare for identical
--                      calendar months between the baseline year (2023) and comparison year (2024)?
-- What It Calculates: 2023 revenue, 2024 revenue, dollar revenue variance, percentage revenue growth,
--                     2023 profit, 2024 profit, dollar profit variance, and percentage profit growth.
-- SQL Technique: CTE aggregating monthly revenue and profit by Year and Month,
--                conditional aggregation (SUM(CASE WHEN Year = ...)) pivoting years side-by-side,
--                and NULLIF() defensive division handling.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyAggregates AS (
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
    [Month],
    MonthName,
    SUM(CASE WHEN [Year] = 2023 THEN MonthlyRevenue ELSE 0.00 END) AS Revenue_2023,
    SUM(CASE WHEN [Year] = 2024 THEN MonthlyRevenue ELSE 0.00 END) AS Revenue_2024,
    (SUM(CASE WHEN [Year] = 2024 THEN MonthlyRevenue ELSE 0.00 END) - 
     SUM(CASE WHEN [Year] = 2023 THEN MonthlyRevenue ELSE 0.00 END)) AS YoYRevenueGrowth,
    ROUND(
        ((SUM(CASE WHEN [Year] = 2024 THEN MonthlyRevenue ELSE 0.00 END) - 
          SUM(CASE WHEN [Year] = 2023 THEN MonthlyRevenue ELSE 0.00 END)) * 100.0) /
        NULLIF(SUM(CASE WHEN [Year] = 2023 THEN MonthlyRevenue ELSE 0.00 END), 0),
        2
    ) AS YoYRevenueGrowthPct,
    SUM(CASE WHEN [Year] = 2023 THEN MonthlyProfit ELSE 0.00 END) AS Profit_2023,
    SUM(CASE WHEN [Year] = 2024 THEN MonthlyProfit ELSE 0.00 END) AS Profit_2024,
    (SUM(CASE WHEN [Year] = 2024 THEN MonthlyProfit ELSE 0.00 END) - 
     SUM(CASE WHEN [Year] = 2023 THEN MonthlyProfit ELSE 0.00 END)) AS YoYProfitGrowth,
    ROUND(
        ((SUM(CASE WHEN [Year] = 2024 THEN MonthlyProfit ELSE 0.00 END) - 
          SUM(CASE WHEN [Year] = 2023 THEN MonthlyProfit ELSE 0.00 END)) * 100.0) /
        NULLIF(SUM(CASE WHEN [Year] = 2023 THEN MonthlyProfit ELSE 0.00 END), 0),
        2
    ) AS YoYProfitGrowthPct
FROM MonthlyAggregates
GROUP BY 
    [Month],
    MonthName
ORDER BY 
    [Month] ASC;
GO

-- ============================================================================
-- 10. Best and Worst Sales Periods
-- Analytical Question: Which specific calendar months registered the historical peaks
--                      and troughs in terms of top-line revenue and net gross profit?
-- What It Calculates: Identifies the single highest revenue month, lowest revenue month,
--                     highest profit month, and lowest profit month across the dataset.
-- SQL Technique: CTE monthly aggregation, multiple directional ROW_NUMBER() window functions
--                (Revenue ASC/DESC, Profit ASC/DESC), UNION ALL consolidation, and dynamic labeling.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
WITH MonthlyAggregates AS (
    SELECT 
        d.[Year],
        d.[Month],
        d.MonthName,
        d.MonthYear,
        SUM(f.SalesAmount) AS MonthlyRevenue,
        SUM(f.Profit) AS MonthlyProfit
    FROM dbo.FactSales f
    INNER JOIN dbo.DimDate d 
        ON f.DateKey = d.DateKey
    GROUP BY 
        d.[Year],
        d.[Month],
        d.MonthName,
        d.MonthYear
),
RankedMonthlyPerformance AS (
    SELECT 
        [Year],
        [Month],
        MonthName,
        MonthYear,
        MonthlyRevenue,
        MonthlyProfit,
        ROW_NUMBER() OVER (ORDER BY MonthlyRevenue DESC) AS RevenueDescRank,
        ROW_NUMBER() OVER (ORDER BY MonthlyRevenue ASC) AS RevenueAscRank,
        ROW_NUMBER() OVER (ORDER BY MonthlyProfit DESC) AS ProfitDescRank,
        ROW_NUMBER() OVER (ORDER BY MonthlyProfit ASC) AS ProfitAscRank
    FROM MonthlyAggregates
)
SELECT 
    'Highest Revenue Month' AS PeriodClassification,
    [Year],
    [Month],
    MonthName,
    MonthYear,
    MonthlyRevenue,
    MonthlyProfit
FROM RankedMonthlyPerformance
WHERE RevenueDescRank = 1

UNION ALL

SELECT 
    'Lowest Revenue Month' AS PeriodClassification,
    [Year],
    [Month],
    MonthName,
    MonthYear,
    MonthlyRevenue,
    MonthlyProfit
FROM RankedMonthlyPerformance
WHERE RevenueAscRank = 1

UNION ALL

SELECT 
    'Highest Profit Month' AS PeriodClassification,
    [Year],
    [Month],
    MonthName,
    MonthYear,
    MonthlyRevenue,
    MonthlyProfit
FROM RankedMonthlyPerformance
WHERE ProfitDescRank = 1

UNION ALL

SELECT 
    'Lowest Profit Month' AS PeriodClassification,
    [Year],
    [Month],
    MonthName,
    MonthYear,
    MonthlyRevenue,
    MonthlyProfit
FROM RankedMonthlyPerformance
WHERE ProfitAscRank = 1;
GO
