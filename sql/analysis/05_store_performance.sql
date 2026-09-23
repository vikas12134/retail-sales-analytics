-- ============================================================================
-- Script Name:   05_store_performance.sql
-- Task Number:   Task 8.5 - Store Performance Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Analysis Scope: Comprehensive store performance evaluation including gross revenue,
--                 COGS, net gross profit, unit quantity sold, distinct transaction
--                 volume, average transaction value (ATV), and profit margin percentages.
--                 Features rankings by revenue, profit, volume, and margin; channel/format
--                 and regional variance analysis; physical store retail footprint
--                 productivity (Sales/Profit per Sq Ft); and a read-only data quality audit suite.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- Execution Note: All queries are strictly READ-ONLY analytical SELECT queries.
--                 No database modification (INSERT/UPDATE/DELETE/ALTER/DROP) is performed.
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. Store-Level Performance Overview
-- Business Question: What is the comprehensive sales, cost, and profit performance
--                    for each individual retail store and digital channel?
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreSalesSummary AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        s.City,
        s.Region,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.CostAmount), 0.00) AS TotalCost,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit,
        COALESCE(SUM(f.Quantity), 0) AS TotalQuantitySold,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreID,
        s.StoreName,
        s.City,
        s.Region
)
SELECT 
    StoreID,
    StoreName,
    City,
    Region,
    TotalRevenue,
    TotalCost,
    TotalProfit,
    TotalQuantitySold,
    NumberOfTransactions,
    ROUND(TotalRevenue / NULLIF(NumberOfTransactions, 0), 2) AS AverageTransactionValue,
    ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMargin
FROM StoreSalesSummary
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 2. Store Revenue Ranking
-- Business Question: Which stores generate the highest total revenue across the enterprise?
-- Window Function: DENSE_RANK() OVER (ORDER BY TotalRevenue DESC)
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreRevenueRankBase AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreID,
        s.StoreName
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS StoreRank,
    StoreID,
    StoreName,
    TotalRevenue,
    TotalProfit,
    NumberOfTransactions
FROM StoreRevenueRankBase
ORDER BY 
    StoreRank ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 3. Store Profit Ranking
-- Business Question: Which stores generate the highest total net profit?
-- Window Function: DENSE_RANK() OVER (ORDER BY TotalProfit DESC)
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreProfitRankBase AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreID,
        s.StoreName
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalProfit DESC) AS StoreRank,
    StoreID,
    StoreName,
    TotalRevenue,
    TotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMargin
FROM StoreProfitRankBase
ORDER BY 
    StoreRank ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 4. Store Quantity Sold Ranking (Product Volume)
-- Business Question: Which stores sell the highest physical volume of products?
-- Window Function: DENSE_RANK() OVER (ORDER BY TotalQuantitySold DESC)
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreQuantityRankBase AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        COALESCE(SUM(f.Quantity), 0) AS TotalQuantitySold,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreID,
        s.StoreName
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalQuantitySold DESC) AS StoreRank,
    StoreID,
    StoreName,
    TotalQuantitySold,
    TotalRevenue,
    NumberOfTransactions
FROM StoreQuantityRankBase
ORDER BY 
    StoreRank ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 5. Store Transaction Performance & Ranking
-- Business Question: Which stores have the highest volume of completed sales transactions,
--                    and what is the average transaction size at each store?
-- Window Function: DENSE_RANK() OVER (ORDER BY NumberOfTransactions DESC)
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreTransactionBase AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreID,
        s.StoreName
)
SELECT 
    DENSE_RANK() OVER (ORDER BY NumberOfTransactions DESC) AS StoreRank,
    StoreID,
    StoreName,
    NumberOfTransactions,
    TotalRevenue,
    ROUND(TotalRevenue / NULLIF(NumberOfTransactions, 0), 2) AS AverageTransactionValue
FROM StoreTransactionBase
ORDER BY 
    StoreRank ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 6. Store Profit Margin Ranking
-- Business Question: Which stores operate at the highest profitability margins?
-- Methodology: Ranks stores by net margin percentage, safely excluding zero-revenue stores.
-- Window Function: DENSE_RANK() OVER (ORDER BY ProfitMargin DESC)
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreMarginBase AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.CostAmount), 0.00) AS TotalCost,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreID,
        s.StoreName
),
StoreMarginCalculations AS (
    SELECT 
        StoreID,
        StoreName,
        TotalRevenue,
        TotalCost,
        TotalProfit,
        ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMargin
    FROM StoreMarginBase
    WHERE TotalRevenue > 0.00
)
SELECT 
    DENSE_RANK() OVER (ORDER BY ProfitMargin DESC) AS StoreRank,
    StoreID,
    StoreName,
    TotalRevenue,
    TotalCost,
    TotalProfit,
    ProfitMargin
FROM StoreMarginCalculations
ORDER BY 
    StoreRank ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 7. Store Performance Variance Across Store Types (Formats)
-- Business Question: How does store performance vary across physical and digital formats
--                    (Online, Flagship Store, Mall Outlet, Standalone Store, Express Store)?
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH StoreTypeAggregates AS (
    SELECT 
        s.StoreType,
        COUNT(DISTINCT s.StoreID) AS StoreCount,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.CostAmount), 0.00) AS TotalCost,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit,
        COALESCE(SUM(f.Quantity), 0) AS TotalUnitsSold,
        COUNT(DISTINCT f.SalesID) AS TotalTransactions
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.StoreType
)
SELECT 
    StoreType,
    StoreCount,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctTotalRevenue,
    TotalCost,
    TotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(SUM(TotalProfit) OVER (), 0), 2) AS PctTotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMargin,
    TotalUnitsSold,
    TotalTransactions,
    ROUND(TotalRevenue / NULLIF(TotalTransactions, 0), 2) AS AverageTransactionValue,
    ROUND(TotalRevenue / NULLIF(StoreCount, 0), 2) AS RevenuePerStore
FROM StoreTypeAggregates
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 8. Store Performance Variance Across Regions
-- Business Question: How do store revenue, transaction count, and profitability
--                    distribute geographically across sales regions?
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH RegionalStoreAggregates AS (
    SELECT 
        s.Region,
        COUNT(DISTINCT s.StoreID) AS StoreCount,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.CostAmount), 0.00) AS TotalCost,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit,
        COALESCE(SUM(f.Quantity), 0) AS TotalUnitsSold,
        COUNT(DISTINCT f.SalesID) AS TotalTransactions
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY 
        s.Region
)
SELECT 
    Region,
    StoreCount,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctTotalRevenue,
    TotalCost,
    TotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(SUM(TotalProfit) OVER (), 0), 2) AS PctTotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMargin,
    TotalUnitsSold,
    TotalTransactions,
    ROUND(TotalRevenue / NULLIF(TotalTransactions, 0), 2) AS AverageTransactionValue,
    ROUND(TotalRevenue / NULLIF(StoreCount, 0), 2) AS RevenuePerStore
FROM RegionalStoreAggregates
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 9. Physical Store Productivity: Sales and Profit per Square Foot
-- Business Question: Which physical retail locations generate the highest revenue
--                    and profit density relative to their floor area?
-- Methodology: Restricts to physical stores (SquareFootage > 0, excluding Online).
-- Target Tables: dbo.DimStore, dbo.FactSales
-- ============================================================================
WITH PhysicalStoreSales AS (
    SELECT 
        s.StoreID,
        s.StoreName,
        s.StoreType,
        s.City,
        s.Region,
        s.SquareFootage,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    WHERE 
        s.SquareFootage > 0
    GROUP BY 
        s.StoreID,
        s.StoreName,
        s.StoreType,
        s.City,
        s.Region,
        s.SquareFootage
),
PhysicalStoreProductivity AS (
    SELECT 
        StoreID,
        StoreName,
        StoreType,
        City,
        Region,
        SquareFootage,
        TotalRevenue,
        TotalProfit,
        NumberOfTransactions,
        ROUND(TotalRevenue / NULLIF(SquareFootage, 0), 2) AS RevenuePerSqFt,
        ROUND(TotalProfit / NULLIF(SquareFootage, 0), 2) AS ProfitPerSqFt,
        ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMargin
    FROM PhysicalStoreSales
)
SELECT 
    DENSE_RANK() OVER (ORDER BY RevenuePerSqFt DESC) AS ProductivityRank,
    StoreID,
    StoreName,
    StoreType,
    City,
    Region,
    SquareFootage,
    TotalRevenue,
    TotalProfit,
    RevenuePerSqFt,
    ProfitPerSqFt,
    ProfitMargin
FROM PhysicalStoreProductivity
ORDER BY 
    ProductivityRank ASC,
    StoreID ASC;
GO

-- ============================================================================
-- 10. Data Quality Checks (Read-Only Audit Suite)
-- Purpose: Systematically verifies referential integrity, unmapped stores,
--          NULL hazards, negative value anomalies, and division-by-zero risks.
-- Target Tables: dbo.FactSales, dbo.DimStore
-- ============================================================================

-- Check 1: FactSales rows with invalid StoreID (Referential Integrity Check)
SELECT 
    'Invalid StoreID in FactSales' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.FactSales f
LEFT JOIN dbo.DimStore s 
    ON f.StoreID = s.StoreID
WHERE s.StoreID IS NULL;
GO

-- Check 2: Stores with no sales transactions (Dormant Store Check)
SELECT 
    'Stores With Zero Sales' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.DimStore s
LEFT JOIN dbo.FactSales f 
    ON s.StoreID = f.StoreID
WHERE f.StoreID IS NULL;
GO

-- Check 3: NULL StoreID values in FactSales
SELECT 
    'NULL StoreID in FactSales' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.FactSales
WHERE StoreID IS NULL;
GO

-- Check 4: NULL StoreID values in DimStore
SELECT 
    'NULL StoreID in DimStore' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.DimStore
WHERE StoreID IS NULL;
GO

-- Check 5: Zero or negative revenue rows in FactSales
SELECT 
    'Zero or Negative Revenue in FactSales' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.FactSales
WHERE SalesAmount <= 0.00;
GO

-- Check 6: Zero or negative cost rows in FactSales
SELECT 
    'Zero or Negative Cost in FactSales' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.FactSales
WHERE CostAmount <= 0.00;
GO

-- Check 7: Zero or negative quantity rows in FactSales
SELECT 
    'Zero or Negative Quantity in FactSales' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM dbo.FactSales
WHERE Quantity <= 0;
GO

-- Check 8: Division-by-Zero Risk Audit Across Stores
SELECT 
    'Stores with Zero Transactions (AOV Div/Zero Risk)' AS CheckName,
    COUNT(*) AS AnomalyCount
FROM (
    SELECT 
        s.StoreID,
        COUNT(DISTINCT f.SalesID) AS TxnCount
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f 
        ON s.StoreID = f.StoreID
    GROUP BY s.StoreID
    HAVING COUNT(DISTINCT f.SalesID) = 0
) sub;
GO

-- Consolidated Data Quality Summary Matrix
WITH DQ_1 AS (
    SELECT COUNT(*) AS InvalidStoreIDs
    FROM dbo.FactSales f
    LEFT JOIN dbo.DimStore s ON f.StoreID = s.StoreID
    WHERE s.StoreID IS NULL
),
DQ_2 AS (
    SELECT COUNT(*) AS ZeroSalesStores
    FROM dbo.DimStore s
    LEFT JOIN dbo.FactSales f ON s.StoreID = f.StoreID
    WHERE f.StoreID IS NULL
),
DQ_3 AS (
    SELECT COUNT(*) AS NullFactStoreIDs
    FROM dbo.FactSales
    WHERE StoreID IS NULL
),
DQ_4 AS (
    SELECT COUNT(*) AS NullDimStoreIDs
    FROM dbo.DimStore
    WHERE StoreID IS NULL
),
DQ_5 AS (
    SELECT COUNT(*) AS NonPositiveRevenueRows
    FROM dbo.FactSales
    WHERE SalesAmount <= 0.00
),
DQ_6 AS (
    SELECT COUNT(*) AS NonPositiveCostRows
    FROM dbo.FactSales
    WHERE CostAmount <= 0.00
),
DQ_7 AS (
    SELECT COUNT(*) AS NonPositiveQuantityRows
    FROM dbo.FactSales
    WHERE Quantity <= 0
),
DQ_8 AS (
    SELECT COUNT(*) AS ZeroTxnStores
    FROM (
        SELECT s.StoreID
        FROM dbo.DimStore s
        LEFT JOIN dbo.FactSales f ON s.StoreID = f.StoreID
        GROUP BY s.StoreID
        HAVING COUNT(DISTINCT f.SalesID) = 0
    ) sub
)
SELECT 
    dq1.InvalidStoreIDs,
    dq2.ZeroSalesStores,
    dq3.NullFactStoreIDs,
    dq4.NullDimStoreIDs,
    dq5.NonPositiveRevenueRows,
    dq6.NonPositiveCostRows,
    dq7.NonPositiveQuantityRows,
    dq8.ZeroTxnStores,
    CASE 
        WHEN dq1.InvalidStoreIDs = 0 
         AND dq2.ZeroSalesStores = 0 
         AND dq3.NullFactStoreIDs = 0 
         AND dq4.NullDimStoreIDs = 0 
         AND dq5.NonPositiveRevenueRows = 0 
         AND dq6.NonPositiveCostRows = 0 
         AND dq7.NonPositiveQuantityRows = 0 
         AND dq8.ZeroTxnStores = 0
        THEN 'PASSED: 100% Data Quality Verified'
        ELSE 'WARNING: Anomalies Detected'
    END AS OverallDataQualityStatus
FROM DQ_1 dq1
CROSS JOIN DQ_2 dq2
CROSS JOIN DQ_3 dq3
CROSS JOIN DQ_4 dq4
CROSS JOIN DQ_5 dq5
CROSS JOIN DQ_6 dq6
CROSS JOIN DQ_7 dq7
CROSS JOIN DQ_8 dq8;
GO
