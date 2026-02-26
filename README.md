# 🍽️ Swiggy SQL Data Warehouse Project

### 📌 Project Overview
Built a complete Star Schema data warehouse in MySQL from raw CSV data including data cleaning, dimensional modeling, fact table creation, and business KPI analysis using advanced SQL (CTEs, window functions, ranking, MoM growth).
This project demonstrates end-to-end data warehousing using MySQL.

Starting from a raw CSV dataset containing food delivery transactions, we:

Loaded and cleaned the data

Removed duplicates

Designed and implemented a Star Schema

Built fact and dimension tables

Applied foreign key relationships

Performed business KPI and trend analysis using advanced SQL

The project simulates a real-world food delivery analytics environment similar to Swiggy/Zomato.

🛠️ Tech Stack

MySQL 8.0

SQL (Window Functions, CTEs, Aggregations)

Dimensional Modeling (Star Schema)

Data Cleaning & Transformation

CSV Data Loading (LOAD DATA INFILE)

📂 Project Structure
1️⃣ Staging Layer

Raw CSV loaded into swiggy_data

Date format transformation using STR_TO_DATE

Data validation (nulls, blanks, duplicates)

Creation of clean table swiggy_data_clean

2️⃣ Data Warehouse Design (Star Schema)
Dimension Tables

dim_date

dim_location

dim_restaurant

dim_category

dim_dish

Fact Table

fact_swiggy_orders

Each dimension contains distinct business keys and surrogate primary keys.
Fact table stores transactional metrics and links to dimensions via foreign keys.

⭐ Star Schema Model

Fact Table:

Order ID (surrogate)

Date ID

Location ID

Restaurant ID

Category ID

Dish ID

Price

Rating

Rating Count

Dimensions:

Date breakdown (Year, Month, Quarter, Week)

Location hierarchy (State → City → Area)

Restaurant

Category

Dish

📊 KPI & Business Analysis
Core KPIs

Total Orders

Total Revenue

Average Dish Price

Average Rating

Time-Based Analysis

Monthly Order Trends

Quarter-wise Growth

Year-wise Growth

Month-over-Month (MoM) %

Location Analysis

Top Cities by Order Volume

Revenue Contribution by State

Restaurant & Category Analysis

Top Restaurants by Orders

Top Categories

Top 3 Restaurants per Category (using DENSE_RANK)

Dish Insights

Most Ordered Dishes

Average Rating by Dish

Rating Distribution

Customer Spend Distribution

Spend buckets (Under 100, 100-199, etc.)

Percentage contribution by spend segment

🔥 Key SQL Concepts Used

LOAD DATA LOCAL INFILE

STR_TO_DATE() for date conversion

SELECT DISTINCT for dimension deduplication

Window Functions:

ROW_NUMBER()

LAG()

DENSE_RANK()

CTEs (Common Table Expressions)

MoM Growth Calculation

Percentage distribution using window aggregates

Foreign Key Constraints

Surrogate Key Design

🧠 Key Learnings

Importance of loading DISTINCT values into dimension tables

How join explosion can occur if dimensions contain duplicates

Correct order of dropping tables (Fact → Dimension)

Handling foreign key constraints safely

Using recovery mode for MySQL crash troubleshooting

Performance considerations in data warehouse joins
