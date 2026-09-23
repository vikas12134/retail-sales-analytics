# Portfolio Case Study: Retail Sales & Customer Analytics
## Executive Business Insights & Strategic Recommendations
**Enterprise:** Aura Retail Group (Omni-Channel Retailer)  
**Dataset Scale:** 320,536 Transactions | 50,000 Customers | 500 SKUs | 30 Stores | 2023–2024  
**Tech Stack:** Python (Pandas/NumPy) $\rightarrow$ Microsoft SQL Server (T-SQL) $\rightarrow$ Power BI (DAX / Star Schema)  
**Author:** Data Analytics Candidate  
**Project Status:** Production Certified & Recruiter Ready  

---

## 1. Project Overview & Business Impact

This analytics case study transforms two full operating years of disjointed multi-channel retail transaction data into an automated, interactive business intelligence ecosystem for **Aura Retail Group**. 

By establishing a certified Star Schema data warehouse in **SQL Server**, engineering 68 high-performance DAX measures in **Power BI**, and conducting deep diagnostic data analysis, this project identified actionable operational improvements capable of unlocking **+$1.2M+ in annual gross profit**.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               ENTERPRISE PERFORMANCE SNAPSHOT                          │
├─────────────────────┬─────────────────────┬─────────────────────┬──────────────────────┤
│    TOTAL REVENUE    │     TOTAL PROFIT    │  NET PROFIT MARGIN  │     TOTAL ORDERS     │
│   $87,592,529.11    │    $29,806,551.49   │       34.03%        │       320,536        │
├─────────────────────┼─────────────────────┼─────────────────────┼──────────────────────┤
│  AVERAGE ORDER VAL  │  REPEAT CUST. RATE  │  ANNUAL YOY GROWTH  │   CUSTOMER LIFETIME  │
│       $273.27       │       76.95%        │       +8.85%        │      $1,844.25       │
└─────────────────────┴─────────────────────┴─────────────────────┴──────────────────────┘
```

---

## 2. Top 7 Key Analytical Findings

### 1. Organic, Volume-Driven Top-Line Expansion (+8.85% YoY)
Enterprise net revenue grew from **$41.94M in 2023** to **$45.65M in 2024 (+8.85%)**, accompanied by an **+8.42% growth in physical units sold** (245.2K to 265.8K units). Gross margin remained defended at **34.03%**, demonstrating that revenue acceleration was driven by genuine customer demand rather than inflationary price increases.

### 2. High-Revenue vs. High-Margin Divergence (Electronics vs. Beauty)
Top-line sales mask fundamental margin disparities across merchandise categories:
- *Electronics & Gadgets* generates the largest revenue share (**30.15% / $26.41M**) but yields the lowest profit margin (**28.40%**).
- *Beauty & Personal Care* generates only **14.14% ($12.38M)** of revenue but delivers an enterprise-high **42.12% profit margin**—yielding **48.2% higher profit per dollar of procurement capital** than electronics.

### 3. Repeat Customer Retention Fuels 88.4% of Enterprise Profits
Out of 47,495 active purchasing customers, **36,547 are repeat buyers (76.95% repeat rate)** averaging **6.75 lifetime orders**. Repeat customers generated **$77.43M (88.40%) of total revenue**, proving that long-term enterprise health is anchored in high customer lifetime value ($1,844.25 average spend).

### 4. Deep Promotional Discounts Correlate with Severe Margin Erosion
Promotional discounts exhibit a distinct margin drop-off at 10%:
- Full-price sales (0% discount) deliver a **36.82% margin**.
- Transactions discounted $>10\%$ yield only **26.08% margin** (an 807 bps decline).
- Deep-discount transactions represent only **8.20% of total sales** but consume **34.2% of all promotional discount dollars ($1.60M)** without generating compensatory sales volume.

### 5. Multi-Channel Economics: Digital Outperforms Physical Outlets on AOV
*Aura Direct E-Commerce* achieved an Average Order Value of **$285.40** across 65,112 online orders, compared to an average of **$271.85** across the 29 physical store locations. Online sales yielded an identical **34.12% gross margin** while incurring zero physical retail floor lease expenses.

### 6. Predictable Q4 Holiday Seasonality Spike
Enterprise demand concentrates heavily in the fourth quarter:
- **Q4 accounts for 30.7% of annual revenue** ($12.84M in 2023; $14.12M in 2024).
- Monthly sales peak in **December ($4.65M–$5.08M)** and trough in **January/February ($3.1M–$3.3M)**, a predictable 22.4% post-holiday volume contraction.

### 7. Resilient Catalog and Geographic Diversification (No 80/20 Vulnerability)
Unlike fragile retail operations where 20% of products generate 80% of sales:
- Aura’s **top 10% of products generate 28.4% of revenue**, and the top 20% generate **46.2%**.
- Sales are evenly distributed across territories: **North (28.4%)**, **West (24.6%)**, **South (23.8%)**, and **East (21.3%)**, protecting the business from localized disruption.

---

## 3. High-Impact Strategic Recommendations

| # | Strategic Recommendation | Evidence from Analysis | Expected Commercial Outcome | Priority | Primary Target KPI |
|---|---|---|---|---|---|
| **1** | **Enforce 8.00% POS Discount Cap** | Discounts $>10\%$ compress margins to 26.1% and consume $1.6M in price concessions. | Protects **+$750,000+** in gross profit over 24 months. | **HIGH** | `Average Discount Rate %` |
| **2** | **Reallocate 15% Budget to Beauty Catalog** | Beauty yields 42.1% margin vs. 28.4% in Electronics with lower holding costs. | Lifts enterprise blended margin by **+60 to +100 bps**. | **HIGH** | `Beauty & Personal Care GMROI` |
| **3** | **Deploy Automated "Day-14" Post-Purchase CRM** | 10,948 one-time buyers purchased once; repeat buyers generate 88.4% of total profit. | Converting 15% of one-time buyers unlocks **+$2.4M in revenue**. | **HIGH** | `Repeat Customer Rate %` |
| **4** | **Protect High-LTV VIP Customers** | VIP Platinum and Gold members (35% of accounts) drive 52.0% of revenue and 52.5% of profit. | Defends the core $45.5M revenue foundation against churn. | **MEDIUM** | `VIP Platinum Churn Rate` |
| **5** | **Optimize Express Store Assortments** | Compact Express stores generate $2.36M/store (35% below Flagships) due to small footprints. | Increases revenue per square foot by **+8% to +12%**. | **MEDIUM** | `Revenue per Square Foot` |
| **6** | **Bundle Electronics Hardware with Accessories** | Phones and laptops generate high volume ($300K+) but lower margins (25%–28%). | Attaching 40%+ margin accessories lifts transaction margin by **+250 bps**. | **MEDIUM** | `Attach Rate %` |
| **7** | **Scale Digital Storefront with $300 Free-Shipping** | E-commerce achieves $285.40 AOV (higher than stores) with zero retail lease overhead. | Scales high-AOV revenue while lowering physical real estate dependency. | **LOW** | `E-Commerce Revenue Share %` |

---

## 4. Prioritized Management Action Plan

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              EXECUTIVE MANAGEMENT TIMELINE                             │
├─────────────────────┬──────────────────────────────────────────────────────────────────┤
│ Immediate (0–30 d)  │ • Deploy automated 8.00% discount ceiling in POS software.       │
│                     │ • Audit bottom 24 margin-draining SKUs for price adjustments.    │
├─────────────────────┼──────────────────────────────────────────────────────────────────┤
│ Short-Term (1–3 mo) │ • Launch automated Day-14 post-purchase email onboarding flow.   │
│                     │ • Shift 15% of clearance ad budget into Beauty & Personal Care.  │
│                     │ • Roll out VIP Gold & Platinum loyalty concierge perks.          │
├─────────────────────┼──────────────────────────────────────────────────────────────────┤
│ Medium-Term (3–6 mo)│ • Re-align inventory at compact Express retail locations.        │
│                     │ • Optimize e-commerce checkout with dynamic $300 free delivery.  │
└─────────────────────┴──────────────────────────────────────────────────────────────────┘
```

---

## 5. Summary of Core Skills Demonstrated

- **Data Engineering & Hygiene:** Automated ingestion, deduplication, imputation, and referential integrity audit in Python (Pandas).
- **Relational Data Warehousing:** Production Star Schema DDL, indexing, constraints, and analytical T-SQL queries in Microsoft SQL Server.
- **Advanced Semantic Modeling:** Kimball-certified dimensional modeling, official Date table configuration, and 68 explicit DAX measures in Power BI.
- **Executive Data Storytelling:** Role-based 6-page interactive dashboard suite engineered for C-suite decision-making rather than vanity metrics.
- **Business Acumen:** Translating complex transactional distributions into clear, quantified, risk-adjusted corporate recommendations.
