# Power BI Connection & Setup Guide
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Database Engine:** Microsoft SQL Server  
**Source Database:** `RetailSalesAnalytics`  
**Target Application:** Microsoft Power BI Desktop  
**Author:** Data Analytics Team  
**Date:** 2026-09-08  
**Document Version:** 1.0  

---

## 1. Objective

This document provides complete, step-by-step instructions for establishing an enterprise-grade connection between **Microsoft Power BI Desktop** and the relational data warehouse database **`RetailSalesAnalytics`** hosted on Microsoft SQL Server.

This guide details:
- Connection configuration and credential management
- The architectural evaluation of **Import** vs. **DirectQuery** storage modes
- Selective schema ingestion (loading only clean Star Schema analytical tables while excluding staging entities)
- Model environment configuration in preparation for data modeling, relationships, and DAX measure authoring

---

## 2. Storage Mode Analysis: Import vs. DirectQuery

When connecting Power BI Desktop to a Microsoft SQL Server database, Power BI requires selecting a storage mode. Choosing the correct storage mode is one of the most critical architectural decisions in a Power BI project.

### 2.1. Comparison Matrix

| Architectural Feature | Import Mode | DirectQuery Mode |
|---|---|---|
| **Data Storage Location** | Data is extracted from SQL Server, compressed, and stored in-memory within Power BI using the **VertiPaQ** columnar engine. | Data remains in SQL Server. Only table schema and metadata are loaded into Power BI. |
| **Query Execution** | Queries are processed in-memory directly on the client machine / Power BI Service. | Visual interactions generate live T-SQL queries sent over the network to SQL Server in real time. |
| **Performance** | **Sub-second response times**. VertiPaQ columnar compression and in-memory caches optimize aggregations. | Dependent on SQL Server hardware, indexing, network latency, and current concurrent database load. |
| **DAX Capabilities** | **100% DAX functionality supported**, including all Time Intelligence functions (`TOTALYTD`, `SAMEPERIODLASTYEAR`), complex iterators (`SUMX`, `RANKX`), and table-manipulation functions. | **Restricted DAX subset**. Measures must translate directly into T-SQL. Many Time Intelligence and statistical DAX functions are blocked or degraded. |
| **Data Freshness** | Data reflects the state as of the last scheduled data refresh (up to 8 times/day on Pro, 48 times/day on Premium). | **Real-time / near real-time**. Every visual interaction reflects current SQL Server table state. |
| **Dataset Size Limits** | 1 GB per dataset on Power BI Pro (uncompressed memory footprint); up to hundreds of GBs on Power BI Premium. | Virtually unlimited data volume, constrained only by SQL Server capacity. |
| **Offline Portability** | **Fully portable**. The `.pbix` file can be opened, inspected, and presented offline without an active network/VPN connection to SQL Server. | **Non-portable without connectivity**. Reports break if SQL Server is offline, unreachable, or behind an inaccessible firewall. |

### 2.2. Mode Recommendation for This Project

> [!IMPORTANT]
> **Recommendation: Use IMPORT MODE.**

#### Business & Technical Justification:
1. **Dataset Sizing vs. Capacity:**
   - The `RetailSalesAnalytics` dataset contains **320,536 transactions** in `FactSales` and **51,261 total dimension rows** across 2 full operational years (2023–2024).
   - In raw CSV format, this data occupies approximately **32 MB**. When ingested into VertiPaQ using columnar compression, dictionary encoding, and run-length encoding, the in-memory footprint compresses to approximately **6 MB to 8 MB**.
   - This footprint consumes less than 1% of the 1 GB Power BI Pro memory threshold, making Import mode extremely lightweight and performant.

2. **Full DAX Time-Intelligence Requirement:**
   - Aura Retail Group's business requirements mandate Year-over-Year (YoY) revenue tracking, Month-over-Month (MoM) sales momentum, Year-to-Date (YTD) financial rollups, and rolling moving averages.
   - Import mode provides native, unrestricted support for the complete suite of DAX Time Intelligence functions (`TOTALYTD`, `SAMEPERIODLASTYEAR`, `DATEADD`, `DATESINPERIOD`). DirectQuery restricts or complicates many of these patterns.

3. **Sub-Second Interactive User Experience:**
   - Executive dashboards require multi-dimensional cross-filtering (e.g., clicking a Product Category slice instantly filters Store Geographies, Customer Loyalty Tiers, and Monthly Trends).
   - Import mode executes cross-filtering in sub-second memory speeds without firing dozens of simultaneous T-SQL queries back to the transactional database.

4. **Portfolio Portability & Reproducibility:**
   - As an end-to-end portfolio project, reviewers, recruiters, and stakeholders need to open and explore the `.pbix` file locally without requiring local SQL Server installation, specific instance configurations, or network credentials.

---

## 3. Step-by-Step Connection Instructions

Follow these exact steps to connect Power BI Desktop to `RetailSalesAnalytics`:

```text
Power BI Desktop
   │
   ├── [Get Data] ──► [SQL Server Database]
   │                         │
   │                         ├── Server:   <ServerName> (e.g., localhost, .\SQLEXPRESS)
   │                         ├── Database: RetailSalesAnalytics
   │                         └── Mode:     Import
   │                                           │
   └── [Navigator] ────────────────────────────┘
         │
         ├── Select: dbo.DimDate
         ├── Select: dbo.DimCustomer
         ├── Select: dbo.DimProduct
         ├── Select: dbo.DimStore
         ├── Select: dbo.FactSales
         └── (DO NOT select staging tables)
               │
               ▼
         [Load / Transform Data]
```

### Step 1: Open Power BI Desktop
1. Launch **Microsoft Power BI Desktop** on your workstation.
2. If the startup splash dialog appears, close it or select **Get data**.

### Step 2: Select Get Data
1. On the **Home** ribbon at the top of the window, locate the **Data** group.
2. Click on the **Get Data** icon.
3. In the dropdown menu, click **SQL Server** (or click **More...** $\rightarrow$ **Database** $\rightarrow$ **SQL Server database** $\rightarrow$ click **Connect**).

### Step 3: Configure SQL Server Connection Parameters
In the **SQL Server database** connection dialog window:

1. **Server:** Enter your SQL Server instance identifier placeholder:
   - For a default local instance: `localhost` or `.`
   - For a named instance (e.g., SQL Express): `localhost\SQLEXPRESS` or `.\SQLEXPRESS`
   - For a remote or enterprise server: `<ServerName>[\<InstanceName>][,<Port>]` (e.g., `db-server.corp.local` or `192.168.1.50,1433`)
2. **Database (optional but strongly recommended):**
   - Enter: `RetailSalesAnalytics`
   *(Explicitly providing the database name limits schema navigation strictly to the analytical warehouse.)*
3. **Data Connectivity mode:**
   - Select the radio button for **Import**.
4. **Advanced options (leave collapsed/default):**
   - *Command timeout in minutes:* Leave blank (defaults to 10 minutes).
   - *SQL statement:* **Leave blank**. We connect directly to the relational dimensional tables rather than writing ad-hoc SQL queries. This allows Power BI to leverage query folding and preserve relationship metadata.
   - *Include relationship columns:* Checked (default).
   - *Navigate using full hierarchy:* Checked (default).
5. Click **OK**.

### Step 4: Authentication Credentials
If this is the first time connecting to the SQL Server instance from Power BI:

1. In the authentication prompt window on the left pane:
   - **Windows:** Select **Windows** if your Windows user account has access permissions (e.g., `Windows Authentication` / Integrated Security). Select **Use my current credentials** or enter alternate domain credentials.
   - **Database:** Select **Database** if using a dedicated SQL Server Authentication login (e.g., user `sa` or `RetailAnalyticsUser`), enter the Username and Password, and ensure **RetailSalesAnalytics** is selected in the scope dropdown.
2. **Encryption Notification:**
   - If a prompt displays: *"We couldn't connect with an encrypted connection. Click OK to connect unencrypted."*, click **OK** (or configure a trusted local SSL certificate).
3. Click **Connect**.

### Step 5: Select Required Tables in Navigator
The **Navigator** dialog window displays all tables and views available in the `RetailSalesAnalytics` database.

> [!CAUTION]
> **Strict Table Selection Rule:**  
> Load **ONLY** the 5 clean dimensional and fact tables. Do **NOT** select staging tables (`stg_*`) or administrative objects.

Check the checkboxes for the following **5 tables**:
- [x] **`dbo.DimDate`**
- [x] **`dbo.DimCustomer`**
- [x] **`dbo.DimProduct`**
- [x] **`dbo.DimStore`**
- [x] **`dbo.FactSales`**

Do **NOT** check:
- [ ] `stg_customers`
- [ ] `stg_products`
- [ ] `stg_stores`
- [ ] `stg_sales`

### Step 6: Initial Inspection & Transform vs. Load
1. In the preview pane on the right of the Navigator, click each table to verify that column names and sample data match expectations:
   - `DimDate`: 16 columns (`DateKey`, `FullDate`, `Year`, `Month`, etc.)
   - `DimCustomer`: 13 columns (`CustomerID`, `FirstName`, `LastName`, `Email`, etc.)
   - `DimProduct`: 8 columns (`ProductID`, `ProductName`, `Category`, `UnitCost`, `UnitPrice`, etc.)
   - `DimStore`: 9 columns (`StoreID`, `StoreName`, `StoreType`, `City`, `State`, etc.)
   - `FactSales`: 16 columns (`SalesID`, `DateKey`, `CustomerID`, `ProductID`, `StoreID`, `SalesAmount`, `Profit`, etc.)
2. Options:
   - Clicking **Transform Data** opens the **Power Query Editor** to verify data types, confirm column names, and create an empty measures container table before loading.
   - Clicking **Load** directly pulls all 5 tables into the in-memory VertiPaQ data model.
3. For professional implementations, click **Transform Data** first to verify column schema types.

### Step 7: Complete Loading (Close & Apply)
1. Inside the **Power Query Editor**, inspect the query names in the left pane:
   - Ensure table names match canonical convention: `DimDate`, `DimCustomer`, `DimProduct`, `DimStore`, `FactSales`.
2. Click **Close & Apply** on the top-left corner of the Home ribbon.
3. Power BI will display a modal dialog indicating loading progress:
   - Reading data from `dbo.DimDate` (731 rows)
   - Reading data from `dbo.DimCustomer` (50,000 rows)
   - Reading data from `dbo.DimProduct` (500 rows)
   - Reading data from `dbo.DimStore` (30 rows)
   - Reading data from `dbo.FactSales` (320,536 rows)
4. Once completed, the tables will appear in the **Data** pane on the far right of the Power BI interface.

---

## 4. Connection Troubleshooting & Common Pitfalls

| Symptom / Error | Root Cause | Solution |
|---|---|---|
| *"A network-related or instance-specific error occurred while establishing a connection to SQL Server."* | Incorrect instance name, SQL Server service is stopped, or TCP/IP protocol is disabled. | 1. Open `SQL Server Configuration Manager` and verify `SQL Server (MSSQLSERVER)` or `SQL Server (SQLEXPRESS)` service status is **Running**.<br>2. Enable **TCP/IP** in SQL Server Network Configuration.<br>3. Verify connection in SSMS using the identical instance string. |
| *"Login failed for user..."* | Authentication mode mismatch or invalid credentials. | Verify whether the instance allows SQL Server and Windows Authentication (Mixed Mode). Re-enter valid credentials in **Data source settings** (`File` $\rightarrow$ `Options and settings` $\rightarrow$ `Data source settings`). |
| *"The key didn't match any rows in the range."* | Table name was renamed or schema was modified in SQL Server after initial navigation. | In Power Query Editor, click `Source` step and re-select the database table. |
| Auto-detected relationships create circular or inaccurate joins | Power BI's automatic relationship detection algorithm inferred joins based on column names across dimensions. | Disable automatic relationship detection: `File` $\rightarrow$ `Options and settings` $\rightarrow$ `Options` $\rightarrow$ `Current File` $\rightarrow$ `Data Load` $\rightarrow$ Uncheck *"Import relationships from data sources on first load"* and *"Autodetect new relationships after data is loaded"*. Model relationships manually as specified in the Data Model documentation. |

---

## 5. Next Steps

With all 5 analytical tables successfully ingested via Import mode:
1. Proceed to **Model View** in Power BI Desktop.
2. Establish the Star Schema relationships between the conformed dimensions and `FactSales`.
3. Configure `DimDate` as the official Date Table.
4. Set field formatting, data categories, and analytical drill-down hierarchies as documented in [Power BI Data Model Documentation](file:///d:/Data_Analytics/retail-sales-analytics/documentation/powerbi_data_model.md).
