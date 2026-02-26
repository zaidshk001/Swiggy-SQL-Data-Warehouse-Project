USe swiggy_db;
-- Step 1 - Data Loading 

SHOW VARIABLES LIKE 'max_allowed_packet';
SET GLOBAL max_allowed_packet = 1073741824;

Drop table swiggy_data;
Create Table swiggy_data (
state varchar(150),
city varchar(150),
order_date nvarchar(150), -- done to load every date rows 
restaurant_name varchar(150),
location varchar(150),
category varchar(150),
dish_name varchar(250),
price_inr Decimal(10,2),
rating float,
rating_count INT)
;

-- the normal method was not loading the full data so we tried a different method to load it 

SHOW VARIABLES LIKE 'local_infile'; 
SET GLOBAL local_infile = 1; -- this we changed to run the above load data query 
SHOW VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';

/* to enable the above we also opened the notepad as an administrator 
from file - Open - C:\ProgramData\MySQL\MySQL Server 8.0\
Change file type from Text Documents to All Files 
Open my.ini
under [mysqld] added local_infile=1
under [client] added local_infile=1
Saved it then restarted mysql service 
Press Windows + R -- services.msc -- MySQL80 -- Right-click → Restart
*/
-- Run the below query to load the full data in the swiggy_data table
LOAD DATA LOCAL INFILE 
'C:\\Users\\zaids\\Downloads\\Swiggy_SQL\\Swiggy_Data.csv'
INTO TABLE swiggy_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

Select COUNT(*) From swiggy_data;

SELECT order_date FROM swiggy_data LIMIT 5;

-- Now convert order_date data type from nvarchar to date
/*We cannot directly modify the column type because MySQL won’t understand DD-MM-YYYY.
We must use STR_TO_DATE(). */

ALTER TABLE swiggy_data 
ADD COLUMN order_date_new DATE;

UPDATE swiggy_data
SET order_date_new = STR_TO_DATE(order_date, '%d-%m-%Y');

-- Verify conversion
SELECT order_date, order_date_new
FROM swiggy_data
LIMIT 10;

-- Drop old column 
ALTER TABLE swiggy_data
DROP COLUMN order_date;

-- rename the column name 
ALTER TABLE swiggy_data
CHANGE order_date_new order_date DATE;

-- align columns
ALTER TABLE swiggy_data
MODIFY order_date DATE
AFTER city;

Select * From swiggy_data;
Select * from swiggy_data_n;

-- Step 2 - Data Validation and  Cleaning 

-- check for null values
Select
SUM(CASE When state is NULL then 1 else 0 ENd) as null_state,
SUM(CASE When city is NULL then 1 else 0 ENd) as null_city,
SUM(CASE When restaurant_name is NULL then 1 else 0 ENd) as null_restaurant,
SUM(CASE When location is NULL then 1 else 0 ENd) as null_location,
SUM(CASE When category is NULL then 1 else 0 ENd) as null_category,
SUM(CASE When dish_name is NULL then 1 else 0 ENd) as null_dish,
SUM(CASE When price_inr is NULL then 1 else 0 ENd) as null_price,
SUM(CASE When rating is NULL then 1 else 0 ENd) as null_rating,
SUM(CASE When rating_count is NULL then 1 else 0 ENd) as null_count,
SUM(CASE When order_date is NULL then 1 else 0 ENd) as null_date
From swiggy_data;

-- no null values in each of the columns 

-- check for Empty or Blank Strings
Select * 
from swiggy_data
Where state = '' OR city = '' OR restaurant_name = '' OR  location = '' OR category = '' OR dish_name ='';

-- check for Duplicate
Select * from swiggy_data;

Select *, COunt(*) as cnt
From swiggy_data
Group by state, city, order_date, restaurant_name, location, category, dish_name, price_inr, rating, rating_count
Having COunt(*) > 1; -- there are 27 duplicate records

with cte as (
Select *,
row_number() over (partition by state, city, order_date, restaurant_name, location, category, dish_name, price_inr, rating, rating_count
Order by (Select Null)) as cnt -- Order by (Select Null) is just to give an order
from swiggy_data)

Delete from cte
where cnt > 1;

-- create a duplicate table from which we will delete those duplicate rows
create table swiggy_data_n AS
Select *
From swiggy_data;

-- we will delete the duplicate table but as our data does not have a unique identifier we will create it then delete duplicate rows


ALTER TABLE swiggy_data_n
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

DELETE FROM swiggy_data_n
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY state, city, order_date, restaurant_name,
                                location, category, dish_name,
                                price_inr, rating, rating_count
                   ORDER BY id
               ) AS rn
        FROM swiggy_data_n
    ) t
    WHERE rn > 1
);

-- method 2 (cleaner approach given all the columns were identical
CREATE TABLE swiggy_data_clean AS
SELECT DISTINCT *
FROM swiggy_data; -- 27 dup rows removed 

-- Step 3 - Creating a star schema  Table creation

-- creating dimension tables 
DROP TABLE IF EXISTS dim_date;
Create table dim_date (
date_id INT AUTO_INCREMENT PRIMARY KEY,
full_date date,
Year Int,
Month Int,
Month_Name varchar(20),
Quarter INT,
Day INT,
Week int);

Select * from dim_date;


drop table dim_location;
Create table dim_location (
location_id INT AUTO_INCREMENT PRIMARY KEY,
State Varchar(100),
City varchar(100),
Location varchar(200)
);

drop table dim_restaurant;
Create table dim_restaurant (
restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
restaurant_name Varchar(200)
);

drop table dim_category;
Create table dim_category (
category_id INT AUTO_INCREMENT PRIMARY KEY,
Category Varchar(200)
);

drop table dim_dish;
Create table dim_dish (
dish_id INT AUTO_INCREMENT PRIMARY KEY,
dish_name Varchar(200)
);

-- create fact table
Drop table fact_swiggy_orders;
truncate table fact_swiggy_orders;
Create table fact_swiggy_orders (
order_id INT AUTO_INCREMENT PRIMARY KEY,
date_id INT,
price_inr decimal(10,2),
rating decimal(4,2),
rating_count Int,
location_id INT,
restaurant_id INT,
category_id Int,
dish_id Int,

foreign key (date_id) references dim_date(date_id),
foreign key (location_id) references dim_location(location_id),
foreign key (restaurant_id) references dim_restaurant(restaurant_id),
foreign key (category_id) references dim_category(category_id),
foreign key (dish_id) references dim_dish(dish_id)
);

Select * from fact_swiggy_orders;

-- Now insert data into dim_date table 
Select * from dim_date;
Truncate Table dim_date;
drop table dim_date;

Insert into dim_date (full_date, year, month, month_name, quarter, day, week)
Select distinct
order_date,
YEAR(order_date),
Month(order_date),
monthname(order_date), 
quarter(order_date),
day(order_date),
week(order_date)
from swiggy_data_n
Where order_date is not null;

Select * From dim_category;
Insert into dim_category (category)
Select Distinct category
From swiggy_data_n;

Select * From dim_location;
Insert into dim_location (state, city, location)
Select Distinct state, city, location
From swiggy_data_n;

Select * From dim_restaurant;
Insert into dim_restaurant (restaurant_name)
Select Distinct restaurant_name
From swiggy_data_n;

truncate table dim_dish;
Select * From dim_dish;
Insert into dim_dish (dish_name)
Select Distinct dish_name
From swiggy_data_n;

/*The nelow step we did because we added the data twice in dim_restaurant and dim_dish table and SQL was not letting us 
drop / truncate those table because of foreign key constraints. 
Best practise is always drop the fact table first then drop the dimension tables */

SHOW CREATE TABLE fact_swiggy_orders;
ALTER TABLE fact_swiggy_orders
DROP FOREIGN KEY fact_swiggy_orders_ibfk_5;

SET FOREIGN_KEY_CHECKS = 0;
-- Now insert into fact table


Insert INTO fact_swiggy_orders (date_id, price_inr, rating, rating_count, location_id, restaurant_id, category_id, dish_id)
Select 
dd.date_id,
s.price_inr,
s.rating,
s.rating_count,
dl.location_id,
dr.restaurant_id,
dc.category_id,
dh.dish_id
From swiggy_data_n s
Join dim_date dd
ON s.order_date = dd.full_date
Join dim_category dc
ON dc.category = s.category
JOIN dim_restaurant dr
ON dr.restaurant_name = s.restaurant_name
JOIN dim_location dl
ON s.state = dl.state and s.city = dl.city and s.location = dl.location
JOIN dim_dish dh
ON dh.dish_name = s.dish_name;

Select * From fact_swiggy_orders;

-- now we have successfully created all the fact and dimension tables

SELECT COUNT(*) FROM fact_swiggy_orders;
SELECT COUNT(*) FROM dim_date;
SELECT COUNT(*) FROM dim_category;
SELECT COUNT(*) FROM dim_restaurant;
SELECT COUNT(*) FROM dim_location;
SELECT COUNT(*) FROM dim_dish;


Select *  -- f.order_id, f.date_id, price_inr,rating,rating_count,f.location_id
From fact_swiggy_orders f
Join dim_date d
ON d.date_id = f.date_id
Join dim_category c
ON c.category_id = f.category_id
Join dim_restaurant r
ON r.restaurant_id = f.restaurant_id
Join dim_location l
ON l.location_id = f.location_id
JOIN dim_dish di
ON di.dish_id = f.dish_id;

-- KPI development

-- 1. Total orders
Select 
COUNT(Distinct order_id) as total_orders
From fact_swiggy_orders;

-- 2. Total Revenue
Select 
CONCAT(ROUND(SUM(price_inr) / 1000000)," Million") as total_revenue
From fact_swiggy_orders;

-- 3. Avg Dish Price
Select 
CONCAT(ROUND(AVG(price_inr),2)," Rupees") as avg_dish_price
From fact_swiggy_orders;

-- 4. Avg Rating
Select 
CONCAT(ROUND(AVG(rating),2)) as avg_rating
From fact_swiggy_orders;


-- Date Based Analysis

-- 1. Monthly order trends
Select
d.year,
d.month,
d.month_name,
COUNT(f.order_id) as total_orders,
SUM(f.price_inr) as revenue,
LAG(COUNT(f.order_id)) over (Partition by  year Order by month) as previous_month,
ROUND(100*(COUNT(f.order_id) - LAG(COUNT(f.order_id)) over (Partition by  year Order by month)) /LAG(COUNT(f.order_id)) over (Partition by  year Order by month),2) as pct
From dim_date d
JOIN fact_swiggy_orders f
on d.date_id = f.date_id
Group by 1,2,3
Order by 1,2,3;

-- 2. Quaterly order trends

Select
d.year,
d.quarter,
COUNT(f.order_id) as total_orders,
SUM(f.price_inr) as revenue,
LAG(COUNT(f.order_id)) over (Partition by  year Order by quarter) as previous_month,
ROUND(100*(COUNT(f.order_id) - LAG(COUNT(f.order_id)) over (Partition by  year Order by quarter)) /LAG(COUNT(f.order_id)) over (Partition by  year Order by quarter),2) as pct
From dim_date d
JOIN fact_swiggy_orders f
on d.date_id = f.date_id
Group by 1,2
Order by 1,2;

-- 3. Year wise growth

Select
d.year,
COUNT(f.order_id) as total_orders,
SUM(f.price_inr) as revenue,
LAG(COUNT(f.order_id)) over (Partition by  year Order by year) as previous_month,
ROUND(100*(COUNT(f.order_id) - LAG(COUNT(f.order_id)) over (Partition by  year Order by year)) /LAG(COUNT(f.order_id)) over (Partition by  year Order by year),2) as pct
From dim_date d
JOIN fact_swiggy_orders f
on d.date_id = f.date_id
Group by 1
Order by 1;

-- 4. Day of week patterns 
Select
dayofweek(d.full_date) as day_of_week,
dayname(d.full_date) as day,
COUNT(f.order_id) as total_orders,
SUM(f.price_inr) as revenue
-- LAG(COUNT(f.order_id)) over (Partition by  year Order by year) as previous_month,
-- ROUND(100*(COUNT(f.order_id) - LAG(COUNT(f.order_id)) over (Partition by  year Order by year)) /LAG(COUNT(f.order_id)) over (Partition by  year Order by year),2) as pct
From dim_date d
JOIN fact_swiggy_orders f
on d.date_id = f.date_id
Group by 1,2
Order by 1,2;

-- Location based analysis 

-- 1. Top 10 cities by order volume
Select
dl.city,
COUNT(s.order_id) as order_cnt
From dim_location dl
JOIN fact_swiggy_orders s
ON dl.location_id = s.location_id
Group by 1
Order by 2 Desc
LIMIT 10;

-- 2. Revenue contribution by state
Select
dl.state,
SUM(s.price_inr) as revenue,
ROUND(100.0 * SUM(s.price_inr) / (Select SUM(price_inr) from fact_swiggy_orders),2) as pct_cont
From dim_location dl
JOIN fact_swiggy_orders s
ON dl.location_id = s.location_id
Group by 1
Order by 3 DESC;

-- Top 10 restaurants by order

Select
restaurant_name,
COUNT(s.order_id) as order_cnt
From dim_restaurant r
JOIN fact_swiggy_orders s
ON r.restaurant_id = s.restaurant_id
Group by 1
Order by 2 Desc
LIMIT 10;

-- top categories 
Select
category,
COUNT(s.order_id) as order_cnt
From dim_category c
JOIN fact_swiggy_orders s
ON c.category_id = s.category_id
Group by 1
Order by 2 Desc
LIMIT 10;

-- top 3 restaurants in each category 
Select 
category,
restaurant_name,
orders,
rnk
From (
Select 
category,
restaurant_name,
Count(order_id) as orders,
DENSE_RANK() over (partition by category order by Count(order_id) DESC) as rnk
From dim_category c
JOIN fact_swiggy_orders s
ON c.category_id = s.category_id
JOin dim_restaurant r
ON r.restaurant_id = s.restaurant_id
Group by 1,2) tota 

where rnk <= 3;

-- most ordered dishes
-- top categories 
Select
dish_name,
COUNT(s.order_id) as order_cnt,
ROUND(AVG(s.rating),2) as avg_rating
From dim_dish d
JOIN fact_swiggy_orders s
ON d.dish_id = s.dish_id
Group by 1
Order by 2 Desc
LIMIT 10;

-- Customer Spending Spend 
Select 
CASE 
 WHEN price_inr < 100 then 'under 100'
 When price_inr between 100 and 199 then '100-199'
 When price_inr between 200 and 299 then '200-299'
 When price_inr between 300 and 499 then '300-499'
 else '500+'
 End as customer_spend,
 COUNT(order_id) as total_orders,
 SUM(COUNT(order_id)) over () as total,
  ROUND(100 * COUNT(order_id) / SUM(COUNT(order_id)) over ()) as pct
From fact_swiggy_orders
Group by 1
Order by 1 DESC;
-- cuisine performance 
Select * from dim_dish;

-- Distribution of dish rating 
Select 
rating,
COUNT(*) as cnt
from fact_swiggy_orders
Group by 1
Order by 2 DESC;
