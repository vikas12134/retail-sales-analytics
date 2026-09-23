"""
generate_raw_data.py
====================
Synthetic RAW Dataset Generator for Aura Retail Group
Project: Retail Sales & Customer Analytics
Author: Data Analytics Team
Date: 2026-09-01
Seed: 42 (Fully Reproducible)

Generates:
1. data/raw/date.csv       (731 rows - 2 full years: 2023-01-01 to 2024-12-31)
2. data/raw/stores.csv     (30 rows - 1 Online + 29 Physical stores across 4 regions)
3. data/raw/products.csv   (500 rows - 5 core merchandise categories)
4. data/raw/customers.csv  (50,000 rows - realistic demographics & behavioral segments)
5. data/raw/sales.csv      (320,000+ rows - transaction-level sales with seasonal & financial realism)

Injects controlled ~1-2% intentional data quality anomalies for subsequent ETL & cleaning demonstration.
Performs automated validation checks across all generated files.
"""

import os
import sys
import random
import datetime
import numpy as np
import pandas as pd
from faker import Faker

# ----------------------------------------------------------------------
# Configuration & Global Constants
# ----------------------------------------------------------------------
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)
fake = Faker()
Faker.seed(RANDOM_SEED)

START_DATE = datetime.date(2023, 1, 1)
END_DATE = datetime.date(2024, 12, 31)

NUM_CUSTOMERS = 50000
NUM_PRODUCTS = 500
NUM_STORES = 30
TARGET_SALES_RECORDS = 325000

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "raw")


# ----------------------------------------------------------------------
# 1. Date Dimension Generator
# ----------------------------------------------------------------------
def generate_date_dimension(start_date, end_date):
    """
    Generates a complete Date dimension table covering start_date to end_date.
    Includes calendar, fiscal, holiday, and weekend attributes.
    """
    print("--> Generating Date Dimension...")
    current_date = start_date
    date_records = []
    
    # Key US retail holidays (Month, Day) or approximate fixed dates
    fixed_holidays = {
        (1, 1): "New Year's Day",
        (7, 4): "Independence Day",
        (11, 11): "Veterans Day",
        (12, 24): "Christmas Eve",
        (12, 25): "Christmas Day",
        (12, 31): "New Year's Eve"
    }

    while current_date <= end_date:
        year = current_date.year
        month = current_date.month
        day = current_date.day
        day_of_week = current_date.isoweekday() # 1=Monday, 7=Sunday
        is_weekend = 1 if day_of_week in [6, 7] else 0
        
        # Holiday heuristic (Fixed + Memorial Day, Labor Day, Thanksgiving, Black Friday)
        is_holiday = 0
        if (month, day) in fixed_holidays:
            is_holiday = 1
        elif month == 5 and day >= 25 and day_of_week == 1: # Memorial Day (Last Monday of May)
            is_holiday = 1
        elif month == 9 and day <= 7 and day_of_week == 1: # Labor Day (First Monday of Sep)
            is_holiday = 1
        elif month == 11 and 22 <= day <= 28 and day_of_week == 4: # Thanksgiving (4th Thursday)
            is_holiday = 1
        elif month == 11 and 23 <= day <= 29 and day_of_week == 5: # Black Friday (Day after Thanksgiving)
            is_holiday = 1
        elif month == 11 and 26 <= day <= 30 and day_of_week == 1: # Cyber Monday
            is_holiday = 1

        quarter = (month - 1) // 3 + 1
        quarter_name = f"{year}-Q{quarter}"
        month_name = current_date.strftime("%B")
        month_year = current_date.strftime("%b-%Y")
        day_name = current_date.strftime("%A")
        week_of_year = current_date.isocalendar()[1]
        date_key = int(current_date.strftime("%Y%m%d"))
        
        fiscal_year = f"FY{year}"
        fiscal_quarter = f"FQ{quarter}"

        date_records.append({
            "DateKey": date_key,
            "FullDate": current_date.strftime("%Y-%m-%d"),
            "Year": year,
            "Quarter": quarter,
            "QuarterName": quarter_name,
            "Month": month,
            "MonthName": month_name,
            "MonthYear": month_year,
            "WeekOfYear": week_of_year,
            "DayOfWeek": day_of_week,
            "DayName": day_name,
            "DayOfMonth": day,
            "IsWeekend": is_weekend,
            "IsHoliday": is_holiday,
            "FiscalYear": fiscal_year,
            "FiscalQuarter": fiscal_quarter
        })
        current_date += datetime.timedelta(days=1)

    df_date = pd.DataFrame(date_records)
    print(f"    Date Dimension generated: {len(df_date)} rows.")
    return df_date


# ----------------------------------------------------------------------
# 2. Store Dimension Generator
# ----------------------------------------------------------------------
def generate_store_dimension(num_stores=30):
    """
    Generates 30 stores: 1 Online Flagship Store and 29 physical stores across 4 regions.
    Assigns realistic store types, square footage, open dates, and performance tiers.
    """
    print("--> Generating Store Dimension...")
    
    regions_config = [
        {"Region": "North", "States": ["IL", "MN", "MI", "OH", "WI", "IN", "IA"], 
         "Cities": ["Chicago", "Minneapolis", "Detroit", "Columbus", "Milwaukee", "Indianapolis", "Des Moines"]},
        {"Region": "South", "States": ["TX", "TX", "TX", "GA", "FL", "NC", "TN", "FL"], 
         "Cities": ["Houston", "Dallas", "Austin", "Atlanta", "Miami", "Charlotte", "Nashville", "Orlando"]},
        {"Region": "East", "States": ["NY", "MA", "PA", "DC", "MD", "PA", "NJ"], 
         "Cities": ["New York", "Boston", "Philadelphia", "Washington", "Baltimore", "Pittsburgh", "Newark"]},
        {"Region": "West", "States": ["CA", "CA", "WA", "AZ", "CO", "CA", "OR"], 
         "Cities": ["Los Angeles", "San Francisco", "Seattle", "Phoenix", "Denver", "San Diego", "Portland"]}
    ]
    
    stores = []
    
    # Store 1: Online Storefront
    stores.append({
        "StoreID": "STR-01",
        "StoreName": "Aura Direct E-Commerce",
        "StoreType": "Online",
        "City": "National Online",
        "State": "National",
        "Region": "National",
        "SquareFootage": 0,
        "OpenDate": "2020-01-15",
        "ManagerName": "Alex Rivera",
        "PerformanceTier": "Tier 1 - Digital Flagship",
        "Weight": 0.22  # Handles ~22% of total company orders
    })
    
    store_counter = 2
    
    for reg_info in regions_config:
        reg = reg_info["Region"]
        states = reg_info["States"]
        cities = reg_info["Cities"]
        
        for idx in range(len(cities)):
            if store_counter > num_stores:
                break
            city = cities[idx]
            state = states[idx]
            store_id = f"STR-{store_counter:02d}"
            
            # First store in major city is Flagship, others vary
            if idx == 0:
                stype = "Flagship Store"
                sq_ft = random.randint(25000, 42000)
                perf_tier = "Tier 1 - High Revenue"
                weight = 0.045
            elif idx in [1, 2]:
                stype = "Mall Outlet"
                sq_ft = random.randint(15000, 24000)
                perf_tier = "Tier 2 - Growth"
                weight = 0.035
            elif idx in [3, 4]:
                stype = "Standalone Store"
                sq_ft = random.randint(12000, 20000)
                perf_tier = "Tier 3 - Average"
                weight = 0.025
            else:
                stype = random.choice(["Mall Outlet", "Express Store", "Standalone Store"])
                sq_ft = random.randint(6000, 14000)
                # Introduce 3-4 underperforming / declining stores
                if store_counter in [8, 15, 23, 29]:
                    perf_tier = "Tier 4 - Underperforming / Declining"
                    weight = 0.012
                else:
                    perf_tier = "Tier 3 - Average"
                    weight = 0.022
                
            store_name = f"Aura {city} {stype.replace(' Store', '')}"
            open_date = fake.date_between_dates(
                date_start=datetime.date(2017, 1, 1), 
                date_end=datetime.date(2022, 6, 30)
            ).strftime("%Y-%m-%d")
            
            manager_name = fake.name()
            
            stores.append({
                "StoreID": store_id,
                "StoreName": store_name,
                "StoreType": stype,
                "City": city,
                "State": state,
                "Region": reg,
                "SquareFootage": sq_ft,
                "OpenDate": open_date,
                "ManagerName": manager_name,
                "PerformanceTier": perf_tier,
                "Weight": weight
            })
            store_counter += 1

    df_stores = pd.DataFrame(stores)
    # Normalize weights so sum is 1.0
    df_stores["Weight"] = df_stores["Weight"] / df_stores["Weight"].sum()
    print(f"    Store Dimension generated: {len(df_stores)} rows.")
    return df_stores


# ----------------------------------------------------------------------
# 3. Product Dimension Generator
# ----------------------------------------------------------------------
def generate_product_dimension(num_products=500):
    """
    Generates 500 products across 5 core merchandise categories.
    Models distinct profit margins (star products, staples, margin drainers).
    """
    print("--> Generating Product Dimension...")
    
    catalog_blueprint = [
        {
            "Category": "Electronics & Gadgets",
            "Subcategories": {
                "Smartphones & Tablets": {"brands": ["NovaTech", "Quantum", "ApexMobile"], "price_range": (299.99, 1299.99), "margin_range": (0.18, 0.32)},
                "Laptops & Computers": {"brands": ["ByteGear", "NovaTech", "ApexLaptops"], "price_range": (499.99, 1799.99), "margin_range": (0.15, 0.28)},
                "Audio & Headphones": {"brands": ["ApexAudio", "PulseSound", "LuminaAcoustics"], "price_range": (39.99, 349.99), "margin_range": (0.35, 0.55)},
                "Smart Home & IoT": {"brands": ["LuminaHome", "QuantumSense", "NovaTech"], "price_range": (24.99, 219.99), "margin_range": (0.30, 0.48)},
                "Cables & Tech Accessories": {"brands": ["ByteGear", "Pulse", "Quantum"], "price_range": (12.99, 69.99), "margin_range": (0.45, 0.68)}
            },
            "TargetCount": 115
        },
        {
            "Category": "Home & Kitchen",
            "Subcategories": {
                "Cookware & Bakeware": {"brands": ["ChefCraft", "HearthStone", "AuraLiving"], "price_range": (29.99, 299.99), "margin_range": (0.35, 0.52)},
                "Small Kitchen Appliances": {"brands": ["ChefCraft", "NovaKitchen", "PureHome"], "price_range": (49.99, 399.99), "margin_range": (0.28, 0.42)},
                "Dining & Glassware": {"brands": ["DecoStyle", "AuraLiving", "HearthStone"], "price_range": (19.99, 149.99), "margin_range": (0.40, 0.60)},
                "Storage & Organization": {"brands": ["PureHome", "DecoStyle", "AuraLiving"], "price_range": (14.99, 89.99), "margin_range": (0.42, 0.65)},
                "Bed & Bath": {"brands": ["AuraLiving", "PureHome", "LuxeComfort"], "price_range": (24.99, 199.99), "margin_range": (0.38, 0.58)}
            },
            "TargetCount": 110
        },
        {
            "Category": "Apparel & Accessories",
            "Subcategories": {
                "Men's Apparel": {"brands": ["UrbanThread", "Vanguard", "SummitFit"], "price_range": (19.99, 149.99), "margin_range": (0.45, 0.62)},
                "Women's Apparel": {"brands": ["AuraStyle", "Solis Apparel", "UrbanThread"], "price_range": (24.99, 189.99), "margin_range": (0.48, 0.65)},
                "Footwear": {"brands": ["Vanguard", "SummitFit", "AeroStep"], "price_range": (49.99, 199.99), "margin_range": (0.38, 0.55)},
                "Bags & Luggage": {"brands": ["Vanguard", "AuraStyle", "TrailPeak"], "price_range": (39.99, 279.99), "margin_range": (0.42, 0.58)},
                "Fashion Accessories & Jewelry": {"brands": ["AuraStyle", "Solis Apparel", "DecoStyle"], "price_range": (14.99, 129.99), "margin_range": (0.55, 0.72)}
            },
            "TargetCount": 105
        },
        {
            "Category": "Beauty & Personal Care",
            "Subcategories": {
                "Skincare": {"brands": ["AuraGlow", "RadiantSkin", "PureEssence"], "price_range": (18.99, 129.99), "margin_range": (0.50, 0.70)},
                "Haircare": {"brands": ["LuxeCare", "VelvetBotanicals", "PureEssence"], "price_range": (14.99, 89.99), "margin_range": (0.48, 0.68)},
                "Fragrances": {"brands": ["VelvetBotanicals", "LuxeCare", "AuraGlow"], "price_range": (39.99, 179.99), "margin_range": (0.55, 0.75)},
                "Makeup": {"brands": ["AuraGlow", "RadiantSkin", "VelvetBotanicals"], "price_range": (12.99, 79.99), "margin_range": (0.52, 0.68)},
                "Personal Grooming": {"brands": ["PureEssence", "LuxeCare", "NovaTech"], "price_range": (19.99, 149.99), "margin_range": (0.35, 0.50)}
            },
            "TargetCount": 85
        },
        {
            "Category": "Sports & Outdoors",
            "Subcategories": {
                "Fitness Equipment": {"brands": ["IronCore", "AeroFit", "OmniSport"], "price_range": (29.99, 599.99), "margin_range": (0.30, 0.48)},
                "Outdoor & Camping Gear": {"brands": ["TrailPeak", "HorizonTrek", "OmniSport"], "price_range": (24.99, 449.99), "margin_range": (0.35, 0.52)},
                "Athletic Footwear & Apparel": {"brands": ["AeroFit", "SummitFit", "IronCore"], "price_range": (29.99, 159.99), "margin_range": (0.42, 0.60)},
                "Cycling & Active Gear": {"brands": ["AeroFit", "TrailPeak", "OmniSport"], "price_range": (19.99, 299.99), "margin_range": (0.36, 0.54)},
                "Hydration & Accessories": {"brands": ["HorizonTrek", "TrailPeak", "IronCore"], "price_range": (12.99, 49.99), "margin_range": (0.48, 0.65)}
            },
            "TargetCount": 85
        }
    ]
    
    product_descriptors = [
        "Pro", "Elite", "Ultra", "Max", "Prime", "Essential", "Classic", "Plus", 
        "Signature", "Deluxe", "Series X", "Precision", "Advanced", "Select"
    ]
    
    products = []
    prod_id_counter = 1
    
    for cat_data in catalog_blueprint:
        category = cat_data["Category"]
        subcats = cat_data["Subcategories"]
        target = cat_data["TargetCount"]
        
        subcat_names = list(subcats.keys())
        counts_per_sub = target // len(subcat_names)
        remainder = target % len(subcat_names)
        
        for i, subcat in enumerate(subcat_names):
            sub_count = counts_per_sub + (1 if i < remainder else 0)
            sub_info = subcats[subcat]
            brands = sub_info["brands"]
            min_p, max_p = sub_info["price_range"]
            min_m, max_m = sub_info["margin_range"]
            
            for _ in range(sub_count):
                brand = random.choice(brands)
                desc = random.choice(product_descriptors)
                clean_name = f"{brand} {subcat.split('&')[0].strip()} {desc} {prod_id_counter}"
                
                raw_price = round(random.uniform(min_p, max_p), 2)
                
                # Assign specific margin profiles:
                # 8% of products are "Margin Drainers" (low base margin, easily negative with discounts)
                # 15% are "Star Products" (high margin, high appeal)
                # 77% are "Standard Market Margin"
                rand_profile = random.random()
                if rand_profile < 0.08:
                    margin = random.uniform(0.04, 0.09)  # Margin drainer (4-9% gross margin)
                elif rand_profile < 0.23:
                    margin = random.uniform(min_m + 0.10, min(0.72, max_m + 0.15)) # Star high margin
                else:
                    margin = random.uniform(min_m, max_m)
                
                unit_cost = round(raw_price * (1.0 - margin), 2)
                unit_cost = max(0.50, unit_cost)
                
                # Product popularity weight (Pareto distribution)
                pop_weight = np.random.pareto(a=1.8) + 0.1
                
                products.append({
                    "ProductID": f"PROD-{prod_id_counter:04d}",
                    "ProductName": clean_name,
                    "Category": category,
                    "Subcategory": subcat,
                    "Brand": brand,
                    "UnitCost": unit_cost,
                    "UnitPrice": raw_price,
                    "Status": "Active",
                    "PopularityWeight": pop_weight
                })
                prod_id_counter += 1

    df_products = pd.DataFrame(products)
    # Normalize popularity weights
    df_products["PopularityWeight"] = df_products["PopularityWeight"] / df_products["PopularityWeight"].sum()
    print(f"    Product Dimension generated: {len(df_products)} rows.")
    return df_products


# ----------------------------------------------------------------------
# 4. Customer Dimension Generator
# ----------------------------------------------------------------------
def generate_customer_dimension(num_customers=50000, stores_df=None):
    """
    Generates 50,000 customers with realistic demographics, locations aligned
    with store regions, join dates, and customer segment tiers.
    """
    print(f"--> Generating Customer Dimension ({num_customers:,} records)...")
    
    # Regional state/city population distribution
    regional_dist = [
        {"Region": "North", "Weight": 0.25, "States": ["IL", "MN", "MI", "OH", "WI", "IN", "IA"], 
         "Cities": ["Chicago", "Minneapolis", "Detroit", "Columbus", "Milwaukee", "Indianapolis", "Des Moines"],
         "ZipPrefix": ["606", "554", "482", "432", "532", "462", "503"]},
        {"Region": "South", "Weight": 0.29, "States": ["TX", "TX", "TX", "GA", "FL", "NC", "TN", "FL"], 
         "Cities": ["Houston", "Dallas", "Austin", "Atlanta", "Miami", "Charlotte", "Nashville", "Orlando"],
         "ZipPrefix": ["770", "752", "787", "303", "331", "282", "372", "328"]},
        {"Region": "East", "Weight": 0.24, "States": ["NY", "MA", "PA", "DC", "MD", "PA", "NJ"], 
         "Cities": ["New York", "Boston", "Philadelphia", "Washington", "Baltimore", "Pittsburgh", "Newark"],
         "ZipPrefix": ["100", "021", "191", "200", "212", "152", "071"]},
        {"Region": "West", "Weight": 0.22, "States": ["CA", "CA", "WA", "AZ", "CO", "CA", "OR"], 
         "Cities": ["Los Angeles", "San Francisco", "Seattle", "Phoenix", "Denver", "San Diego", "Portland"],
         "ZipPrefix": ["900", "941", "981", "850", "802", "921", "972"]}
    ]
    
    reg_weights = [r["Weight"] for r in regional_dist]
    chosen_reg_indices = np.random.choice(len(regional_dist), size=num_customers, p=reg_weights)
    
    # Customer Segment Distribution: Regular (60%), Silver (22%), Gold (13%), VIP Platinum (5%)
    segments = ["Regular", "Silver", "Gold", "VIP Platinum"]
    segment_weights = [0.60, 0.22, 0.13, 0.05]
    chosen_segments = np.random.choice(segments, size=num_customers, p=segment_weights)
    
    # Gender Distribution: Female (51%), Male (47%), Other (2%)
    genders = ["Female", "Male", "Other"]
    gender_weights = [0.51, 0.47, 0.02]
    chosen_genders = np.random.choice(genders, size=num_customers, p=gender_weights)
    
    # Email domains
    email_domains = ["gmail.com", "yahoo.com", "outlook.com", "icloud.com", "hotmail.com", "aol.com", "proton.me"]
    domain_weights = [0.45, 0.20, 0.18, 0.10, 0.04, 0.02, 0.01]
    chosen_domains = np.random.choice(email_domains, size=num_customers, p=domain_weights)
    
    # Purchase frequency tiers (Pareto propensity)
    customer_freq_tiers = np.random.choice([1, 2, 3, 4], size=num_customers, p=[0.48, 0.33, 0.14, 0.05])
    
    customers = []
    
    for i in range(num_customers):
        cust_id = f"CUST-{i+1:05d}"
        gender = chosen_genders[i]
        if gender == "Female":
            fname = fake.first_name_female()
        elif gender == "Male":
            fname = fake.first_name_male()
        else:
            fname = fake.first_name()
        lname = fake.last_name()
        
        domain = chosen_domains[i]
        clean_email = f"{fname.lower()}.{lname.lower()}{random.randint(1, 999)}@{domain}"
        clean_phone = f"{random.randint(200, 999)}-{random.randint(200, 999)}-{random.randint(1000, 9999)}"
        
        # Date of birth between 1950 and 2004
        dob = fake.date_between_dates(
            date_start=datetime.date(1950, 1, 1),
            date_end=datetime.date(2004, 12, 31)
        ).strftime("%Y-%m-%d")
        
        # Regional location assignment
        reg_idx = chosen_reg_indices[i]
        reg_obj = regional_dist[reg_idx]
        reg_name = reg_obj["Region"]
        loc_idx = random.randint(0, len(reg_obj["Cities"]) - 1)
        city = reg_obj["Cities"][loc_idx]
        state = reg_obj["States"][loc_idx]
        zip_prefix = reg_obj["ZipPrefix"][loc_idx]
        postal_code = f"{zip_prefix}{random.randint(10, 99):02d}"
        
        # Signup Date between 2021-01-01 and 2024-11-30
        join_date = fake.date_between_dates(
            date_start=datetime.date(2021, 1, 1),
            date_end=datetime.date(2024, 11, 30)
        ).strftime("%Y-%m-%d")
        
        segment = chosen_segments[i]
        freq_tier = customer_freq_tiers[i]
        
        customers.append({
            "CustomerID": cust_id,
            "FirstName": fname,
            "LastName": lname,
            "Email": clean_email,
            "Phone": clean_phone,
            "Gender": gender,
            "DateOfBirth": dob,
            "City": city,
            "State": state,
            "Region": reg_name,
            "PostalCode": postal_code,
            "CustomerSegment": segment,
            "JoinDate": join_date,
            "FrequencyTier": freq_tier
        })

    df_customers = pd.DataFrame(customers)
    print(f"    Customer Dimension generated: {len(df_customers)} rows.")
    return df_customers


# ----------------------------------------------------------------------
# 5. Sales Transactions Generator
# ----------------------------------------------------------------------
def generate_sales_transactions(df_customers, df_products, df_stores, df_date, target_records=325000):
    """
    Generates 300,000+ realistic transaction-level sales records with:
    - Customer frequency tiers (Pareto distribution)
    - Product demand curves (Stars vs Long-tail)
    - Store performance weighting & Regional affinity
    - Monthly, holiday, and weekend seasonality
    - Discount tiers and strict financial calculations
    """
    print(f"--> Generating Sales Transactions (~{target_records:,} records)...")
    
    customer_ids = df_customers["CustomerID"].values
    customer_regions = df_customers["Region"].values
    freq_tiers = df_customers["FrequencyTier"].values
    
    orders_per_cust = np.zeros(len(df_customers), dtype=int)
    for i, tier in enumerate(freq_tiers):
        if tier == 1:
            orders_per_cust[i] = 1
        elif tier == 2:
            orders_per_cust[i] = np.random.randint(2, 6)
        elif tier == 3:
            orders_per_cust[i] = np.random.randint(6, 19)
        else: # tier 4 VIP
            orders_per_cust[i] = np.random.randint(20, 46)

    # Scale total orders slightly to hit target records
    total_planned = orders_per_cust.sum()
    scale_factor = target_records / total_planned
    orders_per_cust = np.maximum(1, np.round(orders_per_cust * scale_factor).astype(int))
    orders_per_cust[freq_tiers == 1] = 1
    
    total_sales_count = orders_per_cust.sum()
    print(f"    Planned transaction volume: {total_sales_count:,} records across {len(df_customers):,} customers.")
    
    cust_indices = np.repeat(np.arange(len(df_customers)), orders_per_cust)
    np.random.shuffle(cust_indices)
    total_txns = len(cust_indices)
    
    # Monthly Seasonality Weights
    month_multipliers = {
        1: 0.78, 2: 0.74, 3: 0.88, 4: 0.92, 5: 1.02, 6: 1.05,
        7: 1.08, 8: 1.12, 9: 0.98, 10: 1.05, 11: 1.42, 12: 1.65
    }
    # Day of week multipliers
    dow_multipliers = {
        1: 0.84, 2: 0.82, 3: 0.86, 4: 0.92, 5: 1.16, 6: 1.38, 7: 1.26
    }
    
    date_keys = df_date["DateKey"].values
    full_dates = df_date["FullDate"].values
    date_weights = []
    
    for _, row in df_date.iterrows():
        m_mult = month_multipliers[row["Month"]]
        d_mult = dow_multipliers[row["DayOfWeek"]]
        h_mult = 1.35 if row["IsHoliday"] == 1 else 1.0
        y_mult = 1.12 if row["Year"] == 2024 else 1.0
        w = m_mult * d_mult * h_mult * y_mult
        date_weights.append(w)
        
    date_weights = np.array(date_weights) / sum(date_weights)
    sampled_date_indices = np.random.choice(len(df_date), size=total_txns, p=date_weights)
    
    prod_ids = df_products["ProductID"].values
    prod_costs = df_products["UnitCost"].values
    prod_prices = df_products["UnitPrice"].values
    prod_weights = df_products["PopularityWeight"].values
    
    sampled_prod_indices = np.random.choice(len(df_products), size=total_txns, p=prod_weights)
    
    store_ids = df_stores["StoreID"].values
    store_regions = df_stores["Region"].values
    store_weights = df_stores["Weight"].values
    
    region_store_map = {
        "North": np.where(store_regions == "North")[0],
        "South": np.where(store_regions == "South")[0],
        "East": np.where(store_regions == "East")[0],
        "West": np.where(store_regions == "West")[0]
    }
    online_store_idx = np.where(store_ids == "STR-01")[0][0]
    
    sampled_store_indices = np.zeros(total_txns, dtype=int)
    cust_assigned_regions = customer_regions[cust_indices]
    rand_channels = np.random.random(total_txns)
    
    for reg in ["North", "South", "East", "West"]:
        mask = (cust_assigned_regions == reg)
        sub_n = np.sum(mask)
        if sub_n == 0:
            continue
        
        reg_stores = region_store_map[reg]
        reg_sub_weights = store_weights[reg_stores]
        reg_sub_weights = reg_sub_weights / reg_sub_weights.sum()
        
        sub_rands = rand_channels[mask]
        sub_store_res = np.zeros(sub_n, dtype=int)
        
        online_mask = (sub_rands < 0.22)
        sub_store_res[online_mask] = online_store_idx
        
        in_reg_mask = (sub_rands >= 0.22) & (sub_rands < 0.95)
        if np.any(in_reg_mask):
            sub_store_res[in_reg_mask] = np.random.choice(reg_stores, size=np.sum(in_reg_mask), p=reg_sub_weights)
            
        cross_reg_mask = (sub_rands >= 0.95)
        if np.any(cross_reg_mask):
            phys_stores = np.where(store_ids != "STR-01")[0]
            phys_weights = store_weights[phys_stores] / store_weights[phys_stores].sum()
            sub_store_res[cross_reg_mask] = np.random.choice(phys_stores, size=np.sum(cross_reg_mask), p=phys_weights)
            
        sampled_store_indices[mask] = sub_store_res

    # Quantities
    qty_pool = [1, 2, 3, 4, 5, 6, 8, 10]
    qty_probs = [0.66, 0.21, 0.07, 0.03, 0.015, 0.008, 0.004, 0.003]
    sampled_quantities = np.random.choice(qty_pool, size=total_txns, p=qty_probs)
    
    # Discount Rates
    disc_pool = [0.00, 0.05, 0.10, 0.15, 0.20, 0.30]
    disc_probs = [0.52, 0.16, 0.15, 0.10, 0.05, 0.02]
    sampled_discounts = np.random.choice(disc_pool, size=total_txns, p=disc_probs)
    
    # Payment Methods
    payment_methods_pool = ["Credit Card", "Debit Card", "UPI / Digital Wallet", "Cash", "Gift Card"]
    pay_probs_online = [0.55, 0.22, 0.18, 0.00, 0.05]
    pay_probs_instore = [0.38, 0.30, 0.18, 0.10, 0.04]
    
    is_online_arr = (sampled_store_indices == online_store_idx)
    sampled_payments = np.empty(total_txns, dtype=object)
    
    online_count = np.sum(is_online_arr)
    instore_count = total_txns - online_count
    
    if online_count > 0:
        sampled_payments[is_online_arr] = np.random.choice(payment_methods_pool, size=online_count, p=pay_probs_online)
    if instore_count > 0:
        sampled_payments[~is_online_arr] = np.random.choice(payment_methods_pool, size=instore_count, p=pay_probs_instore)

    # Financial Calculations
    u_prices = prod_prices[sampled_prod_indices]
    u_costs = prod_costs[sampled_prod_indices]
    
    gross_amounts = np.round(sampled_quantities * u_prices, 2)
    disc_amounts = np.round(gross_amounts * sampled_discounts, 2)
    sales_amounts = np.round(gross_amounts - disc_amounts, 2)
    cost_amounts = np.round(sampled_quantities * u_costs, 2)
    profit_amounts = np.round(sales_amounts - cost_amounts, 2)
    
    # Build Sales DataFrame
    sales_records = {
        "TransactionID": [f"TXN-{idx+1:07d}" for idx in range(total_txns)],
        "DateKey": date_keys[sampled_date_indices],
        "OrderDate": full_dates[sampled_date_indices],
        "CustomerID": customer_ids[cust_indices],
        "ProductID": prod_ids[sampled_prod_indices],
        "StoreID": store_ids[sampled_store_indices],
        "SalesChannel": np.where(is_online_arr, "Online", "In-Store"),
        "Quantity": sampled_quantities,
        "UnitPrice": u_prices,
        "Discount": sampled_discounts,
        "DiscountAmount": disc_amounts,
        "SalesAmount": sales_amounts,
        "UnitCost": u_costs,
        "CostAmount": cost_amounts,
        "Profit": profit_amounts,
        "PaymentMethod": sampled_payments
    }
    
    df_sales = pd.DataFrame(sales_records)
    df_sales.sort_values(by=["OrderDate", "TransactionID"], inplace=True)
    df_sales.reset_index(drop=True, inplace=True)
    df_sales["TransactionID"] = [f"TXN-{idx+1:07d}" for idx in range(len(df_sales))]
    
    print(f"    Sales Transactions generated: {len(df_sales):,} rows.")
    return df_sales


# ----------------------------------------------------------------------
# 6. Inject Intentional Controlled Data Quality Issues (~1-2%)
# ----------------------------------------------------------------------
def inject_data_quality_issues(df_customers, df_products, df_stores, df_sales):
    """
    Injects a controlled, documented set of realistic data quality issues
    into the RAW datasets for demonstration in subsequent cleaning & ETL tasks.
    """
    print("--> Injecting Controlled Intentional Data Quality Issues...")
    
    df_cust = df_customers.copy()
    df_prod = df_products.copy()
    df_stor = df_stores.copy()
    df_sal = df_sales.copy()
    
    # --- A. Customers Dataset Issues ---
    n_cust = len(df_cust)
    
    # 1. Missing Emails (~750 rows, 1.5%)
    null_email_indices = np.random.choice(n_cust, size=750, replace=False)
    df_cust.loc[null_email_indices, "Email"] = np.nan
    
    # 2. Missing Phone numbers (~1,000 rows, 2.0%)
    null_phone_indices = np.random.choice(n_cust, size=1000, replace=False)
    df_cust.loc[null_phone_indices, "Phone"] = np.nan
    
    # 3. Missing DateOfBirth (~1,250 rows, 2.5%)
    null_dob_indices = np.random.choice(n_cust, size=1250, replace=False)
    df_cust.loc[null_dob_indices, "DateOfBirth"] = np.nan
    
    # 4. Leading / Trailing Whitespace in FirstName, LastName, City (~600 rows)
    ws_indices = np.random.choice(n_cust, size=600, replace=False)
    for idx in ws_indices[:200]:
        df_cust.loc[idx, "FirstName"] = f"  {df_cust.loc[idx, 'FirstName']}"
    for idx in ws_indices[200:400]:
        df_cust.loc[idx, "LastName"] = f"{df_cust.loc[idx, 'LastName']}  "
    for idx in ws_indices[400:]:
        df_cust.loc[idx, "City"] = f" {df_cust.loc[idx, 'City']} "
        
    # 5. Inconsistent Capitalization in CustomerSegment & State (~500 rows)
    case_indices = np.random.choice(n_cust, size=500, replace=False)
    for idx in case_indices[:250]:
        seg = df_cust.loc[idx, "CustomerSegment"]
        df_cust.loc[idx, "CustomerSegment"] = seg.lower() if random.random() < 0.5 else seg.upper()
    for idx in case_indices[250:]:
        st = df_cust.loc[idx, "State"]
        df_cust.loc[idx, "State"] = st.lower()

    if "FrequencyTier" in df_cust.columns:
        df_cust.drop(columns=["FrequencyTier"], inplace=True)
        
    # --- B. Products Dataset Issues ---
    n_prod = len(df_prod)
    
    # 1. Inconsistent Category Casing (~15 rows)
    prod_case_indices = np.random.choice(n_prod, size=15, replace=False)
    for idx in prod_case_indices:
        cat = df_prod.loc[idx, "Category"]
        df_prod.loc[idx, "Category"] = cat.lower() if random.random() < 0.5 else cat.upper()
        
    # 2. Slight Category Typos / Variations (~8 rows)
    prod_typo_indices = np.random.choice(n_prod, size=8, replace=False)
    typo_map = {
        "Electronics & Gadgets": "Electrnics & Gadgets",
        "Home & Kitchen": "Home and Kitchen",
        "Apparel & Accessories": "Apparel & Accs",
        "Beauty & Personal Care": "Beauty & Personalcare",
        "Sports & Outdoors": "Sports and Outdoors"
    }
    for idx in prod_typo_indices:
        curr_cat = df_prod.loc[idx, "Category"]
        for orig_cat, typo_val in typo_map.items():
            if orig_cat.lower() in curr_cat.lower():
                df_prod.loc[idx, "Category"] = typo_val
                break
                
    # 3. Leading / Trailing Whitespace in ProductName (~20 rows)
    prod_ws_indices = np.random.choice(n_prod, size=20, replace=False)
    for idx in prod_ws_indices:
        df_prod.loc[idx, "ProductName"] = f"  {df_prod.loc[idx, 'ProductName']} "

    if "PopularityWeight" in df_prod.columns:
        df_prod.drop(columns=["PopularityWeight"], inplace=True)

    # --- C. Stores Dataset Issues ---
    if "Weight" in df_stor.columns:
        df_stor.drop(columns=["Weight"], inplace=True)
    if "PerformanceTier" in df_stor.columns:
        df_stor.drop(columns=["PerformanceTier"], inplace=True)
        
    df_stor.loc[2, "StoreName"] = f"{df_stor.loc[2, 'StoreName']}  "
    df_stor.loc[14, "StoreName"] = f" {df_stor.loc[14, 'StoreName']} "
    df_stor.loc[8, "StoreName"] = df_stor.loc[8, "StoreName"].replace("Galleria", "Galeria")

    # --- D. Sales Dataset Issues ---
    n_sales = len(df_sal)
    
    # 1. Duplicate Sales Transactions (~450 exact duplicate rows appended)
    dup_indices = np.random.choice(n_sales, size=450, replace=False)
    df_duplicates = df_sal.iloc[dup_indices].copy()
    df_sal = pd.concat([df_sal, df_duplicates], ignore_index=True)
    
    # 2. Suspicious / Erroneous Quantities (~35 rows)
    neg_qty_indices = np.random.choice(n_sales, size=25, replace=False)
    df_sal.loc[neg_qty_indices, "Quantity"] = np.random.choice([-1, -2, -3], size=25)
    
    zero_qty_indices = np.random.choice(n_sales, size=10, replace=False)
    df_sal.loc[zero_qty_indices, "Quantity"] = 0
    df_sal.loc[zero_qty_indices, "SalesAmount"] = 0.0
    df_sal.loc[zero_qty_indices, "CostAmount"] = 0.0
    df_sal.loc[zero_qty_indices, "Profit"] = 0.0
    
    # 3. Invalid / Unparseable Dates (~30 rows)
    invalid_date_indices = np.random.choice(n_sales, size=30, replace=False)
    for i, idx in enumerate(invalid_date_indices):
        if i % 3 == 0:
            df_sal.loc[idx, "OrderDate"] = "2023-02-30"
            df_sal.loc[idx, "DateKey"] = 20230230
        elif i % 3 == 1:
            df_sal.loc[idx, "OrderDate"] = "2024-13-01"
            df_sal.loc[idx, "DateKey"] = 20241301
        else:
            df_sal.loc[idx, "OrderDate"] = "INVALID_DATE"
            df_sal.loc[idx, "DateKey"] = 99999999
            
    # 4. Orphaned Foreign Keys (~75 rows)
    orphan_cust_indices = np.random.choice(n_sales, size=40, replace=False)
    for idx in orphan_cust_indices:
        df_sal.loc[idx, "CustomerID"] = f"CUST-{random.randint(99990, 99999)}"
        
    orphan_prod_indices = np.random.choice(n_sales, size=25, replace=False)
    for idx in orphan_prod_indices:
        df_sal.loc[idx, "ProductID"] = f"PROD-{random.randint(9990, 9999)}"
        
    orphan_store_indices = np.random.choice(n_sales, size=15, replace=False)
    for idx in orphan_store_indices:
        df_sal.loc[idx, "StoreID"] = "STR-99"
        
    print("    Data quality issues successfully injected.")
    return df_cust, df_prod, df_stor, df_sal


# ----------------------------------------------------------------------
# 7. Automated Data Validation & Reporting Suite
# ----------------------------------------------------------------------
def validate_and_summarize(df_cust, df_prod, df_stor, df_date, df_sal):
    """
    Performs comprehensive automated validation checks across all generated CSV dataframes.
    Prints formatted report conforming to Task 4 specifications.
    """
    print("\n" + "="*80)
    print("                      DATA VALIDATION & INTEGRITY REPORT                      ")
    print("="*80)
    
    datasets = {
        "customers.csv": df_cust,
        "products.csv": df_prod,
        "stores.csv": df_stor,
        "date.csv": df_date,
        "sales.csv": df_sal
    }
    
    print("\n--- 1. BASIC TABLE SUMMARY ---")
    summary_rows = []
    for name, df in datasets.items():
        summary_rows.append({
            "File": name,
            "Rows": len(df),
            "Columns": len(df.columns),
            "Missing Values": df.isna().sum().sum(),
            "Duplicates": df.duplicated().sum()
        })
    df_summary = pd.DataFrame(summary_rows)
    print(df_summary.to_string(index=False))
    
    print("\n--- 2. DETAILED COLUMN DEFINITIONS & MISSING VALUE COUNTS ---")
    for name, df in datasets.items():
        print(f"\n[{name}] ({len(df):,} rows, {len(df.columns)} cols):")
        col_info = []
        for col in df.columns:
            null_count = df[col].isna().sum()
            null_pct = (null_count / len(df)) * 100
            col_info.append({
                "Column": col,
                "Dtype": str(df[col].dtype),
                "Nulls": null_count,
                "Null %": f"{null_pct:.2f}%"
            })
        print(pd.DataFrame(col_info).to_string(index=False))

    print("\n--- 3. REFERENTIAL INTEGRITY CHECKS (FOREIGN KEYS) ---")
    valid_cust_ids = set(df_cust["CustomerID"].dropna())
    valid_prod_ids = set(df_prod["ProductID"].dropna())
    valid_store_ids = set(df_stor["StoreID"].dropna())
    valid_date_keys = set(df_date["DateKey"].dropna())
    
    invalid_cust_count = (~df_sal["CustomerID"].isin(valid_cust_ids)).sum()
    invalid_prod_count = (~df_sal["ProductID"].isin(valid_prod_ids)).sum()
    invalid_store_count = (~df_sal["StoreID"].isin(valid_store_ids)).sum()
    invalid_date_count = (~df_sal["DateKey"].isin(valid_date_keys)).sum()
    
    print(f"  * Invalid / Orphaned CustomerIDs in sales: {invalid_cust_count:,}")
    print(f"  * Invalid / Orphaned ProductIDs in sales:  {invalid_prod_count:,}")
    print(f"  * Invalid / Orphaned StoreIDs in sales:    {invalid_store_count:,}")
    print(f"  * Invalid / Orphaned DateKeys in sales:    {invalid_date_count:,}")

    print("\n--- 4. SALES DOMAIN & FINANCIAL METRICS ---")
    valid_date_mask = df_sal["DateKey"].isin(valid_date_keys)
    min_date = df_sal.loc[valid_date_mask, "OrderDate"].min()
    max_date = df_sal.loc[valid_date_mask, "OrderDate"].max()
    
    min_qty = df_sal["Quantity"].min()
    max_qty = df_sal["Quantity"].max()
    
    tot_revenue = df_sal["SalesAmount"].sum()
    tot_cost = df_sal["CostAmount"].sum()
    tot_profit = df_sal["Profit"].sum()
    overall_margin_pct = (tot_profit / tot_revenue) * 100 if tot_revenue > 0 else 0
    aov = tot_revenue / len(df_sal)
    
    diff = np.abs(df_sal["Profit"] - (df_sal["SalesAmount"] - df_sal["CostAmount"]))
    calc_mismatches = (diff > 0.02).sum()
    
    print(f"  * Min Order Date:           {min_date}")
    print(f"  * Max Order Date:           {max_date}")
    print(f"  * Min Quantity:             {min_qty} (Contains negative/zero intentional anomalies)")
    print(f"  * Max Quantity:             {max_qty}")
    print(f"  * Total Revenue (Gross):    ${tot_revenue:,.2f}")
    print(f"  * Total Cost (COGS):        ${tot_cost:,.2f}")
    print(f"  * Total Net Profit:         ${tot_profit:,.2f}")
    print(f"  * Overall Profit Margin:    {overall_margin_pct:.2f}%")
    print(f"  * Average Order Value (AOV):${aov:,.2f}")
    print(f"  * Profit = Sales - Cost Verification Mismatches: {calc_mismatches} (0 = 100% Mathematically Consistent)")
    
    print("\n" + "="*80)
    print("                         VALIDATION SUMMARY COMPLETED                         ")
    print("="*80 + "\n")
    
    return {
        "df_summary": df_summary,
        "invalid_cust_count": invalid_cust_count,
        "invalid_prod_count": invalid_prod_count,
        "invalid_store_count": invalid_store_count,
        "invalid_date_count": invalid_date_count,
        "min_date": min_date,
        "max_date": max_date,
        "min_qty": min_qty,
        "max_qty": max_qty,
        "tot_revenue": tot_revenue,
        "tot_cost": tot_cost,
        "tot_profit": tot_profit,
        "overall_margin_pct": overall_margin_pct,
        "aov": aov,
        "calc_mismatches": calc_mismatches
    }


# ----------------------------------------------------------------------
# 8. Main Pipeline Execution
# ----------------------------------------------------------------------
def main():
    print("="*80)
    print("         AURA RETAIL GROUP - SYNTHETIC RAW DATA GENERATION (TASK 4)           ")
    print("="*80)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 1. Generate Dimension Data
    df_date = generate_date_dimension(START_DATE, END_DATE)
    df_stores = generate_store_dimension(NUM_STORES)
    df_products = generate_product_dimension(NUM_PRODUCTS)
    df_customers = generate_customer_dimension(NUM_CUSTOMERS, df_stores)
    
    # 2. Generate Sales Transactions
    df_sales = generate_sales_transactions(df_customers, df_products, df_stores, df_date, TARGET_SALES_RECORDS)
    
    # 3. Inject Controlled Data Quality Issues
    df_cust_raw, df_prod_raw, df_stor_raw, df_sales_raw = inject_data_quality_issues(
        df_customers, df_products, df_stores, df_sales
    )
    
    # 4. Save Raw CSV Files
    print("--> Exporting RAW CSV files to data/raw/...")
    
    date_path = os.path.join(OUTPUT_DIR, "date.csv")
    stores_path = os.path.join(OUTPUT_DIR, "stores.csv")
    products_path = os.path.join(OUTPUT_DIR, "products.csv")
    customers_path = os.path.join(OUTPUT_DIR, "customers.csv")
    sales_path = os.path.join(OUTPUT_DIR, "sales.csv")
    
    df_date.to_csv(date_path, index=False)
    df_stor_raw.to_csv(stores_path, index=False)
    df_prod_raw.to_csv(products_path, index=False)
    df_cust_raw.to_csv(customers_path, index=False)
    df_sales_raw.to_csv(sales_path, index=False)
    
    print(f"    Saved: {date_path} ({os.path.getsize(date_path)/1024:.1f} KB)")
    print(f"    Saved: {stores_path} ({os.path.getsize(stores_path)/1024:.1f} KB)")
    print(f"    Saved: {products_path} ({os.path.getsize(products_path)/1024:.1f} KB)")
    print(f"    Saved: {customers_path} ({os.path.getsize(customers_path)/1024:.1f} KB)")
    print(f"    Saved: {sales_path} ({os.path.getsize(sales_path)/(1024*1024):.2f} MB)")
    
    # 5. Run Validation
    val_results = validate_and_summarize(df_cust_raw, df_prod_raw, df_stor_raw, df_date, df_sales_raw)
    
    print("Task 4 Data Generation & Validation successfully finished.")


if __name__ == "__main__":
    main()
