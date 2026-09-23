-- ============================================================================
-- Script Name:   07_profitability_discount_analysis.sql
-- Task Number:   Task 8.7 - Profitability & Discount Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Purpose:       Comprehensive financial and discount analysis examining the
--                relationship between promotional discounting and commercial
--                profitability. Evaluates enterprise-wide profit margins,
--                product-level profitability, discount band distributions,
--                high-discount and loss-making transactions, category margins,
--                monthly profitability timelines, and ranked product contribution.
-- Target Tables: dbo.FactSales, dbo.DimProduct, dbo.DimDate
-- Execution Note: All queries are strictly READ-ONLY analytical SELECT queries.
--                 No database modification (INSERT/UPDATE/DELETE/ALTER/DROP) is performed.
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. Overall Enterprise Profitability
-- Analytical Question: What is the overall financial profitability of the enterprise
--                      in terms of revenue, COGS, gross profit, and net margin?
-- What It Calculates: Aggregated enterprise revenue, total cost of goods sold (COGS),
--                     total net gross profit, and overall profit margin percentage.
-- Calculation Logic: TotalRevenue = SUM(SalesAmount), TotalCost = SUM(CostAmount),
--                    TotalProfit = SUM(Profit),
--                    ProfitMarginPercentage = (TotalProfit / TotalRevenue) * 100
--                    guarded against division by zero using NULLIF().
-- Target Table: dbo.FactSales
-- ============================================================================
SELECT 
    SUM(SalesAmount) AS TotalRevenue,
    SUM(CostAmount) AS TotalCost,
    SUM(Profit) AS TotalProfit,
    ROUND((SUM(Profit) * 100.0) / NULLIF(SUM(SalesAmount), 0), 2) AS ProfitMarginPercentage
FROM dbo.FactSales;
GO

-- ============================================================================
-- 2. Profit by Product
-- Analytical Question: What is the sales volume, revenue, cost, profit, and margin
--                      percentage for each individual merchandise catalog item?
-- What It Calculates: Product ID, product name, core merchandise category, total revenue,
--                     total cost, total gross profit, and profit margin percentage.
-- Calculation Logic: Joins FactSales to DimProduct on ProductID, aggregates sales facts,
--                    computes margin percentage with NULLIF protection, and sorts
--                    by total gross profit descending.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    ROUND((SUM(f.Profit) * 100.0) / NULLIF(SUM(f.SalesAmount), 0), 2) AS ProfitMarginPercentage
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p 
    ON f.ProductID = p.ProductID
GROUP BY 
    p.ProductID,
    p.ProductName,
    p.Category
ORDER BY 
    TotalProfit DESC;
GO

-- ============================================================================
-- 3. Discount Band Analysis
-- Analytical Question: How do sales volume, unit quantity, revenue, cost, and net
--                      profit distribute across standardized promotional discount tiers?
-- What It Calculates: Transaction count, total units sold, gross revenue, cost, profit,
--                     and profit margin percentage grouped by promotional discount band.
-- Calculation Logic: Discount is stored as a decimal proportion (0.00 to 1.00).
--                    Bands are categorized via CASE:
--                      - 'No Discount (0%)'         : Discount = 0.00
--                      - 'Low Discount (1% - 10%)'   : Discount > 0.00 AND Discount <= 0.10
--                      - 'Medium Discount (11% - 20%)': Discount > 0.10 AND Discount <= 0.20
--                      - 'High Discount (> 20%)'     : Discount > 0.20
--                    Calculates margin percentage per band with NULLIF() safety.
-- Target Table: dbo.FactSales
-- ============================================================================
WITH DiscountCategorizedSales AS (
    SELECT 
        CASE 
            WHEN Discount = 0.00 THEN 'No Discount (0%)'
            WHEN Discount > 0.00 AND Discount <= 0.10 THEN 'Low Discount (1% - 10%)'
            WHEN Discount > 0.10 AND Discount <= 0.20 THEN 'Medium Discount (11% - 20%)'
            ELSE 'High Discount (> 20%)'
        END AS DiscountBand,
        CASE 
            WHEN Discount = 0.00 THEN 1
            WHEN Discount > 0.00 AND Discount <= 0.10 THEN 2
            WHEN Discount > 0.10 AND Discount <= 0.20 THEN 3
            ELSE 4
        END AS BandSortOrder,
        SalesID,
        Quantity,
        SalesAmount,
        CostAmount,
        Profit
    FROM dbo.FactSales
)
SELECT 
    DiscountBand,
    COUNT(DISTINCT SalesID) AS NumberOfTransactions,
    SUM(Quantity) AS TotalQuantitySold,
    SUM(SalesAmount) AS TotalRevenue,
    SUM(CostAmount) AS TotalCost,
    SUM(Profit) AS TotalProfit,
    ROUND((SUM(Profit) * 100.0) / NULLIF(SUM(SalesAmount), 0), 2) AS ProfitMarginPercentage
FROM DiscountCategorizedSales
GROUP BY 
    DiscountBand,
    BandSortOrder
ORDER BY 
    BandSortOrder ASC;
GO

-- ============================================================================
-- 4. Discount vs. Profitability Correlation
-- Analytical Question: What is the observed correlation between average discount given,
--                      average unit price, top-line revenue, and profit margin?
-- What It Calculates: Average applied discount rate, average catalog unit price,
--                     total revenue, total profit, profit margin percentage,
--                     and total transactions across promotional discount tiers.
-- Calculation Logic: Uses CTE classification with CASE, averages unit price and discount rate,
--                     converts average discount into a rounded percentage, and guards
--                     margin calculation using NULLIF().
-- Target Table: dbo.FactSales
-- ============================================================================
WITH DiscountMarginBase AS (
    SELECT 
        CASE 
            WHEN Discount = 0.00 THEN 'No Discount (0%)'
            WHEN Discount > 0.00 AND Discount <= 0.10 THEN 'Low Discount (1% - 10%)'
            WHEN Discount > 0.10 AND Discount <= 0.20 THEN 'Medium Discount (11% - 20%)'
            ELSE 'High Discount (> 20%)'
        END AS DiscountBand,
        CASE 
            WHEN Discount = 0.00 THEN 1
            WHEN Discount > 0.00 AND Discount <= 0.10 THEN 2
            WHEN Discount > 0.10 AND Discount <= 0.20 THEN 3
            ELSE 4
        END AS BandSortOrder,
        SalesID,
        Discount,
        UnitPrice,
        SalesAmount,
        Profit
    FROM dbo.FactSales
)
SELECT 
    DiscountBand,
    ROUND(AVG(Discount) * 100.0, 2) AS AverageDiscountPercentage,
    ROUND(AVG(UnitPrice), 2) AS AverageUnitPrice,
    SUM(SalesAmount) AS TotalRevenue,
    SUM(Profit) AS TotalProfit,
    ROUND((SUM(Profit) * 100.0) / NULLIF(SUM(SalesAmount), 0), 2) AS ProfitMarginPercentage,
    COUNT(DISTINCT SalesID) AS NumberOfTransactions
FROM DiscountMarginBase
GROUP BY 
    DiscountBand,
    BandSortOrder
ORDER BY 
    BandSortOrder ASC;
GO

-- ============================================================================
-- 5. High-Discount Transactions Inspection
-- Analytical Question: Which specific individual sales transactions received the highest
--                      promotional discount rates across the enterprise?
-- What It Calculates: Line-item transactional details for transactions where the applied
--                     promotional discount rate is at or above the high tier (Discount >= 0.20).
-- Calculation Logic: Filters FactSales for Discount >= 0.20 (20%+ promotional discount rate),
--                    projects key identifying dimensions (SalesID, ProductID, StoreID, CustomerID)
--                    and quantitative metrics, ordered by Discount descending and SalesAmount descending.
-- Target Table: dbo.FactSales
-- ============================================================================
SELECT 
    SalesID,
    ProductID,
    StoreID,
    CustomerID,
    Quantity,
    UnitPrice,
    Discount,
    SalesAmount,
    CostAmount,
    Profit
FROM dbo.FactSales
WHERE 
    Discount >= 0.20
ORDER BY 
    Discount DESC,
    SalesAmount DESC;
GO

-- ============================================================================
-- 6. Low or Negative Profit Transactions Audit
-- Analytical Question: Which individual sales transactions resulted in break-even
--                      or negative net profit (Profit <= 0.00)?
-- What It Calculates: Complete transactional line-item details for commercial transactions
--                     where total net profit is less than or equal to zero.
-- Calculation Logic: Filters FactSales for Profit <= 0.00, projecting primary keys,
--                    operational dimensions, unit price, applied discount rate,
--                    revenue, cost, and net loss. Ordered by Profit ascending (steepest loss first).
-- Target Table: dbo.FactSales
-- ============================================================================
SELECT 
    SalesID,
    ProductID,
    StoreID,
    Quantity,
    UnitPrice,
    Discount,
    SalesAmount,
    CostAmount,
    Profit
FROM dbo.FactSales
WHERE 
    Profit <= 0.00
ORDER BY 
    Profit ASC,
    SalesAmount DESC;
GO

-- ============================================================================
-- 7. Profit Margin by Product Category
-- Analytical Question: How does revenue, cost, profit volume, and profit margin
--                      percentage differ across core merchandise categories?
-- What It Calculates: Total revenue, total COGS (CostAmount), total net profit,
--                     profit margin percentage, and transaction volume per product category.
-- Calculation Logic: Joins FactSales to DimProduct on ProductID, groups by DimProduct.Category,
--                    computes margin percentage with NULLIF() protection, and orders by TotalProfit descending.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
SELECT 
    p.Category,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    ROUND((SUM(f.Profit) * 100.0) / NULLIF(SUM(f.SalesAmount), 0), 2) AS ProfitMarginPercentage,
    COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p 
    ON f.ProductID = p.ProductID
GROUP BY 
    p.Category
ORDER BY 
    TotalProfit DESC;
GO

-- ============================================================================
-- 8. Monthly Profitability Trend
-- Analytical Question: How have monthly revenue, cost, profit, and margin percentages
--                      trended chronologically across the reporting calendar?
-- What It Calculates: Total monthly sales revenue, total COGS, total net profit,
--                     and monthly profit margin percentage for each calendar year and month.
-- Calculation Logic: Joins FactSales to DimDate on DateKey, aggregates financial measures
--                    by d.[Year], d.[Month], and d.MonthName, computes profit margin with
--                    NULLIF() safety, and orders strictly chronologically.
-- Target Tables: dbo.FactSales, dbo.DimDate
-- ============================================================================
SELECT 
    d.[Year],
    d.[Month],
    d.MonthName,
    SUM(f.SalesAmount) AS TotalRevenue,
    SUM(f.CostAmount) AS TotalCost,
    SUM(f.Profit) AS TotalProfit,
    ROUND((SUM(f.Profit) * 100.0) / NULLIF(SUM(f.SalesAmount), 0), 2) AS ProfitMarginPercentage
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
-- 9. Top Products by Total Profit Ranking
-- Analytical Question: Which products generate the highest cumulative gross profit,
--                      and how do they rank across the enterprise merchandise catalog?
-- What It Calculates: Profit ranking (ProfitRank), product identifier, product name,
--                     merchandise category, and cumulative net profit for all products.
-- Calculation Logic: CTE aggregates total profit per product, outer query applies
--                    DENSE_RANK() OVER (ORDER BY TotalProfit DESC), ordered by
--                    ProfitRank ascending and ProductID ascending.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
WITH ProductProfitRankBase AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.Profit) AS TotalProfit
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalProfit DESC) AS ProfitRank,
    ProductID,
    ProductName,
    Category,
    TotalProfit
FROM ProductProfitRankBase
ORDER BY 
    ProfitRank ASC,
    ProductID ASC;
GO

-- ============================================================================
-- 10. Lowest-Profit Products Ranking (Bottom Products by Profit)
-- Analytical Question: Which catalog products generate the lowest total profit or
--                      greatest net loss across the enterprise?
-- What It Calculates: Reverse profit rank (LowestProfitRank), product ID, product name,
--                     category, and total net profit for the least profitable products.
-- Calculation Logic: CTE aggregates total profit per product, outer query applies
--                    DENSE_RANK() OVER (ORDER BY TotalProfit ASC), ordered by
--                    LowestProfitRank ascending and ProductID ascending.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
WITH ProductLowestProfitBase AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.Profit) AS TotalProfit
    FROM dbo.FactSales f
    INNER JOIN dbo.DimProduct p 
        ON f.ProductID = p.ProductID
    GROUP BY 
        p.ProductID,
        p.ProductName,
        p.Category
)
SELECT 
    DENSE_RANK() OVER (ORDER BY TotalProfit ASC) AS LowestProfitRank,
    ProductID,
    ProductName,
    Category,
    TotalProfit
FROM ProductLowestProfitBase
ORDER BY 
    LowestProfitRank ASC,
    ProductID ASC;
GO

-- ============================================================================
-- 11. Consolidated Product Profitability & Discount Summary
-- Analytical Question: What is the comprehensive multi-dimensional profitability,
--                      pricing, discount, and sales volume matrix for every catalog product?
-- What It Calculates: Product ID, product name, category, total units sold, total revenue,
--                     total cost, total profit, profit margin percentage, average unit price,
--                     average applied discount rate, and distinct transaction count.
-- Calculation Logic: Uses CTE for product-level aggregation across FactSales and DimProduct,
--                    calculates margin percentage with NULLIF() division-by-zero protection,
--                    formats average discount rate as a percentage, and sorts by TotalProfit DESC.
-- Target Tables: dbo.FactSales, dbo.DimProduct
-- ============================================================================
WITH ProductProfitabilitySummaryBase AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(f.Quantity) AS TotalQuantitySold,
        SUM(f.SalesAmount) AS TotalRevenue,
        SUM(f.CostAmount) AS TotalCost,
        SUM(f.Profit) AS TotalProfit,
        ROUND(AVG(f.UnitPrice), 2) AS AverageUnitPrice,
        ROUND(AVG(f.Discount) * 100.0, 2) AS AverageDiscountPercentage,
        COUNT(DISTINCT f.SalesID) AS NumberOfTransactions
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
    TotalQuantitySold,
    TotalRevenue,
    TotalCost,
    TotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(TotalRevenue, 0), 2) AS ProfitMarginPercentage,
    AverageUnitPrice,
    AverageDiscountPercentage,
    NumberOfTransactions
FROM ProductProfitabilitySummaryBase
ORDER BY 
    TotalProfit DESC,
    TotalRevenue DESC;
GO
