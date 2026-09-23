# Retail Sales & Customer Analytics

An end-to-end Data Analytics portfolio project simulating a real-world retail enterprise to extract actionable business insights from transactional and customer data.

---

## 1. Project Objective

The primary objective of this project is to demonstrate a complete, production-grade Data Analyst workflow: from raw transaction ingestion, data hygiene, relational modeling, and SQL transformations to DAX calculations, interactive Power BI visualizations, and strategic business recommendations.

---

## 2. Business Problem

Retail businesses often struggle with fragmented customer data, declining customer retention, unoptimized inventory, and lack of visibility into regional sales profitability. 

Management requires a unified analytics solution to answer key operational and strategic questions:
- Which product categories and lines drive the highest margins versus raw revenue?
- Who are the high-value customers, and how can we identify churn risks early?
- How do sales and order volume trend month-over-month across different store locations and sales channels?
- What customer cohorts exhibit the highest lifetime value (LTV) and retention rates?

---

## 3. Tools & Technologies

| Tool / Technology | Purpose |
|---|---|
| **Python (Pandas, NumPy)** | Data synthesis, cleaning, validation, and automated ETL ingestion |
| **SQL Server (T-SQL)** | Relational data warehousing, staging tables, data transformations, and analytical queries |
| **Power BI** | Data modeling (Star Schema), interactive reporting, visual storytelling |
| **DAX (Data Analysis Expressions)** | Time intelligence, KPIs, dynamic metrics, customer segmentation |
| **Excel / CSV** | Raw data formats and ad-hoc exports |
| **Git / GitHub** | Version control and project documentation |

---

## 4. Planned Workflow

```
[Raw Data] 
    │
    ▼
[Data Cleaning & Validation (Python/Pandas)]
    │
    ▼
[SQL Server Database & Staging Ingestion]
    │
    ▼
[Data Modeling & Transformation (T-SQL / Views / Star Schema)]
    │
    ▼
[Exploratory SQL Data Analysis & Business Queries]
    │
    ▼
[Power BI Integration & DAX KPI Engineering]
    │
    ▼
[Interactive Dashboard Design & Visual Storytelling]
    │
    ▼
[Executive Reporting & Actionable Business Insights]
```

---

## 5. Key Business Questions

1. **Revenue & Profitability Performance:**
   - What are total sales, gross profits, and profit margins across fiscal quarters and years?
   - Which products/categories are underperforming or operating at negative margins?

2. **Customer Segmentation & Behavior:**
   - How can customers be segmented based on Recency, Frequency, and Monetary (RFM) metrics?
   - What is the repeat customer rate versus one-time buyers?

3. **Cohort & Retention Analysis:**
   - How do monthly acquisition cohorts perform over a 12-month lifecycle?
   - What is the churn rate across customer tiers?

4. **Regional & Channel Trends:**
   - Which geographical regions and sales channels contribute most to growth?
   - Are there localized seasonal spikes or shipping bottlenecks?

---

## 6. Project Directory Structure

```text
retail-sales-analytics/
│
├── data/
│   ├── raw/                 # Original unmodified dataset files (CSV/Excel)
│   └── cleaned/             # Post-Python cleaned and validated datasets
│
├── python/                  # Python scripts & Jupyter notebooks for ETL and data preparation
│
├── sql/
│   ├── database/            # DDL scripts for database and table schema creation
│   ├── staging/             # Data loading and staging procedures
│   ├── transformations/     # Data cleaning, normalization, views, and star-schema models
│   └── analysis/            # Analytical queries solving specific business questions
│
├── powerbi/                 # Power BI report files (.pbix), theme files, and templates
│
├── reports/                 # Exported PDF/image reports and executive slide summaries
│
├── documentation/           # Data dictionaries, business requirement docs, and architecture diagrams
│
└── README.md                # Project documentation and summary
```

---

## 7. Project Status

- [x] **Phase 1: Project Setup & Repository Architecture** (Completed)
- [ ] **Phase 2: Dataset Preparation & Python Data Cleaning**
- [ ] **Phase 3: SQL Server Database Setup & Relational Modeling**
- [ ] **Phase 4: Exploratory Data Analysis & Business Query Development**
- [ ] **Phase 5: Power BI Data Modeling & DAX Measures**
- [ ] **Phase 6: Dashboard Development & Visual Polish**
- [ ] **Phase 7: Final Business Insights & Executive Summary**
