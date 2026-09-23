-- ============================================================================
-- Script Name:   02_product_performance.sql
-- Task Number:   Task 8.2 - Product Performance Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Analysis Scope: Product-level sales volume, revenue, profitability, rankings,
--                 category aggregations, and revenue contribution percentages.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. Product Performance Overview
-- Business Question: What is the overall sales performance for each product?
-- Calculates: Product ID, Product Name, Category, Total Quantity Sold,
--             Total Revenue, Total Cost, Total Profit, Average Selling Price,
--             and Number of Sales Transactions.
-- ============================================================================
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    SUM(f.Quantity) AS TotalQuantitySold,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    ROUND(AVG(f.UnitPrice), 2) AS AvgSellingPrice,
    COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p 
    ON f.ProductID = p.ProductID
GROUP BY 
    p.ProductID,
    p.ProductName,
    p.Category
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 2. Top Products by Revenue
-- Business Question: Which top 10 products generate the highest gross revenue?
-- Ranking Method: DENSE_RANK() window function based on Total Sales Revenue.
-- ============================================================================
WITH ProductRevenueRanking AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.SalesAmount) AS TotalRevenue,
        DENSE_RANK() OVER (ORDER BY SUM(f.SalesAmount) DESC) AS RevenueRank
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    RevenueRank,
    ProductID,
    ProductName,
    Category,
    TotalRevenue
FROM ProductRevenueRanking
WHERE RevenueRank <= 10
ORDER BY 
    RevenueRank ASC;
GO

-- ============================================================================
-- 3. Top Products by Profit
-- Business Question: Which top 10 products deliver the greatest net profit?
-- Ranking Method: DENSE_RANK() window function based on Total Net Profit.
-- ============================================================================
WITH ProductProfitRanking AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.Profit) AS TotalProfit,
        DENSE_RANK() OVER (ORDER BY SUM(f.Profit) DESC) AS ProfitRank
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    ProfitRank,
    ProductID,
    ProductName,
    Category,
    TotalProfit
FROM ProductProfitRanking
WHERE ProfitRank <= 10
ORDER BY 
    ProfitRank ASC;
GO

-- ============================================================================
-- 4. Top Products by Quantity
-- Business Question: Which top 10 products have the highest physical volume sold?
-- Ranking Method: DENSE_RANK() window function based on Total Quantity Sold.
-- ============================================================================
WITH ProductQuantityRanking AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.Quantity) AS TotalQuantitySold,
        DENSE_RANK() OVER (ORDER BY SUM(f.Quantity) DESC) AS QuantityRank
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    QuantityRank,
    ProductID,
    ProductName,
    Category,
    TotalQuantitySold
FROM ProductQuantityRanking
WHERE QuantityRank <= 10
ORDER BY 
    QuantityRank ASC;
GO

-- ============================================================================
-- 5. Bottom Products
-- Business Question: Which products generate the lowest revenue and lowest profit?
-- Ranking Method: DENSE_RANK() ascending order for Bottom 10 identification.
-- ============================================================================

-- 5A: Bottom 10 Products by Revenue
WITH BottomRevenueRanking AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.SalesAmount) AS TotalRevenue,
        DENSE_RANK() OVER (ORDER BY SUM(f.SalesAmount) ASC) AS RevenueRankBottom
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    RevenueRankBottom,
    ProductID,
    ProductName,
    Category,
    TotalRevenue
FROM BottomRevenueRanking
WHERE RevenueRankBottom <= 10
ORDER BY 
    RevenueRankBottom ASC;
GO

-- 5B: Bottom 10 Products by Profit
WITH BottomProfitRanking AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.Profit) AS TotalProfit,
        DENSE_RANK() OVER (ORDER BY SUM(f.Profit) ASC) AS ProfitRankBottom
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    ProfitRankBottom,
    ProductID,
    ProductName,
    Category,
    TotalProfit
FROM BottomProfitRanking
WHERE ProfitRankBottom <= 10
ORDER BY 
    ProfitRankBottom ASC;
GO

-- ============================================================================
-- 6. Category Performance
-- Business Question: How do different merchandise categories compare across
--                    volume, revenue, costs, profit, SKU count, and transactions?
-- ============================================================================
SELECT 
    p.Category,
    SUM(f.Quantity) AS TotalQuantitySold,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    COUNT(DISTINCT p.ProductID) AS NumberOfProducts,
    COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p 
    ON f.ProductID = p.ProductID
GROUP BY 
    p.Category
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 7. Product Profitability
-- Business Question: What is the profit margin percentage for each product?
-- Metric Logic: ProfitMarginPct = (Total Profit / Total Revenue) * 100.
-- Safety: Handles zero/null revenue using CASE and NULLIF to avoid division by zero.
-- ============================================================================
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    CASE 
        WHEN SUM(f.SalesAmount) = 0 THEN 0.00
        ELSE ROUND((SUM(f.Profit) * 100.0) / NULLIF(SUM(f.SalesAmount), 0), 2)
    END AS ProfitMarginPct
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p 
    ON f.ProductID = p.ProductID
GROUP BY 
    p.ProductID,
    p.ProductName,
    p.Category
ORDER BY 
    ProfitMarginPct DESC,
    TotalProfit DESC;
GO

-- ============================================================================
-- 8. Revenue Contribution
-- Business Question: What percentage does each product contribute to overall sales?
-- Metric Logic: (Product Revenue / Total Enterprise Revenue) * 100.
-- Calculation: Uses SUM() OVER () window function to compute total revenue dynamically.
-- ============================================================================
WITH ProductSalesSummary AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.SalesAmount) AS ProductRevenue
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    ProductID,
    ProductName,
    Category,
    ProductRevenue,
    SUM(ProductRevenue) OVER () AS TotalRevenue,
    CASE 
        WHEN SUM(ProductRevenue) OVER () = 0 THEN 0.00
        ELSE ROUND((ProductRevenue * 100.0) / NULLIF(SUM(ProductRevenue) OVER (), 0), 4)
    END AS RevenueContributionPct,
    DENSE_RANK() OVER (ORDER BY ProductRevenue DESC) AS RevenueRank
FROM ProductSalesSummary
ORDER BY 
    ProductRevenue DESC;
GO
