---

# **Amazon USA Sales Analysis Project**

---

## **Project Overview**

I worked on analyzing a dataset comprising over 20,000 sales records from an Amazon-like e-commerce platform. The project involved deep exploration of customer behavior, product performance, and sales trends using PostgreSQL. I solved complex SQL problems, such as revenue analysis, customer segmentation, and inventory management, showcasing my ability to derive actionable insights.

The project emphasized data cleaning, addressing null values, and tackling real-world business challenges through structured queries. Additionally, an ERD diagram was created to visually illustrate the database schema and the relationships between tables.

An ERD diagram is included to visually represent the database schema and relationships between tables.

---

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

1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.

---join oi - o - pr
-- prod id
-- sum of quantity * price per unit
-- grp by prod id
-- top 10 prod

```sql
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
