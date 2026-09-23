-- ============================================================================
-- Script: 04_create_indexes.sql
-- Description: Creates performance-optimized B-Tree indexes for analytical workloads.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-05
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- PART 1: FACTSALES FOREIGN KEY & COVERING INDEXES
-- In a Star Schema, the central Fact table (320,536+ rows) is frequently joined 
-- with dimensions and filtered on dimension keys.
-- Covering indexes with INCLUDE clauses eliminate key lookups for common aggregations.
-- ============================================================================

-- 1. Index on DateKey (Covering for Financial Aggregations)
-- Why it exists: DateKey is the most frequent join and filter predicate in retail reporting.
-- Supported Query Patterns:
--   - Daily, monthly, quarterly, and annual sales rollups.
--   - Year-over-Year (YoY) and Month-over-Month (MoM) trend queries.
--   - Time-intelligence filtering from Power BI date slicers.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactSales_DateKey' AND object_id = OBJECT_ID(N'dbo.FactSales'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_DateKey
    ON dbo.FactSales (DateKey)
    INCLUDE (SalesAmount, CostAmount, Profit, Quantity);
    PRINT 'Index [IX_FactSales_DateKey] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_FactSales_DateKey] already exists. Skipping.';
END
GO

-- 2. Index on CustomerID (Covering for Customer Analytics)
-- Why it exists: Evaluates customer purchase histories across 50,000 customers.
-- Supported Query Patterns:
--   - Recency, Frequency, and Monetary (RFM) customer segmentation.
--   - Customer lifetime value (LTV) and average transaction frequency.
--   - Repeat customer vs. one-time buyer analysis.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactSales_CustomerID' AND object_id = OBJECT_ID(N'dbo.FactSales'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_CustomerID
    ON dbo.FactSales (CustomerID)
    INCLUDE (OrderDate, SalesAmount, Profit);
    PRINT 'Index [IX_FactSales_CustomerID] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_FactSales_CustomerID] already exists. Skipping.';
END
GO

-- 3. Index on ProductID (Covering for Merchandise Performance)
-- Why it exists: Supports SKU-level margin and volume rollups across 500 catalog items.
-- Supported Query Patterns:
--   - Top 10 and Bottom 10 revenue-generating products.
--   - Product margin drainers vs. high-margin star products.
--   - Quantity velocity and reorder forecasting queries.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactSales_ProductID' AND object_id = OBJECT_ID(N'dbo.FactSales'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_ProductID
    ON dbo.FactSales (ProductID)
    INCLUDE (Quantity, SalesAmount, CostAmount, Profit);
    PRINT 'Index [IX_FactSales_ProductID] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_FactSales_ProductID] already exists. Skipping.';
END
GO

-- 4. Index on StoreID (Covering for Store & Channel Analytics)
-- Why it exists: Accelerates store and regional performance comparisons across 30 stores.
-- Supported Query Patterns:
--   - Store-level profitability benchmarks.
--   - E-commerce vs. physical store revenue comparisons.
--   - Regional performance comparisons and revenue attribution.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactSales_StoreID' AND object_id = OBJECT_ID(N'dbo.FactSales'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_StoreID
    ON dbo.FactSales (StoreID)
    INCLUDE (SalesAmount, CostAmount, Profit, Quantity);
    PRINT 'Index [IX_FactSales_StoreID] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_FactSales_StoreID] already exists. Skipping.';
END
GO

-- 5. Index on OrderDate (Temporal Filtering)
-- Why it exists: Supports queries using raw calendar dates (BETWEEN '2023-01-01' AND '2023-12-31').
-- Supported Query Patterns:
--   - Rolling 30-day, 60-day, or 90-day moving window aggregations.
--   - Day-of-week and seasonal promotional window analysis.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactSales_OrderDate' AND object_id = OBJECT_ID(N'dbo.FactSales'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactSales_OrderDate
    ON dbo.FactSales (OrderDate);
    PRINT 'Index [IX_FactSales_OrderDate] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_FactSales_OrderDate] already exists. Skipping.';
END
GO


-- ============================================================================
-- PART 2: DIMENSION FILTERING & HIERARCHY INDEXES
-- Supports fast filtering on high-cardinality and high-frequency dimension attributes.
-- ============================================================================

-- 6. DimCustomer: Region and State Filtering
-- Supported Query Patterns: Regional demographic filtering and geographic slicers in Power BI.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DimCustomer_Region_State' AND object_id = OBJECT_ID(N'dbo.DimCustomer'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimCustomer_Region_State
    ON dbo.DimCustomer (Region, [State])
    INCLUDE (CustomerSegment);
    PRINT 'Index [IX_DimCustomer_Region_State] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_DimCustomer_Region_State] already exists. Skipping.';
END
GO

-- 7. DimCustomer: Loyalty Segment Filtering
-- Supported Query Patterns: Filtering by VIP Platinum, Gold, Silver, and Regular segments.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DimCustomer_Segment' AND object_id = OBJECT_ID(N'dbo.DimCustomer'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimCustomer_Segment
    ON dbo.DimCustomer (CustomerSegment);
    PRINT 'Index [IX_DimCustomer_Segment] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_DimCustomer_Segment] already exists. Skipping.';
END
GO

-- 8. DimProduct: Category and Subcategory Hierarchy
-- Supported Query Patterns: Drill-down from 5 core Categories to 25 Subcategories in Power BI matrix visuals.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DimProduct_Category_Subcategory' AND object_id = OBJECT_ID(N'dbo.DimProduct'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimProduct_Category_Subcategory
    ON dbo.DimProduct (Category, Subcategory);
    PRINT 'Index [IX_DimProduct_Category_Subcategory] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_DimProduct_Category_Subcategory] already exists. Skipping.';
END
GO

-- 9. DimProduct: Brand Filtering
-- Supported Query Patterns: Merchandising queries filtering across the 34 manufacturer brands.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DimProduct_Brand' AND object_id = OBJECT_ID(N'dbo.DimProduct'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimProduct_Brand
    ON dbo.DimProduct (Brand);
    PRINT 'Index [IX_DimProduct_Brand] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_DimProduct_Brand] already exists. Skipping.';
END
GO

-- 10. DimStore: Region and StoreType Filtering
-- Supported Query Patterns: Comparing Mall Outlets vs. Flagship vs. Standalone stores within each sales region.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DimStore_Region_StoreType' AND object_id = OBJECT_ID(N'dbo.DimStore'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimStore_Region_StoreType
    ON dbo.DimStore (Region, StoreType);
    PRINT 'Index [IX_DimStore_Region_StoreType] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_DimStore_Region_StoreType] already exists. Skipping.';
END
GO

-- 11. DimDate: Year and Month Filtering
-- Supported Query Patterns: Time-series aggregations joining DimDate with FactSales by fiscal/calendar periods.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DimDate_Year_Month' AND object_id = OBJECT_ID(N'dbo.DimDate'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimDate_Year_Month
    ON dbo.DimDate ([Year], [Month])
    INCLUDE (QuarterName, MonthName, IsHoliday, IsWeekend);
    PRINT 'Index [IX_DimDate_Year_Month] created successfully.';
END
ELSE
BEGIN
    PRINT 'Index [IX_DimDate_Year_Month] already exists. Skipping.';
END
GO

PRINT 'All analytical indexes created successfully.';
GO
