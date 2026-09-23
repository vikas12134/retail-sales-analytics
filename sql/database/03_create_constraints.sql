-- ============================================================================
-- Script: 03_create_constraints.sql
-- Description: Enforces Referential Integrity (Foreign Keys) and Data Quality (CHECK Constraints).
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-05
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- PART 1: REFERENTIAL INTEGRITY CONSTRAINTS (FOREIGN KEYS)
-- All relationships follow Star Schema architecture:
-- Dimensions = ONE side (Parent with Primary Key)
-- FactSales  = MANY side (Child with Foreign Key)
-- ============================================================================

-- 1. FactSales -> DimDate
-- Purpose: Ensures every sale maps strictly to an existing calendar day in the 2023-2024 period.
-- Supports time-series intelligence, fiscal reporting, and MoM/YoY trend analysis.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_FactSales_DimDate')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT FK_FactSales_DimDate
    FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey);
    PRINT 'Foreign Key [FK_FactSales_DimDate] added successfully.';
END
ELSE
BEGIN
    PRINT 'Foreign Key [FK_FactSales_DimDate] already exists. Skipping.';
END
GO

-- 2. FactSales -> DimCustomer
-- Purpose: Connects every transactional purchase to a valid customer profile.
-- Supports RFM segmentation, customer lifetime value (LTV), and cohort retention models.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_FactSales_DimCustomer')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT FK_FactSales_DimCustomer
    FOREIGN KEY (CustomerID) REFERENCES dbo.DimCustomer (CustomerID);
    PRINT 'Foreign Key [FK_FactSales_DimCustomer] added successfully.';
END
ELSE
BEGIN
    PRINT 'Foreign Key [FK_FactSales_DimCustomer] already exists. Skipping.';
END
GO

-- 3. FactSales -> DimProduct
-- Purpose: Links line item sales to the central product master catalog.
-- Enables category margin rollups, brand performance analysis, and star vs. loss-leader analysis.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_FactSales_DimProduct')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT FK_FactSales_DimProduct
    FOREIGN KEY (ProductID) REFERENCES dbo.DimProduct (ProductID);
    PRINT 'Foreign Key [FK_FactSales_DimProduct] added successfully.';
END
ELSE
BEGIN
    PRINT 'Foreign Key [FK_FactSales_DimProduct] already exists. Skipping.';
END
GO

-- 4. FactSales -> DimStore
-- Purpose: Attributes every retail and online transaction to its operating store or digital channel.
-- Supports regional revenue benchmarks, square footage productivity, and channel mix analysis.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_FactSales_DimStore')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT FK_FactSales_DimStore
    FOREIGN KEY (StoreID) REFERENCES dbo.DimStore (StoreID);
    PRINT 'Foreign Key [FK_FactSales_DimStore] added successfully.';
END
ELSE
BEGIN
    PRINT 'Foreign Key [FK_FactSales_DimStore] already exists. Skipping.';
END
GO


-- ============================================================================
-- PART 2: DATA INTEGRITY CONSTRAINTS (CHECK CONSTRAINTS)
-- Enforces commercial and statistical business rules validated in Task 5.
-- ============================================================================

-- FactSales CHECK Constraints:
-- 1. Quantity must be strictly positive (zero-unit and negative return anomalies filtered in Task 5)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_Quantity')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_Quantity CHECK (Quantity > 0);
    PRINT 'Constraint [CK_FactSales_Quantity] added successfully.';
END
GO

-- 2. Discount rate must be bounded between 0% (0.00) and 100% (1.00)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_Discount')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_Discount CHECK (Discount >= 0.00 AND Discount <= 1.00);
    PRINT 'Constraint [CK_FactSales_Discount] added successfully.';
END
GO

-- 3. Unit Price must be non-negative
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_UnitPrice')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_UnitPrice CHECK (UnitPrice >= 0.00);
    PRINT 'Constraint [CK_FactSales_UnitPrice] added successfully.';
END
GO

-- 4. Unit Cost must be non-negative
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_UnitCost')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_UnitCost CHECK (UnitCost >= 0.00);
    PRINT 'Constraint [CK_FactSales_UnitCost] added successfully.';
END
GO

-- 5. Sales Amount must be non-negative
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_SalesAmount')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_SalesAmount CHECK (SalesAmount >= 0.00);
    PRINT 'Constraint [CK_FactSales_SalesAmount] added successfully.';
END
GO

-- 6. Cost Amount must be non-negative
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_CostAmount')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_CostAmount CHECK (CostAmount >= 0.00);
    PRINT 'Constraint [CK_FactSales_CostAmount] added successfully.';
END
GO

-- 7. SalesChannel must be either 'Online' or 'In-Store'
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_FactSales_SalesChannel')
BEGIN
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT CK_FactSales_SalesChannel CHECK (SalesChannel IN ('Online', 'In-Store'));
    PRINT 'Constraint [CK_FactSales_SalesChannel] added successfully.';
END
GO

-- DimProduct CHECK Constraints:
-- 8. UnitPrice >= 0
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_DimProduct_UnitPrice')
BEGIN
    ALTER TABLE dbo.DimProduct
    ADD CONSTRAINT CK_DimProduct_UnitPrice CHECK (UnitPrice >= 0.00);
    PRINT 'Constraint [CK_DimProduct_UnitPrice] added successfully.';
END
GO

-- 9. UnitCost >= 0
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_DimProduct_UnitCost')
BEGIN
    ALTER TABLE dbo.DimProduct
    ADD CONSTRAINT CK_DimProduct_UnitCost CHECK (UnitCost >= 0.00);
    PRINT 'Constraint [CK_DimProduct_UnitCost] added successfully.';
END
GO

-- 10. Category must belong to the 5 canonical business domains
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_DimProduct_Category')
BEGIN
    ALTER TABLE dbo.DimProduct
    ADD CONSTRAINT CK_DimProduct_Category CHECK (Category IN (
        'Electronics & Gadgets',
        'Home & Kitchen',
        'Apparel & Accessories',
        'Beauty & Personal Care',
        'Sports & Outdoors'
    ));
    PRINT 'Constraint [CK_DimProduct_Category] added successfully.';
END
GO

-- DimCustomer CHECK Constraints:
-- 11. CustomerSegment must belong to approved loyalty tiers
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_DimCustomer_Segment')
BEGIN
    ALTER TABLE dbo.DimCustomer
    ADD CONSTRAINT CK_DimCustomer_Segment CHECK (CustomerSegment IN (
        'Regular',
        'Silver',
        'Gold',
        'VIP Platinum'
    ));
    PRINT 'Constraint [CK_DimCustomer_Segment] added successfully.';
END
GO

-- 12. Gender must belong to recognized categories
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_DimCustomer_Gender')
BEGIN
    ALTER TABLE dbo.DimCustomer
    ADD CONSTRAINT CK_DimCustomer_Gender CHECK (Gender IN ('Female', 'Male', 'Other'));
    PRINT 'Constraint [CK_DimCustomer_Gender] added successfully.';
END
GO

-- DimStore CHECK Constraints:
-- 13. SquareFootage must be non-negative (0 for Online)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_DimStore_SquareFootage')
BEGIN
    ALTER TABLE dbo.DimStore
    ADD CONSTRAINT CK_DimStore_SquareFootage CHECK (SquareFootage >= 0);
    PRINT 'Constraint [CK_DimStore_SquareFootage] added successfully.';
END
GO

PRINT 'All Foreign Key and CHECK constraints successfully verified and created.';
GO
