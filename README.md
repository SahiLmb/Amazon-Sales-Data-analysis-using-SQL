---

# **Amazon USA Sales Analysis Project**

---

## Project Overview
End-to-end analysis of 20,000+ sales records from an Amazon-like e-commerce platform, combining SQL data exploration with Power BI visualization.

## SQL Analysis & Database Design
- Analyzed **20,000+ sales records** using PostgreSQL
- Solved **20 complex business problems**:
  - 📈 Revenue trend analysis (YoY, MoM comparisons)
  - 👥 Customer segmentation (RFM, new vs returning)
  - 📦 Product performance (profit margins, return rates)
  - ⚙️ Operational metrics (shipping delays, inventory alerts)
- Designed comprehensive **ERD diagram** to visualize database schema

## Power BI Implementation
### Dashboard Architecture
Built interactive dashboard with 5 key pages:
1. **Executive Summary** - High-level KPIs
2. **Product Performance** - Margins & rankings
3. **Customer Insights** - Segmentation & CLV
4. **Operations Hub** - Logistics & inventory
5. **Regional Analysis** - Geographic trends

### Technical Implementation
- Developed **40+ DAX measures** mirroring SQL logic:
  - 🕰️ Time intelligence functions
  - 💰 Customer lifetime value
  - 🏆 Dynamic ranking systems
- Designed space-optimized visualizations:
  - 🎚 Compact scorecards
  - 🔍 Interactive matrices
  - 📊 Mini-chart integrations
- Implemented cross-filtering and unified navigation

## Key Features
- **Actionable insights** from raw sales data
- **ERD-driven data model** ensuring accuracy
- **Responsive design** for limited dashboard space


An ERD diagram is included to visually represent the database schema and relationships between tables along with the Power BI dashboard link.

---
![Power BI dashboard](https://github.com/SahiLmb/Amazon-Sales-Data-analysis-using-SQL)

![ERD Scratch](https://github.com/SahiLmb/Amazon-Sales-Data-analysis-using-SQL/blob/main/amazon%20erd.png)

## **Database Setup & Design**

### **Schema Structure**

```sql
CREATE TABLE category
(
  category_id	INT PRIMARY KEY,
  category_name VARCHAR(20)
);

-- customers TABLE
CREATE TABLE customers
(
  customer_id INT PRIMARY KEY,	
  first_name	VARCHAR(20),
  last_name	VARCHAR(20),
  state VARCHAR(20),
  address VARCHAR(5) DEFAULT ('xxxx')
);

-- sellers TABLE
CREATE TABLE sellers
(
  seller_id INT PRIMARY KEY,
  seller_name	VARCHAR(25),
  origin VARCHAR(15)
);

-- products table
  CREATE TABLE products
  (
  product_id INT PRIMARY KEY,	
  product_name VARCHAR(50),	
  price	FLOAT,
  cogs	FLOAT,
  category_id INT, -- FK 
  CONSTRAINT product_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- orders
CREATE TABLE orders
(
  order_id INT PRIMARY KEY, 	
  order_date	DATE,
  customer_id	INT, -- FK
  seller_id INT, -- FK 
  order_status VARCHAR(15),
  CONSTRAINT orders_fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT orders_fk_sellers FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_items
(
  order_item_id INT PRIMARY KEY,
  order_id INT,	-- FK 
  product_id INT, -- FK
  quantity INT,	
  price_per_unit FLOAT,
  CONSTRAINT order_items_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT order_items_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- payment TABLE
CREATE TABLE payments
(
  payment_id	
  INT PRIMARY KEY,
  order_id INT, -- FK 	
  payment_date DATE,
  payment_status VARCHAR(20),
  CONSTRAINT payments_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE shippings
(
  shipping_id	INT PRIMARY KEY,
  order_id	INT, -- FK
  shipping_date DATE,	
  return_date	 DATE,
  shipping_providers	VARCHAR(15),
  delivery_status VARCHAR(15),
  CONSTRAINT shippings_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE inventory
(
  inventory_id INT PRIMARY KEY,
  product_id INT, -- FK
  stock INT,
  warehouse_id INT,
  last_stock_date DATE,
  CONSTRAINT inventory_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
  );
```

---

## **Task: Data Cleaning**

I cleaned the dataset by:
- **Removing duplicates**: Duplicates in the customer and order tables were identified and removed.
- **Handling missing values**: Null values in critical fields (e.g., customer address, payment status) were either filled with default values or handled using appropriate methods.

---

## **Handling Null Values**

Null values were handled based on their context:
- **Customer addresses**: Missing addresses were assigned default placeholder values.
- **Payment statuses**: Orders with null payment statuses were categorized as “Pending.”
- **Shipping information**: Null return dates were left as is, as not all shipments are returned.

---

## **Objective**

The primary objective of this project is to showcase SQL proficiency through complex queries that address real-world e-commerce business challenges. The analysis covers various aspects of e-commerce operations, including:
- Customer behavior
- Sales trends
- Inventory management
- Payment and shipping analysis
- Forecasting and product performance

---

## **Identifying Business Problems**

Key business problems identified:
1. Low product availability due to inconsistent restocking.
2. High return rates for specific product categories.
3. Significant delays in shipments and inconsistencies in delivery times.
4. High customer acquisition costs with a low customer retention rate.

---

### Solutions Implemented:

- #### Restock Prediction: By forecasting product demand based on past sales, I optimized restocking cycles, minimizing stockouts.
- #### Product Performance: Identified high-return products and optimized their sales strategies, such as product bundling and pricing adjustments.
- #### Shipping Optimization: Analyzed shipping times and delivery providers to recommend better logistics strategies and improve customer satisfaction.
- #### Customer Segmentation: Conducted RFM analysis to target marketing efforts towards "At-Risk" customers, improving retention and loyalty.

## **Solving Business Problems**

- 1. #### Top Selling Products

Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.

```sql
---join oi - o - pr
-- prod id
-- sum of quantity * price per unit
-- grp by prod id
-- top 10 prod

SELECT * FROM order_items

--- Creating new column
ALTER TABLE order_items
ADD COLUMN total_sale FLOAT;


-- Updating price qty * price per unit
UPDATE order_items
SET total_sale = quantity * price_per_unit;
SELECT * FROM order_items
ORDER BY quantity DESC

SELECT 
	oi.product_id,
	p.product_name,
	SUM(oi.total_sale) as total_sale,
	COUNT(o.order_id) as total_orders
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON p.product_id = oi.product_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10
```

2. #### Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.

```sql
-- category_id, cate_name, total revenue, total contribution
-- oi -- products -- cate table
-- group by cat id and name sum total (oi)

SELECT
	p.category_id,
	c.category_name,
	SUM(oi.total_sale) as total_sale,
	SUM(oi.total_sale)/(SELECT SUM(total_sale) from order_items) * 100 as percentage_contribution
FROM order_items as oi
JOIN
products as p
ON p.product_id = oi.product_id
LEFT JOIN category as c
ON c.category_id = p.category_id
GROUP BY 1,2
ORDER BY 3 DESC
```

#### 3.Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.

- AOV stands for average order value, which is a metric that measures the average amount of money a customer spends per order on an ecommerce website or app.

```sql
-- o -- oi -- cust
-- group by cust id and cust name sum(total_sale)/no orders

SELECT 
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) as full_name,
SUM(total_sale)/COUNT(o.order_id) as AOV,
COUNT(o.order_id) as total_orders --- filters
FROM orders as o
JOIN
customers as c
ON 
c.customer_id = o.customer_id
JOIN
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1,2
HAVING COUNT(o.order_id) > 5

```

#### 4. Monthly Sales Trend
Query monthly total sales over the past 2 years.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!

```sql

-- last 2 years data
-- each month sales and their prev month sales

SELECT 
	year,
	month,
	total_sale as current_month_sale,
	LAG(total_sale, 1) OVER(ORDER BY year, month) as last_month_sale
FROM ---
(
SELECT 
	EXTRACT(MONTH FROM o.order_date) as month,
	EXTRACT(YEAR FROM o.order_date) as year,
	ROUND(
			SUM(oi.total_sale::numeric)
			,2) as total_sale
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 1, 2
ORDER BY year, month
) as t1
```
