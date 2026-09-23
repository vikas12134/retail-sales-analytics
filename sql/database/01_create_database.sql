-- ============================================================================
-- Script: 01_create_database.sql
-- Description: Creates the RetailSalesAnalytics database with production settings.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-05
-- ============================================================================

USE [master];
GO

-- 1. Check if database already exists; create only if absent (Non-destructive)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'RetailSalesAnalytics')
BEGIN
    PRINT 'Creating database [RetailSalesAnalytics]...';
    
    CREATE DATABASE [RetailSalesAnalytics]
    COLLATE SQL_Latin1_General_CP1_CI_AS;
    
    PRINT 'Database [RetailSalesAnalytics] created successfully.';
END
ELSE
BEGIN
    PRINT 'Database [RetailSalesAnalytics] already exists. Skipping creation.';
END
GO

-- 2. Switch context to RetailSalesAnalytics
USE [RetailSalesAnalytics];
GO

-- 3. Configure Database Options for Analytical / Data Warehouse Workloads
-- Set Recovery Model to SIMPLE: Optimal for analytical data warehouses to minimize transaction log growth
ALTER DATABASE [RetailSalesAnalytics] SET RECOVERY SIMPLE;
GO

-- Enable AUTO_UPDATE_STATISTICS to maintain optimal cardinality estimates for analytical queries
ALTER DATABASE [RetailSalesAnalytics] SET AUTO_UPDATE_STATISTICS ON;
GO

-- Enable READ_COMMITTED_SNAPSHOT for high-concurrency analytical queries without locking contention
ALTER DATABASE [RetailSalesAnalytics] SET READ_COMMITTED_SNAPSHOT ON;
GO

PRINT 'Database [RetailSalesAnalytics] configured successfully for analytical workloads.';
GO
