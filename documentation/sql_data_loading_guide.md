# SQL Server Data Loading & Execution Guide
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Database:** `RetailSalesAnalytics`  
**Document Version:** 1.0  
**Author:** Data Analytics Team  
**Date:** 2026-09-06  

---

## 1. Overview & Prerequisites

This operational guide provides step-by-step instructions for executing the **Task 7 SQL ETL Data Loading Pipeline**. Following these steps will ingest the cleaned CSV datasets into staging tables, validate data hygiene, and load the production Star Schema data warehouse (`dbo.DimDate`, `dbo.DimCustomer`, `dbo.DimProduct`, `dbo.DimStore`, and `dbo.FactSales`).

### Prerequisites:
1. **Microsoft SQL Server Engine:** SQL Server 2019, 2022, or 2025 (Standard, Enterprise, Developer, or Express Edition).
2. **Database Tools:** SQL Server Management Studio (SSMS v18, v19, or v20) OR Azure Data Studio / `sqlcmd`.
3. **Database Schema Deployed:** The `RetailSalesAnalytics` database must be initialized with Star Schema tables, constraints, indexes, and views (deployed via `sql/database/` in Task 6).
4. **Source Cleaned CSVs:** The following files must exist in `data/cleaned/`:
   - `date.csv` (731 rows)
   - `customers.csv` (50,000 rows)
   - `products.csv` (500 rows)
   - `stores.csv` (30 rows)
   - `sales.csv` (320,536 rows)

---

## 2. Important Rules Regarding File Paths & Permissions

`BULK INSERT` executes within the SQL Server database engine service, which introduces two critical operational requirements:

### Rule 1: Absolute File Paths Required
SQL Server does not recognize application-relative paths (e.g. `..\..\data\cleaned\sales.csv`). You must supply an **absolute Windows filesystem path** (e.g. `D:\Data_Analytics\retail-sales-analytics\data\cleaned\sales.csv`).

### Rule 2: SQL Server Service Account NTFS Read Permissions
The Windows service account running your SQL Server instance must have **NTFS Read permission** on the folder where your CSV files reside.
- If you encounter **Operating System Error 5 (Access is denied)**:
  1. Open Windows File Explorer and navigate to the project directory: `D:\Data_Analytics\retail-sales-analytics`.
  2. Right-click the `data` folder $\rightarrow$ **Properties** $\rightarrow$ **Security** tab.
  3. Click **Edit...** $\rightarrow$ **Add...**.
  4. Enter `NT SERVICE\MSSQLSERVER` (or `NT SERVICE\MSSQL$SQLEXPRESS` if using SQL Express) and click **Check Names**.
  5. Check **Read & execute**, **List folder contents**, and **Read**, then click **OK**.

---

## 3. Configuring Placeholder Paths in `02_load_staging_data.sql`

Before executing `sql/staging/02_load_staging_data.sql`, you must update the file path placeholders:

1. Open `sql/staging/02_load_staging_data.sql` in SSMS or your text editor.
2. Locate the placeholder string:
   ```text
   <ABSOLUTE_PATH_TO_PROJECT_ROOT>
   ```
3. Use **Find and Replace** (`Ctrl + H` in SSMS):
   - **Find:** `<ABSOLUTE_PATH_TO_PROJECT_ROOT>`
   - **Replace with:** Your absolute project directory path (e.g., `D:\Data_Analytics\retail-sales-analytics` without trailing slash)
4. Verify the updated paths look like:
   ```sql
   BULK INSERT staging.stg_Date
   FROM 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\date.csv'
   WITH (
       FIRSTROW = 2,
       FIELDTERMINATOR = ',',
       ROWTERMINATOR = '\n',
       CODEPAGE = '65001',
       TABLOCK
   );
   ```
5. Save the file.

---

## 4. Step-by-Step Execution Workflow in SSMS

Open SQL Server Management Studio and connect to your instance (e.g. `localhost` or `.\SQLEXPRESS`). Execute the 5 staging scripts in strict numerical sequence:

```text
┌──────────────────────────────────────────────────────────────────┐
│  STEP 1: 01_create_staging_tables.sql                            │
│  Creates staging schema & tables (stg_Date, stg_Customer, etc.)  │
└─────────────────────────────────┬────────────────────────────────┘
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 2: 02_load_staging_data.sql                                │
│  BULK INSERT cleaned CSVs into staging tables                    │
└─────────────────────────────────┬────────────────────────────────┘
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 3: 03_validate_staging_data.sql                            │
│  Validates row counts, nulls, duplicates, and orphan records     │
│  MUST REPORT: [PASS] before proceeding                           │
└─────────────────────────────────┬────────────────────────────────┘
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 4: 04_transform_and_load.sql                               │
│  Atomic transaction: type conversions, key mappings, load dims  │
│  first, then FactSales                                           │
└─────────────────────────────────┬────────────────────────────────┘
                                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 5: 05_validate_final_data.sql                              │
│  Comprehensive QA audit: PKs, FKs, math reconciliation, views    │
│  MUST REPORT: [PASS] - DATA WAREHOUSE 100% CERTIFIED!            │
└──────────────────────────────────────────────────────────────────┘
```

---

### Step 1: Create Staging Schema & Tables
- **File:** `sql/staging/01_create_staging_tables.sql`
- **Action:** Open in SSMS (`Ctrl + O`) and click **Execute** (`F5`).
- **Expected Message:**
  ```text
  Schema [staging] created successfully.
  Table [staging].[stg_Date] created successfully.
  Table [staging].[stg_Customer] created successfully.
  Table [staging].[stg_Product] created successfully.
  Table [staging].[stg_Store] created successfully.
  Table [staging].[stg_Sales] created successfully.
  ```

---

### Step 2: Ingest CSV Data into Staging
- **File:** `sql/staging/02_load_staging_data.sql`
- **Action:** Ensure you replaced `<ABSOLUTE_PATH_TO_PROJECT_ROOT>`, then click **Execute** (`F5`).
- **Execution Time:** ~2 to 5 seconds.
- **Expected Output Table:**
  | StagingTable | LoadedRowCount | ExpectedRowCount | VerificationStatus |
  |---|---|---|---|
  | `stg_Customer` | 50000 | 50000 | MATCH |
  | `stg_Date` | 731 | 731 | MATCH |
  | `stg_Product` | 500 | 500 | MATCH |
  | `stg_Sales` | 320536 | 320536 | MATCH |
  | `stg_Store` | 30 | 30 | MATCH |

---

### Step 3: Run Pre-Load Staging Validation
- **File:** `sql/staging/03_validate_staging_data.sql`
- **Action:** Open in SSMS and click **Execute** (`F5`).
- **Checks Performed:** 27 automated data quality tests covering:
  - Row count completeness
  - Zero primary key NULLs or blank strings
  - Zero duplicate business keys
  - Zero orphan customer, product, store, or date records
  - Safe castability to numeric and date formats
  - Approved domain values (`SalesChannel`, `Category`, `CustomerSegment`)
- **Expected Final Message:**
  ```text
  ============================================================================
                      STAGING VALIDATION SUMMARY RESULTS                      
  ============================================================================
  Total Staging Verification Checks: 27
  Passed Checks:                     27
  Failed Checks:                     0
  FINAL VERDICT: [PASS] - STAGING DATA IS 100% VALIDATED AND READY TO LOAD!
  ============================================================================
  ```

---

### Step 4: Transform & Load Production Star Schema
- **File:** `sql/staging/04_transform_and_load.sql`
- **Action:** Open in SSMS and click **Execute** (`F5`).
- **Execution Behavior:**
  - Clears target tables in referential dependency order (`FactSales` $\rightarrow$ `Dimensions`).
  - Transforms and casts fields from `staging.*`.
  - Imputes customer `DateOfBirth` blanks to SQL `NULL`.
  - Maps staging `TransactionID` to primary key `SalesID`.
  - Populates dimensions first, then `dbo.FactSales`.
  - Commits atomic transaction.
- **Expected Message:**
  ```text
  Step 1: Clearing existing production data in referential dependency order...
  Step 2: Loading [dbo].[DimDate] from [staging].[stg_Date]...
    -> Loaded 731 rows into dbo.DimDate.
  Step 3: Loading [dbo].[DimCustomer] from [staging].[stg_Customer]...
    -> Loaded 50000 rows into dbo.DimCustomer.
  Step 4: Loading [dbo].[DimProduct] from [staging].[stg_Product]...
    -> Loaded 500 rows into dbo.DimProduct.
  Step 5: Loading [dbo].[DimStore] from [staging].[stg_Store]...
    -> Loaded 30 rows into dbo.DimStore.
  Step 6: Loading [dbo].[FactSales] from [staging].[stg_Sales]...
    -> Loaded 320536 rows into dbo.FactSales.
  Transaction COMMITTED successfully.
  ```

---

### Step 5: Final Production Quality Assurance Audit
- **File:** `sql/staging/05_validate_final_data.sql`
- **Action:** Open in SSMS and click **Execute** (`F5`).
- **Checks Performed:** 28 production quality tests:
  - Exact row count verification on `dbo.DimDate`, `dbo.DimCustomer`, `dbo.DimProduct`, `dbo.DimStore`, `dbo.FactSales`.
  - Primary key uniqueness on all 5 tables.
  - Foreign key referential integrity (0 orphan records).
  - Mathematical reconciliation of discount, sales amount, COGS, and profit formulas.
  - Verification of commercial CHECK constraint boundaries.
  - Temporal range validation (`2023-01-01` to `2024-12-31`).
  - Reporting view compilation and execution health.
- **Expected Final Message:**
  ```text
  ============================================================================
                  FINAL PRODUCTION DATA VALIDATION SUMMARY                    
  ============================================================================
  Total Quality Assurance Checks: 28
  Passed Checks:                  28
  Failed Checks:                  0
  FINAL VERDICT: [PASS] - DATA WAREHOUSE IS 100% VALIDATED, RECONCILED & CERTIFIED!
  The Star Schema is completely ready for SQL Analysis, DAX & Power BI modeling.
  ============================================================================
  ```
- **Executive Metrics Snapshot Output:**
  Displays total revenue, gross profit, total units sold, and overall gross margin percentage for commercial sign-off.

---

## 5. Alternative Execution via Command Line (`sqlcmd`)

If executing from a PowerShell terminal, replace `<ABSOLUTE_PATH_TO_PROJECT_ROOT>` in `02_load_staging_data.sql` first, then run:

```powershell
# Navigate to the staging directory
cd "D:\Data_Analytics\retail-sales-analytics\sql\staging"

# Execute in strict sequence
sqlcmd -S localhost -E -C -i "01_create_staging_tables.sql"
sqlcmd -S localhost -E -C -i "02_load_staging_data.sql"
sqlcmd -S localhost -E -C -i "03_validate_staging_data.sql"
sqlcmd -S localhost -E -C -i "04_transform_and_load.sql"
sqlcmd -S localhost -E -C -i "05_validate_final_data.sql"
```

*Flags:*
- `-S localhost`: Database server instance.
- `-E`: Windows Integrated Authentication.
- `-C`: Trusts server certificate (required for encrypted connections).
- `-i`: Input script file.

---

## 6. Expected Row Counts & Verification Reference

| Layer | Table Name | Key Column | Expected Rows | Match Condition |
|---|---|---|---|---|
| **Staging** | `staging.stg_Date` | `DateKey` | **731** | Exact match with `date.csv` |
| **Staging** | `staging.stg_Customer` | `CustomerID` | **50,000** | Exact match with `customers.csv` |
| **Staging** | `staging.stg_Product` | `ProductID` | **500** | Exact match with `products.csv` |
| **Staging** | `staging.stg_Store` | `StoreID` | **30** | Exact match with `stores.csv` |
| **Staging** | `staging.stg_Sales` | `TransactionID` | **320,536** | Exact match with `sales.csv` |
| **Production** | `dbo.DimDate` | `DateKey` | **731** | Conformed Calendar Dimension |
| **Production** | `dbo.DimCustomer` | `CustomerID` | **50,000** | Customer Master Dimension |
| **Production** | `dbo.DimProduct` | `ProductID` | **500** | Product Catalog Dimension |
| **Production** | `dbo.DimStore` | `StoreID` | **30** | Retail Store Dimension |
| **Production** | `dbo.FactSales` | `SalesID` | **320,536** | Central Transaction Fact Table |

---

## 7. Troubleshooting Common Issues

### Issue 1: Operating System Error 3 / "The system cannot find the path specified"
- **Cause:** You ran `02_load_staging_data.sql` without replacing the `<ABSOLUTE_PATH_TO_PROJECT_ROOT>` placeholder, or there is a typo in your filesystem path.
- **Fix:** Open `02_load_staging_data.sql`, verify the absolute path to each CSV file exists, and re-execute.

### Issue 2: Operating System Error 5 / "Access is denied"
- **Cause:** SQL Server service account lacks NTFS Read permission on your CSV folder.
- **Fix:** Follow the steps in **Section 2, Rule 2** above to grant Read permissions to `NT SERVICE\MSSQLSERVER`.

### Issue 3: Msg 547 / "The INSERT statement conflicted with the FOREIGN KEY constraint"
- **Cause:** Tables were loaded out of order, or an orphan key exists in the fact data.
- **Fix:** Always execute `04_transform_and_load.sql` as written. It automatically handles the dimension-first load hierarchy.

### Issue 4: Idempotent Reload Procedure
- To reload the warehouse from scratch at any time:
  1. Simply re-execute `02_load_staging_data.sql` (it automatically truncates staging first).
  2. Run `03_validate_staging_data.sql`.
  3. Run `04_transform_and_load.sql` (it automatically clears existing production tables in safe FK order).
  4. Run `05_validate_final_data.sql`.
