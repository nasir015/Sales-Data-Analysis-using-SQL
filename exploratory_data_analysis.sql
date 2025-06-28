
USE master;
GO
-- Set database to SINGLE_USER with immediate rollback
ALTER DATABASE SupermarketSales
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'SupermarketSales')
BEGIN
    DROP DATABASE SupermarketSales;
END;
GO

-- Create database name is 'SupermarketSales'
CREATE DATABASE SupermarketSales;
GO
-- Use the database
USE SupermarketSales;
GO
-- Create schema
CREATE SCHEMA sales;
GO

-- if exist sales.customers delete it
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'sales.customers') AND type in (N'U'))
BEGIN
    DROP TABLE sales.customers;
END;
GO
-- Create table for customers.csv
-- Create table
CREATE TABLE sales.customers (
    customer_id VARCHAR(100) ,
    customer_name VARCHAR(100)
);
GO
-- Upload data from customers.csv
BULK INSERT sales.customers
FROM 'E:\sql\Project\Sales Data Analysis\Data\Customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- if exist sales.location delete it
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'sales.location') AND type in (N'U'))
BEGIN
    DROP TABLE sales.location;
END;
GO
-- Create table for Location.csv
CREATE TABLE sales.location (
    postal_code NVARCHAR(100) ,
    city NVARCHAR(100),
    state NVARCHAR(100),
    Category NVARCHAR(100),
    country NVARCHAR(100)
);
GO
-- Upload data from Location.csv
BULK INSERT sales.location
FROM 'E:\sql\Project\Sales Data Analysis\Data\Location.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

-- if exist sales.order delete it
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'sales.orders') AND type in (N'U'))
BEGIN
    DROP TABLE sales.orders;
END;
GO
-- Create table for Orders.csv
CREATE TABLE sales.orders (
    order_id NVARCHAR(100) ,
    order_date DATE,
    ship_date DATE,
    ship_mode NVARCHAR(100),
    customer_id NVARCHAR(100),
    segment NVARCHAR(30),
    postal_code NVARCHAR(100),
    product_id NVARCHAR(100),
    sale NVARCHAR(100),
    quantity NVARCHAR(100),
    discount NVARCHAR(100),
    profit NVARCHAR(100)
);
GO

-- Upload data from Orders.csv
BULK INSERT sales.orders
FROM 'E:\sql\Project\Sales Data Analysis\Data\Orders.csv'
WITH (
    DATAFILETYPE = 'char',
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n'
);
GO

-- if exist sales.products delete it
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'sales.products')
    AND type in (N'U'))
BEGIN
    DROP TABLE sales.products;
END;
GO

-- Create table for Products.csv
CREATE TABLE sales.products (
    product_id NVARCHAR(100) ,
    category NVARCHAR(100),
    sub_category NVARCHAR(100),
    product_name NVARCHAR(255)
    
);
GO
-- Upload data from Products.csv
BULK INSERT sales.products
FROM 'E:\sql\Project\Sales Data Analysis\Data\Products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    CODEPAGE = '65001'    -- UTF-8 encoding
);
GO

-- if exist sales.dimention_table delete it

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'sales.dimention_table') AND type in (N'V'))
BEGIN
    DROP VIEW sales.dimention_table;
END;
GO
-- Create view for sales.dimention_table
GO
CREATE VIEW sales.dimention_table AS
SELECT
    *,
    ROUND(Sale / NULLIF(Quantity, 0),2) AS Unit_Price,
    ROUND(Sale - Profit,2) AS Cost
FROM (
    SELECT
        o.order_id AS Order_ID,
        o.customer_id AS Customer_ID,
        o.product_id AS Product_ID,
        c.customer_name AS Customer_Name,
        p.product_name AS Product_Name,
        CAST(o.quantity AS INT) AS Quantity,
        CAST(o.sale AS FLOAT) AS Sale,
        CAST(CAST(o.discount AS float) AS int) AS Discount,
        CAST(o.profit AS FLOAT) AS Profit,
        o.segment AS Segment,
        p.category AS Category,
        p.sub_category AS Sub_Category, 
        CAST(o.order_date AS DATE) AS Order_Date,       
        CAST(o.ship_date AS DATE) AS Ship_Date,
        o.ship_mode AS Ship_Mode,     
        o.postal_code AS Postal_Code,
        l.city AS City,
        l.state AS State,
        -- l.Category AS Category, -- Removed duplicate Category column
        l.country AS Country
    FROM sales.orders as o
    LEFT JOIN sales.location as l
        ON o.postal_code = l.postal_code
    LEFT JOIN sales.products as p
        ON o.product_id = p.product_id
    LEFT JOIN sales.customers as c
        ON o.customer_id = c.customer_id
) AS klo;
GO


/* ================================================================================
Exploratory Data Analysis
===================================================================================
 */

-- Total revinue by category
SELECT 
    Category,
    ROUND(SUM(Sale),2) AS Total_sale
FROM sales.dimention_table
GROUP BY Category;

-- Total revinue by sub-category
SELECT 
    Sub_Category,
    ROUND(SUM(Sale),2) AS Total_sale
FROM sales.dimention_table
GROUP BY Sub_Category;


-- Total Number of Orders
SELECT 
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM sales.dimention_table;


-- Total Number of Customers
SELECT 
    COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM sales.dimention_table;


-- Monthly sale trend (current year)
SELECT
    DATENAME(MONTH, order_date) AS Month_Name,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
WHERE YEAR(order_date) = 2023
GROUP BY MONTH(order_date),
         DATENAME(MONTH, order_date)
ORDER BY Total_sale DESC;


-- Top 5 products by sale
SELECT top 5
    Product_Name,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
GROUP BY Product_Name
ORDER BY Total_sale DESC;


-- Top 5 Sub Categories by units sold
SELECT TOP 5
    Sub_Category,
    SUM(Quantity) AS Total_Units_Sold
FROM sales.dimention_table
GROUP BY Sub_Category
ORDER BY Total_Units_Sold DESC;


-- Average items per order

SELECT
    AVG(Total_Items_Per_Order) AS Average_Items_Per_Order
FROM
(SELECT 
    Order_ID,
    sum(Quantity) AS Total_Items_Per_Order
FROM sales.dimention_table
GROUP BY Order_ID)r;


-- Top 5 state that generated the most sale

SELECT TOP 5
    State,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
GROUP BY State
ORDER BY Total_sale DESC;


-- Top 5 City that generated the most sale

SELECT TOP 5
    City,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
GROUP BY City
ORDER BY Total_sale DESC;


-- sale by Segment
SELECT 
    Segment,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
GROUP BY Segment
ORDER BY Total_sale DESC;


-- Orders by day of week
SELECT 
    DATENAME(WEEKDAY, Order_Date) AS Day_Of_Week,
    COUNT(Order_ID) AS Total_Orders
FROM sales.dimention_table
WHERE 
    YEAR(Order_Date) = 2023 -- Filter for the current year
GROUP BY DATENAME(WEEKDAY, Order_Date)
ORDER BY Total_Orders DESC;

SELECT distinct Segment FROM sales.dimention_table;


-- Orders by month of year
SELECT
    DATENAME(MONTH, Order_Date) AS Month_Of_Year,
    COUNT(Order_ID) AS Total_Orders
FROM sales.dimention_table
WHERE 
    YEAR(Order_Date) = 2023 -- Filter for the current year
GROUP BY DATENAME(MONTH, Order_Date)
ORDER BY Total_Orders DESC; 


-- Products never sold
SELECT 
    product_id,
    product_name
FROM sales.products
WHERE product_id NOT IN (
    SELECT DISTINCT Product_ID
    FROM sales.orders
);


-- Count customers with at least one order
SELECT
    *
FROM sales.dimention_table
WHERE Customer_ID IN (
SELECT 
    Customer_ID
FROM sales.customers
WHERE Customer_ID IN (
    SELECT DISTINCT Customer_ID
    FROM sales.orders
))



-- Count customers with No order
SELECT
    *
FROM sales.dimention_table
WHERE Customer_ID IN (
SELECT 
    Customer_ID
FROM sales.customers
WHERE Customer_ID NOT IN (
    SELECT DISTINCT Customer_ID
    FROM sales.orders
))


-- Number of discounted orders 
SELECT
    COUNT(Order_ID) AS Discounted_Orders
FROM sales.dimention_table
WHERE Discount > 0 and  Order_Date >= '2023-01-01' AND Order_Date < '2024-01-01';


-- Number of orders with no discount
SELECT
    COUNT(Order_ID) AS Non_Discounted_Orders
FROM sales.dimention_table
WHERE Discount = 0 and Order_Date >= '2023-01-01' AND Order_Date < '2024-01-01';


-- Year‑over‑year sale
SELECT 
    YEAR(Order_Date) AS YEAR,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
GROUP BY YEAR(Order_Date)
ORDER BY YEAR(Order_Date) DESC;


-- Year‑over‑year Profit
SELECT 
    YEAR(Order_Date) AS YEAR,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales.dimention_table
GROUP BY YEAR(Order_Date)
ORDER BY YEAR(Order_Date) DESC;


-- Quarterly sale split
SELECT 
    DATEPART(YEAR, Order_Date) AS Year,
    DATEPART(QUARTER, Order_Date) AS Quarter,
    ROUND(SUM(Sale), 2) AS Total_sale
FROM sales.dimention_table
GROUP BY DATEPART(YEAR, Order_Date), DATEPART(QUARTER, Order_Date)
ORDER BY Year DESC, Quarter DESC;


-- Quarterly profit split
SELECT 
    DATEPART(YEAR, Order_Date) AS Year,
    DATEPART(QUARTER, Order_Date) AS Quarter,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales.dimention_table
GROUP BY DATEPART(YEAR, Order_Date), DATEPART(QUARTER, Order_Date)
ORDER BY Year DESC, Quarter DESC;


-- Running cumulative sale by month
-- This query calculates the cumulative sale for each month in the dataset.
SELECT 
    DATEPART(YEAR, Order_Date) AS Year,
    DATENAME(MONTH,Order_Date) AS Month,
    ROUND(SUM(Sale), 2) AS Monthly_Sale,
    ROUND(SUM(ROUND(SUM(Sale), 2)) OVER (ORDER BY DATEPART(YEAR, Order_Date), DATENAME(MONTH,Order_Date)),2) AS Cumulative_Sale
FROM sales.dimention_table
WHERE Order_Date >= '2023-01-01' AND Order_Date < '2024-01-01'
GROUP BY DATEPART(YEAR, Order_Date), DATENAME(MONTH,Order_Date);


-- Running cumulative profit by month
-- This query calculates the cumulative profit for each month in the dataset.

SELECT 
    DATEPART(YEAR, Order_Date) AS Year,
    DATENAME(MONTH,Order_Date) AS Month,
    ROUND(SUM(Profit), 2) AS Monthly_Profit,
    ROUND(SUM(ROUND(SUM(Profit), 2)) OVER (ORDER BY DATEPART(YEAR, Order_Date), DATENAME(MONTH,Order_Date)),2) AS Cumulative_Profit
FROM sales.dimention_table
WHERE Order_Date >= '2023-01-01' AND Order_Date < '2024-01-01'
GROUP BY DATEPART(YEAR, Order_Date), DATENAME(MONTH,Order_Date);


-- Top 5 Products for each month by sale

WITH SalesByMonth AS (
    SELECT
        MONTH(Order_Date) AS Month,
        DATENAME(MONTH, Order_Date) AS Month_Name,
        Product_ID,
        ROUND(SUM(Sale), 2) AS Total_sale,
        RANK() OVER (PARTITION BY MONTH(Order_Date) ORDER BY SUM(Sale) DESC) AS Sale_Rank
    FROM sales.dimention_table
    GROUP BY MONTH(Order_Date), DATENAME(MONTH, Order_Date), Product_ID
)
SELECT 
    Month,
    Month_Name,
    Product_ID,
    Total_sale
FROM SalesByMonth
WHERE Sale_Rank <= 5



-- Top 5 Products for each month by profit
WITH ProfitByMonth AS (
    SELECT
        MONTH(Order_Date) AS Month,
        DATENAME(MONTH, Order_Date) AS Month_Name,
        Product_ID,
        ROUND(SUM(Profit), 2) AS Total_Profit,
        RANK() OVER (PARTITION BY MONTH(Order_Date) ORDER BY SUM(Profit) DESC) AS Profit_Rank
    FROM sales.dimention_table
    GROUP BY MONTH(Order_Date), DATENAME(MONTH, Order_Date), Product_ID
)
SELECT 
    Month,
    Month_Name,
    Product_ID,
    Total_Profit
FROM ProfitByMonth
WHERE Profit_Rank <= 5;


-- 3‑month moving average Sale

SELECT
    MONTH(Order_Date) AS Month,
    Order_Date,
    Sale AS Sale,
    AVG(Sale) OVER(PARTITION BY MONTH(Order_Date) ORDER BY Order_Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Moving_Average_Sale
FROM sales.dimention_table;


-- Customers with >30% Sale growth
-- Step 1: Aggregate total monthly sales per customer
WITH MonthlySales AS (
    SELECT 
        Customer_ID,
        YEAR(Order_Date) AS Year,  -- Extracting the year part of the order date
        MONTH(Order_Date) AS Month,  -- Extracting the month part of the order date
        SUM(Sale) AS Total_Sale  -- Total sales for that customer in that Year-Month
    FROM sales.dimention_table
    GROUP BY Customer_ID, YEAR(Order_Date), MONTH(Order_Date)  -- Grouping by customer and month
),

-- Step 2: Use window function to get the previous month's sales for each customer
SaleGrowth AS (
    SELECT 
        Customer_ID,
        Year,
        Month,
        Total_Sale,
        
        -- Get previous month's Total_Sale using LAG window function
        LAG(Total_Sale) OVER (
            PARTITION BY Customer_ID  -- Reset LAG for each customer
            ORDER BY Year, Month      -- Ensure proper chronological order
        ) AS Previous_Total_Sale
    FROM MonthlySales
)

-- Step 3: Calculate sales growth percentage and filter records
SELECT 
    Customer_ID,
    Total_Sale,
    Previous_Total_Sale,
    
    -- Calculate % growth only when previous month sale is not zero
    -- (Avoid division by zero error)
    CASE 
        WHEN Previous_Total_Sale = 0 THEN NULL
        ELSE (Total_Sale - Previous_Total_Sale) / Previous_Total_Sale * 100
    END AS Sale_Growth_Percentage

FROM SaleGrowth

-- Step 4: Filter to include only customers with > 30% month-over-month sales growth
WHERE 
    Previous_Total_Sale IS NOT NULL  -- Exclude first month or missing previous sales
    AND (Total_Sale - Previous_Total_Sale) / Previous_Total_Sale * 100 > 30
    -- Keep only rows with sales growth > 30%


-- Product with >30% Profit growth

WITH MonthlyProfit AS (
    SELECT 
        Product_ID,
        YEAR(Order_Date) AS Year,  -- Year portion of order date
        MONTH(Order_Date) AS Month,  -- Month portion of order date
        SUM(Profit) AS Total_Profit  -- Monthly total profit per product
    FROM sales.dimention_table
    GROUP BY Product_ID, YEAR(Order_Date), MONTH(Order_Date)
),
ProfitGrowth AS (
    SELECT 
        Product_ID,
        Year,
        Month,
        Total_Profit,
        -- Previous month’s profit using window function
        LAG(Total_Profit) OVER (
            PARTITION BY Product_ID
            ORDER BY Year, Month
        ) AS Previous_Total_Profit
    FROM MonthlyProfit
),
FinalProfitGrowth AS (
    SELECT
        Product_ID,
        Year,
        Month,
        Total_Profit,
        Previous_Total_Profit,
        -- Safe calculation with zero check using CASE
        CASE 
            WHEN Previous_Total_Profit = 0 THEN NULL
            ELSE (Total_Profit - Previous_Total_Profit) / Previous_Total_Profit * 100
        END AS Profit_Growth_Percentage
    FROM ProfitGrowth
)

SELECT 
    Product_ID,
    Total_Profit,
    Previous_Total_Profit,
    Profit_Growth_Percentage
FROM FinalProfitGrowth
WHERE 
    Profit_Growth_Percentage IS NOT NULL  -- Exclude nulls (from zero previous profit)
    AND Profit_Growth_Percentage > 30     -- Only include profits with more than 30% growth


-- Weekly Sales heatmap (pivot)

SELECT 
    DATENAME(MONTH,Order_Date) AS Month_Name,
    DATENAME(WEEKDAY, Order_Date) AS Day_Of_Week,
    DATEPART(WEEK, Order_Date) AS Week_Number,
    DATEPART(WEEKDAY, Order_Date) AS Weekday_Number,  -- New column for sorting days
    ROUND(SUM(Sale), 2) AS Total_Sale
FROM sales.dimention_table
WHERE Order_Date >= '2023-01-01' 
  AND Order_Date <  '2024-01-01'
GROUP BY 
    DATENAME(MONTH,Order_Date),
    DATENAME(WEEKDAY, Order_Date), 
    DATEPART(WEEK, Order_Date),
    DATEPART(WEEKDAY, Order_Date)   -- Needed for ORDER BY
ORDER BY 
    Week_Number,
    Weekday_Number;    



-- Product price variance
SELECT
    Product_ID,
    STDEV(Unit_Price) AS Price_Variance
FROM sales.dimention_table
GROUP BY Product_ID
ORDER BY Price_Variance DESC;


-- Orders with unusually high discount (>50%)

SELECT 
    Order_ID,
    Customer_ID,
    Product_ID,
    Sale,
    Quantity,
    Discount,
    Profit
FROM sales.dimention_table
WHERE 
    Discount > 50;



-- Orders with unusually high profit (>1000)
SELECT 
    Order_ID,
    Customer_ID,
    Product_ID,
    Sale,
    Quantity,
    Discount,
    Profit
FROM sales.dimention_table
WHERE
    Profit > 1000;


-- Category Sale ranking per State

WITH CategorySale AS (
    SELECT 
        State,
        Category,
        ROUND(SUM(Sale),2) AS Total_Sale
    FROM sales.dimention_table
    GROUP BY State, Category
),
CategoryRanking AS (
    SELECT
        State,
        Category,
        Total_Sale,
        RANK() OVER (
            PARTITION BY State        -- Restart ranking per State
            ORDER BY Total_Sale DESC   -- Highest Sale = Rank 1
        ) AS Sale_Rank
    FROM CategorySale
)
SELECT 
    State,
    Category,
    Total_Sale,
    Sale_Rank
FROM CategoryRanking
WHERE 
    Sale_Rank <= 3  -- Only include top 3 categories per state
ORDER BY State, Sale_Rank;



-- daily Sale vs 7‑day rolling average
SELECT
    Order_Date AS Day,
    Daily_Sale,
    ROUND(AVG(Daily_Sale) OVER (ORDER BY Order_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS Rolling_7_Day_Average
FROM (
    SELECT
        Order_Date,
        ROUND(SUM(Sale), 2) AS Daily_Sale
    FROM sales.dimention_table
    WHERE Order_Date >= '2023-01-01' AND Order_Date < '2024-01-01'
    GROUP BY Order_Date
) AS DailySales


-- Customers with no orders in last 12 months

SELECT 
    Customer_ID
FROM sales.customers
WHERE customer_id NOT IN (
    SELECT DISTINCT Customer_ID 
    FROM sales.orders
    WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01'
)



-- Percentage of repeat customers

SELECT
    COUNT(DISTINCT Customer_ID) * 100.0 / (SELECT COUNT(*) FROM sales.customers) AS Repeat_Customer_Percentage
FROM sales.dimention_table
WHERE Customer_ID IN (
    SELECT Customer_ID
    FROM sales.dimention_table
    GROUP BY Customer_ID
    HAVING COUNT(DISTINCT Order_ID) > 1
)


-- Products with >20% of revenue coming from discounts

WITH DiscountedSales AS (
    SELECT 
        Product_ID,
        SUM(Sale) AS Total_Sale,
        SUM(CASE WHEN Discount > 0 THEN Sale ELSE 0 END) AS Discounted_Sale
    FROM sales.dimention_table
    GROUP BY Product_ID
)

SELECT 
    Product_ID,
    Total_Sale,
    Discounted_Sale,
    ROUND(Discounted_Sale * 100.0 / Total_Sale, 2) AS Discount_Percentage
FROM DiscountedSales
WHERE 
    ROUND(Discounted_Sale * 100.0 / Total_Sale, 2)> .2
ORDER BY Discount_Percentage DESC;



-- Top 10 Customer lifetime revenue and first/last order
SELECT top 10
    Customer_ID,
    ROUND(SUM(Sale),2) AS Lifetime_Revenue,
    MIN(Order_Date) AS First_Order_Date,
    MAX(Order_Date) AS Last_Order_Date
FROM sales.dimention_table
GROUP BY Customer_ID
Having SUM(Sale)>5000
ORDER BY Lifetime_Revenue DESC;



-- Days since last order for active customers
SELECT 
    Customer_ID,
    DATEDIFF(DAY, MAX(Order_Date), GETDATE()) AS Days_Since_Last_Order
FROM sales.dimention_table
WHERE Order_Date >= '2023-01-01' AND Order_Date < '2024-01-01'
GROUP BY Customer_ID;



-- Most profitable 10% of products
WITH ProductProfit AS (
    SELECT 
        Product_ID,
        ROUND(SUM(Profit), 2) AS Total_Profit
    FROM sales.dimention_table
    GROUP BY Product_ID
),
ProfitThreshold AS (
    SELECT 
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Total_Profit) OVER () AS Top_10_Percent_Profit
    FROM ProductProfit
)
SELECT 
    Product_ID,
    Total_Profit
FROM ProductProfit
WHERE Total_Profit >= (SELECT TOP 1 Top_10_Percent_Profit FROM ProfitThreshold)


-- Products contributing to 80% of total revenue (Pareto) with ABC classification

WITH TotalRevenue AS (
    SELECT 
        ROUND(SUM(Sale), 2) AS Overall_Total_Sale
    FROM sales.dimention_table
),
ProductRevenue AS (
    SELECT 
        Product_ID,
        ROUND(SUM(Sale), 2) AS Product_Total_Sale
    FROM sales.dimention_table
    GROUP BY Product_ID
),
CumulativeRevenue AS (
    SELECT 
        Product_ID,
        Product_Total_Sale,
        SUM(Product_Total_Sale) OVER (ORDER BY Product_Total_Sale DESC) AS Cumulative_Sale
    FROM ProductRevenue
)

SELECT 
    Product_ID,
    Product_Total_Sale,
    Cumulative_Sale,
    ROUND(Cumulative_Sale * 100.0 / (SELECT Overall_Total_Sale FROM TotalRevenue), 2) AS Cumulative_Percentage,
    CASE 
        WHEN ROUND(Cumulative_Sale * 100.0 / (SELECT Overall_Total_Sale FROM TotalRevenue), 2) <= 50 THEN 'A'
        WHEN ROUND(Cumulative_Sale * 100.0 / (SELECT Overall_Total_Sale FROM TotalRevenue), 2) <= 80 THEN 'B'
        ELSE 'C'
    END AS ABC_Class
FROM CumulativeRevenue
WHERE Cumulative_Sale <= (SELECT Overall_Total_Sale FROM TotalRevenue) * 0.8
ORDER BY Product_Total_Sale DESC;



-- Customers who buy high margin products (>30% margin) often

WITH HighMarginProducts AS (
    SELECT 
        Product_ID,
        ROUND((Profit / Sale) * 100, 2) AS Margin_Percentage
    FROM sales.dimention_table
    GROUP BY Product_ID, Profit, Sale
    HAVING ROUND((Profit / Sale) * 100, 2) > 30
),
FrequentHighMarginCustomers AS (
    SELECT 
        o.Customer_ID,
        COUNT(DISTINCT o.Order_ID) AS Order_Count
    FROM sales.orders o
    JOIN HighMarginProducts hmp ON o.Product_ID = hmp.Product_ID
    GROUP BY o.Customer_ID
    HAVING COUNT(DISTINCT o.Order_ID) > 5  -- Customers with more than 5 orders of high margin products
)
SELECT 
    c.Customer_ID,
    c.customer_name,
    f.Order_Count
FROM sales.customers c
JOIN FrequentHighMarginCustomers f ON c.customer_id = f.Customer_ID
ORDER BY f.Order_Count DESC;


-- Identify anomalous orders (value > 3 std dev above mean)
WITH OrderStats AS (
    SELECT 
        ROUND(SUM(Sale), 2) AS Total_Sale,
        AVG(ROUND(SUM(Sale), 2)) OVER () AS Mean_Sale,
        STDEV(ROUND(SUM(Sale), 2)) OVER () AS StdDev_Sale
    FROM sales.dimention_table
    GROUP BY Order_ID
)
SELECT 
    Total_Sale,
    Mean_Sale,
    StdDev_Sale,
    CASE 
        WHEN Total_Sale > Mean_Sale + 3 * StdDev_Sale THEN 'Anomalous'
        ELSE 'Normal'
    END AS Order_Status
FROM OrderStats
WHERE Total_Sale > Mean_Sale + 3 * StdDev_Sale
ORDER BY Total_Sale DESC;


