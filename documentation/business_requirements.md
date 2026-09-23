# Business Requirements Document (BRD)
## Project: Retail Sales & Customer Analytics

---

## 1. Business Background

**Aura Retail Group** is a mid-sized multi-channel omni-retail enterprise operating across four major geographic regions (North, South, East, West) with a network of 25 physical retail store outlets alongside an integrated e-commerce storefront. 

The company offers a diverse catalog of merchandise across multiple core categories:
- **Electronics & Gadgets**
- **Home & Kitchen**
- **Apparel & Accessories**
- **Beauty & Personal Care**
- **Sports & Outdoors**

### Business Model & Operations
Aura Retail operates a hybrid retail sales model:
- **Direct-to-Consumer (D2C) In-Store:** Customers visit brick-and-mortar retail locations to purchase products with point-of-sale (POS) discounts and seasonal promotional offers.
- **Online Channel:** Customers purchase via the web/mobile store with home delivery options.
- **Revenue Generation:** Driven by retail merchandise sales, upsells, cross-category purchases, and promotional clearance campaigns.
- **Cost Structure:** Cost of Goods Sold (COGS), promotional discount expenses, shipping/logistics fulfillment costs, and regional retail operating overheads.

---

## 2. Business Problem

Despite consistent sales volume, senior management and department leaders face significant analytical blindspots due to fragmented data storage, manual Excel-based reporting, and a lack of unified analytics. 

Key operational and strategic bottlenecks include:

1. **Difficulty Tracking Revenue & True Profitability:**
   - Leadership lacks real-time visibility into net profit after discounts and product acquisition costs, resulting in misleading revenue-only growth assumptions.
2. **Uncertainty About Best & Worst-Performing Products:**
   - Merchandising teams cannot easily differentiate high-margin star products from high-revenue, loss-making items (loss leaders).
3. **Inability to Identify High-Value & Repeat Customers:**
   - Marketing cannot segment one-time promo hunters from loyal high-lifetime-value (LTV) customers, causing wasteful untargeted marketing spend.
4. **Disparities Across Store & Regional Performance:**
   - Significant unexplained variance in revenue and margin performance across physical stores and geographic regions.
5. **Lack of Visibility into Sales & Seasonal Trends:**
   - Inability to forecast recurring demand spikes, month-over-month (MoM) dips, and day-of-week purchase habits.
6. **Erosion of Margins from Uncontrolled Discounting:**
   - Heavy discounting campaigns run without measuring whether volume increases offset gross margin compression.
7. **Delayed Detection of Declining Performance:**
   - Store managers and regional directors discover underperforming stores or dying product lines months after trends start.

---

## 3. Project Objective

The objective of this project is to build an end-to-end modern Data Analytics solution that transforms raw, disjointed retail transaction data into an automated, interactive business intelligence ecosystem.

### Core Architecture & Technical Objective:
- **Python / Pandas:** Automate raw transactional data ingestion, schema validation, data cleaning, missing value handling, and feature engineering.
- **SQL Server / T-SQL:** Build a robust relational data warehouse schema (Staging → Star Schema dimensional model with Fact and Dimension tables) and execute analytical queries for deep exploratory analysis.
- **Power BI:** Design an enterprise-grade semantic data model with explicit relationships, DAX measure tables, dynamic time intelligence, and role-based interactive dashboards.
- **Business Insights & Recommendations:** Deliver concrete, data-backed strategic recommendations to executive leadership to optimize pricing, customer retention, product mix, and regional investments.

---

## 4. Business Questions

Below are 24 high-impact business questions categorized across 8 core operational domains.

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        24 CORE BUSINESS QUESTIONS                          │
├────────────────────────────────┬───────────────────────────────────────────┤
│ A. Overall Business Perf. (3) │ E. Store Performance (3)                  │
│ B. Sales & Time Trends (3)     │ F. Regional Performance (3)               │
│ C. Product Performance (3)     │ G. Profitability & Discounts (3)          │
│ D. Customer Analysis (3)       │ H. Business Opportunities & Actions (3)   │
└────────────────────────────────┴───────────────────────────────────────────┘
```

---

### A. Overall Business Performance

#### Question 1: What is the total gross revenue, total cost of goods, and net profit generated across the entire business?
- **Why the business cares:** Provides executive leadership with an immediate macroeconomic health check of top-line revenue versus bottom-line profit.
- **Metric / Data Required:** `Total Revenue`, `Total COGS`, `Total Net Profit`, `Profit Margin %` from transaction facts.
- **Expected Business Decision:** High-level budget allocation, financial solvency assessment, and enterprise growth target adjustments.

#### Question 2: What is the overall profit margin percentage, and is the business meeting its baseline target of 20% net margin?
- **Why the business cares:** High sales volume is unsustainable if operational margins are too thin to cover corporate overhead.
- **Metric / Data Required:** `(Total Profit / Total Revenue) * 100`, historical margin thresholds.
- **Expected Business Decision:** Implement enterprise-wide cost controls or adjust baseline pricing rules if margin dips below targets.

#### Question 3: What is the overall Average Order Value (AOV) and units sold per transaction?
- **Why the business cares:** AOV reveals transaction basket size and customer willingness to spend in a single visit.
- **Metric / Data Required:** `Total Revenue / Total Orders`, `Total Units Sold / Total Orders`.
- **Expected Business Decision:** Optimize cross-selling strategies, minimum spend thresholds for free shipping, and checkout upsells.

---

### B. Sales & Time Trends

#### Question 4: How are monthly sales and profit trending over time (Month-over-Month and Year-over-Year)?
- **Why the business cares:** Detects seasonal cycles, growth momentum, and early indicators of business downturns.
- **Metric / Data Required:** `Monthly Revenue`, `Monthly Profit`, `MoM Growth %`, `YoY Growth %`, `Order Date`.
- **Expected Business Decision:** Plan annual inventory procurement, adjust seasonal staffing, and optimize marketing launch calendars.

#### Question 5: Which days of the week and months of the year experience peak purchasing activity?
- **Why the business cares:** Customer footfall and online ordering fluctuate across weekends vs. weekdays and holiday quarters.
- **Metric / Data Required:** `Sales Revenue by Day of Week`, `Order Volume by Month/Quarter`.
- **Expected Business Decision:** Schedule store staff rosters and schedule flash sales / promotional blasts on peak shopping days.

#### Question 6: Are there quarters or specific months where revenue spikes but profitability drops?
- **Why the business cares:** Identifies "unprofitable revenue surges" often driven by excessive holiday discounts or high clearance costs.
- **Metric / Data Required:** Quarterly `Revenue Trend` vs. `Profit Margin Trend`.
- **Expected Business Decision:** Cap promotional discounts during high-traffic quarters (e.g., Q4 Black Friday / Holiday season).

---

### C. Product Performance

#### Question 7: Which product categories and individual products generate the highest revenue?
- **Why the business cares:** Identifies volume drivers and top-selling anchor products that attract customers.
- **Metric / Data Required:** `Revenue by Product Category`, `Top 10 Products by Revenue`.
- **Expected Business Decision:** Maintain stock levels for core drivers and feature top sellers in primary marketing banners.

#### Question 8: Which products generate the highest net profit and profit margin?
- **Why the business cares:** High-margin products generate the cash flow that fuels business expansion, regardless of total volume.
- **Metric / Data Required:** `Net Profit by Product`, `Profit Margin % by Product/Category`.
- **Expected Business Decision:** Incentivize sales associates to push high-margin SKUs and bundle them with popular items.

#### Question 9: Which products exhibit high sales volume/revenue but low or negative profit margins ("margin drainers")?
- **Why the business cares:** Selling items at a loss or razor-thin margin cannibalizes profits without adding strategic value.
- **Metric / Data Required:** Products with `Sales Volume > 75th percentile` AND `Profit Margin < 5%`.
- **Expected Business Decision:** Renegotiate supplier unit costs, increase retail price points, or discontinue unprofitable SKUs.

---

### D. Customer Analysis

#### Question 10: How many unique customers have purchased, and what is the overall customer acquisition trajectory?
- **Why the business cares:** Tracking customer base growth is a core metric for long-term brand viability.
- **Metric / Data Required:** `Count of Distinct Customer IDs`, `New Customers Acquired per Month`.
- **Expected Business Decision:** Evaluate top-of-funnel marketing campaigns and customer acquisition cost (CAC) efficiency.

#### Question 11: What percentage of total customers are repeat buyers versus one-time purchasers?
- **Why the business cares:** Acquiring new customers costs 5x more than retaining existing ones; a low repeat rate indicates retention failure.
- **Metric / Data Required:** `Repeat Customer Count`, `Total Customer Count`, `Repeat Customer Rate %`.
- **Expected Business Decision:** Launch dedicated post-purchase onboarding email sequences and loyalty reward programs.

#### Question 12: Who are the top 10% highest-value customers by total lifetime revenue and order frequency?
- **Why the business cares:** The Pareto Principle (80/20 rule) often applies; VIP customers drive disproportionate profit.
- **Metric / Data Required:** `Customer Lifetime Value (LTV)`, `Order Frequency per Customer`, `RFM Score`.
- **Expected Business Decision:** Create VIP concierge services, exclusive early-access sales, and personalized retention incentives.

---

### E. Store Performance

#### Question 13: Which physical store locations generate the highest revenue, profit, and customer footfall?
- **Why the business cares:** Identifies benchmark flagship stores and top-performing store managers.
- **Metric / Data Required:** `Revenue by Store ID/Name`, `Profit by Store`, `Order Volume by Store`.
- **Expected Business Decision:** Extract best practices from top stores to replicate in lower-performing locations; reward store leadership.

#### Question 14: Which stores are consistently underperforming or experiencing negative growth trends?
- **Why the business cares:** Persistent store underperformance bleeds operational capital.
- **Metric / Data Required:** `Store-level MoM Revenue Growth`, `Store Profit Margin < Regional Average`.
- **Expected Business Decision:** Investigate local store management, restructure store marketing, downsize, or plan store relocation.

#### Question 15: How does the online e-commerce sales channel compare to physical retail stores in terms of AOV and profit margin?
- **Why the business cares:** Understanding channel efficiency informs digital transformation and real estate investment strategies.
- **Metric / Data Required:** `Sales Channel Split (Online vs. In-Store)`, `Channel AOV`, `Channel Margin %`.
- **Expected Business Decision:** Shift capital budget toward digital fulfillment or in-store experiential retail based on channel ROI.

---

### F. Regional Performance

#### Question 16: Which geographic regions (North, South, East, West) generate the largest share of revenue and profit?
- **Why the business cares:** Highlights territorial market share and geographical strengths.
- **Metric / Data Required:** `Revenue by Region`, `Profit Contribution % by Region`.
- **Expected Business Decision:** Prioritize regional marketing spend and adjust regional inventory warehouse allocations.

#### Question 17: Which regions exhibit the fastest growth rates versus stagnant markets?
- **Why the business cares:** High-growth emerging regions represent expansion opportunities, while stagnating regions need intervention.
- **Metric / Data Required:** `Regional YoY Growth %`, `Quarterly Regional Run Rate`.
- **Expected Business Decision:** Expand physical store footprint into fast-growing territories; re-evaluate product-market fit in stagnant zones.

#### Question 18: Are product category preferences significantly different across geographic regions?
- **Why the business cares:** Regional demographics and climate drive divergent purchasing behaviors (e.g., apparel vs. outdoor gear).
- **Metric / Data Required:** `Product Category Sales Breakdown by Region`.
- **Expected Business Decision:** Tailor localized store assortments and regional promotional catalogs to local demand patterns.

---

### G. Profitability & Discount Impact

#### Question 19: How do promotional discount tiers (e.g., 0%, 1-10%, 11-20%, >20%) impact overall profit margins?
- **Why the business cares:** Determines whether discounting drives accretive volume or simply destroys profit margins.
- **Metric / Data Required:** `Discount % Tier`, `Units Sold per Tier`, `Gross Profit per Tier`, `Margin % per Tier`.
- **Expected Business Decision:** Set strict guardrails and maximum authorized discount thresholds for store managers and promo campaigns.

#### Question 20: What is the total monetary value lost to promotional discounts across categories and stores?
- **Why the business cares:** Quantifies the exact dollar impact of price reductions on company profits.
- **Metric / Data Required:** `Total Discount Amount = SUM(Original Price - Discounted Selling Price) * Quantity`.
- **Expected Business Decision:** Eliminate automatic blanket discounts and transition to targeted, personalized promotional vouchers.

#### Question 21: Which product categories are over-discounted with minimal corresponding lift in sales volume?
- **Why the business cares:** Identifies price-inelastic products where discounts waste margin without stimulating demand.
- **Metric / Data Required:** `Discount Rate vs. Sales Volume Elasticity by Category`.
- **Expected Business Decision:** Cease promotions on inelastic categories (e.g., staple electronics or proprietary home goods).

---

### H. Business Opportunities & Strategic Actions

#### Question 22: Which product categories represent the strongest cross-selling and bundling opportunities?
- **Why the business cares:** Multi-item baskets increase AOV without increasing customer acquisition costs.
- **Metric / Data Required:** `Co-purchased Category Affinity`, `Multi-Item Basket Rate`.
- **Expected Business Decision:** Implement curated product bundles (e.g., Laptop + Accessories) with modest bundle savings.

#### Question 23: Which customer segments represent the highest churn risk (no purchases in >90 days)?
- **Why the business cares:** Re-engaging lapsed customers before they permanently churn protects customer lifetime value.
- **Metric / Data Required:** `Days Since Last Purchase (Recency) > 90`, `Historical Spend Tier`.
- **Expected Business Decision:** Trigger automated "Win-Back" email campaigns featuring dynamic personalized discount codes.

#### Question 24: What specific pricing, inventory, and regional actions should executive leadership execute next quarter?
- **Why the business cares:** Consolidates analytical findings into clear, prioritized business execution steps.
- **Metric / Data Required:** Comprehensive synthesis of `Margin`, `Growth`, `Inventory Velocity`, and `Regional ROI`.
- **Expected Business Decision:** Formulate the upcoming quarterly strategic operational plan and executive OKRs.

---

## 5. Key KPIs (Key Performance Indicators)

The following 12 core business metrics will be standardized, computed in SQL, and modeled as explicit DAX measures in Power BI.

| # | KPI Name | Business Definition | Business Meaning / Strategic Value | Basic Calculation Logic |
|---|---|---|---|---|
| 1 | **Total Revenue** | Total gross monetary value of all completed sales transactions after applied discounts. | Primary measure of top-line commercial scale and business volume. | `SUM(Quantity * Unit_Selling_Price)` |
| 2 | **Total Cost (COGS)** | Total cost incurred to procure or manufacture all items sold. | Establishes the cost baseline required to evaluate gross profitability. | `SUM(Quantity * Unit_Cost)` |
| 3 | **Total Profit** | Net gross profit generated after deducting cost of goods from total revenue. | Ultimate measure of bottom-line financial health and operational success. | `Total Revenue - Total Cost` |
| 4 | **Profit Margin %** | The percentage of total revenue converted into net profit. | Evaluates pricing power, operational efficiency, and margin health. | `(Total Profit / Total Revenue) * 100` |
| 5 | **Total Orders** | Total count of distinct completed sales transactions / receipts. | Measures sales activity volume and customer checkout frequency. | `COUNT_DISTINCT(Order_ID)` |
| 6 | **Total Units Sold** | Total physical quantity of merchandise items sold across all orders. | Tracks physical inventory movement, demand scale, and warehouse throughput. | `SUM(Quantity)` |
| 7 | **Average Order Value (AOV)** | Average monetary spend per individual sales transaction. | Measures basket size effectiveness, pricing strategy, and upselling impact. | `Total Revenue / Total Orders` |
| 8 | **Unique Customers** | Total count of distinct individual customers who have made at least one purchase. | Measures the breadth and reach of the active customer base. | `COUNT_DISTINCT(Customer_ID)` |
| 9 | **Repeat Customers** | Total count of unique customers with 2 or more lifetime transactions. | Quantifies customer loyalty, satisfaction, and retention strength. | `COUNT_DISTINCT(Customer_ID WHERE Order_Count > 1)` |
| 10 | **Repeat Customer Rate %** | Proportion of total customer base that has purchased multiple times. | Core health metric for retention marketing; high rate indicates strong product-market fit. | `(Repeat Customers / Unique Customers) * 100` |
| 11 | **Revenue Growth (MoM / YoY)** | Percentage change in revenue compared to previous month or same month last year. | Demonstrates business trajectory, seasonal momentum, and expansion pace. | `((Revenue_Current - Revenue_Prior) / Revenue_Prior) * 100` |
| 12 | **Profit Growth (MoM / YoY)** | Percentage change in net profit compared to prior period. | Ensures bottom-line profitability is growing in tandem with or faster than top-line revenue. | `((Profit_Current - Profit_Prior) / Profit_Prior) * 100` |

---

## 6. Stakeholders & Analytical Requirements

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PROJECT STAKEHOLDERS                            │
├───────────────────────────────────┬────────────────────────────────────┤
│ • CEO / Business Owner            │ • Store Managers                   │
│ • Sales Director / Manager        │ • Marketing Manager                │
│ • Regional Operations Managers    │ • Finance & Inventory Director     │
└───────────────────────────────────┴────────────────────────────────────┘
```

### 1. CEO / Business Owner
- **Core Focus:** High-level enterprise performance, total revenue, net profitability, company growth trajectory, and market share expansion.
- **Key Information Required:**
  - Executive summary KPI cards (Revenue, Profit, Margin %, YoY Growth).
  - High-level channel and regional contribution breakdown.
  - Strategic risks (declining product categories, loss-making store locations).

### 2. Sales Director / Manager
- **Core Focus:** Sales target attainment, channel performance, sales velocity, and sales associate productivity.
- **Key Information Required:**
  - Monthly and quarterly revenue run rates vs. targets.
  - Average Order Value (AOV) and units per transaction across channels.
  - Category-level sales velocity and seasonal demand trends.

### 3. Regional Operations Managers
- **Core Focus:** Territory-specific store performance, regional revenue distribution, and operational efficiency across assigned stores.
- **Key Information Required:**
  - Ranked store performance matrix within their specific region.
  - Store-by-store sales trends, profit margins, and footfall metrics.
  - Identification of struggling stores requiring operational intervention or inventory rebalancing.

### 4. Store Managers
- **Core Focus:** Granular daily/weekly store sales, top-selling local SKUs, local customer traffic, and daily sales targets.
- **Key Information Required:**
  - Store-specific daily and weekly sales dashboard.
  - Top 10 best-selling products and out-of-stock risk alerts.
  - Local customer return rates and average transaction sizes.

### 5. Marketing Manager
- **Core Focus:** Customer acquisition, retention rates, promotional campaign ROI, and customer lifetime value.
- **Key Information Required:**
  - Repeat customer rate and customer churn analysis.
  - RFM customer segmentation (Champions, Loyalists, At-Risk, Lapsed).
  - Impact of promotional discounts on customer acquisition vs. margin degradation.

### 6. Finance & Inventory Director
- **Core Focus:** Cost of Goods Sold (COGS), gross margins, cash flow predictability, discount losses, and inventory turnover.
- **Key Information Required:**
  - Gross profit margin breakdown by product line and vendor.
  - Dollar value of revenue lost to promotional discounting.
  - Low-margin / negative-margin product identification for price adjustment.

---

## 7. Expected Deliverables

This project will produce 8 core analytical deliverables:

1. **Cleaned & Validated Datasets:**
   - Standardized, validated, and normalized CSV/Parquet datasets produced via Python ETL scripts.
2. **SQL Server Relational Database & Warehouse:**
   - Production-ready DDL scripts creating a normalized staging schema and an optimized Star Schema (Fact and Dimension tables with primary/foreign keys).
3. **SQL Analysis Queries Repository:**
   - Well-documented `.sql` query files organized by business question (Aggregations, Window Functions, CTEs, Cohort Analysis, RFM Segmentation).
4. **Power BI Semantic Data Model:**
   - Star-schema data model (`.pbix`) with clean 1-to-many relationships, proper cardinality, dedicated date tables, and optimized data types.
5. **DAX Measures Library:**
   - Centralized measure tables organizing core KPIs, time intelligence (YTD, QTD, MoM, YoY), dynamic pricing metrics, and ranking logic.
6. **Interactive Power BI Executive Dashboard:**
   - Multi-page, visually polished dashboard featuring Executive Summary, Sales Trends, Product Performance, Customer Insights, and Regional Analysis.
7. **Business Insights Report:**
   - Structured executive analytical summary synthesizing findings, trends, anomalies, and operational realities.
8. **Actionable Strategic Recommendations:**
   - Concrete business roadmap providing prioritized actions for executive leadership, marketing, sales, and store operations.

---

## 8. Success Criteria

The success of this data analytics project will be evaluated against the following criteria:

- [x] **Clarity of Business Visibility:** Leadership can evaluate total revenue, COGS, and profit margin in under 5 seconds via high-level KPI cards.
- [x] **Multi-Dimensional Slice & Dice:** Users can seamlessly filter performance by Product Category, Customer Tier, Store Location, Region, and Time Period.
- [x] **Interactive & Intuitive UI/UX:** The Power BI dashboard features clear visual hierarchy, cross-filtering, drill-through capabilities, and responsive navigation.
- [x] **Automated Data Processing:** Data pipeline cleanly handles missing values, date parsing, and data type validation without manual intervention.
- [x] **Data Integrity & Consistency:** Calculated KPIs match 100% across SQL analytical queries and Power BI DAX measures.
- [x] **Actionable Decision Support:** The final report delivers unambiguous, data-backed business decisions rather than just passive charts.

---

## 9. Project Scope

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              PROJECT SCOPE                                 │
├──────────────────────────────────────┬─────────────────────────────────────┤
│             IN SCOPE                 │            OUT OF SCOPE             │
├──────────────────────────────────────┼─────────────────────────────────────┤
│ • Transactional Sales & Revenue      │ • Real-time streaming analytics     │
│ • Product Cost & Gross Profitability │ • Live POS hardware integration     │
│ • Customer Demographics & RFM        │ • Warehouse inventory logistics     │
│ • Store & Regional Comparisons       │ • Employee shift / payroll tracking │
│ • Historical Time Trends & Seasonality│ • Detailed supplier contract terms  │
│ • Promotional Discount Impact        │ • Web traffic clickstream tracking  │
│ • Strategic Business Recommendations │ • Automated predictive ML modeling  │
└──────────────────────────────────────┴─────────────────────────────────────┘
```

### In Scope
- **Sales & Orders:** Analysis of individual transactional line items, order dates, quantities, and sales channels.
- **Financial Metrics:** Revenue, Cost of Goods Sold (COGS), Gross Profit, Profit Margins, and Discount Amounts.
- **Customer Intelligence:** Customer counts, repeat purchase rates, lifetime spend (LTV), and RFM segmentation.
- **Product & Merchandising:** Category and SKU-level performance, margin contribution, and bundling opportunities.
- **Geographic & Store Footprint:** Regional breakdown and individual store-level comparisons.
- **Discount & Pricing Strategy:** Analysis of discount tiers and their net effect on margin preservation.
- **Business Recommendations:** Practical, strategic guidance for executive leadership.

### Out of Scope
- **Warehouse & Real-Time Logistics:** Warehouse bin management, freight fleet tracking, and real-time stock replenishment.
- **Human Resources & Staff Payroll:** Individual store associate sales commissions, hourly wage modeling, and shift scheduling.
- **Supplier Manufacturing Operations:** Raw material supplier procurement tracking and factory-floor supply chain logistics.
- **Multi-Touch Marketing Attribution:** Digital ad clickstream tracking, impression tracking, and programmatic ad bid management.
- **Real-Time Data Streaming:** Sub-second IoT streaming analytics (project focuses on daily batch analytical warehousing).
