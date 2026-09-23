-- ============================================================================
-- Script: 05_create_views.sql
-- Description: Creates foundational analytical views supporting BI and reporting.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-05
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. VIEW: vw_SalesDetail
-- Purpose: Denormalizes FactSales with all 4 Dimension tables (Date, Customer,
-- Product, Store) into a unified tabular structure.
-- Analytical Uses:
--   - Direct connection point for Power BI / Excel reporting layers.
--   - Rapid ad-hoc exploration without requiring manual 5-table JOIN syntax.
--   - Provides both SalesID and TransactionID aliases for traceability.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_SalesDetail
AS
SELECT 
    -- Transaction Identifiers
    fs.SalesID,
    fs.SalesID AS TransactionID,
    
    -- Temporal Attributes (DimDate)
    fs.DateKey,
    fs.OrderDate,
    dd.[Year] AS OrderYear,
    dd.[Quarter] AS OrderQuarter,
    dd.QuarterName AS OrderQuarterName,
    dd.[Month] AS OrderMonth,
    dd.MonthName AS OrderMonthName,
    dd.MonthYear AS OrderMonthYear,
    dd.WeekOfYear AS OrderWeekOfYear,
    dd.DayName AS OrderDayName,
    dd.IsWeekend,
    dd.IsHoliday,
    dd.FiscalYear,
    dd.FiscalQuarter,
    
    -- Customer Attributes (DimCustomer)
    fs.CustomerID,
    dc.FirstName + ' ' + dc.LastName AS CustomerName,
    dc.Email AS CustomerEmail,
    dc.Gender AS CustomerGender,
    dc.DateOfBirth AS CustomerDateOfBirth,
    dc.City AS CustomerCity,
    dc.[State] AS CustomerState,
    dc.Region AS CustomerRegion,
    dc.PostalCode AS CustomerPostalCode,
    dc.CustomerSegment,
    dc.JoinDate AS CustomerJoinDate,
    
    -- Product Attributes (DimProduct)
    fs.ProductID,
    dp.ProductName,
    dp.Category AS ProductCategory,
    dp.Subcategory AS ProductSubcategory,
    dp.Brand AS ProductBrand,
    dp.[Status] AS ProductStatus,
    
    -- Store & Channel Attributes (DimStore & FactSales)
    fs.StoreID,
    ds.StoreName,
    ds.StoreType,
    ds.City AS StoreCity,
    ds.[State] AS StoreState,
    ds.Region AS StoreRegion,
    ds.SquareFootage AS StoreSquareFootage,
    ds.ManagerName AS StoreManagerName,
    fs.SalesChannel,
    fs.PaymentMethod,
    
    -- Quantitative Transaction Facts
    fs.Quantity,
    fs.UnitPrice,
    fs.Discount,
    ROUND(fs.Quantity * fs.UnitPrice, 2) AS GrossSalesAmount,
    fs.DiscountAmount,
    fs.SalesAmount AS NetSalesAmount,
    fs.UnitCost,
    fs.CostAmount,
    fs.Profit,
    CASE 
        WHEN fs.SalesAmount > 0 
        THEN ROUND((fs.Profit / fs.SalesAmount) * 100.0, 2)
        ELSE 0.00 
    END AS ProfitMarginPct

FROM dbo.FactSales fs
INNER JOIN dbo.DimDate dd 
    ON fs.DateKey = dd.DateKey
INNER JOIN dbo.DimCustomer dc 
    ON fs.CustomerID = dc.CustomerID
INNER JOIN dbo.DimProduct dp 
    ON fs.ProductID = dp.ProductID
INNER JOIN dbo.DimStore ds 
    ON fs.StoreID = ds.StoreID;
GO

PRINT 'View [dbo].[vw_SalesDetail] created successfully.';
GO


-- ============================================================================
-- 2. VIEW: vw_MonthlySalesSummary
-- Purpose: Pre-aggregates transactional revenue, cost, profit, order volume,
-- and unit metrics at the monthly level.
-- Analytical Uses:
--   - Executive time-series monitoring (Month-over-Month & Year-over-Year trends).
--   - Baseline dataset for macroeconomic revenue and margin forecasting.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_MonthlySalesSummary
AS
SELECT 
    dd.[Year],
    dd.[Month],
    dd.MonthName,
    dd.MonthYear,
    dd.QuarterName,
    dd.FiscalYear,
    dd.FiscalQuarter,
    COUNT(DISTINCT fs.SalesID) AS TotalOrders,
    SUM(fs.Quantity) AS TotalUnitsSold,
    ROUND(SUM(fs.Quantity * fs.UnitPrice), 2) AS TotalGrossSales,
    ROUND(SUM(fs.DiscountAmount), 2) AS TotalDiscountAmount,
    ROUND(SUM(fs.SalesAmount), 2) AS TotalRevenue,
    ROUND(SUM(fs.CostAmount), 2) AS TotalCOGS,
    ROUND(SUM(fs.Profit), 2) AS TotalNetProfit,
    ROUND(SUM(fs.Profit) / NULLIF(SUM(fs.SalesAmount), 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT fs.SalesID), 0), 2) AS AverageOrderValue

FROM dbo.FactSales fs
INNER JOIN dbo.DimDate dd 
    ON fs.DateKey = dd.DateKey
GROUP BY 
    dd.[Year],
    dd.[Month],
    dd.MonthName,
    dd.MonthYear,
    dd.QuarterName,
    dd.FiscalYear,
    dd.FiscalQuarter;
GO

PRINT 'View [dbo].[vw_MonthlySalesSummary] created successfully.';
GO


-- ============================================================================
-- 3. VIEW: vw_CategoryPerformance
-- Purpose: Aggregates sales and margin metrics by merchandise Category and Subcategory.
-- Analytical Uses:
--   - Identifies high-margin merchandise lines vs. volume-heavy margin drainers.
--   - Informs inventory allocation and seasonal promotional planning.
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_CategoryPerformance
AS
SELECT 
    dp.Category,
    dp.Subcategory,
    COUNT(DISTINCT dp.ProductID) AS ActiveSKUCount,
    COUNT(DISTINCT fs.SalesID) AS TotalOrders,
    SUM(fs.Quantity) AS TotalUnitsSold,
    ROUND(SUM(fs.SalesAmount), 2) AS TotalRevenue,
    ROUND(SUM(fs.CostAmount), 2) AS TotalCOGS,
    ROUND(SUM(fs.Profit), 2) AS TotalNetProfit,
    ROUND(SUM(fs.Profit) / NULLIF(SUM(fs.SalesAmount), 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(AVG(fs.UnitPrice), 2) AS AvgUnitPrice,
    ROUND(AVG(fs.Discount) * 100.0, 2) AS AvgDiscountPct

FROM dbo.FactSales fs
INNER JOIN dbo.DimProduct dp 
    ON fs.ProductID = dp.ProductID
GROUP BY 
    dp.Category,
    dp.Subcategory;
GO

PRINT 'View [dbo].[vw_CategoryPerformance] created successfully.';
GO


-- ============================================================================
-- 4. VIEW: vw_CustomerRFMBase
-- Purpose: Consolidates customer purchasing activity into foundational Recency,
-- Frequency, and Monetary (RFM) components.
-- Analytical Uses:
--   - Input for RFM customer scoring and tier assignment.
--   - Identifies high-value repeat buyers vs. churn-risk customers.
--   - Note: Recency is calculated relative to the dataset boundary (2024-12-31).
-- ============================================================================
CREATE OR ALTER VIEW dbo.vw_CustomerRFMBase
AS
SELECT 
    dc.CustomerID,
    dc.FirstName + ' ' + dc.LastName AS CustomerName,
    dc.CustomerSegment,
    dc.Region,
    dc.[State],
    dc.JoinDate,
    MIN(fs.OrderDate) AS FirstOrderDate,
    MAX(fs.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(fs.OrderDate), '2024-12-31') AS RecencyDays,
    COUNT(DISTINCT fs.SalesID) AS OrderFrequency,
    SUM(fs.Quantity) AS TotalUnitsPurchased,
    ROUND(SUM(fs.SalesAmount), 2) AS MonetaryValue,
    ROUND(SUM(fs.Profit), 2) AS TotalProfitContributed,
    ROUND(SUM(fs.SalesAmount) / NULLIF(COUNT(DISTINCT fs.SalesID), 0), 2) AS AverageOrderValue

FROM dbo.DimCustomer dc
LEFT JOIN dbo.FactSales fs 
    ON dc.CustomerID = fs.CustomerID
GROUP BY 
    dc.CustomerID,
    dc.FirstName,
    dc.LastName,
    dc.CustomerSegment,
    dc.Region,
    dc.[State],
    dc.JoinDate;
GO

PRINT 'View [dbo].[vw_CustomerRFMBase] created successfully.';
GO

PRINT 'All analytical views created successfully.';
GO
