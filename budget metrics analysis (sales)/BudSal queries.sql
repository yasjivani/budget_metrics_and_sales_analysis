USE budget;

-- Retrieve all unique states present in the dataset.

        SELECT DISTINCT state
        FROM us_sales_dataset;

-- List the total number of products sold in each market. 

		SELECT
			ROW_NUMBER() OVER (ORDER BY product) AS sr_no,
            product
		FROM
			(
				SELECT DISTINCT product
                FROM us_sales_dataset
            ) AS product_list;

-- Fetch the records where the profit is greater than 100. 

		SELECT *
        FROM us_sales_dataset
        WHERE profit > 100;
        
-- Display all products that belong to a specific product type, such as "Coffee." 

		SELECT DISTINCT product AS products_belongs_to_COFFEE
        FROM us_sales_dataset
        WHERE product_type IN ('Coffee');
        
        SELECT DISTINCT product AS products_belongs_to_TEA
        FROM us_sales_dataset
        WHERE product_type = 'Tea'; -- Displayed all products belongs to tea 
        
        SELECT DISTINCT product AS products_belongs_to_COFFEE_and_TEA,
        product_type
        FROM us_sales_dataset
        WHERE product_type IN ('Coffee','Tea')
        ORDER BY product_type; -- Displayed all products belongs to tea and coffee
        
-- Find all transactions that occurred in January 2022. 

		SELECT *
		FROM us_sales_dataset
		WHERE YEAR(date_on) = 2022 AND MONTH(date_on) = 1;
        
-- Calculate the total profit for each product type 

		SELECT product_type, SUM(profit) AS total_profit
        FROM us_sales_dataset
        GROUP BY product_type
        ORDER BY total_profit DESC;
        
-- Retrieve rows where the sales are greater than the corresponding budget sales.

		SELECT *
        FROM us_sales_dataset
        WHERE sales > budgeted_sales;
        
-- Group the data by market and calculate the total and average sales for each market. 

		SELECT 
			market,
			SUM(sales) AS total_sales_USD,
			ROUND(AVG(sales),2) AS average_sales_USD
		FROM us_sales_dataset
        GROUP BY market
        ORDER BY total_sales_USD DESC;
        
-- Identify the top 5 states with the highest total profits.

		SELECT 
			state,
			SUM(profit) AS total_profit_USD
        FROM us_sales_dataset
        GROUP BY state
        ORDER BY total_profit_USD DESC
        LIMIT 5;
        
-- Retrieve the details of transactions where the actual margin is less than the budget margin 

		SELECT *
        FROM us_sales_dataset
        WHERE margin < budgeted_margin;
        
-- Count the number of transactions for each product type 

		SELECT 
			product_type,
			COUNT(*) AS total_transactions
		FROM us_sales_dataset
        GROUP BY product_type
        ORDER BY product_type ASC; -- use of ASC is not mandated as by default the column is arranged in ascending order when ORDER BY is used for particular column
        
-- Find the average inventory level for each state.

		SELECT
			state,
			ROUND(AVG(inventory),2) AS average_inventory_level
		FROM us_sales_dataset
		GROUP BY state
        ORDER BY average_inventory_level;
            
-- Write a query to find the variance between actual and budgeted COGS for each market. 

		SELECT 
			market,
			ROUND(VARIANCE(cogs - budgeted_cogs),2) AS variance_cogs
		FROM us_sales_dataset
		GROUP BY market
        ORDER BY variance_cogs DESC;
        
-- Create a query to find all records where the inventory level is above 1000 and sales exceed 300. 

		SELECT *
		FROM us_sales_dataset
		WHERE inventory > 1000 AND sales > 300;
    
-- Display the state, market, and total expenses for transactions where marketing expenses are more than 10% of the total sales. 

		SELECT
			area_code,
			state,
			market,
			total_expenses
		FROM us_sales_dataset
		WHERE marketing > (0.1 * sales);
		
-- Create a ranking query to rank states by total sales within each market. 
        
        SELECT
            market,
            state,
            SUM(sales) AS total_sales,
			RANK() OVER (PARTITION BY market ORDER BY SUM(sales) DESC) AS ranking
		FROM us_sales_dataset
        GROUP BY state,market;
        
-- Write a query to find the cumulative sales per state in chronological order

		SELECT
			state,
            date_on AS Date,
            sales,
            SUM(sales) OVER (PARTITION BY state ORDER BY date_on ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cummulative_sale
		FROM us_sales_dataset
        ORDER BY state,date_on;
        
        
-- Use a subquery to find states with a total profit above the average profit across all states.

		SELECT 
			state,
            SUM(profit) AS total_profit
		FROM us_sales_dataset
        GROUP BY state
        HAVING total_profit >
							(
								SELECT AVG(state_profit)
								FROM
									(
										SELECT SUM(profit) AS state_profit
                                        FROM us_sales_dataset
                                        GROUP BY state
                                    ) AS avg_profit
							);
                            
-- Identify the product with the highest profit margin for each market
	
		SELECT
			a.market,
			a.product,
			b.highest_profit_margin AS total_profit
		FROM
			(
				SELECT
					market,
					product,
					SUM(margin) AS total_profit_margin
				FROM us_sales_dataset
				GROUP BY market,product
			) AS a
		JOIN
			(
				SELECT
					market,
					MAX(total_profit_margin) AS highest_profit_margin
				FROM
					(
						SELECT
							market,
							product,
							SUM(margin) AS total_profit_margin
						FROM us_sales_dataset
						GROUP BY market,product
					) AS sub
				GROUP BY market
			) AS b
		ON a.total_profit_margin = b.highest_profit_margin
		GROUP BY market,product;
        
-- Create a query using a window function to calculate the rolling average of sales over 3 consecutive dates for each product
		
        SELECT
			product,
            date_on as date,
            sales,
            ROUND
				(
					AVG(sales) OVER (PARTITION BY product ORDER BY date_on ROWS BETWEEN 3 PRECEDING AND CURRENT ROW),2
				) AS rolling_average_of_sales_over_3_consecutive_dates
			FROM us_sales_dataset
            ORDER BY product,date_on;

-- Write a query to find the percentage contribution of marketing expenses to total expenses for each transaction
		
        SELECT 
			state,
            market,
            market_size,
            date_on AS date,
            product,
            marketing AS marketing_expenses,
            total_expenses,
            ROUND((marketing*100/total_expenses),2) AS contribution_of_MktExp_in_TotExp
		FROM us_sales_dataset
        WHERE marketing > 0
        ORDER BY state,market,market_size;
        
-- Use a Common Table Expression (CTE) to find states where the total inventory exceeds 10,000

		WITH inventory_cte AS
							(
								SELECT 
									state,
                                    SUM(inventory) AS total_inventory
								FROM us_sales_dataset
                                GROUP BY state
                                ORDER BY total_inventory DESC
                            )
		SELECT *
        FROM inventory_cte
        WHERE total_inventory > 10000;
        
        -- same query rewritten using a subquery instead of a CTE
        SELECT *
        FROM
			(
				SELECT 
					state,
					SUM(inventory) AS total_inventory
				FROM us_sales_dataset
				GROUP BY state
				ORDER BY total_inventory DESC
			) AS sub
        WHERE total_inventory > 10000;
        
-- Find anomalies by identifying transactions where the actual sales significantly deviate (e.g., by more than 20%) from the budgeted sales.

		SELECT
            state,
            market,
            market_size,
            product,
            date_on,
            sales AS actual_sales,
            budgeted_sales,
            ABS(sales - budgeted_sales) AS absolute_diff,
            ROUND((ABS(sales - budgeted_sales) * 100 / budgeted_sales),2) deviation_percentage
		FROM us_sales_dataset
        WHERE budgeted_sales > 0
        AND (ABS(sales - budgeted_sales) / budgeted_sales) > 0.20
        ORDER BY state,market,market_size,product;
        
-- Generate a report showing the year-wise total sales and total profits for each product type.
		
        SELECT 
			YEAR(date_on) AS years,
            product_type,
            SUM(sales) AS total_sales,
            SUM(profit) AS total_profit
		FROM us_sales_dataset
        GROUP BY YEAR(date_on),product_type;        
        
        SELECT 
			product_type,
			SUM(CASE WHEN YEAR(date_on) = 2022 THEN Sales ELSE 0 END) AS Sales_2022,
			SUM(CASE WHEN YEAR(date_on) = 2023 THEN Sales ELSE 0 END) AS Sales_2023,
			SUM(CASE WHEN YEAR(date_on) = 2022 THEN Profit ELSE 0 END) AS Profit_2022,
			SUM(CASE WHEN YEAR(date_on) = 2023 THEN Profit ELSE 0 END) AS Profit_2023
		FROM us_sales_dataset
        GROUP BY product_type
        ORDER BY product_type;
        
        SELECT 
			product_type,
			'Sales' AS Metric,
			SUM(CASE WHEN YEAR(date_on) = 2022 THEN Sales ELSE 0 END) AS `2022`,
			SUM(CASE WHEN YEAR(date_on) = 2023 THEN Sales ELSE 0 END) AS `2023`
		FROM 
			us_sales_dataset
		GROUP BY 
			product_type
		UNION ALL
		SELECT 
			product_type,
			'Profit' AS Metric,
			SUM(CASE WHEN YEAR(date_on) = 2022 THEN Profit ELSE 0 END) AS `2022`,
			SUM(CASE WHEN YEAR(date_on) = 2023 THEN Profit ELSE 0 END) AS `2023`
		FROM 
			us_sales_dataset
		GROUP BY 
			product_type
		ORDER BY 
			product_type, Metric;

-- Create a view summarizing key metrics (total sales, total expenses, and profit) for each market size.

		CREATE VIEW key_metrics_based_on_market_size AS
		SELECT
			market_size,
            SUM(sales) AS total_sales,
            SUM(total_expenses) AS total_expenses,
            SUM(profit) AS total_profit
		FROM us_sales_dataset
        GROUP BY market_size
        ORDER BY total_profit DESC;
        
        SELECT * FROM key_metrics_based_on_market_size;         

-- Write a query to create a "Profit Efficiency" metric, defined as (Profit / Sales) * 100, and list the top 10 transactions based on this metric.

		SELECT
			productID,
            product,
            date_on AS date,
            sales,
            profit,
            ROUND((profit*100/sales),2) AS profit_efficiency
		FROM us_sales_dataset
        ORDER BY profit_efficiency 
        LIMIT 10;


-- Use a recursive query to analyze the sales trend over time for each product (month-on-month change).
		
        WITH RECURSIVE sales_trends AS
		(
			SELECT
				productID,
                MONTH(date_on) AS months,
                YEAR(date_on) AS years,
                SUM(sales) AS total_sales
			FROM us_sales_dataset
            GROUP BY productID,months,years
		)
            SELECT * FROM sales_trends
            UNION ALL
            SELECT
				st.productID,
                st.months + 1 AS months,
                st.years,
                u.sales - st.total_sales AS month_on_month_changes
			FROM us_sales_dataset AS u
            JOIN sales_trends AS st
            ON u.productID = st.productID AND MONTH(u.date_on) = st.months+1;    
        
-- Simulate a pivot table using SQL to show total sales for each product type across different markets.

		SELECT
			product_type,
            SUM(CASE WHEN market = 'East' THEN sales ELSE 0 END) AS east_market_sales,
            SUM(CASE WHEN market = 'West' THEN sales ELSE 0 END) AS west_market_sales,
            SUM(CASE WHEN market = 'South' THEN sales ELSE 0 END) AS south_market_sales,
            SUM(CASE WHEN market = 'Central' THEN sales ELSE 0 END) AS central_market_sales
		FROM us_sales_dataset
        GROUP BY product_type;           

-- Write a stored procedure to find the top 3 profitable products in a given market, with the market name passed as a parameter.

		DELIMITER $$

		CREATE PROCEDURE Top3ProfitableProducts(IN market_name VARCHAR(50))
		BEGIN
			SELECT 
				product, 
				SUM(profit) AS total_profit
			FROM us_sales_dataset
			WHERE market = market_name
			GROUP BY product
			ORDER BY total_profit DESC
			LIMIT 3;
		END$$

		DELIMITER ;

		CALL Top3ProfitableProducts('East' );
        
        
        -- stored procedure for determining Product Profit Based On Its Types 
        DELIMITER //
        
        CREATE PROCEDURE ProductProfitBasedOnItsTypes (IN product_type_name VARCHAR(50))
        BEGIN
			SELECT 
				product,
				SUM(profit) AS TotalProfit
			FROM us_sales_dataset
            WHERE product_type = product_type_name
            GROUP BY product
            ORDER BY TotalProfit DESC;
        END //
        
        DELIMETER ;
        
        CALL ProductProfitBasedOnItsTypes('Espresso');
        
        
        -- stored procedure to find total sales for particular market 
        DELIMITER //
        
        CREATE PROCEDURE GetTotalSalesbyMarket
									(
										IN market_name VARCHAR(50),
                                        OUT total_sales INT
									)
		BEGIN
			SELECT SUM(sales) INTO total_sales
            FROM us_sales_dataset
            WHERE market = market_name;
		END //
        DELIMITER ;

		
            