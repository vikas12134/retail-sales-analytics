# Data Cleaning Rules & Business Transformation Dictionary
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Document Version:** 1.0  
**Pipeline Author:** Data Analytics Team  
**Last Updated:** 2026-09-05  

---

## 1. Overview & Cleaning Philosophy

This document serves as the formal audit trail and business rule specification for all transformations applied to raw retail datasets during the Python/Pandas data quality pipeline.

### Core Data Analyst Principles Followed:
1. **Raw Data Immutability:** Raw CSV files in `data/raw/` are strictly read-only and preserved in their original state.
2. **Zero Silent Deletions:** Every removed, imputed, or altered record is logged, counted, and justified.
3. **Domain-Justified Imputation:** Missing values are treated according to retail business logic rather than generic zero-fills.
4. **Preservation of Referential Integrity:** Foreign key relationships between facts and dimensions are 100% validated prior to database loading.
5. **Deterministic Reproducibility:** The pipeline is fully scripted, version-controlled, and produces identical results across executions.

---

## 2. Table-by-Table Data Cleaning Rules

### RULE-CUST-01: Leading & Trailing Whitespace in Customer Names and City
- **Problem:** Data entry operators and web form inputs introduced accidental leading and trailing whitespace in `FirstName`, `LastName`, and `City`.
- **Detection Method:** `.str.startswith(" ")` and `.str.endswith(" ")` checks.
- **Affected Records:** 200 in `FirstName`, 200 in `LastName`, 200 in `City` (600 total).
- **Cleaning Rule:** Apply `.str.strip()` to remove whitespace. Apply `.str.title()` to `City` for proper noun capitalization.
- **Why Chosen:** Prevents duplicate-looking city groups and ensures polished customer communications in reporting.

### RULE-CUST-02: Inconsistent State Code Casing
- **Problem:** State postal abbreviations contained mixed casing (e.g. `ny`, `il`, `tx`, `fl`).
- **Detection Method:** `.str.islower()` check on `State` column.
- **Affected Records:** 250 records.
- **Cleaning Rule:** Convert to uppercase using `.str.upper()`.
- **Why Chosen:** US postal standards require 2-letter uppercase state codes (`NY`, `IL`, `TX`, `FL`). Essential for regional SQL joins and Power BI map visuals.

### RULE-CUST-03: Inconsistent Customer Segment Casing
- **Problem:** `CustomerSegment` contained mixed casing variants (`regular`, `REGULAR`, `silver`, `SILVER`, `gold`, `GOLD`, `vip platinum`, `VIP PLATINUM`).
- **Detection Method:** Value counts on `CustomerSegment.unique()`.
- **Affected Records:** 500 records.
- **Cleaning Rule:** Map lowercase variants via explicit dictionary to standard business tiers: `Regular`, `Silver`, `Gold`, `VIP Platinum`.
- **Why Chosen:** Prevents fragmented customer cohorts in segmentation analysis and RFM modeling.

### RULE-CUST-04: Truncated East Coast Postal Codes
- **Problem:** East Coast postal codes beginning with `0` (e.g. Massachusetts `021xx`, New Jersey `071xx`) were parsed as integers, stripping the leading zero and resulting in 4-digit strings (e.g. `7198`, `2168`).
- **Detection Method:** `.str.len() < 5` check on `PostalCode`.
- **Affected Records:** 3,494 records.
- **Cleaning Rule:** Pad string with leading zero using `.str.zfill(5)`.
- **Why Chosen:** US ZIP codes are 5-character categorical strings. Restoring leading zeros ensures geographic accuracy.

### RULE-CUST-05: Missing Customer Email Addresses
- **Problem:** 750 customer records (1.5%) had `NaN` in `Email`.
- **Detection Method:** `.isna().sum()` on `Email`.
- **Affected Records:** 750 records.
- **Cleaning Rule:** Impute with `'Not Provided'`.
- **Why Chosen:** In retail POS operations, in-store shoppers frequently opt out of sharing email addresses. Populating with `'Not Provided'` preserves record completeness while enabling analysts to query non-contactable segments.

### RULE-CUST-06: Missing Customer Phone Numbers
- **Problem:** 1,000 customer records (2.0%) had `NaN` in `Phone`.
- **Detection Method:** `.isna().sum()` on `Phone`.
- **Affected Records:** 1,000 records.
- **Cleaning Rule:** Impute with `'Not Provided'`.
- **Why Chosen:** Guest checkouts and online customers frequently bypass phone input. Standardizing to `'Not Provided'` avoids `NULL` handling complexities in reporting strings.

### RULE-CUST-07: Missing Customer Date of Birth (DOB)
- **Problem:** 1,250 customer records (2.5%) had `NaN` in `DateOfBirth`.
- **Detection Method:** `.isna().sum()` on `DateOfBirth`.
- **Affected Records:** 1,250 records.
- **Cleaning Rule:** Retain as nullable `DATE` (`NaT` / empty string in CSV).
- **Why Chosen:** DOB is an optional demographic attribute. Fabricating a surrogate date (e.g. `1900-01-01`) would severely distort demographic age metrics (skewing average customer age from 42 to 78 years). SQL Server natively supports nullable `DATE` columns.

---

### RULE-PROD-01: Leading & Trailing Whitespace in Product Names
- **Problem:** Product catalog entries had padding spaces in `ProductName`.
- **Detection Method:** `.str.startswith(" ")` and `.str.endswith(" ")`.
- **Affected Records:** 20 records.
- **Cleaning Rule:** Apply `.str.strip()`.
- **Why Chosen:** Ensures clean product labels in Power BI visuals and reports.

### RULE-PROD-02: Product Category Casing and Typographical Inconsistencies
- **Problem:** `Category` column contained casing variations and spelling typos:
  - `Electrnics & Gadgets`, `ELECTRONICS & GADGETS`, `electronics & gadgets`
  - `Home and Kitchen`, `HOME & KITCHEN`, `home & kitchen`
  - `Apparel & Accs`, `APPAREL & ACCESSORIES`, `apparel & accessories`
  - `Beauty & Personalcare`, `BEAUTY & PERSONAL CARE`
  - `Sports and Outdoors`, `SPORTS & OUTDOORS`, `sports & outdoors`
- **Detection Method:** `.unique()` comparison against canonical catalog blueprint.
- **Affected Records:** 23 records (15 casing, 8 spelling/typos).
- **Cleaning Rule:** Map all variations to the 5 official merchandise categories:
  1. `Electronics & Gadgets`
  2. `Home & Kitchen`
  3. `Apparel & Accessories`
  4. `Beauty & Personal Care`
  5. `Sports & Outdoors`
- **Why Chosen:** Product categories are top-level corporate reporting dimensions; variations cause fragmented revenue and margin rollups.

---

### RULE-STOR-01: Whitespace in Retail Store Names
- **Problem:** `StoreName` contained whitespace in Store `STR-03` (`Aura Minneapolis Mall Outlet  `) and Store `STR-15` (` Aura Nashville Standalone `).
- **Detection Method:** Leading/trailing space check across `StoreName`.
- **Affected Records:** 2 records.
- **Cleaning Rule:** Apply `.str.strip()`.
- **Why Chosen:** Guarantees uniform store naming across slicers and tabular visuals.

---

### RULE-SALE-01: Duplicate Sales Transactions
- **Problem:** Exactly 450 duplicate rows existed in `sales.csv` with identical `TransactionID`, `DateKey`, `CustomerID`, `ProductID`, `StoreID`, `Quantity`, and financial metrics.
- **Detection Method:** `df.duplicated(subset=['TransactionID'], keep='first')`.
- **Affected Records:** 450 records.
- **Cleaning Rule:** Remove exact duplicates, retaining the first occurrence.
- **Why Chosen:** Transaction IDs represent unique POS receipt identifiers. Duplicate records represent ETL replay / ingestion double-counting that artificially inflates revenue.

### RULE-SALE-02: Calendar-Impossible and Corrupt Transaction Dates
- **Problem:** 30 transaction records contained invalid date strings:
  - 10 rows: `OrderDate = '2023-02-30'`, `DateKey = 20230230` (February 30 does not exist).
  - 10 rows: `OrderDate = '2024-13-01'`, `DateKey = 20241301` (Month 13 does not exist).
  - 10 rows: `OrderDate = 'INVALID_DATE'`, `DateKey = 99999999` (Corrupted string).
- **Detection Method:** Date parsing with `pd.to_datetime(errors='coerce')` and validation against `DimDate.DateKey`.
- **Affected Records:** 30 records.
- **Cleaning Rule:** Quarantine and filter out records.
- **Why Chosen:** Transaction dates cannot be safely guessed without fabricating business history. Furthermore, these dates fail SQL Server `DATE` conversion and break referential integrity with `DimDate`.

### RULE-SALE-03: Orphaned Foreign Keys (Referential Integrity Violations)
- **Problem:** 80 transaction records referenced foreign keys that do not exist in parent dimension tables:
  - 40 records with `CustomerID` in range `CUST-99990` to `CUST-99999` (Customer dimension only extends to `CUST-50000`).
  - 25 records with `ProductID` in range `PROD-9990` to `PROD-9999` (Product catalog only extends to `PROD-0500`).
  - 15 records with `StoreID = 'STR-99'` (Store dimension only extends to `STR-30`).
- **Detection Method:** Anti-join checks (`~df_sales[FK].isin(df_dim[PK])`).
- **Affected Records:** 80 records.
- **Cleaning Rule:** Quarantine and filter out records from the clean fact table.
- **Why Chosen:** Loading orphan foreign keys into a relational schema causes foreign key constraint violation failures in SQL Server. In production data warehouses, orphan records are routed to an audit quarantine table.

### RULE-SALE-04: Non-Commercial Zero-Quantity Transactions
- **Problem:** 10 transaction records had `Quantity = 0` with `$0.00` SalesAmount, CostAmount, and Profit.
- **Detection Method:** `df['Quantity'] == 0`.
- **Affected Records:** 10 records.
- **Cleaning Rule:** Filter out zero-quantity records.
- **Why Chosen:** A transaction with zero items sold and zero revenue represents a cancelled line item or POS checkout glitch. Including them distorts Average Order Value (AOV) and order volume metrics.

### RULE-SALE-05: Corrupt Negative-Quantity Transactions
- **Problem:** 25 transaction records had negative quantities (`-1`, `-2`, `-3`), but positive `UnitPrice`, positive `SalesAmount`, positive `CostAmount`, and positive `Profit`.
- **Detection Method:** `df['Quantity'] < 0`.
- **Affected Records:** 25 records.
- **Cleaning Rule:** Quarantine and filter out records.
- **Why Chosen:** The negative sign was injected into `Quantity` without adjusting financial fields, creating an irreconcilable financial contradiction (negative units with positive revenue and profit). True quantity cannot be reliably deduced.

### RULE-SALE-06: Strict Financial Recalculation & Rounding Parity
- **Problem:** Minor rounding variances in discount and profit amounts can accumulate across millions of records.
- **Detection Method:** Recomputed financial derivations using documented business formulas:
```text
Gross Sales = Quantity * UnitPrice
Discount Amount = round(Gross Sales * Discount, 2)
Sales Amount = round(Gross Sales - Discount Amount, 2)
Cost Amount = round(Quantity * UnitCost, 2)
Profit = round(Sales Amount - Cost Amount, 2)
```
- **Affected Records:** All 320,536 clean records.
- **Cleaning Rule:** Enforce exact 2-decimal rounded precision across all derivations.
- **Why Chosen:** Guarantees 100% mathematical integrity across all SQL and DAX measures.

---

## 3. Summary of Quarantined Records

| Category | Issue | Affected Records | Final Action |
|---|---|---|---|
| **Duplicates** | Identical `TransactionID` and attributes | 450 | Deduplicated (retained 1st occurrence) |
| **Invalid Dates** | Calendar-impossible / unparseable dates | 30 | Quarantined / Filtered |
| **Broken FK (Customer)** | Non-existent customer IDs | 40 | Quarantined / Filtered |
| **Broken FK (Product)** | Non-existent product SKUs | 25 | Quarantined / Filtered |
| **Broken FK (Store)** | Non-existent store IDs | 15 | Quarantined / Filtered |
| **Zero Quantities** | Zero items sold, $0 transaction | 10 | Quarantined / Filtered |
| **Negative Quantities** | Negative items with positive revenue | 25 | Quarantined / Filtered |
| **Total Filtered from Raw FactSales** | — | **595** | **Result: 320,536 Clean Transactions** |
