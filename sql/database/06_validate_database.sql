-- ============================================================================
-- Script: 06_validate_database.sql
-- Description: Automated schema validation suite checking tables, keys, 
-- constraints, indexes, views, and providing post-load verification queries.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-05
-- ============================================================================

USE [RetailSalesAnalytics];
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT '        RETAIL SALES ANALYTICS - DATABASE SCHEMA VALIDATION REPORT          ';
PRINT '============================================================================';
PRINT 'Execution Timestamp: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT 'Current Database:    ' + DB_NAME();
PRINT '';

-- Temporary table to collect validation results
IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
    DROP TABLE #ValidationResults;

CREATE TABLE #ValidationResults (
    CheckCategory   VARCHAR(50),
    CheckName       VARCHAR(100),
    ExpectedResult  VARCHAR(100),
    ActualResult    VARCHAR(100),
    [Status]        VARCHAR(10)
);

-- ============================================================================
-- CHECK 1: DATABASE EXISTENCE & PROPERTIES
-- ============================================================================
DECLARE @dbName VARCHAR(100) = DB_NAME();
DECLARE @recoveryModel VARCHAR(50) = CONVERT(VARCHAR(50), DATABASEPROPERTYEX(@dbName, 'Recovery'));

INSERT INTO #ValidationResults
VALUES 
('Database', 'Database Name', 'RetailSalesAnalytics', @dbName, 
 CASE WHEN @dbName = 'RetailSalesAnalytics' THEN 'PASS' ELSE 'FAIL' END),
('Database', 'Recovery Model', 'SIMPLE', @recoveryModel, 
 CASE WHEN @recoveryModel = 'SIMPLE' THEN 'PASS' ELSE 'FAIL' END);


-- ============================================================================
-- CHECK 2: STAR SCHEMA TABLE EXISTENCE (5 TABLES)
-- ============================================================================
DECLARE @expectedTables TABLE (TableName VARCHAR(50));
INSERT INTO @expectedTables VALUES 
('DimDate'), ('DimCustomer'), ('DimProduct'), ('DimStore'), ('FactSales');

INSERT INTO #ValidationResults
SELECT 
    'Table Existence',
    'Table: dbo.' + e.TableName,
    'EXISTS',
    CASE WHEN t.name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
    CASE WHEN t.name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END
FROM @expectedTables e
LEFT JOIN sys.tables t ON t.name = e.TableName AND SCHEMA_NAME(t.schema_id) = 'dbo';


-- ============================================================================
-- CHECK 3: PRIMARY KEY CONSTRAINTS (5 PRIMARY KEYS)
-- ============================================================================
DECLARE @expectedPKs TABLE (TableName VARCHAR(50), PKName VARCHAR(50), KeyColumn VARCHAR(50));
INSERT INTO @expectedPKs VALUES 
('DimDate', 'PK_DimDate', 'DateKey'),
('DimCustomer', 'PK_DimCustomer', 'CustomerID'),
('DimProduct', 'PK_DimProduct', 'ProductID'),
('DimStore', 'PK_DimStore', 'StoreID'),
('FactSales', 'PK_FactSales', 'SalesID');

INSERT INTO #ValidationResults
SELECT 
    'Primary Keys',
    'PK on dbo.' + e.TableName + ' (' + e.KeyColumn + ')',
    e.PKName,
    ISNULL(kc.name, 'MISSING'),
    CASE WHEN kc.name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END
FROM @expectedPKs e
LEFT JOIN sys.key_constraints kc 
    ON kc.name = e.PKName AND kc.type = 'PK';


-- ============================================================================
-- CHECK 4: FOREIGN KEY CONSTRAINTS (4 REFERENTIAL CONSTRAINTS)
-- ============================================================================
DECLARE @expectedFKs TABLE (FKName VARCHAR(50), ParentTable VARCHAR(50), ChildTable VARCHAR(50));
INSERT INTO @expectedFKs VALUES 
('FK_FactSales_DimDate', 'DimDate', 'FactSales'),
('FK_FactSales_DimCustomer', 'DimCustomer', 'FactSales'),
('FK_FactSales_DimProduct', 'DimProduct', 'FactSales'),
('FK_FactSales_DimStore', 'DimStore', 'FactSales');

INSERT INTO #ValidationResults
SELECT 
    'Foreign Keys',
    e.FKName + ' (' + e.ChildTable + ' -> ' + e.ParentTable + ')',
    'EXISTS & ACTIVE',
    CASE 
        WHEN fk.name IS NOT NULL AND fk.is_disabled = 0 THEN 'EXISTS & ACTIVE'
        WHEN fk.name IS NOT NULL AND fk.is_disabled = 1 THEN 'DISABLED'
        ELSE 'MISSING' 
    END,
    CASE WHEN fk.name IS NOT NULL AND fk.is_disabled = 0 THEN 'PASS' ELSE 'FAIL' END
FROM @expectedFKs e
LEFT JOIN sys.foreign_keys fk 
    ON fk.name = e.FKName;


-- ============================================================================
-- CHECK 5: CHECK CONSTRAINTS (13 CONSTRAINTS)
-- ============================================================================
DECLARE @expectedCKs TABLE (CKName VARCHAR(50), TableName VARCHAR(50));
INSERT INTO @expectedCKs VALUES 
('CK_FactSales_Quantity', 'FactSales'),
('CK_FactSales_Discount', 'FactSales'),
('CK_FactSales_UnitPrice', 'FactSales'),
('CK_FactSales_UnitCost', 'FactSales'),
('CK_FactSales_SalesAmount', 'FactSales'),
('CK_FactSales_CostAmount', 'FactSales'),
('CK_FactSales_SalesChannel', 'FactSales'),
('CK_DimProduct_UnitPrice', 'DimProduct'),
('CK_DimProduct_UnitCost', 'DimProduct'),
('CK_DimProduct_Category', 'DimProduct'),
('CK_DimCustomer_Segment', 'DimCustomer'),
('CK_DimCustomer_Gender', 'DimCustomer'),
('CK_DimStore_SquareFootage', 'DimStore');

INSERT INTO #ValidationResults
SELECT 
    'Check Constraints',
    e.CKName + ' on ' + e.TableName,
    'EXISTS & ACTIVE',
    CASE 
        WHEN cc.name IS NOT NULL AND cc.is_disabled = 0 THEN 'EXISTS & ACTIVE'
        ELSE 'MISSING' 
    END,
    CASE WHEN cc.name IS NOT NULL AND cc.is_disabled = 0 THEN 'PASS' ELSE 'FAIL' END
FROM @expectedCKs e
LEFT JOIN sys.check_constraints cc 
    ON cc.name = e.CKName;


-- ============================================================================
-- CHECK 6: INDEXES (11 INDEXES)
-- ============================================================================
DECLARE @expectedIndexes TABLE (IndexName VARCHAR(50), TableName VARCHAR(50));
INSERT INTO @expectedIndexes VALUES 
('IX_FactSales_DateKey', 'FactSales'),
('IX_FactSales_CustomerID', 'FactSales'),
('IX_FactSales_ProductID', 'FactSales'),
('IX_FactSales_StoreID', 'FactSales'),
('IX_FactSales_OrderDate', 'FactSales'),
('IX_DimCustomer_Region_State', 'DimCustomer'),
('IX_DimCustomer_Segment', 'DimCustomer'),
('IX_DimProduct_Category_Subcategory', 'DimProduct'),
('IX_DimProduct_Brand', 'DimProduct'),
('IX_DimStore_Region_StoreType', 'DimStore'),
('IX_DimDate_Year_Month', 'DimDate');

INSERT INTO #ValidationResults
SELECT 
    'Indexes',
    'Index: ' + e.IndexName + ' on ' + e.TableName,
    'EXISTS',
    CASE WHEN i.name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
    CASE WHEN i.name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END
FROM @expectedIndexes e
LEFT JOIN sys.indexes i 
    ON i.name = e.IndexName;


-- ============================================================================
-- CHECK 7: ANALYTICAL VIEWS (4 VIEWS)
-- ============================================================================
DECLARE @expectedViews TABLE (ViewName VARCHAR(50));
INSERT INTO @expectedViews VALUES 
('vw_SalesDetail'),
('vw_MonthlySalesSummary'),
('vw_CategoryPerformance'),
('vw_CustomerRFMBase');

INSERT INTO #ValidationResults
SELECT 
    'Views',
    'View: dbo.' + e.ViewName,
    'EXISTS',
    CASE WHEN v.name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
    CASE WHEN v.name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END
FROM @expectedViews e
LEFT JOIN sys.views v 
    ON v.name = e.ViewName AND SCHEMA_NAME(v.schema_id) = 'dbo';


-- ============================================================================
-- SUMMARY DISPLAY & FINAL VERDICT
-- ============================================================================
SELECT 
    CheckCategory,
    CheckName,
    ExpectedResult,
    ActualResult,
    [Status]
FROM #ValidationResults
ORDER BY 
    CASE CheckCategory
        WHEN 'Database' THEN 1
        WHEN 'Table Existence' THEN 2
        WHEN 'Primary Keys' THEN 3
        WHEN 'Foreign Keys' THEN 4
        WHEN 'Check Constraints' THEN 5
        WHEN 'Indexes' THEN 6
        WHEN 'Views' THEN 7
        ELSE 8
    END, CheckName;

DECLARE @totalChecks INT, @passedChecks INT, @failedChecks INT;
SELECT 
    @totalChecks = COUNT(*),
    @passedChecks = SUM(CASE WHEN [Status] = 'PASS' THEN 1 ELSE 0 END),
    @failedChecks = SUM(CASE WHEN [Status] = 'FAIL' THEN 1 ELSE 0 END)
FROM #ValidationResults;

PRINT '';
PRINT '============================================================================';
PRINT '                      VALIDATION SUMMARY RESULTS                            ';
PRINT '============================================================================';
PRINT 'Total Schema Verification Checks: ' + CAST(@totalChecks AS VARCHAR(10));
PRINT 'Passed Checks:                    ' + CAST(@passedChecks AS VARCHAR(10));
PRINT 'Failed Checks:                    ' + CAST(@failedChecks AS VARCHAR(10));

IF @failedChecks = 0
BEGIN
    PRINT 'FINAL VERDICT: [PASS] - DATABASE SCHEMA IS 100% CERTIFIED AND READY!';
END
ELSE
BEGIN
    PRINT 'FINAL VERDICT: [FAIL] - PLEASE REVIEW FAILED CHECKS ABOVE.';
END
PRINT '============================================================================';
PRINT '';


-- ============================================================================
-- POST-LOAD VERIFICATION TEMPLATE QUERIES (FOR TASK 7)
-- NOTE: Do NOT run for data validation until CSV data is loaded in Task 7.
-- ============================================================================
PRINT '--- Post-Load Verification Query Reference (For Task 7 ETL Verification) ---';
PRINT 'SELECT ''DimDate''      AS [Table], COUNT(*) AS [ActualRows], 731     AS [ExpectedRows] FROM dbo.DimDate';
PRINT 'UNION ALL';
PRINT 'SELECT ''DimCustomer''  AS [Table], COUNT(*) AS [ActualRows], 50000   AS [ExpectedRows] FROM dbo.DimCustomer';
PRINT 'UNION ALL';
PRINT 'SELECT ''DimProduct''   AS [Table], COUNT(*) AS [ActualRows], 500     AS [ExpectedRows] FROM dbo.DimProduct';
PRINT 'UNION ALL';
PRINT 'SELECT ''DimStore''     AS [Table], COUNT(*) AS [ActualRows], 30      AS [ExpectedRows] FROM dbo.DimStore';
PRINT 'UNION ALL';
PRINT 'SELECT ''FactSales''    AS [Table], COUNT(*) AS [ActualRows], 320536  AS [ExpectedRows] FROM dbo.FactSales;';
PRINT '';

-- Current Table Row Counts (Should all be 0 at Task 6 completion)
SELECT 
    t.name AS [TableName],
    SUM(p.rows) AS [CurrentRowCount],
    CASE 
        WHEN SUM(p.rows) = 0 THEN 'READY FOR DATA LOAD (0 Rows)'
        ELSE 'CONTAINS DATA (' + CAST(SUM(p.rows) AS VARCHAR(20)) + ' Rows)'
    END AS [LoadStatus]
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.name IN ('DimDate', 'DimCustomer', 'DimProduct', 'DimStore', 'FactSales')
  AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;
GO
