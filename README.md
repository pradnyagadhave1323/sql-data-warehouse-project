# Data Warehouse and Analytics Project

Welcome to the Data Warehouse and Analytics Project repository! 🚀
This project demonstrates a comprehensive data warehousing and analytics solution, from building a data warehouse to generating actionable insights. Designed as a portfolio project, it highlights industry best practices in data engineering and analytics.

🚀 Project Requirements
Building the Data Warehouse (Data Engineering)
Objective

Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.
Specifications
Data Sources: Import data from two source systems (ERP and CRM) provided as CSV files.
Data Quality: Cleanse and resolve data quality issues prior to analysis.
Integration: Combine both sources into a single, user-friendly data model designed for analytical queries.
Scope: Focus on the latest dataset only; historization of data is not required.
Documentation: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

📐 Data Model

The data warehouse follows a star schema design to optimize analytical queries and reporting performance.
Fact Table
fact_sales
order_id
customer_id
product_id
order_date
quantity
sales_amount
Dimension Tables
dim_customers
customer_id
customer_name
city
country
dim_products
product_id
product_name
category
price
dim_date
date_id
date
month
year
quarter
This schema improves query performance and simplifies reporting.

🔄 ETL Process

The ETL (Extract, Transform, Load) process includes the following steps:
Extract
Import CSV files from ERP and CRM systems.
Load raw data into staging tables.
Transform
Clean missing and invalid data.
Standardize column formats.
Remove duplicates.
Join ERP and CRM data.
Create dimension and fact tables.
Load
Load transformed data into the data warehouse tables.
Ensure referential integrity between fact and dimension tables.

🛠 Tools & Technologies Used
SQL Server
SQL
CSV Files
Data Warehouse
ETL
Star Schema
GitHub
