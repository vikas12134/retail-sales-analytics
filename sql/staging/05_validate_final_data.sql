-- ============================================================================
-- Script: 05_validate_final_data.sql
-- Description: Comprehensive production quality assurance suite verifying final
--              row counts, primary/foreign key constraints, financial reconciliation,
--              business logic rules, and analytical reporting views.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-06
-- ============================================================================

USE [RetailSalesAnalytics];
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT '        RETAIL SALES ANALYTICS - FINAL PRODUCTION DATA QA AUDIT             ';
PRINT '============================================================================';
PRINT 'Execution Timestamp: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT 'Current Database:    ' + DB_NAME();
PRINT '';

-- Temporary table to collect validation results
IF OBJECT_ID('tempdb..#FinalValidationResults') IS NOT NULL
    DROP TABLE #FinalValidationResults;

CREATE TABLE #FinalValidationResults (
    CheckCategory   VARCHAR(50),
    CheckName       VARCHAR(100),
    ExpectedResult  VARCHAR(100),
    ActualResult    VARCHAR(100),
    [Status]        VARCHAR(10)
);

-- ============================================================================
-- CHECK CATEGORY 1: PRODUCTION ROW COUNTS
-- ============================================================================
DECLARE @cntDate INT, @cntCust INT, @cntProd INT, @cntStore INT, @cntSales INT;

SELECT @cntDate  = COUNT(*) FROM dbo.DimDate;
SELECT @cntCust  = COUNT(*) FROM dbo.DimCustomer;
SELECT @cntProd  = COUNT(*) FROM dbo.DimProduct;
SELECT @cntStore = COUNT(*) FROM dbo.DimStore;
SELECT @cntSales = COUNT(*) FROM dbo.FactSales;

INSERT INTO #FinalValidationResults VALUES
('Row Counts', 'dbo.DimDate Row Count', '731', CAST(@cntDate AS VARCHAR(20)),
 CASE WHEN @cntDate = 731 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'dbo.DimCustomer Row Count', '50000', CAST(@cntCust AS VARCHAR(20)),
 CASE WHEN @cntCust = 50000 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'dbo.DimProduct Row Count', '500', CAST(@cntProd AS VARCHAR(20)),
 CASE WHEN @cntProd = 500 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'dbo.DimStore Row Count', '30', CAST(@cntStore AS VARCHAR(20)),
 CASE WHEN @cntStore = 30 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'dbo.FactSales Row Count', '320536', CAST(@cntSales AS VARCHAR(20)),
 CASE WHEN @cntSales = 320536 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 2: PRIMARY KEY UNIQUENESS & NOT-NULL ENFORCEMENT
-- ============================================================================
DECLARE @dupDateKey INT, @dupCustID INT, @dupProdID INT, @dupStoreID INT, @dupSalesID INT;

SELECT @dupDateKey = ISNULL(SUM(cnt - 1), 0) FROM (SELECT DateKey, COUNT(*) AS cnt FROM dbo.DimDate GROUP BY DateKey HAVING COUNT(*) > 1) d;
SELECT @dupCustID  = ISNULL(SUM(cnt - 1), 0) FROM (SELECT CustomerID, COUNT(*) AS cnt FROM dbo.DimCustomer GROUP BY CustomerID HAVING COUNT(*) > 1) d;
SELECT @dupProdID  = ISNULL(SUM(cnt - 1), 0) FROM (SELECT ProductID, COUNT(*) AS cnt FROM dbo.DimProduct GROUP BY ProductID HAVING COUNT(*) > 1) d;
SELECT @dupStoreID = ISNULL(SUM(cnt - 1), 0) FROM (SELECT StoreID, COUNT(*) AS cnt FROM dbo.DimStore GROUP BY StoreID HAVING COUNT(*) > 1) d;
SELECT @dupSalesID = ISNULL(SUM(cnt - 1), 0) FROM (SELECT SalesID, COUNT(*) AS cnt FROM dbo.FactSales GROUP BY SalesID HAVING COUNT(*) > 1) d;

INSERT INTO #FinalValidationResults VALUES
('Primary Keys', 'PK Uniqueness on dbo.DimDate', '0 duplicates', CAST(@dupDateKey AS VARCHAR(20)) + ' duplicates',
 CASE WHEN @dupDateKey = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Keys', 'PK Uniqueness on dbo.DimCustomer', '0 duplicates', CAST(@dupCustID AS VARCHAR(20)) + ' duplicates',
 CASE WHEN @dupCustID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Keys', 'PK Uniqueness on dbo.DimProduct', '0 duplicates', CAST(@dupProdID AS VARCHAR(20)) + ' duplicates',
 CASE WHEN @dupProdID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Keys', 'PK Uniqueness on dbo.DimStore', '0 duplicates', CAST(@dupStoreID AS VARCHAR(20)) + ' duplicates',
 CASE WHEN @dupStoreID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Keys', 'PK Uniqueness on dbo.FactSales', '0 duplicates', CAST(@dupSalesID AS VARCHAR(20)) + ' duplicates',
 CASE WHEN @dupSalesID = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 3: REFERENTIAL INTEGRITY (FOREIGN KEY ORPHANS)
-- ============================================================================
DECLARE @orphanDateKey INT, @orphanCustID INT, @orphanProdID INT, @orphanStoreID INT;

SELECT @orphanDateKey = COUNT(*) 
FROM dbo.FactSales fs
LEFT JOIN dbo.DimDate dd ON fs.DateKey = dd.DateKey
WHERE dd.DateKey IS NULL;

SELECT @orphanCustID = COUNT(*) 
FROM dbo.FactSales fs
LEFT JOIN dbo.DimCustomer dc ON fs.CustomerID = dc.CustomerID
WHERE dc.CustomerID IS NULL;

SELECT @orphanProdID = COUNT(*) 
FROM dbo.FactSales fs
LEFT JOIN dbo.DimProduct dp ON fs.ProductID = dp.ProductID
WHERE dp.ProductID IS NULL;

SELECT @orphanStoreID = COUNT(*) 
FROM dbo.FactSales fs
LEFT JOIN dbo.DimStore ds ON fs.StoreID = ds.StoreID
WHERE ds.StoreID IS NULL;

INSERT INTO #FinalValidationResults VALUES
('Referential Integrity', 'FK_FactSales_DimDate Orphans', '0 orphans', CAST(@orphanDateKey AS VARCHAR(20)) + ' orphans',
 CASE WHEN @orphanDateKey = 0 THEN 'PASS' ELSE 'FAIL' END),
('Referential Integrity', 'FK_FactSales_DimCustomer Orphans', '0 orphans', CAST(@orphanCustID AS VARCHAR(20)) + ' orphans',
 CASE WHEN @orphanCustID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Referential Integrity', 'FK_FactSales_DimProduct Orphans', '0 orphans', CAST(@orphanProdID AS VARCHAR(20)) + ' orphans',
 CASE WHEN @orphanProdID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Referential Integrity', 'FK_FactSales_DimStore Orphans', '0 orphans', CAST(@orphanStoreID AS VARCHAR(20)) + ' orphans',
 CASE WHEN @orphanStoreID = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 4: FINANCIAL RECONCILIATION & MATHEMATICAL CONSISTENCY
-- ============================================================================
DECLARE @errDiscountAmt INT, @errSalesAmt INT, @errCostAmt INT, @errProfit INT;

-- 1. DiscountAmount = round(Quantity * UnitPrice * Discount, 2)
SELECT @errDiscountAmt = COUNT(*) 
FROM dbo.FactSales 
WHERE ABS(DiscountAmount - ROUND(Quantity * UnitPrice * Discount, 2)) > 0.05;

-- 2. SalesAmount = round((Quantity * UnitPrice) - DiscountAmount, 2)
SELECT @errSalesAmt = COUNT(*) 
FROM dbo.FactSales 
WHERE ABS(SalesAmount - ROUND((Quantity * UnitPrice) - DiscountAmount, 2)) > 0.05;

-- 3. CostAmount = round(Quantity * UnitCost, 2)
SELECT @errCostAmt = COUNT(*) 
FROM dbo.FactSales 
WHERE ABS(CostAmount - ROUND(Quantity * UnitCost, 2)) > 0.05;

-- 4. Profit = round(SalesAmount - CostAmount, 2)
SELECT @errProfit = COUNT(*) 
FROM dbo.FactSales 
WHERE ABS(Profit - ROUND(SalesAmount - CostAmount, 2)) > 0.05;

INSERT INTO #FinalValidationResults VALUES
('Financial Integrity', 'DiscountAmount Reconciliation', '0 discrepancies', CAST(@errDiscountAmt AS VARCHAR(20)) + ' discrepancies',
 CASE WHEN @errDiscountAmt = 0 THEN 'PASS' ELSE 'FAIL' END),
('Financial Integrity', 'SalesAmount Net Reconciliation', '0 discrepancies', CAST(@errSalesAmt AS VARCHAR(20)) + ' discrepancies',
 CASE WHEN @errSalesAmt = 0 THEN 'PASS' ELSE 'FAIL' END),
('Financial Integrity', 'CostAmount (COGS) Reconciliation', '0 discrepancies', CAST(@errCostAmt AS VARCHAR(20)) + ' discrepancies',
 CASE WHEN @errCostAmt = 0 THEN 'PASS' ELSE 'FAIL' END),
('Financial Integrity', 'Profit Reconciliation', '0 discrepancies', CAST(@errProfit AS VARCHAR(20)) + ' discrepancies',
 CASE WHEN @errProfit = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 5: BUSINESS LOGIC BOUNDARIES & CHECK CONSTRAINTS
-- ============================================================================
DECLARE @invQty INT, @invDiscount INT, @invChannel INT, @invCategory INT, @invSegment INT;

SELECT @invQty = COUNT(*) FROM dbo.FactSales WHERE Quantity <= 0;
SELECT @invDiscount = COUNT(*) FROM dbo.FactSales WHERE Discount < 0.00 OR Discount > 1.00;
SELECT @invChannel = COUNT(*) FROM dbo.FactSales WHERE SalesChannel NOT IN ('Online', 'In-Store');
SELECT @invCategory = COUNT(*) FROM dbo.DimProduct WHERE Category NOT IN (
    'Electronics & Gadgets', 'Home & Kitchen', 'Apparel & Accessories', 'Beauty & Personal Care', 'Sports & Outdoors'
);
SELECT @invSegment = COUNT(*) FROM dbo.DimCustomer WHERE CustomerSegment NOT IN ('Regular', 'Silver', 'Gold', 'VIP Platinum');

INSERT INTO #FinalValidationResults VALUES
('Business Logic', 'Quantity > 0 Verification', '0 violations', CAST(@invQty AS VARCHAR(20)) + ' violations',
 CASE WHEN @invQty = 0 THEN 'PASS' ELSE 'FAIL' END),
('Business Logic', 'Discount 0.00 - 1.00 Range', '0 violations', CAST(@invDiscount AS VARCHAR(20)) + ' violations',
 CASE WHEN @invDiscount = 0 THEN 'PASS' ELSE 'FAIL' END),
('Business Logic', 'SalesChannel Domain Verification', '0 violations', CAST(@invChannel AS VARCHAR(20)) + ' violations',
 CASE WHEN @invChannel = 0 THEN 'PASS' ELSE 'FAIL' END),
('Business Logic', 'Product Category (5 Domains)', '0 violations', CAST(@invCategory AS VARCHAR(20)) + ' violations',
 CASE WHEN @invCategory = 0 THEN 'PASS' ELSE 'FAIL' END),
('Business Logic', 'Customer Segments (4 Tiers)', '0 violations', CAST(@invSegment AS VARCHAR(20)) + ' violations',
 CASE WHEN @invSegment = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 6: TEMPORAL RANGE & ANALYTICAL SANITY
-- ============================================================================
DECLARE @minDate DATE, @maxDate DATE, @dateSpanMatch VARCHAR(20);

SELECT @minDate = MIN(OrderDate), @maxDate = MAX(OrderDate) FROM dbo.FactSales;

IF @minDate = '2023-01-01' AND @maxDate = '2024-12-31'
    SET @dateSpanMatch = 'PASS';
ELSE
    SET @dateSpanMatch = 'FAIL';

INSERT INTO #FinalValidationResults VALUES
('Temporal Range', 'Order Date Range (2023-2024)', '2023-01-01 to 2024-12-31', 
 CAST(@minDate AS VARCHAR(10)) + ' to ' + CAST(@maxDate AS VARCHAR(10)), @dateSpanMatch);


-- ============================================================================
-- CHECK CATEGORY 7: REPORTING VIEW OPERABILITY
-- ============================================================================
DECLARE @v1Status VARCHAR(10) = 'PASS', @v2Status VARCHAR(10) = 'PASS', 
        @v3Status VARCHAR(10) = 'PASS', @v4Status VARCHAR(10) = 'PASS';

BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_SalesDetail;
END TRY
BEGIN CATCH
    SET @v1Status = 'FAIL';
END CATCH;

BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_MonthlySalesSummary;
END TRY
BEGIN CATCH
    SET @v2Status = 'FAIL';
END CATCH;

BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_CategoryPerformance;
END TRY
BEGIN CATCH
    SET @v3Status = 'FAIL';
END CATCH;

BEGIN TRY
    SELECT TOP 1 * FROM dbo.vw_CustomerRFMBase;
END TRY
BEGIN CATCH
    SET @v4Status = 'FAIL';
END CATCH;

INSERT INTO #FinalValidationResults VALUES
('Views Operability', 'View: dbo.vw_SalesDetail', 'OPERATIONAL', @v1Status, @v1Status),
('Views Operability', 'View: dbo.vw_MonthlySalesSummary', 'OPERATIONAL', @v2Status, @v2Status),
('Views Operability', 'View: dbo.vw_CategoryPerformance', 'OPERATIONAL', @v3Status, @v3Status),
('Views Operability', 'View: dbo.vw_CustomerRFMBase', 'OPERATIONAL', @v4Status, @v4Status);


-- ============================================================================
-- SUMMARY DISPLAY & FINAL VERDICT
-- ============================================================================
SELECT 
    CheckCategory,
    CheckName,
    ExpectedResult,
    ActualResult,
    [Status]
FROM #FinalValidationResults
ORDER BY 
    CASE CheckCategory
        WHEN 'Row Counts' THEN 1
        WHEN 'Primary Keys' THEN 2
        WHEN 'Referential Integrity' THEN 3
        WHEN 'Financial Integrity' THEN 4
        WHEN 'Business Logic' THEN 5
        WHEN 'Temporal Range' THEN 6
        WHEN 'Views Operability' THEN 7
        ELSE 8
    END, CheckName;

DECLARE @totalChecks INT, @passedChecks INT, @failedChecks INT;
SELECT 
    @totalChecks = COUNT(*),
    @passedChecks = SUM(CASE WHEN [Status] = 'PASS' THEN 1 ELSE 0 END),
    @failedChecks = SUM(CASE WHEN [Status] = 'FAIL' THEN 1 ELSE 0 END)
FROM #FinalValidationResults;

PRINT '';
PRINT '============================================================================';
PRINT '                FINAL PRODUCTION DATA VALIDATION SUMMARY                    ';
PRINT '============================================================================';
PRINT 'Total Quality Assurance Checks: ' + CAST(@totalChecks AS VARCHAR(10));
PRINT 'Passed Checks:                  ' + CAST(@passedChecks AS VARCHAR(10));
PRINT 'Failed Checks:                  ' + CAST(@failedChecks AS VARCHAR(10));

IF @failedChecks = 0
BEGIN
    PRINT 'FINAL VERDICT: [PASS] - DATA WAREHOUSE IS 100% VALIDATED, RECONCILED & CERTIFIED!';
    PRINT 'The Star Schema is completely ready for SQL Analysis, DAX & Power BI modeling.';
END
ELSE
BEGIN
    PRINT 'FINAL VERDICT: [FAIL] - DATA QUALITY ISSUES DETECTED. PLEASE REVIEW FAILED CHECKS.';
END
PRINT '============================================================================';
PRINT '';

-- Key Executive Metrics Snapshot
PRINT '--- Key Executive Warehouse Totals ---';
SELECT 
    COUNT(*) AS [TotalLineItems],
    COUNT(DISTINCT CustomerID) AS [ActiveCustomers],
    COUNT(DISTINCT ProductID) AS [ActiveProducts],
    COUNT(DISTINCT StoreID) AS [ActiveStores],
    SUM(Quantity) AS [TotalUnitsSold],
    FORMAT(SUM(SalesAmount), 'C', 'en-US') AS [TotalRevenue],
    FORMAT(SUM(CostAmount), 'C', 'en-US') AS [TotalCOGS],
    FORMAT(SUM(Profit), 'C', 'en-US') AS [TotalGrossProfit],
    FORMAT(ROUND(SUM(Profit) / NULLIF(SUM(SalesAmount), 0) * 100, 2), 'N2') + '%' AS [OverallGrossMarginPct]
FROM dbo.FactSales;
GO
