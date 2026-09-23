-- ============================================================================
-- Script: 04_transform_and_load.sql
-- Description: Transforms and loads data from staging tables into the production
--              Star Schema tables (dbo.DimDate, dbo.DimCustomer, dbo.DimProduct,
--              dbo.DimStore, dbo.FactSales) within an atomic transaction.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-06
-- ============================================================================

USE [RetailSalesAnalytics];
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT '        RETAIL SALES ANALYTICS - PRODUCTION STAR SCHEMA ETL LOAD            ';
PRINT '============================================================================';
PRINT 'Execution Timestamp: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '';

-- ============================================================================
-- PRE-CHECK: ENSURE STAGING TABLES CONTAIN DATA BEFORE RUNNING PRODUCTION LOAD
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM staging.stg_Sales)
BEGIN
    RAISERROR('ERROR: Staging tables are empty. Please run 02_load_staging_data.sql first.', 16, 1);
    RETURN;
END;

-- ============================================================================
-- BEGIN ATOMIC TRANSACTION
-- ============================================================================
BEGIN TRY
    BEGIN TRANSACTION;

    PRINT 'Step 1: Clearing existing production data in referential dependency order...';

    -- Child fact table must be cleared first before parent dimension tables
    DELETE FROM dbo.FactSales;
    PRINT '  - Cleared dbo.FactSales';

    DELETE FROM dbo.DimCustomer;
    PRINT '  - Cleared dbo.DimCustomer';

    DELETE FROM dbo.DimProduct;
    PRINT '  - Cleared dbo.DimProduct';

    DELETE FROM dbo.DimStore;
    PRINT '  - Cleared dbo.DimStore';

    DELETE FROM dbo.DimDate;
    PRINT '  - Cleared dbo.DimDate';
    PRINT 'All target tables cleared successfully.';
    PRINT '';

    -- ========================================================================
    -- STEP 2: LOAD CONFORMED DIMENSION: dbo.DimDate (Expected: 731 rows)
    -- ========================================================================
    PRINT 'Step 2: Loading [dbo].[DimDate] from [staging].[stg_Date]...';

    INSERT INTO dbo.DimDate (
        DateKey,
        FullDate,
        [Year],
        [Quarter],
        QuarterName,
        [Month],
        MonthName,
        MonthYear,
        WeekOfYear,
        DayOfWeek,
        DayName,
        DayOfMonth,
        IsWeekend,
        IsHoliday,
        FiscalYear,
        FiscalQuarter
    )
    SELECT 
        CAST(TRIM(DateKey) AS INT),
        CAST(TRIM(FullDate) AS DATE),
        CAST(TRIM([Year]) AS SMALLINT),
        CAST(TRIM([Quarter]) AS TINYINT),
        CAST(TRIM(QuarterName) AS VARCHAR(10)),
        CAST(TRIM([Month]) AS TINYINT),
        CAST(TRIM(MonthName) AS VARCHAR(15)),
        CAST(TRIM(MonthYear) AS VARCHAR(10)),
        CAST(TRIM(WeekOfYear) AS TINYINT),
        CAST(TRIM(DayOfWeek) AS TINYINT),
        CAST(TRIM(DayName) AS VARCHAR(10)),
        CAST(TRIM(DayOfMonth) AS TINYINT),
        CAST(TRIM(IsWeekend) AS BIT),
        CAST(TRIM(IsHoliday) AS BIT),
        CAST(TRIM(FiscalYear) AS VARCHAR(10)),
        CAST(TRIM(FiscalQuarter) AS VARCHAR(10))
    FROM staging.stg_Date;

    DECLARE @rowsDate INT = @@ROWCOUNT;
    PRINT '  -> Loaded ' + CAST(@rowsDate AS VARCHAR(10)) + ' rows into dbo.DimDate.';
    PRINT '';

    -- ========================================================================
    -- STEP 3: LOAD CUSTOMER DIMENSION: dbo.DimCustomer (Expected: 50,000 rows)
    -- Transformation: Empty DateOfBirth strings converted to NULL
    -- ========================================================================
    PRINT 'Step 3: Loading [dbo].[DimCustomer] from [staging].[stg_Customer]...';

    INSERT INTO dbo.DimCustomer (
        CustomerID,
        FirstName,
        LastName,
        Email,
        Phone,
        Gender,
        DateOfBirth,
        City,
        [State],
        Region,
        PostalCode,
        CustomerSegment,
        JoinDate
    )
    SELECT 
        CAST(TRIM(CustomerID) AS VARCHAR(20)),
        CAST(TRIM(FirstName) AS VARCHAR(50)),
        CAST(TRIM(LastName) AS VARCHAR(50)),
        CAST(TRIM(Email) AS VARCHAR(100)),
        CAST(TRIM(Phone) AS VARCHAR(30)),
        CAST(TRIM(Gender) AS VARCHAR(20)),
        CASE 
            WHEN TRIM(DateOfBirth) = '' OR DateOfBirth IS NULL THEN NULL 
            ELSE CAST(TRIM(DateOfBirth) AS DATE) 
        END,
        CAST(TRIM(City) AS VARCHAR(50)),
        CAST(TRIM([State]) AS VARCHAR(10)),
        CAST(TRIM(Region) AS VARCHAR(20)),
        CAST(TRIM(PostalCode) AS VARCHAR(10)),
        CAST(TRIM(CustomerSegment) AS VARCHAR(30)),
        CAST(TRIM(JoinDate) AS DATE)
    FROM staging.stg_Customer;

    DECLARE @rowsCust INT = @@ROWCOUNT;
    PRINT '  -> Loaded ' + CAST(@rowsCust AS VARCHAR(10)) + ' rows into dbo.DimCustomer.';
    PRINT '';

    -- ========================================================================
    -- STEP 4: LOAD PRODUCT DIMENSION: dbo.DimProduct (Expected: 500 rows)
    -- ========================================================================
    PRINT 'Step 4: Loading [dbo].[DimProduct] from [staging].[stg_Product]...';

    INSERT INTO dbo.DimProduct (
        ProductID,
        ProductName,
        Category,
        Subcategory,
        Brand,
        UnitCost,
        UnitPrice,
        [Status]
    )
    SELECT 
        CAST(TRIM(ProductID) AS VARCHAR(20)),
        CAST(TRIM(ProductName) AS VARCHAR(150)),
        CAST(TRIM(Category) AS VARCHAR(50)),
        CAST(TRIM(Subcategory) AS VARCHAR(50)),
        CAST(TRIM(Brand) AS VARCHAR(50)),
        CAST(TRIM(UnitCost) AS DECIMAL(10, 2)),
        CAST(TRIM(UnitPrice) AS DECIMAL(10, 2)),
        CAST(TRIM([Status]) AS VARCHAR(20))
    FROM staging.stg_Product;

    DECLARE @rowsProd INT = @@ROWCOUNT;
    PRINT '  -> Loaded ' + CAST(@rowsProd AS VARCHAR(10)) + ' rows into dbo.DimProduct.';
    PRINT '';

    -- ========================================================================
    -- STEP 5: LOAD STORE DIMENSION: dbo.DimStore (Expected: 30 rows)
    -- ========================================================================
    PRINT 'Step 5: Loading [dbo].[DimStore] from [staging].[stg_Store]...';

    INSERT INTO dbo.DimStore (
        StoreID,
        StoreName,
        StoreType,
        City,
        [State],
        Region,
        SquareFootage,
        OpenDate,
        ManagerName
    )
    SELECT 
        CAST(TRIM(StoreID) AS VARCHAR(20)),
        CAST(TRIM(StoreName) AS VARCHAR(100)),
        CAST(TRIM(StoreType) AS VARCHAR(50)),
        CAST(TRIM(City) AS VARCHAR(50)),
        CAST(TRIM([State]) AS VARCHAR(20)),
        CAST(TRIM(Region) AS VARCHAR(20)),
        CAST(TRIM(SquareFootage) AS INT),
        CAST(TRIM(OpenDate) AS DATE),
        CAST(TRIM(ManagerName) AS VARCHAR(100))
    FROM staging.stg_Store;

    DECLARE @rowsStore INT = @@ROWCOUNT;
    PRINT '  -> Loaded ' + CAST(@rowsStore AS VARCHAR(10)) + ' rows into dbo.DimStore.';
    PRINT '';

    -- ========================================================================
    -- STEP 6: LOAD CENTRAL FACT TABLE: dbo.FactSales (Expected: 320,536 rows)
    -- Transformation: Staging 'TransactionID' maps to Primary Key 'SalesID'
    -- ========================================================================
    PRINT 'Step 6: Loading [dbo].[FactSales] from [staging].[stg_Sales]...';

    INSERT INTO dbo.FactSales (
        SalesID,
        DateKey,
        OrderDate,
        CustomerID,
        ProductID,
        StoreID,
        SalesChannel,
        Quantity,
        UnitPrice,
        Discount,
        DiscountAmount,
        SalesAmount,
        UnitCost,
        CostAmount,
        Profit,
        PaymentMethod
    )
    SELECT 
        CAST(TRIM(TransactionID) AS VARCHAR(20)),
        CAST(TRIM(DateKey) AS INT),
        CAST(TRIM(OrderDate) AS DATE),
        CAST(TRIM(CustomerID) AS VARCHAR(20)),
        CAST(TRIM(ProductID) AS VARCHAR(20)),
        CAST(TRIM(StoreID) AS VARCHAR(20)),
        CAST(TRIM(SalesChannel) AS VARCHAR(20)),
        CAST(TRIM(Quantity) AS INT),
        CAST(TRIM(UnitPrice) AS DECIMAL(10, 2)),
        CAST(TRIM(Discount) AS DECIMAL(4, 2)),
        CAST(TRIM(DiscountAmount) AS DECIMAL(10, 2)),
        CAST(TRIM(SalesAmount) AS DECIMAL(10, 2)),
        CAST(TRIM(UnitCost) AS DECIMAL(10, 2)),
        CAST(TRIM(CostAmount) AS DECIMAL(10, 2)),
        CAST(TRIM(Profit) AS DECIMAL(10, 2)),
        CAST(TRIM(PaymentMethod) AS VARCHAR(30))
    FROM staging.stg_Sales;

    DECLARE @rowsSales INT = @@ROWCOUNT;
    PRINT '  -> Loaded ' + CAST(@rowsSales AS VARCHAR(10)) + ' rows into dbo.FactSales.';
    PRINT '';

    -- ========================================================================
    -- COMMIT TRANSACTION
    -- ========================================================================
    COMMIT TRANSACTION;
    PRINT 'Transaction COMMITTED successfully.';
    PRINT '';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Transaction ROLLED BACK due to error.';
    END;

    PRINT '============================================================================';
    PRINT '                       ETL LOAD ERROR DETAILS                               ';
    PRINT '============================================================================';
    PRINT 'Error Number:    ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error Line:      ' + CAST(ERROR_LINE() AS VARCHAR(10));
    PRINT 'Error Message:   ' + ERROR_MESSAGE();
    PRINT '============================================================================';

    THROW;
END CATCH;

-- ============================================================================
-- STEP 7: SUMMARY OF PRODUCTION ROW COUNTS
-- ============================================================================
PRINT '============================================================================';
PRINT '                 PRODUCTION STAR SCHEMA LOAD SUMMARY                        ';
PRINT '============================================================================';

SELECT 
    t.name AS [TableName],
    SUM(p.rows) AS [ActualRowCount],
    CASE t.name
        WHEN 'DimDate'     THEN 731
        WHEN 'DimCustomer' THEN 50000
        WHEN 'DimProduct'  THEN 500
        WHEN 'DimStore'    THEN 30
        WHEN 'FactSales'   THEN 320536
        ELSE 0
    END AS [ExpectedRowCount],
    CASE 
        WHEN t.name = 'DimDate'     AND SUM(p.rows) = 731    THEN 'SUCCESS (MATCH)'
        WHEN t.name = 'DimCustomer' AND SUM(p.rows) = 50000  THEN 'SUCCESS (MATCH)'
        WHEN t.name = 'DimProduct'  AND SUM(p.rows) = 500    THEN 'SUCCESS (MATCH)'
        WHEN t.name = 'DimStore'    AND SUM(p.rows) = 30     THEN 'SUCCESS (MATCH)'
        WHEN t.name = 'FactSales'   AND SUM(p.rows) = 320536 THEN 'SUCCESS (MATCH)'
        ELSE 'FAIL (MISMATCH)'
    END AS [LoadStatus]
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE s.name = 'dbo'
  AND t.name IN ('DimDate', 'DimCustomer', 'DimProduct', 'DimStore', 'FactSales')
  AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY 
    CASE t.name
        WHEN 'DimDate'     THEN 1
        WHEN 'DimCustomer' THEN 2
        WHEN 'DimProduct'  THEN 3
        WHEN 'DimStore'    THEN 4
        WHEN 'FactSales'   THEN 5
    END;

PRINT '============================================================================';
PRINT 'ETL Transform and Load process completed.';
PRINT 'Proceed to execute 05_validate_final_data.sql for comprehensive QA audit.';
PRINT '============================================================================';
GO
