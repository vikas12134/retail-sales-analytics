-- ============================================================================
-- Script: 03_validate_staging_data.sql
-- Description: Automated quality assurance and data validation suite for staging tables.
--              Validates row counts, nullability, uniqueness, referential integrity,
--              and type castability before executing production load.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-06
-- ============================================================================

USE [RetailSalesAnalytics];
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT '        RETAIL SALES ANALYTICS - STAGING DATA VALIDATION REPORT             ';
PRINT '============================================================================';
PRINT 'Execution Timestamp: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT 'Current Database:    ' + DB_NAME();
PRINT '';

-- Temporary table to collect validation results
IF OBJECT_ID('tempdb..#StagingValidationResults') IS NOT NULL
    DROP TABLE #StagingValidationResults;

CREATE TABLE #StagingValidationResults (
    CheckCategory   VARCHAR(50),
    CheckName       VARCHAR(100),
    ExpectedResult  VARCHAR(100),
    ActualResult    VARCHAR(100),
    [Status]        VARCHAR(10)
);

-- ============================================================================
-- CHECK CATEGORY 1: STAGING ROW COUNTS
-- ============================================================================
DECLARE @cntDate INT, @cntCust INT, @cntProd INT, @cntStore INT, @cntSales INT;

SELECT @cntDate  = COUNT(*) FROM staging.stg_Date;
SELECT @cntCust  = COUNT(*) FROM staging.stg_Customer;
SELECT @cntProd  = COUNT(*) FROM staging.stg_Product;
SELECT @cntStore = COUNT(*) FROM staging.stg_Store;
SELECT @cntSales = COUNT(*) FROM staging.stg_Sales;

INSERT INTO #StagingValidationResults VALUES
('Row Counts', 'staging.stg_Date Row Count', '731', CAST(@cntDate AS VARCHAR(20)),
 CASE WHEN @cntDate = 731 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'staging.stg_Customer Row Count', '50000', CAST(@cntCust AS VARCHAR(20)),
 CASE WHEN @cntCust = 50000 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'staging.stg_Product Row Count', '500', CAST(@cntProd AS VARCHAR(20)),
 CASE WHEN @cntProd = 500 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'staging.stg_Store Row Count', '30', CAST(@cntStore AS VARCHAR(20)),
 CASE WHEN @cntStore = 30 THEN 'PASS' ELSE 'FAIL' END),
('Row Counts', 'staging.stg_Sales Row Count', '320536', CAST(@cntSales AS VARCHAR(20)),
 CASE WHEN @cntSales = 320536 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 2: PRIMARY / BUSINESS KEY NULL & BLANK CHECKS
-- ============================================================================
DECLARE @nullDateKey INT, @nullCustID INT, @nullProdID INT, @nullStoreID INT, @nullTxnID INT;

SELECT @nullDateKey = COUNT(*) FROM staging.stg_Date WHERE DateKey IS NULL OR TRIM(DateKey) = '';
SELECT @nullCustID  = COUNT(*) FROM staging.stg_Customer WHERE CustomerID IS NULL OR TRIM(CustomerID) = '';
SELECT @nullProdID  = COUNT(*) FROM staging.stg_Product WHERE ProductID IS NULL OR TRIM(ProductID) = '';
SELECT @nullStoreID = COUNT(*) FROM staging.stg_Store WHERE StoreID IS NULL OR TRIM(StoreID) = '';
SELECT @nullTxnID   = COUNT(*) FROM staging.stg_Sales WHERE TransactionID IS NULL OR TRIM(TransactionID) = '';

INSERT INTO #StagingValidationResults VALUES
('Primary Key Nulls', 'stg_Date.DateKey NULL or Blank', '0', CAST(@nullDateKey AS VARCHAR(20)),
 CASE WHEN @nullDateKey = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Key Nulls', 'stg_Customer.CustomerID NULL or Blank', '0', CAST(@nullCustID AS VARCHAR(20)),
 CASE WHEN @nullCustID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Key Nulls', 'stg_Product.ProductID NULL or Blank', '0', CAST(@nullProdID AS VARCHAR(20)),
 CASE WHEN @nullProdID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Key Nulls', 'stg_Store.StoreID NULL or Blank', '0', CAST(@nullStoreID AS VARCHAR(20)),
 CASE WHEN @nullStoreID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Primary Key Nulls', 'stg_Sales.TransactionID NULL or Blank', '0', CAST(@nullTxnID AS VARCHAR(20)),
 CASE WHEN @nullTxnID = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 3: PRIMARY / BUSINESS KEY UNIQUENESS (DUPLICATES)
-- ============================================================================
DECLARE @dupDateKey INT, @dupCustID INT, @dupProdID INT, @dupStoreID INT, @dupTxnID INT;

SELECT @dupDateKey = ISNULL(SUM(cnt - 1), 0) FROM (SELECT DateKey, COUNT(*) AS cnt FROM staging.stg_Date GROUP BY DateKey HAVING COUNT(*) > 1) d;
SELECT @dupCustID  = ISNULL(SUM(cnt - 1), 0) FROM (SELECT CustomerID, COUNT(*) AS cnt FROM staging.stg_Customer GROUP BY CustomerID HAVING COUNT(*) > 1) d;
SELECT @dupProdID  = ISNULL(SUM(cnt - 1), 0) FROM (SELECT ProductID, COUNT(*) AS cnt FROM staging.stg_Product GROUP BY ProductID HAVING COUNT(*) > 1) d;
SELECT @dupStoreID = ISNULL(SUM(cnt - 1), 0) FROM (SELECT StoreID, COUNT(*) AS cnt FROM staging.stg_Store GROUP BY StoreID HAVING COUNT(*) > 1) d;
SELECT @dupTxnID   = ISNULL(SUM(cnt - 1), 0) FROM (SELECT TransactionID, COUNT(*) AS cnt FROM staging.stg_Sales GROUP BY TransactionID HAVING COUNT(*) > 1) d;

INSERT INTO #StagingValidationResults VALUES
('Key Uniqueness', 'stg_Date.DateKey Duplicates', '0', CAST(@dupDateKey AS VARCHAR(20)),
 CASE WHEN @dupDateKey = 0 THEN 'PASS' ELSE 'FAIL' END),
('Key Uniqueness', 'stg_Customer.CustomerID Duplicates', '0', CAST(@dupCustID AS VARCHAR(20)),
 CASE WHEN @dupCustID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Key Uniqueness', 'stg_Product.ProductID Duplicates', '0', CAST(@dupProdID AS VARCHAR(20)),
 CASE WHEN @dupProdID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Key Uniqueness', 'stg_Store.StoreID Duplicates', '0', CAST(@dupStoreID AS VARCHAR(20)),
 CASE WHEN @dupStoreID = 0 THEN 'PASS' ELSE 'FAIL' END),
('Key Uniqueness', 'stg_Sales.TransactionID Duplicates', '0', CAST(@dupTxnID AS VARCHAR(20)),
 CASE WHEN @dupTxnID = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 4: REFERENTIAL INTEGRITY PRE-CHECK (ORPHAN RECORDS)
-- ============================================================================
DECLARE @orphanDate INT, @orphanCust INT, @orphanProd INT, @orphanStore INT;

-- Sales DateKey -> Date DateKey
SELECT @orphanDate = COUNT(*) 
FROM staging.stg_Sales s
LEFT JOIN staging.stg_Date d ON TRIM(s.DateKey) = TRIM(d.DateKey)
WHERE d.DateKey IS NULL;

-- Sales CustomerID -> Customer CustomerID
SELECT @orphanCust = COUNT(*) 
FROM staging.stg_Sales s
LEFT JOIN staging.stg_Customer c ON TRIM(s.CustomerID) = TRIM(c.CustomerID)
WHERE c.CustomerID IS NULL;

-- Sales ProductID -> Product ProductID
SELECT @orphanProd = COUNT(*) 
FROM staging.stg_Sales s
LEFT JOIN staging.stg_Product p ON TRIM(s.ProductID) = TRIM(p.ProductID)
WHERE p.ProductID IS NULL;

-- Sales StoreID -> Store StoreID
SELECT @orphanStore = COUNT(*) 
FROM staging.stg_Sales s
LEFT JOIN staging.stg_Store st ON TRIM(s.StoreID) = TRIM(st.StoreID)
WHERE st.StoreID IS NULL;

INSERT INTO #StagingValidationResults VALUES
('Referential Integrity', 'Orphan DateKey in stg_Sales', '0', CAST(@orphanDate AS VARCHAR(20)),
 CASE WHEN @orphanDate = 0 THEN 'PASS' ELSE 'FAIL' END),
('Referential Integrity', 'Orphan CustomerID in stg_Sales', '0', CAST(@orphanCust AS VARCHAR(20)),
 CASE WHEN @orphanCust = 0 THEN 'PASS' ELSE 'FAIL' END),
('Referential Integrity', 'Orphan ProductID in stg_Sales', '0', CAST(@orphanProd AS VARCHAR(20)),
 CASE WHEN @orphanProd = 0 THEN 'PASS' ELSE 'FAIL' END),
('Referential Integrity', 'Orphan StoreID in stg_Sales', '0', CAST(@orphanStore AS VARCHAR(20)),
 CASE WHEN @orphanStore = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 5: DATA TYPE CASTABILITY & FORMAT HYGIENE
-- ============================================================================
DECLARE @invalidOrderDates INT, @invalidQuantities INT, @invalidSalesAmounts INT, 
        @invalidUnitPrices INT, @invalidDiscounts INT, @invalidDOB INT;

SELECT @invalidOrderDates   = COUNT(*) FROM staging.stg_Sales WHERE TRY_CAST(TRIM(OrderDate) AS DATE) IS NULL;
SELECT @invalidQuantities   = COUNT(*) FROM staging.stg_Sales WHERE TRY_CAST(TRIM(Quantity) AS INT) IS NULL;
SELECT @invalidSalesAmounts = COUNT(*) FROM staging.stg_Sales WHERE TRY_CAST(TRIM(SalesAmount) AS DECIMAL(10,2)) IS NULL;
SELECT @invalidUnitPrices   = COUNT(*) FROM staging.stg_Sales WHERE TRY_CAST(TRIM(UnitPrice) AS DECIMAL(10,2)) IS NULL;
SELECT @invalidDiscounts    = COUNT(*) FROM staging.stg_Sales WHERE TRY_CAST(TRIM(Discount) AS DECIMAL(4,2)) IS NULL;

-- DOB in stg_Customer can be empty/NULL, but if provided, must cast to DATE:
SELECT @invalidDOB = COUNT(*) 
FROM staging.stg_Customer 
WHERE TRIM(DateOfBirth) <> '' 
  AND DateOfBirth IS NOT NULL 
  AND TRY_CAST(TRIM(DateOfBirth) AS DATE) IS NULL;

INSERT INTO #StagingValidationResults VALUES
('Data Castability', 'stg_Sales.OrderDate valid DATE', '0 invalid', CAST(@invalidOrderDates AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidOrderDates = 0 THEN 'PASS' ELSE 'FAIL' END),
('Data Castability', 'stg_Sales.Quantity valid INT', '0 invalid', CAST(@invalidQuantities AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidQuantities = 0 THEN 'PASS' ELSE 'FAIL' END),
('Data Castability', 'stg_Sales.SalesAmount valid DECIMAL', '0 invalid', CAST(@invalidSalesAmounts AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidSalesAmounts = 0 THEN 'PASS' ELSE 'FAIL' END),
('Data Castability', 'stg_Sales.UnitPrice valid DECIMAL', '0 invalid', CAST(@invalidUnitPrices AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidUnitPrices = 0 THEN 'PASS' ELSE 'FAIL' END),
('Data Castability', 'stg_Sales.Discount valid DECIMAL', '0 invalid', CAST(@invalidDiscounts AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidDiscounts = 0 THEN 'PASS' ELSE 'FAIL' END),
('Data Castability', 'stg_Customer.DateOfBirth valid DATE (if populated)', '0 invalid', CAST(@invalidDOB AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidDOB = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK CATEGORY 6: BUSINESS DOMAIN VALIDATION
-- ============================================================================
DECLARE @invalidChannels INT, @invalidCategories INT, @invalidSegments INT;

SELECT @invalidChannels = COUNT(*) 
FROM staging.stg_Sales 
WHERE TRIM(SalesChannel) NOT IN ('Online', 'In-Store');

SELECT @invalidCategories = COUNT(*) 
FROM staging.stg_Product 
WHERE TRIM(Category) NOT IN (
    'Electronics & Gadgets',
    'Home & Kitchen',
    'Apparel & Accessories',
    'Beauty & Personal Care',
    'Sports & Outdoors'
);

SELECT @invalidSegments = COUNT(*) 
FROM staging.stg_Customer 
WHERE TRIM(CustomerSegment) NOT IN ('Regular', 'Silver', 'Gold', 'VIP Platinum');

INSERT INTO #StagingValidationResults VALUES
('Business Domains', 'stg_Sales.SalesChannel valid values', '0 invalid', CAST(@invalidChannels AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidChannels = 0 THEN 'PASS' ELSE 'FAIL' END),
('Business Domains', 'stg_Product.Category valid domains', '0 invalid', CAST(@invalidCategories AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidCategories = 0 THEN 'PASS' ELSE 'FAIL' END),
('Business Domains', 'stg_Customer.CustomerSegment valid tiers', '0 invalid', CAST(@invalidSegments AS VARCHAR(20)) + ' invalid',
 CASE WHEN @invalidSegments = 0 THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- SUMMARY DISPLAY & FINAL VERDICT
-- ============================================================================
SELECT 
    CheckCategory,
    CheckName,
    ExpectedResult,
    ActualResult,
    [Status]
FROM #StagingValidationResults
ORDER BY 
    CASE CheckCategory
        WHEN 'Row Counts' THEN 1
        WHEN 'Primary Key Nulls' THEN 2
        WHEN 'Key Uniqueness' THEN 3
        WHEN 'Referential Integrity' THEN 4
        WHEN 'Data Castability' THEN 5
        WHEN 'Business Domains' THEN 6
        ELSE 7
    END, CheckName;

DECLARE @totalChecks INT, @passedChecks INT, @failedChecks INT;
SELECT 
    @totalChecks = COUNT(*),
    @passedChecks = SUM(CASE WHEN [Status] = 'PASS' THEN 1 ELSE 0 END),
    @failedChecks = SUM(CASE WHEN [Status] = 'FAIL' THEN 1 ELSE 0 END)
FROM #StagingValidationResults;

PRINT '';
PRINT '============================================================================';
PRINT '                    STAGING VALIDATION SUMMARY RESULTS                      ';
PRINT '============================================================================';
PRINT 'Total Staging Verification Checks: ' + CAST(@totalChecks AS VARCHAR(10));
PRINT 'Passed Checks:                     ' + CAST(@passedChecks AS VARCHAR(10));
PRINT 'Failed Checks:                     ' + CAST(@failedChecks AS VARCHAR(10));

IF @failedChecks = 0
BEGIN
    PRINT 'FINAL VERDICT: [PASS] - STAGING DATA IS 100% VALIDATED AND READY TO LOAD!';
    PRINT 'You may safely proceed to execute 04_transform_and_load.sql.';
END
ELSE
BEGIN
    PRINT 'FINAL VERDICT: [FAIL] - STAGING DATA HAS QUALITY ISSUES. REVIEW FAILED CHECKS ABOVE.';
    PRINT 'Do NOT proceed with production load until staging issues are resolved.';
END
PRINT '============================================================================';
PRINT '';
GO
