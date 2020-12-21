SELECT * FROM `alibaba-userbehavior`.ubhsmall;

/* deal with the duplicates */

SELECT user_id, item_id,timestamp FROM ubhsmall
GROUP BY user_id, item_id, timestamp
HAVING COUNT(user_id) > 1;-- checking null values

/* create a new table */

CREATE TABLE ubhsc
SELECT * FROM ubhsmall
GROUP BY user_id, item_id, cate_id, behavior_type, timestamp;-- let`s have a copy table

/* deal with the missing values */
SELECT COUNT(user_id), COUNT(item_id), 
COUNT(cate_id), COUNT(behavior_type), COUNT(timestamp)
FROM ubhsc; -- based on the results, no missing values

/* Consistent processing */

ALTER TABLE ubhsc ADD ID int unsigned primary key auto_increment;-- put a new key, named ID as PK
ALTER TABLE ubhsc ADD(longdate VARCHAR(255), date VARCHAR(255), time VARCHAR(255));-- add longdate, date, time to store time

UPDATE ubhsc
SET longdate=FROM_UNIXTIME(timestamp,'%Y-%m-%d %k:%i:%s'),
date=FROM_UNIXTIME(timestamp,'%Y-%m-%d'),
time=FROM_UNIXTIME(timestamp,'%k:%i:%s')
WHERE ID BETWEEN 1 and 1000000;-- change the format

ALTER TABLE ubhsc ADD hour INT(30);
UPDATE ubhsc SET hour = HOUR(time);-- add a column, named hour. which is used to store HOUR

/* dealing wtih the outliers */

SELECT COUNT(longdate)
FROM ubhsc
WHERE longdate<'2017-11-25 00:00:00' or longdate >'2017-12-03 24:00:00';

DELETE FROM ubhsc
WHERE longdate<'2017-11-25 00:00:00' or longdate >'2017-12-03 24:00:00';

/* after data clean, lets have a look the data */
SELECT 
COUNT(distinct user_id) AS 'user number',
COUNT(distinct item_id) AS 'product number',
COUNT(distinct cate_id) AS 'the number of types of products',
SUM(case when behavior_type = 'pv' then 1 else 0 end) AS 'PV number',
SUM(case when behavior_type = 'fav' then 1 else 0 end) AS 'Fav number',
SUM(case when behavior_type = 'cart' then 1 else 0 end) AS 'Cart number',
SUM(case when behavior_type = 'buy' then 1 else 0 end) AS 'Buy number',
COUNT(longdate) AS 'Total'
from ubhsc;

/*data analysis based on the dimension of customer*/

/*
(1) The dimension of customer
	1. The analysis of whole operation 
    1.1 the analysis of user traffic
    Results: total page review (PV),total Unique visitor(UV), Visits per capita(PV/UV)
*/

SELECT COUNT(DISTINCT user_id) AS 'Total page review (PV)',
sum(case when behavior_type='pv' then 1 else 0 END) as 'Total unique visitor(UV)',
sum(case when behavior_type='pv' then 1 else 0 END)/COUNT(DISTINCT user_id) as 'Visits per capita(PV/UV)'
FROM ubhsc; -- results: PV is 2696, UV is 240791, PV/UV is 89.3142

/*
(2) the relation between date/time and PV, UV and average PV
*/

# Date dimension
SELECT Date,
COUNT(DISTINCT user_ID) AS 'Total UV',
sum(case when behavior_type='pv' then 1 else 0 END) as 'Total PV',
sum(case when behavior_type='pv' then 1 else 0 END)/COUNT(DISTINCT user_id) as 'Visits per capita'
FROM ubhsc
GROUP BY Date
ORDER BY Date;

# Day(24 hours) Dimesition 
SELECT `hour`,
COUNT(DISTINCT User_ID) AS 'Total UV',
sum(case when behavior_type='pv' then 1 else 0 END) as 'Total PV',
sum(case when behavior_type='pv' then 1 else 0 END)/COUNT(DISTINCT user_id) as 'Visits per capita'
FROM ubhsc
GROUP BY `hour`
ORDER BY `hour`;

/*
The results show that during the period from 2017/11/25 to 2017/12/3, 
PV and UV have similar trends with the date, between 11/25 and 12/1 maintained a stable level, 
after 12/2, it began to increase significantly, 
the growth rate about it is 33%, 
while the number of visits per capita is relatively stable, with a slow downward trend since 12/1.
*/ -- date dimension

/*
Taking a day as the dimension, there is no major fluctuation in UV and PV between 10 and 18 o'clock (UV fluctuates around 6000, and PV fluctuates around 45000).
 From 18 o'clock to 23 o'clock, UV and PV increase significantly, 
 and PV fluctuate Obviously (frequently accessed by users)
*/

/*
(3) Consumption Behavior analysis
1. active analysis
*/
SELECT date, COUNT(DISTINCT(user_id)) AS 'Active user' -- group by date 
FROM ubhsc 
GROUP BY date 
ORDER BY date ASC;

SELECT  hour, COUNT(DISTINCT(user_id)) AS 'Active user' -- group by time
FROM ubhsc 
GROUP BY hour
ORDER BY hour ASC;

# Results:

/*
Date: 

The number of active users from November 25 to December 1 was evenly distributed, 
and the number of active users rose significantly from December 1st, 
reaching 137774 on December 2

Hour:
In a day, 4 o’clock is the lowest point of active number, 
0-7 o’clock is at a low peak, which is in line with the rules of user work and rest. 
The number of active users rises from 4-10 o’clock, 
and there is little fluctuation between 10-18 o’clock. 
The number of active nighttime users begins to increase, and between 21:00 and 22:00, users are most active

*/

/*
2. Paid Users analysis 
*/

# Paid User
SELECT  date, COUNT(DISTINCT(user_id)) AS 'Paid User',sum(case when behavior_type='buy' then 1 else 0 end)/COUNT(DISTINCT(user_id)) AS 'Per capita consumption of paying users'
FROM ubhsc 
WHERE behavior_type='buy'
GROUP BY date
ORDER BY date ASC;

SELECT `hour` as 'hour', COUNT(DISTINCT user_id) as 'number of paid user'
FROM ubhsc
WHERE behavior_type='buy'
GROUP BY `hour`;

# the ratio of paid 
SELECT a.date, a.AU, b.PU,CONCAT(ROUND(b.PU*100/a.AU,2),'%') FROM 
(SELECT date, COUNT(DISTINCT(user_id)) AS AU
FROM ubhsc 
GROUP BY date 
ORDER BY date ASC) a
LEFT JOIN 
(SELECT date, COUNT(DISTINCT user_id) as PU
FROM ubhsc
WHERE behavior_type='buy'
GROUP BY date) b ON a.date =b.date;

# User behavior analysis
SELECT user_id,COUNT(behavior_type) as User_Behavior,
sum(case when behavior_type='pv' then 1 else 0 end ) as Click,
sum(case when behavior_type='fav' then 1 else 0 end) as Fav,
sum(case when behavior_type='cart' then 1 else 0 end) as buy_more_than_1,
sum(case when behavior_type='buy' then 1 else 0 end) as buy
FROM ubhsc
GROUP BY user_id
ORDER BY User_Behavior DESC;

# group by date 
SELECT date as 'date', 
sum(case when behavior_type='pv' then 1 else 0 end ) as 'click',
sum(case when behavior_type='fav' then 1 else 0 end) as 'fav',
sum(case when behavior_type='cart' then 1 else 0 end) as 'buy more than 1',
sum(case when behavior_type='buy' then 1 else 0 end) as 'buy'
FROM ubhsc
GROUP BY date
ORDER BY date ASC;

#group by hour
SELECT `hour` as 'date', 
sum(case when behavior_type='pv' then 1 else 0 end ) as 'click',
sum(case when behavior_type='fav' then 1 else 0 end) as 'fav',
sum(case when behavior_type='cart' then 1 else 0 end) as 'buy more than 1',
sum(case when behavior_type='buy' then 1 else 0 end) as 'buy'
FROM ubhsc
GROUP BY `hour`
ORDER BY `hour` ASC;

#Repurchase rate and retention rate
#Repurchase rate: Repurchase rate = the number of people who have purchased twice or more times/the total number of users who have purchased
SELECT
sum(case when t.buy>1 then 1 else 0 end ) as 'Repurchase',
sum(case when t.buy>0 then 1 else 0 end ) as 'Purchase',
CONCAT(ROUND(sum(case when t.buy>1 then 1 else 0 end)*100/ sum(case when t.buy>0 then 1 else 0 end),2),'%') as 'Repurchase rate'
from 
(SELECT user_id,COUNT(behavior_type) as 'User behavior',
sum(case when behavior_type='buy' then 1 else 0 end) as buy
FROM ubhsc
GROUP BY user_id) t

/*
Retention after N days =(the number of users still logged in after N days after registration)/ the total number of new users on the first day
*/
#Take 2017-11-25 as the first day to calculate the retention rate of the next day, the 3rd day and the 7th day

select count(distinct user_id) as 'Day 1: New users' from ubhsc
where date = '2017-11-25';-- 1941
select count(distinct user_id) as 'Day 2: Retained number of users' from ubhsc
where date = '2017-11-26' and user_id in (SELECT user_id FROM ubhsc
WHERE date = '2017-11-25');-- 1534
select count(distinct user_id) as 'Day 3: Retained number of users'  from ubhsc
where date = '2017-11-27' and user_id in (SELECT user_id FROM ubhsc
WHERE date = '2017-11-25');-- 1533
select count(distinct user_id) as 'Day 4: Retained number of users'  from ubhsc
where date = '2017-12-01' and user_id in (SELECT user_id FROM ubhsc
WHERE date = '2017-11-25');-- 1483

CREATE TABLE Retention
(Day_1_New_users int,
Day_2_Retained_number_of_users int,
Day_3_Retained_number_of_users int,
Day_7_Retained_number_of_users int)

INSERT INTO Retention VALUES(1941,1534,1533,1483);

SELECT CONCAT(ROUND(100*Day_2_Retained_number_of_users/Day_1_New_users,2),'%')AS 'Next day retention',
CONCAT(ROUND(100*Day_3_Retained_number_of_users/Day_1_New_users,2),'%')AS 'Three-day retention rate',
CONCAT(ROUND(100*Day_7_Retained_number_of_users/Day_1_New_users,2),'%')AS 'Seven-day retention rate'
from Retention;

#User Value Analysis (RFM model)
select COUNT(DISTINCT Item_ID)
from ubhsc;-- 148833

select  COUNT(DISTINCT Item_ID)
from ubhsc 
where Behavior_type='buy';-- 5302

select a.number_purchase,COUNT(a.Item_ID) as 'product number'
FROM
(select  Item_ID,COUNT(User_ID) as number_purchase
from ubhsc 
where Behavior_type='buy'
GROUP BY Item_ID) as a
GROUP BY number_purchase
ORDER BY number_purchase DESC;

/* Results: In this statistical data, 5302 kinds of goods were purchased only once, 
accounting for 93.15% (4939/5302) of the number of goods purchased by users, 
indicating that the sale of goods mainly relies on the long tail effect of goods
*/


