#first grab customer codes for Croma india
SELECT * FROM dim_customer WHERE customer like "%croma%" AND market="india";

#Get all the sales transaction data from fact_sales_monthly table for that customer(croma: 90002002) in the fiscal_year 2021
SELECT * FROM fact_sales_monthly 
WHERE 
	customer_code=90002002 AND
	YEAR(DATE_ADD(date, INTERVAL 4 MONTH))=2021 
ORDER BY date asc
LIMIT 100000;

#create a function 'get_fiscal_year' to get fiscal year by passing the date
CREATE FUNCTION `get_fiscal_year`(calendar_date DATE) 
RETURNS int
DETERMINISTIC
	get_fiscal_yearBEGIN
        	DECLARE fiscal_year INT;
        	SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
        	RETURN fiscal_year;
END

#Replacing the function created in the step:b
SELECT * FROM fact_sales_monthly 
WHERE 
	customer_code=90002002 AND
	get_fiscal_year(date)=2021 
ORDER BY date asc
LIMIT 100000;

#Gross Sales Report: Monthly Product Transactions

#Perform joins to pull product information
SELECT s.date, s.product_code, p.product, p.variant, s.sold_quantity 
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code=p.product_code
WHERE 
	customer_code=90002002 AND 
	get_fiscal_year(date)=2021     
LIMIT 1000000;

#Performing join with 'fact_gross_price' table with the above query and generating required fields
SELECT 
	 s.date, 
	 s.product_code, 
	 p.product, 
	 p.variant, 
	 s.sold_quantity, 
	 g.gross_price,
	 ROUND(s.sold_quantity*g.gross_price,2) as gross_price_total
FROM fact_sales_monthly s
JOIN dim_product p
	 ON s.product_code=p.product_code
JOIN fact_gross_price g
	 ON g.fiscal_year=get_fiscal_year(s.date)
	 AND g.product_code=s.product_code
WHERE 
	 customer_code=90002002 AND 
	 get_fiscal_year(s.date)=2021     
LIMIT 1000000;

#Gross Sales Report: Total Sales Amount:
#Generate monthly gross sales report for Croma India for all the years
SELECT 
	  s.date, 
	  SUM(ROUND(s.sold_quantity*g.gross_price,2)) as monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
	  ON g.fiscal_year=get_fiscal_year(s.date) AND g.product_code=s.product_code
WHERE 
	  customer_code=90002002
GROUP BY date;

#Generate a yearly report for Croma India where there are two columns
SELECT 
      get_fiscal_year(date) as fiscal_year,
      sum(round(s.sold_quantity*g.gross_price,2)) as Yearly_sales
FROM fact_sales_monthly s      
JOIN fact_gross_price g
     ON g.fiscal_year=get_fiscal_year(s.date) 
     and g.product_code=s.product_code
WHERE
     customer_code=90002002
GROUP BY get_fiscal_year(s.date)
ORDER BY fiscal_year;     
     
