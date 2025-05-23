-- EDA

SELECT * FROM category;
SELECT * FROM customers;

SELECT * FROM inventory;
SELECT * FROM order_items; 

SELECT DISTINCT payment_status FROM payments;

SELECT * from products;
SELECT * from sellers;
SELECT * FROM shippings;

-- checking the relations b/w tables
SELECT * FROM shippings
WHERE return_date IS NOT NULL;

SELECT * FROM orders
WHERE order_id = 6747;

SELECT * FROM payments
WHERE order_id = 6747;

SELECT * FROM shippings
WHERE return_date IS NULL;

-- select current_user,now()
-- -----------------------------
-- Business Problems Analysis
-- -----------------------------

/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
*/

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

/*
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
*/

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

/*
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
*/

-- o -- oi -- cust
-- group by cust id and cust name sum(total_sale)/no orders for avg.

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

/*
4. Monthly Sales Trend
Query monthly total sales over the past 2 year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
*/

-- last 2 years data
-- each month sales and their prev month sales


SELECT
	month,
	year,
	total_sale as current_month_sale,
	LAG(total_sale, 1) OVER(ORDER BY year, month) as last_month_sale, --going 1 row up therefore used 1 in lag func
	-- extra 
	ROUND(
        ((total_sale - LAG(total_sale, 1) OVER(ORDER BY year, month)) / 
         NULLIF(LAG(total_sale, 1) OVER(ORDER BY year, month), 0)) * 100, 2
    ) AS percentage_difference
FROM
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
WHERE order_date >= CURRENT_DATE - INTERVAL '2 year'
GROUP BY 1,2
ORDER BY year, month
) as t1

/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
*/

-- using subquery
SELECT * FROM customers
WHERE customer_id NOT IN (SELECT 
	DISTINCT customer_id 
	FROM orders)

-- another way of implementation using joins
SELECT *
FROM customers as c
LEFT JOIN
orders as o
ON
o.customer_id = c.customer_id
WHERE o.customer_id IS NULL

/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
*/

WITH ranking_table
AS
(
SELECT
	c.state,
	cat.category_name,
	SUM(oi.total_sale) as total_sale,
	RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sale) ASC)
FROM orders as o
JOIN
customers as c
ON o.customer_id = c.customer_id
JOIN
order_items as oi
ON o.order_id = oi.order_id
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN 
category as cat
ON cat.category_id = p.category_id
GROUP BY 1,2
)
SELECT *
FROM ranking_table
WHERE rank=1
-- ORDER BY 1,3 ASC

/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
*/
-- cx - o - oi
-- cx id group by sum(total_sale)
-- order by total sale
-- rank


SELECT 
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) as full_name,
SUM(total_sale) as CLTV,
DENSE_RANK() OVER(ORDER BY SUM(total_sale) DESC) as customer_rank
FROM orders as o
JOIN
customers as c
ON 
c.customer_id = o.customer_id
JOIN
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1,2
ORDER BY 3 DESC


/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/

SELECT 
i.inventory_id,
p.product_name,
i.stock as current_stock_left,
i.last_stock_date,
i.warehouse_id
from inventory as i
JOIN 
products as p
ON p.product_id = i.product_id
WHERE i.stock < 10


/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/

-- cx -- o -- ship

SELECT 
	c.*,
	o.*,
	s.shipping_providers,
s.shipping_date - o.order_date as days_took_to_shipped
FROM orders as o
JOIN
customers as c
ON c.customer_id = o.customer_id
JOIN
shippings as s
ON o.order_id = s.order_id 
WHERE s.shipping_date - o.order_date > 3


/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
*/

SELECT 
	p.payment_status,
	COUNT(*) as total_cnt,
	COUNT(*)::numeric/(SELECT COUNT(*) FROM payments)::numeric * 100 as percentage
FROM orders as o
JOIN
payments as p
ON o.order_id = p.order_id
GROUP BY 1


/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
*/
WITH top_sellers 
AS
(
SELECT 
s.seller_id,
s.seller_name,
SUM(oi.total_sale) as total_sale
FROM orders as o
JOIN
sellers as s
ON o.seller_id = s.seller_id
JOIN
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5
),
sellers_reports
AS
(SELECT 
	o.seller_id,
	ts.seller_name,
	o.order_status,
	COUNT(*) as total_orders
FROM orders as o
JOIN
top_sellers  as ts
ON ts.seller_id = o.seller_id
 	where
 	o.order_status NOT IN ('Inprogress') 
GROUP BY 1,2,3
)

SELECT 
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as Completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as Cancelled_orders,
	SUM(CASE WHEN order_status = 'Returned' THEN total_orders ELSE 0 END) as Returned_orders,
	SUM(total_orders) as total_orders,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric/
	NULLIF(SUM(total_orders),0)::numeric * 100 as successful_orders_percentage
FROM sellers_reports
GROUP BY 1 ,2


/*
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/

-- o -- oi -- prod
-- prod group by pid 
-- to find profit SUM(total_sale - cogs * qty) as profit
SELECT 
	product_id,
	product_name,
	profit_margin,
	DENSE_RANK() OVER(ORDER BY profit_margin DESC) as product_ranking
FROM 
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sale - (p.cogs * oi.quantity)) as profit,
	SUM(oi.total_sale - (p.cogs * oi.quantity))/sum(total_sale) * 100 as profit_margin
FROM order_items as oi
JOIN
products as p
ON oi.product_id = p.product_id
GROUP BY 1,2)


/*
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
*/

SELECT 
p.product_id,
p.product_name,
COUNT(*) as total_unit_sold,
SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_returned,
SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric/COUNT(*)::numeric as returned_percentage

FROM order_items as oi
JOIN
products as p
ON oi.product_id = p.product_id
JOIN orders as o
ON o.order_id = oi.order_id
GROUP BY 1,2
ORDER BY 5 DESC
LIMIT 10

/*
15. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
*/

WITH cte1 -- as these sellers has not done any sale in last 6 month
AS
(SELECT * FROM sellers
WHERE seller_id NOT IN (SELECT seller_id FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '6 month')
)

SELECT 
o.seller_id,
MAX(o.order_date) as last_sale_date,
MAX(oi.total_sale) as last_sale_amount
FROM orders as o
JOIN 
cte1
ON cte1.seller_id = o.seller_id
JOIN order_items as oi
ON o.order_id = oi.order_id
GROUP BY 1


/*
16. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
*/
SELECT 
c_full_name as customers,
total_orders,
total_returned,
CASE WHEN total_returned > 5 THEN 'Returning_customers' ELSE 'New'
END as cust_category


FROM 
(SELECT 
CONCAT(c.first_name, ' ', c.last_name) as c_full_name,
COUNT(o.order_id) as total_orders,
SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)as total_returned

FROM orders as o
JOIN
customers as c
ON c.customer_id = o.customer_id
JOIN
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1
)


/*
17. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
*/
SELECT * FROM
(
SELECT 
c.state,
CONCAT(c.first_name, ' ', c.last_name) as customers,
COUNT(o.order_id) as total_orders,
SUM(oi.total_sale) as total_sale,
DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) as rank
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN
customers as c
ON
c.customer_id = o.customer_id
GROUP BY 1,2
) as t1
WHERE rank <= 5


/*
18. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
*/

-- oi - o - shiping
-- group by shipping provider id sum(total sale), total orders

SELECT 
	s.shipping_providers,
	COUNT(o.order_id) as order_handled,
	SUM(oi.total_sale) as total_sale,
	COALESCE(AVG(s.return_date - s.shipping_date),0) as average_days
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN
shippings as s
ON
s.order_id = o.order_id
GROUP BY 1


/*
19. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/

-- join o - oi - p
-- filter 2022
-- group by p id sum(total sale)

-- join o - oi - p
-- filter 2023
-- group by p id sum(total sale)

-- join 1st and 2nd

WITH twenty_two_sale 
as
(
SELECT
	p.product_id,
	p.product_name,
	SUM(oi.total_sale) as revenue
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2022
GROUP BY 1,2
),
twenty_three_sale
AS
(
SELECT
	p.product_id,
	p.product_name,
	SUM(oi.total_sale) as revenue
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1,2
)

SELECT
	three.product_id,
	three.product_name,
	two.revenue as twenty_two_revenue,
	three.revenue as twenty_three_revenue,
	two.revenue - three.revenue as rev_diff,
	ROUND((three.revenue - two.revenue)::numeric/two.revenue::numeric * 100, 2) as reveneue_dec_ratio
FROM twenty_two_sale as two
JOIN
twenty_three_sale as three
ON two.product_id = three.product_id
WHERE 
	two.revenue > three.revenue
ORDER BY 6 DESC
LIMIT 10


-- Store PROCEDURE


/*
Final Task
-- Store Procedure
create a function as soon as the product is sold the same quantity should be reduced from inventory table
after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 
*/

SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM inventory;
SELECT * FROM products
order_id,
order_date,
customer_id,
seller_id,
order_item_id,
product_id,
quantity,


-- actual query starts here

CREATE OR REPLACE PROCEDURE add_sales
(
p_order_id INT,
p_customer_id INT,
p_seller_id INT,
p_order_item_id INT,
p_product_id INT,
p_quantity INT
)
LANGUAGE plpgsql
AS $$

DECLARE
-- all variable
v_count INT;
v_price FLOAT;
v_product VARCHAR(50);

BEGIN
-- Fetching product name and price based on product id entered
	SELECT 
		price, product_name
		INTO
		v_price, v_product
	FROM products
	WHERE product_id = p_product_id; -- based on product_id user has enter

-- checking stock and product availability in inventory	
	SELECT 
		COUNT(*) 
		INTO
		v_count
	FROM inventory
	WHERE 
		product_id = p_product_id
		AND 
		stock >= p_quantity;
	
	IF v_count > 0 THEN
	-- add into orders and order_items table
		INSERT INTO orders(order_id, order_date, customer_id, seller_id)
		VALUES
		(p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

	-- adding into order list
		INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sale)
		VALUES
		(p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price*p_quantity);

	--updating inventory
		UPDATE inventory
		SET stock = stock - p_quantity
		WHERE product_id = p_product_id;

		RAISE NOTICE 'Thank you product: % sale has been added and inventory stock is updated',v_product; 
	
	ELSE
		RAISE NOTICE 'Thank you for your info, The product: % is not available', v_product;

	END IF;
	
END;
$$

-- calling procedure
CALL add_sales
-- adding parameters value.
(
25000, 2, 5, 25001, 1, 40
)

(
p_order_id INT,
p_customer_id INT,
p_seller_id INT,
p_order_item_id INT,
p_product_id INT,
p_quantity INT
)


 