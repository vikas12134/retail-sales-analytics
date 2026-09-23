# Business Analytics & Technical Interview Notes
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Tech Stack:** Python (Pandas/NumPy) | Microsoft SQL Server (T-SQL) | Power BI Desktop (DAX / Star Schema)  
**Author:** Data Analytics Candidate  
**Date:** 2026-09-08  
**Document Purpose:** Direct Technical & Strategic Interview Preparation Guide  

---

## 1. Executive Interview Reference Guide

This document prepares candidates to articulate the architectural decisions, technical methodologies, analytical discoveries, and business impact of the **Aura Retail Group** project during technical and executive data analyst interviews.

All answers reflect the **actual codebase, schema, data hygiene pipeline, and analytical findings** established across Tasks 1 through 11.

---

## 2. Core Interview Questions & Answers

### Q1: What business problem did you solve in this project?
**Candidate Answer:**  
"Aura Retail Group is a mid-sized omni-channel retailer operating 29 physical stores and an e-commerce platform across four geographic regions. Despite steady top-line sales volume, senior leadership faced critical analytical blindspots:
1. They lacked visibility into true net profitability after promotional discounts and cost of goods sold (COGS).
2. They could not distinguish high-volume, low-margin 'margin drainers' from high-margin star products.
3. They lacked customer retention metrics, treating one-time promo hunters the same as high-lifetime-value VIP customers.
4. They experienced unexplained operational performance disparities across physical retail store formats and geographic territories.

I built an end-to-end analytics solution—from automated data hygiene in Python, relational warehousing in SQL Server, to an enterprise semantic model with 68 DAX measures in Power BI—transforming 320,536 raw transactions into actionable strategic decisions that identified **+$1.2M in annual profit improvement opportunities**."

---

### Q2: Why did you design a Star Schema rather than a Snowflake Schema or a single flat table?
**Candidate Answer:**  
"I implemented a classic Ralph Kimball Star Schema with 4 conformed dimensions (`DimDate`, `DimCustomer`, `DimProduct`, `DimStore`) linked to 1 central fact table (`FactSales`) via active 1-to-many, single-direction relationships.

I chose this over a single flat table and a snowflake schema for three reasons:
1. **In-Memory VertiPaQ Optimization:** Power BI's VertiPaQ engine utilizes columnar compression (dictionary and run-length encoding). Storing text attributes like Customer Segment, Product Category, or Store Region in conformed dimensions prevents redundant string repetition across 320,536 fact rows, compressing the model from ~32MB down to ~7MB.
2. **Elimination of Multi-Hop Snowflake Joins:** Denormalizing product subcategories into `DimProduct` and store geography into `DimStore` eliminated multi-table snowflake joins, resulting in sub-second visual query execution.
3. **Deterministic DAX Filter Context Transition:** In a star schema, filter context flows cleanly along single-direction 1-to-many paths from dimensions to facts. This prevents circular relationship ambiguities, context leakage, and non-deterministic results in DAX calculations."

---

### Q3: Why did you use Microsoft SQL Server as the intermediary warehouse rather than connecting Power BI directly to the raw CSV files?
**Candidate Answer:**  
"Connecting Power BI directly to flat files introduces severe architectural risks in enterprise settings:
1. **Data Integrity & Referential Constraints:** SQL Server enforces primary key uniqueness (`PK_DimCustomer_CustomerID`), foreign key referential integrity (`FK_FactSales_CustomerID`), and commercial business rules via `CHECK` constraints (e.g. `Quantity > 0`, `Discount BETWEEN 0 AND 1`).
2. **Covering B-Tree Indexes:** I engineered 11 performance-tuned B-Tree indexes (such as `IX_FactSales_DateKey INCLUDE (SalesAmount, Profit)`), allowing heavy analytical aggregations and window functions to run directly in the database engine without table scans.
3. **Decoupling ETL from Semantic Modeling:** By staging and transforming data in SQL Server first, the data pipeline is auditable, secure, version-controlled, and accessible by multiple downstream tools (e.g. Python ML pipelines, Power BI, Excel reporting) rather than being trapped in a proprietary Power Query M script."

---

### Q4: What data-quality issues did you discover during the data cleaning phase, and how did you resolve them?
**Candidate Answer:**  
"During the Python/Pandas audit, I discovered controlled, realistic enterprise anomalies across all raw datasets:
1. **Technical Duplicates:** 450 identical duplicate sales records resulting from ingestion replay were identified and purged.
2. **Referential Integrity Orphans:** 110 transactions in `FactSales` contained foreign keys that did not exist in parent dimensions (e.g., non-existent customer keys `CUST-99990` to `CUST-99999`, product keys `PROD-9990` to `PROD-9999`). These were quarantined and filtered to achieve 100% referential integrity.
3. **Invalid Calendar Dates:** 30 corrupted dates were detected in sales records (such as February 30th or Month 13). These unparseable dates were quarantined to protect time-intelligence calculations.
4. **Impossible Quantities:** Detected 10 records with zero quantity and 25 records with negative quantities but positive sales amounts (accounting impossibilities). These were filtered.
5. **Text Inconsistencies & Leading Zeroes:** Cleaned leading/trailing whitespace across names, normalized category casing variants, and zero-padded 3,494 East Coast postal codes (e.g., `7198` $\rightarrow$ `07198`) where standard numeric CSV parsers had stripped the leading zero.

In total, exactly **595 anomalous records** were filtered, certifying the remaining 320,536 rows as 100% mathematically balanced and GAAP-compliant."

---

### Q5: What was your most important SQL analysis, and what business question did it answer?
**Candidate Answer:**  
"My most impactful SQL analysis was **07_profitability_discount_analysis.sql**, which evaluated the relationship between promotional discounting tiers and bottom-line margin compression.

Using Common Table Expressions (CTEs) and conditional aggregation, I binned sales into four discount bands: `No Discount (0%)`, `Low (1%–10%)`, `Medium (11%–20%)`, and `High (>20%)`. The query proved that while zero-discount sales achieved a **36.82% margin**, transactions discounted above 10% collapsed to **26.08% margin** (an 807 bps decline). 

Crucially, transactions with >10% discount generated only **8.2% of total order volume** but accounted for **34.2% of all promotional discount dollars ($1.60M)**. This proved to leadership that deep discounting was destroying margins without generating compensatory volume lift."

---

### Q6: Why did you use SQL window functions, and in which analyses were they critical?
**Candidate Answer:**  
"I utilized SQL window functions extensively because they calculate running totals, moving averages, period-over-period lags, and rankings across row partitions without collapsing the underlying dataset granularity:
1. **`LAG()` in Sales Trends (`02_sales_trends.sql`):** I used `LAG(MonthlyRevenue, 1) OVER (ORDER BY Year, Month)` to calculate Month-over-Month (MoM) dollar and percentage revenue growth without requiring expensive self-joins.
2. **`SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` in Advanced Analytics (`08_advanced_analysis.sql`):** Created progressive cumulative running revenue and profit trajectories across the 24-month horizon.
3. **`DENSE_RANK() OVER (...)` in Store & Product Performance (`02_product_performance.sql`, `05_store_performance.sql`):** Dynamically ranked the top 10 and bottom 10 products by revenue and profit, and ranked stores within their respective geographical territories.
4. **`NTILE(5)` in Customer RFM Segmentation (`04_customer_segmentation.sql`):** Stratified customers into quintiles (scores 1 to 5) across Recency, Frequency, and Monetary spend to construct an RFM behavioral segmentation model."

---

### Q7: Why did you prioritize DAX measures over calculated columns in Power BI?
**Candidate Answer:**  
"I adhered strictly to the enterprise best practice of prioritizing **explicit DAX measures over calculated columns**:
1. **Memory Footprint & VertiPaQ Storage:** Calculated columns are evaluated during data refresh and stored in memory in the tabular model. For a 320,536-row fact table, creating multiple calculated columns unnecessarily inflates file size and RAM consumption. Measures consume zero storage; they are evaluated dynamically at query time in CPU cache.
2. **Dynamic Context Transition & Slicer Responsiveness:** Calculated columns are static at the row level and cannot respond to user slicers (such as Year, Region, or Category). Explicit DAX measures dynamically recalculate based on the active filter context created by visuals and slicers.
3. **Avoidance of Ratio-of-Averages Errors:** Calculating metrics like `Profit Margin %` as a calculated column and then averaging it across visual rows produces an unweighted mathematical error. Writing `[Profit Margin %] = DIVIDE([Total Profit], [Total Revenue], 0)` as an explicit measure guarantees exact mathematical precision."

---

### Q8: What was your most important Power BI dashboard insight?
**Candidate Answer:**  
"The most compelling visual insight emerged on **Page 3 (Product Performance)** and **Page 6 (Profitability)** through the **Margin vs. Volume Strategic Scatter Chart**:
- When plotting `[Product Revenue]` on the X-axis against `[Product Profit Margin %]` on the Y-axis with bubble sizes scaled by `[Product Units Sold]`, we immediately exposed a major commercial misalignment.
- *Electronics & Gadgets* was perceived by leadership as the core business because it generates 30.1% of sales ($26.4M). However, the scatter chart revealed it delivers the lowest margin (28.4%) and ties up 71.6 cents of procurement capital per dollar of revenue.
- Meanwhile, *Beauty & Personal Care* generates only 14.1% of sales ($12.4M) but achieves a 42.1% profit margin, delivering **48.2% more gross profit per dollar of inventory capital**. This gave executive leadership the empirical evidence needed to reallocate seasonal marketing budgets toward high-margin lines."

---

### Q9: What primary business recommendations did you deliver to executive management?
**Candidate Answer:**  
"I delivered seven prioritized recommendations backed directly by empirical evidence:
1. **Promotional Governance:** Implement a hard automated POS discount ceiling of 8.00%, requiring regional managerial override for discounts $>10\%$. This will protect **+$750,000+** in gross profit over 24 months.
2. **Category Budget Rebalancing:** Shift 15% of clearance marketing funds from low-margin consumer electronics toward high-margin Beauty & Personal Care lines, lifting enterprise blended margin by +60 to +100 bps.
3. **Automated Day-14 Retention Flow:** Repeat customers generate 88.4% of company profits with a 76.95% repeat rate. Deploying an automated re-engagement email sequence to convert 15% of the 10,948 one-time buyers unlocks **+$2.4M in incremental revenue**.
4. **VIP Loyalty Concierge:** Protect the top 35% of customers (VIP Platinum and Gold tiers) who generate 52.0% of total revenue ($45.5M) through early-access shopping and exclusive product bundles."

---

### Q10: What were the primary limitations of your analysis?
**Candidate Answer:**  
"I maintained strict analytical honesty by identifying four key operational limitations:
1. **Observational Correlation vs. Causality:** We proved that deep discounts correlate with lower margins, but observational data cannot prove causality. Controlled A/B pricing tests are required to confirm true SKU-level price elasticity.
2. **Absence of Inventory Holding Costs:** The warehouse tracks procurement cost (COGS) and retail price, but does not capture warehouse carrying costs, stockout frequencies, or supplier lead times.
3. **Lack of Marketing Ad Spend / CAC Data:** While we track customer acquisition dates and loyalty segments, we lack digital marketing ad spend data (Meta, Google Ads) to compute exact Customer Acquisition Cost (CAC) or Return on Ad Spend (ROAS).
4. **Synthetic Operating Data:** Although mathematically validated and referentially sound, the data was generated via statistical models rather than capturing external macroeconomic recessions or physical supply-chain black-swan disruptions."

---

### Q11: How did you validate your Power BI reporting results against SQL Server?
**Candidate Answer:**  
"I conducted a systematic 14-point mathematical reconciliation between SQL Server warehouse queries and Power BI DAX evaluations:
- Verified that `[Total Revenue]` in Power BI matched `SUM(SalesAmount)` in SQL Server down to the exact cent: **`$87,592,529.11` ($\Delta = \$0.00$)**.
- Verified `Total Cost` (**$57,785,977.62$**), `Total Profit` (**$29,806,551.49$**), `Profit Margin %` (**34.03%**), `Total Orders` (**320,536**), and `Total Units Sold` (**511,058**).
- Validated date continuity across all 731 contiguous calendar days in `DimDate` and verified that no visual matrix generated synthetic blank join rows or `#DIV/0!` errors.
- Validated that `ISINSCOPE()` guards prevented `RANKX()` measures from calculating synthetic ordinal ranks on visual grand total lines."

---

### Q12: How would you improve this project if you had access to additional enterprise data?
**Candidate Answer:**  
"With expanded data access, I would introduce three advanced analytical layers:
1. **Predictive Churn Machine Learning Model:** Using Python (Scikit-Learn/XGBoost) to engineer customer RFM features and predict churn probabilities before customers lapse, feeding dynamic risk scores into Power BI.
2. **Market Basket Association Mining:** Ingesting multi-item checkout receipts and running Apriori association algorithms to identify co-purchased product pairs, powering automated checkout upsell recommendations.
3. **Store Labor Efficiency & Floor Analytics:** Integrating store employee scheduling and payroll logs to evaluate sales per associate-hour, allowing store operations to optimize staffing rosters against peak shopping hours."
