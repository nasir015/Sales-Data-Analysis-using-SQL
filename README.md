# 🛒 Supermarket Sales - SQL Exploratory Data Analysis

This project performs an **Exploratory Data Analysis (EDA)** using **pure SQL** on retail sales data from a fictional supermarket. The analysis explores customer behavior, sales trends, discounts, product performance, and more — directly within a relational database system.

---

## 📁 Project Structure

<pre> ```plaintext SupermarketSales-EDA/ │ ├── exploratory_data_analysis.sql # Main SQL script: setup + analysis ├── Data/ │ ├── Customers.csv │ ├── Location.csv │ ├── Orders.csv │ └── Products.csv └── README.md ``` </pre>




## ⚙️ How to Run the Project

1. **Install** SQL Server (or a compatible engine that supports `BULK INSERT`).
2. Open SQL Server Management Studio (SSMS) or any SQL client.
3. Make sure the `.csv` files from the `Data/` folder are available locally.
4. Open and execute `exploratory_data_analysis.sql`.
5. Modify the file paths inside `BULK INSERT` statements to match your system if needed.

> 💡 The script creates the database, tables, loads data, creates a view (`sales.dimention_table`), and runs over 50 insightful SQL queries.

---



## 📊 Key SQL Analyses Performed

### 🔍 Sales & Revenue
- Total revenue by category & sub-category
- Monthly and quarterly sales trends
- Year-over-year sales & profits



### 👥 Customer Insights
- Repeat customer percentage
- Customer lifetime value
- Customers with >30% month-over-month sales growth
- Days since last order
- Customers with no orders in last 12 months



### 📦 Product Performance
- Top-selling and most profitable products
- Product price variance
- Products contributing to 80% of revenue (Pareto/ABC classification)
- Products never sold
- Products with >20% revenue from discounts



### 📈 Time-Based Trends
- Weekly and daily sales trends
- Rolling 7-day and 3-month moving averages



### 🧾 Discount & Profitability
- Discounted vs non-discounted order counts
- Orders with high discounts (>50%)
- Orders with high profit (>1000)
- Profit growth per product (>30%)



### ⚠️ Anomalies & Ranking
- Anomalous orders using standard deviation method
- Category sales ranking per state
- Top 10% most profitable products



🧰 Tools Used
- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- SQL (DDL, DML, Analytical Functions, Window Functions)
- CSV Data Files



📦 Dataset Overview
All .csv files used in this project are stored in the Data/ folder:
- Customers.csv – Customer info
- Orders.csv – Sales transactions
- Products.csv – Product hierarchy & names
- Location.csv – Geography, city, state
- Note: This is a sample project; data may be anonymized or synthetic.



📄 License
MIT License – feel free to use and adapt this project with attribution.


