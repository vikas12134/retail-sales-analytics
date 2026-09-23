-- ============================================================================
-- Script: 01_overall_performance.sql
-- Description: TASK 8.1 - Overall Business Performance Analysis
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Database: RetailSalesAnalytics
-- Target Table: dbo.FactSales
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ----------------------------------------------------------------------------
-- 1. Total Revenue
-- ----------------------------------------------------------------------------
SELECT 
    SUM(SalesAmount) AS TotalRevenue
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 2. Total Cost
-- ----------------------------------------------------------------------------
SELECT 
    SUM(CostAmount) AS TotalCost
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 3. Total Profit
-- ----------------------------------------------------------------------------
SELECT 
    SUM(Profit) AS TotalProfit
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 4. Overall Profit Margin
-- ----------------------------------------------------------------------------
SELECT 
    ROUND((SUM(Profit) * 100.0) / NULLIF(SUM(SalesAmount), 0), 2) AS OverallProfitMargin
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 5. Number of Sales Transactions
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT SalesID) AS NumberOfSalesTransactions
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 6. Total Units Sold
-- ----------------------------------------------------------------------------
SELECT 
    SUM(Quantity) AS TotalUnitsSold
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 7. Number of Unique Customers
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT CustomerID) AS NumberOfUniqueCustomers
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 8. Average Order Value
-- ----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(SalesAmount) / NULLIF(COUNT(DISTINCT SalesID), 0), 2) AS AverageOrderValue
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 9. Average Revenue per Customer
-- ----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(SalesAmount) / NULLIF(COUNT(DISTINCT CustomerID), 0), 2) AS AverageRevenuePerCustomer
FROM dbo.FactSales;
GO

-- ----------------------------------------------------------------------------
-- 10. Average Selling Price
-- ----------------------------------------------------------------------------
SELECT 
    ROUND(AVG(UnitPrice), 2) AS AverageSellingPrice
FROM dbo.FactSales;
GO
