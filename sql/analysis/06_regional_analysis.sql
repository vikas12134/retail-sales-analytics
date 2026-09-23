-- ============================================================================
-- Script Name:   06_regional_analysis.sql
-- Task Number:   Task 8.6 - Regional Performance Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Purpose:       Comprehensive regional performance analysis evaluating revenue,
--                cost, profit, unit volume, and transaction frequency across
--                geographic sales regions. Features regional revenue and profit
--                rankings, intra-regional store performance and ranking, top
--                store identification per region, chronological monthly trend
--                analysis, and a consolidated multi-metric regional summary.
-- Target Tables: dbo.FactSales, dbo.DimStore, dbo.DimDate
-- Execution Note: All queries are strictly READ-ONLY analytical SELECT queries.
--                 No database modification (INSERT/UPDATE/DELETE/ALTER/DROP) is performed.
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. Regional Revenue Analysis
-- 1. Business Question: Which geographic regions generate the most revenue?
-- 2. What It Calculates: Total revenue, distinct transaction count, and physical
--                        units sold aggregated by geographic sales region.
-- 3. Main SQL Technique: INNER JOIN, multi-column aggregation (SUM, COUNT DISTINCT),
--                        GROUP BY, and descending metric sorting.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
SELECT 
    s.Region,
    SUM(f.SalesAmount) AS TotalRevenue,
    COUNT(DISTINCT f.SalesID) AS NumberOfTransactions,
    SUM(f.Quantity) AS TotalQuantitySold
FROM dbo.FactSales f
INNER JOIN dbo.DimStore s 
    ON f.StoreID = s.StoreID
GROUP BY 
    s.Region
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 2. Regional Profitability
-- 1. Business Question: Which geographic regions generate the most net profit,
--                       and what are their respective profit margins?
-- 2. What It Calculates: Total revenue, COGS (TotalCost), net gross profit (TotalProfit),
--                        and net profit margin percentage per geographic sales region.
-- 3. Main SQL Technique: Aggregate financial arithmetic, NULLIF() division-by-zero
--                        protection, ROUND(), GROUP BY, and descending profit sort.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
SELECT 
    s.Region,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    ROUND((SUM(f.Profit) * 100.0) / NULLIF(SUM(f.SalesAmount), 0), 2) AS ProfitMarginPercentage
FROM dbo.FactSales f
INNER JOIN dbo.DimStore s 
    ON f.StoreID = s.StoreID
GROUP BY 
    s.Region
ORDER BY 
    TotalProfit DESC;
GO

-- ============================================================================
-- 3. Regional Revenue Ranking
-- 1. Business Question: How do geographic regions rank relative to one another
--                       in terms of total sales revenue?
-- 2. What It Calculates: Dense ordinal ranking (RevenueRank) of each geographic
--                        sales region ordered by total sales revenue.
-- 3. Main SQL Technique: Common Table Expression (CTE) for clean aggregation,
--                        DENSE_RANK() window function without partitioning,
--                        and deterministic rank ordering.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
WITH RegionalRevenueBase AS (
    SELECT 
        s.Region,
        SUM(f.SalesAmount) AS TotalRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimStore s 
        ON f.StoreID = s.StoreID
    GROUP BY 
        s.Region
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,
    Region,
    TotalRevenue
FROM RegionalRevenueBase
ORDER BY 
    RevenueRank ASC;
GO

-- ============================================================================
-- 4. Regional Profit Ranking
-- 1. Business Question: How do geographic regions rank relative to one another
--                       in terms of total net profit?
-- 2. What It Calculates: Dense ordinal ranking (ProfitRank) of each geographic
--                        sales region ordered by total net gross profit.
-- 3. Main SQL Technique: Common Table Expression (CTE) pre-aggregation,
--                        DENSE_RANK() window function, and ascending rank sort.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
WITH RegionalProfitBase AS (
    SELECT 
        s.Region,
        SUM(f.Profit) AS TotalProfit
    FROM dbo.FactSales f
    INNER JOIN dbo.DimStore s 
        ON f.StoreID = s.StoreID
    GROUP BY 
        s.Region
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalProfit DESC) AS ProfitRank,
    Region,
    TotalProfit
FROM RegionalProfitBase
ORDER BY 
    ProfitRank ASC;
GO

-- ============================================================================
-- 5. Store Performance Within Regions
-- 1. Business Question: How does each individual store perform within its home
--                       geographic region, and what is its intra-regional rank?
-- 2. What It Calculates: Store-level revenue, profit, transaction count, and the
--                        store's revenue rank scoped strictly within its region.
-- 3. Main SQL Technique: CTE for store-level aggregation, window function with
--                        PARTITION BY region and ORDER BY revenue, followed by
--                        hierarchical multi-column ordering.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
WITH StoreRegionalPerformanceBase AS (
    SELECT 
        s.Region,
        s.StoreID,
        s.StoreName,
        SUM(f.SalesAmount) AS TotalRevenue,
        SUM(f.Profit) AS TotalProfit,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
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
    TotalProfit,
    NumberOfTransactions,
    DENSE_RANK() OVER (
        PARTITION BY Region 
        ORDER BY TotalRevenue DESC
    ) AS StoreRevenueRankWithinRegion
FROM StoreRegionalPerformanceBase
ORDER BY 
    Region ASC,
    StoreRevenueRankWithinRegion ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 6. Top Store in Each Region
-- 1. Business Question: Which retail location is the top-performing store by
--                       revenue within each geographic region?
-- 2. What It Calculates: The store with rank #1 in total sales revenue for every
--                        geographic region, dynamically without hardcoded IDs.
-- 3. Main SQL Technique: CTE with DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...),
--                        outer query filtering on rank = 1, and descending revenue sort.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
WITH RankedStoresPerRegion AS (
    SELECT 
        s.Region,
        s.StoreID,
        s.StoreName,
        SUM(f.SalesAmount) AS TotalRevenue,
        DENSE_RANK() OVER (
            PARTITION BY s.Region 
            ORDER BY SUM(f.SalesAmount) DESC
        ) AS RevenueRankWithinRegion
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
    RevenueRankWithinRegion
FROM RankedStoresPerRegion
WHERE 
    RevenueRankWithinRegion = 1
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 7. Regional Sales Over Time
-- 1. Business Question: How do revenue and profitability evolve across geographic
--                       regions on a chronological monthly timeline?
-- 2. What It Calculates: Monthly net revenue and monthly net profit for each
--                        sales region across the two-year reporting period.
-- 3. Main SQL Technique: 3-table relational INNER JOIN (FactSales, DimStore, DimDate),
--                        multi-level temporal grouping, and chronological sorting.
-- Target Tables: dbo.FactSales, dbo.DimStore, dbo.DimDate
-- ============================================================================
SELECT 
    d.[Year],
    d.[Month],
    d.MonthName,
    d.MonthYear,
    s.Region,
    SUM(f.SalesAmount) AS MonthlyRevenue,
    SUM(f.Profit) AS MonthlyProfit
FROM dbo.FactSales f
INNER JOIN dbo.DimStore s 
    ON f.StoreID = s.StoreID
INNER JOIN dbo.DimDate d 
    ON f.DateKey = d.DateKey
GROUP BY 
    d.[Year],
    d.[Month],
    d.MonthName,
    d.MonthYear,
    s.Region
ORDER BY 
    d.[Year] ASC,
    d.[Month] ASC,
    s.Region ASC;
GO

-- ============================================================================
-- 8. Regional Performance Summary
-- 1. Business Question: What is the consolidated executive overview of sales, cost,
--                       profit, transaction volume, unit volume, average transaction
--                       value, margin percentages, and enterprise ranks across all regions?
-- 2. What It Calculates: Comprehensive regional metrics matrix including TotalRevenue,
--                        TotalCost, TotalProfit, TotalQuantitySold, NumberOfTransactions,
--                        AverageTransactionValue, ProfitMarginPercentage, RevenueRank,
--                        and ProfitRank.
-- 3. Main SQL Technique: Multi-metric CTE aggregation, dual window functions for
--                        parallel rankings, NULLIF() defensive division handling,
--                        ROUND() precision formatting, and rank-ordered presentation.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================
WITH RegionalSummaryBase AS (
    SELECT 
        s.Region,
        SUM(f.SalesAmount) AS TotalRevenue,
        SUM(f.CostAmount) AS TotalCost,
        SUM(f.Profit) AS TotalProfit,
        SUM(f.Quantity) AS TotalQuantitySold,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
    FROM dbo.FactSales f
    INNER JOIN dbo.DimStore s 
        ON f.StoreID = s.StoreID
    GROUP BY 
        s.Region
)
SELECT 
    Region,
    TotalRevenue,
    TotalCost,
    TotalProfit,
    TotalQuantitySold,
    NumberOfTransactions,
    ROUND(TotalRevenue / NULLIF(NumberOfTransactions, 0), 2) AS AverageTransactionValue,
    ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMarginPercentage,
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,
    DENSE_RANK() OVER (ORDER BY TotalProfit DESC) AS ProfitRank
FROM RegionalSummaryBase
ORDER BY 
    RevenueRank ASC;
GO
