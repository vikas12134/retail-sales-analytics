# SQL Server Database Setup & Deployment Guide
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Database:** `RetailSalesAnalytics`  
**Target Environment:** Microsoft SQL Server 2019 / 2022 / 2025 / Azure SQL Managed Instance  
**Document Version:** 1.0  
**Date:** 2026-09-05  

---

## 1. Prerequisites & Overview

This guide provides step-by-step instructions for deploying the **Star Schema** data warehouse for Aura Retail Group.

### Required Software:
- **Microsoft SQL Server** (2019, 2022, or 2025 Developer/Standard/Enterprise Edition or SQL Server Express)
- **SQL Server Management Studio (SSMS)** (v18, v19, or v20) OR **Azure Data Studio** / **sqlcmd CLI**

### Repository Directory Structure for SQL Scripts:
All deployment scripts are located under the `sql/database/` directory:

```text
retail-sales-analytics/
└── sql/
    └── database/
        ├── 01_create_database.sql       # 1. Database creation & configuration
        ├── 02_create_tables.sql         # 2. Star Schema tables (4 Dims + 1 Fact)
        ├── 03_create_constraints.sql    # 3. Foreign keys & CHECK constraints
        ├── 04_create_indexes.sql        # 4. Analytical B-Tree covering indexes
        ├── 05_create_views.sql          # 5. Foundational reporting views
        └── 06_validate_database.sql     # 6. Automated schema validation suite
```

---

## 2. Step-by-Step Deployment in SQL Server Management Studio (SSMS)

### Step 1: Open SQL Server Management Studio
1. Press the **Windows Key** on your keyboard.
2. Type **SQL Server Management Studio** (or **SSMS**) and click to launch the application.

### Step 2: Connect to SQL Server Instance
1. In the **Connect to Server** dialog box:
   - **Server type:** Select `Database Engine`.
   - **Server name:** Enter your server name (e.g. `localhost`, `.`, `(local)`, or your named instance like `localhost\SQLEXPRESS`).
   - **Authentication:** 
     - Choose `Windows Authentication` (recommended for local development).
     - Or choose `SQL Server Authentication` and provide your `Login` and `Password` (e.g., `sa`).
   - **Connection Properties / Encryption:** Under Options $\rightarrow$ Connection Properties, check **Trust server certificate** if using SQL Server 2022/2025 with default local certificates.
2. Click **Connect**.
3. In the **Object Explorer** panel on the left, verify that your SQL Server instance is connected.

---

### Step 3: Execute Database Creation Script (`01_create_database.sql`)
1. In SSMS, click **File** $\rightarrow$ **Open** $\rightarrow$ **File...** (or press `Ctrl + O`).
2. Navigate to your project folder: `retail-sales-analytics/sql/database/`.
3. Select `01_create_database.sql` and click **Open**.
4. Review the script contents. Notice that it safely checks `IF NOT EXISTS` to avoid destroying any existing database.
5. Click the **Execute** button on the toolbar (or press `F5`).
6. In the **Messages** pane, confirm you see:
   ```text
   Database [RetailSalesAnalytics] created successfully.
   Database [RetailSalesAnalytics] configured successfully for analytical workloads.
   ```
7. In **Object Explorer**, right-click **Databases** and click **Refresh**. Verify that `RetailSalesAnalytics` is now visible.

---

### Step 4: Execute Table Creation Script (`02_create_tables.sql`)
1. In SSMS, click **File** $\rightarrow$ **Open** $\rightarrow$ **File...** (`Ctrl + O`).
2. Select `02_create_tables.sql` and click **Open**.
3. Verify that the script specifies `USE [RetailSalesAnalytics];` at the top.
4. Click **Execute** (`F5`).
5. Confirm output messages:
   ```text
   Table [dbo].[DimDate] created successfully.
   Table [dbo].[DimCustomer] created successfully.
   Table [dbo].[DimProduct] created successfully.
   Table [dbo].[DimStore] created successfully.
   Table [dbo].[FactSales] created successfully.
   All Star Schema tables (4 Dimensions + 1 Central Fact) created successfully.
   ```
6. In **Object Explorer**, expand `Databases` $\rightarrow$ `RetailSalesAnalytics` $\rightarrow$ `Tables`. Verify all 5 tables are listed.

---

### Step 5: Execute Constraints Script (`03_create_constraints.sql`)
1. Open `03_create_constraints.sql` in SSMS (`Ctrl + O`).
2. Click **Execute** (`F5`).
3. This script creates:
   - 4 Foreign Keys connecting `FactSales` to each dimension table.
   - 13 CHECK constraints enforcing data boundaries (`Quantity > 0`, valid categories, etc.).
4. Confirm output message:
   ```text
   All Foreign Key and CHECK constraints successfully verified and created.
   ```

---

### Step 6: Execute Indexes Script (`04_create_indexes.sql`)
1. Open `04_create_indexes.sql` in SSMS (`Ctrl + O`).
2. Click **Execute** (`F5`).
3. This script creates 11 B-Tree indexes:
   - Covering indexes on foreign keys of `FactSales` (`DateKey`, `CustomerID`, `ProductID`, `StoreID`).
   - Slicing indexes on dimension tables (Region, Segment, Category, Brand, Year/Month).
4. Confirm output message:
   ```text
   All analytical indexes created successfully.
   ```

---

### Step 7: Execute Analytical Views Script (`05_create_views.sql`)
1. Open `05_create_views.sql` in SSMS (`Ctrl + O`).
2. Click **Execute** (`F5`).
3. This script compiles:
   - `dbo.vw_SalesDetail` (Flat denormalized reporting dataset)
   - `dbo.vw_MonthlySalesSummary` (Monthly time-series summary)
   - `dbo.vw_CategoryPerformance` (Merchandise category margin scorecard)
   - `dbo.vw_CustomerRFMBase` (Customer RFM baseline metrics)
4. Confirm output message:
   ```text
   All analytical views created successfully.
   ```
5. In **Object Explorer**, expand `RetailSalesAnalytics` $\rightarrow$ `Views`. Confirm all 4 views are visible.

---

### Step 8: Validate the Database (`06_validate_database.sql`)
1. Open `06_validate_database.sql` in SSMS (`Ctrl + O`).
2. Click **Execute** (`F5`).
3. View the **Results** grid and **Messages** tab.
4. The automated validation script verifies:
   - Database existence and recovery model (`SIMPLE`)
   - 5 tables existence
   - 5 Primary Keys existence
   - 4 Foreign Keys existence and active status
   - 13 CHECK constraints active status
   - 11 Indexes existence
   - 4 Views existence
5. Confirm the final verdict message:
   ```text
   ============================================================================
                         VALIDATION SUMMARY RESULTS                            
   ============================================================================
   Total Schema Verification Checks: 44
   Passed Checks:                    44
   Failed Checks:                    0
   FINAL VERDICT: [PASS] - DATABASE SCHEMA IS 100% CERTIFIED AND READY!
   ============================================================================
   ```
6. Verify the table row counts at the bottom: all 5 tables will show `0 Rows` (`READY FOR DATA LOAD`), confirming the database structure is complete and waiting for ETL ingestion in Task 7.

---

## 3. Alternative Deployment via Command Line (`sqlcmd`)

If you prefer automated terminal deployment without opening SSMS, you can execute the entire suite sequentially using `sqlcmd` from PowerShell or Command Prompt:

```powershell
# Navigate to the database scripts directory
cd d:\Data_Analytics\retail-sales-analytics\sql\database

# Execute scripts in strict sequence
sqlcmd -S localhost -E -C -i "01_create_database.sql"
sqlcmd -S localhost -E -C -i "02_create_tables.sql"
sqlcmd -S localhost -E -C -i "03_create_constraints.sql"
sqlcmd -S localhost -E -C -i "04_create_indexes.sql"
sqlcmd -S localhost -E -C -i "05_create_views.sql"
sqlcmd -S localhost -E -C -i "06_validate_database.sql"
```

*Note on Flags:*
- `-S localhost`: Connects to local default SQL Server instance. Replace with `.\SQLEXPRESS` if using SQL Express.
- `-E`: Uses Windows Integrated Authentication.
- `-C`: Trusts server certificate (required for SQL Server 2022+ default encrypted connections).
- `-i`: Specifies input SQL script file.

---

## 4. Troubleshooting & FAQ

### Issue 1: "Cannot connect to localhost / A network-related or instance-specific error occurred"
- **Cause:** SQL Server service is stopped or instance name is different.
- **Fix:** 
  1. Press `Win + R`, type `services.msc`, and press Enter.
  2. Locate `SQL Server (MSSQLSERVER)` or `SQL Server (SQLEXPRESS)`.
  3. Ensure the service status is **Running**. If stopped, right-click and select **Start**.

### Issue 2: "The certificate chain was issued by an authority that is not trusted"
- **Cause:** In SQL Server 2022/2025, encryption is mandatory by default.
- **Fix:** In SSMS connection dialog $\rightarrow$ Options $\rightarrow$ Check **Trust server certificate**. In `sqlcmd`, include the `-C` flag.

### Issue 3: "Invalid object name 'dbo.FactSales' / Foreign Key creation fails"
- **Cause:** Scripts were executed out of order (e.g. constraints before tables).
- **Fix:** Always execute in sequence: `01` $\rightarrow$ `02` $\rightarrow$ `03` $\rightarrow$ `04` $\rightarrow$ `05` $\rightarrow$ `06`.
