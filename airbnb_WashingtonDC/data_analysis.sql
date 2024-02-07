/*
	Airbnb Data Analysis in SQL Server Queries
	
	Airbnb row dataset has been downloaded from the following website:
	Inside Airbnb: Get the Data at http://insideairbnb.com/get-the-data/
	Washington, D.C., District of Columbia, United States 13 September, 2023
	The downloaded dataset list:
	1) listings.csv
	2) reviews.csv
	3) calendar.csv
	4) neighbourhoods.csv

	The dataset has been imported into MS SQL Server in Local Database Machine.
	The dataset has been cleaned (please refer to data_cleaning.sql for details)
	The dataset has been organized and structured (please refer to data_modeling.sql) 
	The dataset's time series coverage (11/21/2008 - 9/12/2023)
	The dataset's location coverage (District of Columbia, Virginia, Maryland USA)
			
*/

-- A. KPI’s (Key Performance Indicator metrics)
---		1. Total Bookings.
SELECT SUM(number_of_reviews) AS total_bookings
FROM dbo.listings_cleaned

---		2. Total Accommodation Properties.
SELECT COUNT(id) AS total_accomm_properties
FROM dbo.listings_cleaned

---		3. Total Hosts.
SELECT COUNT(host_id) AS total_hosts
FROM dbo.host_profile


-- B. Yearly Trend for Bookings
WITH cte AS
(SELECT DISTINCT YEAR(lis.first_review) AS year_
	, (SELECT SUM(number_of_reviews) FROM dbo.listings_cleaned 
		WHERE YEAR(first_review) BETWEEN 2009 AND YEAR(lis.first_review)) AS total_bookings
	, SUM(number_of_reviews) OVER (PARTITION BY YEAR(lis.first_review)) AS new_bookings
FROM dbo.listings_cleaned AS lis)
SELECT *
	, CAST(CAST(new_bookings AS DECIMAL(10,1)) 
	/ CAST(total_bookings AS DECIMAL(10,1))*100 AS DECIMAL(10,1)) AS percentage_of_increase
FROM cte
ORDER BY year_

-- C. Yearly Trend for Accommodation Properties.
WITH cte AS
(SELECT DISTINCT YEAR(lis.first_review) AS year_
	, (SELECT COUNT(id) FROM dbo.listings_cleaned 
		WHERE YEAR(first_review) BETWEEN 2009 AND YEAR(lis.first_review)) AS total_accomm_properties
	, COUNT(id) OVER (PARTITION BY YEAR(lis.first_review)) AS new_accomm_properties
FROM dbo.listings_cleaned AS lis)
SELECT *
	, CAST(CAST(new_accomm_properties AS DECIMAL(10,1)) 
	/ CAST(total_accomm_properties AS DECIMAL(10,1))*100 AS DECIMAL(10,1)) AS percentage_of_increase
FROM cte
ORDER BY year_

-- D. Yearly Trend for Host Growth.
WITH cte AS
(SELECT *
	, RANK() OVER(ORDER BY host_since) rn
FROM dbo.host_profile
)
SELECT YEAR(host_since) AS year_
	, MAX(rn) AS total_hosts
	, COUNT(host_id) AS new_hosts
	, CAST(CAST(COUNT(host_id) AS DECIMAL(10,1)) 
	/ CAST(MAX(rn) AS DECIMAL(10,1))*100 AS DECIMAL(10,1)) AS percentage_of_increase
from cte
group by year(host_since)
order by year(host_since)


--	E. Review Rating Breakdown By Stars.
SELECT DISTINCT ROUND(review_scores_rating, 0) AS star
	, SUM(number_of_reviews) AS number_of_reviews
FROM dbo.listings_cleaned
GROUP BY ROUND(review_scores_rating, 0)
ORDER BY ROUND(review_scores_rating, 0) DESC

--	F. Review Comments Breakdown By Positive/Negative Feedback
---		1. This statement create function to split and count the most used word.
CREATE FUNCTION [dbo].[DelimitedSplitN4K](
    @pString NVARCHAR(4000), 
    @pDelimiter NCHAR(1)
)
RETURNS TABLE WITH SCHEMABINDING AS
RETURN

WITH E1(N) AS (
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),
E2(N) AS (SELECT 1 FROM E1 a, E1 b),
E4(N) AS (SELECT 1 FROM E2 a, E2 b),
cteTally(N) AS(
    SELECT TOP (ISNULL(DATALENGTH(@pString)/2,0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4
),
cteStart(N1) AS (
    SELECT 1 UNION ALL 
    SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@pString,t.N,1) = @pDelimiter
),
cteLen(N1,L1) AS(
    SELECT s.N1,
        ISNULL(NULLIF(CHARINDEX(@pDelimiter,@pString,s.N1),0)-s.N1,4000)
    FROM cteStart s
)
SELECT 
    ItemNumber = ROW_NUMBER() OVER(ORDER BY l.N1),
    Item       = SUBSTRING(@pString, l.N1, l.L1)
FROM cteLen l;

---		2. This statement calls function dbo.DelimitedSplitN4K on dbo.reviews to split words 
---		from comments column, distinct them and counts the number of occurrences.
SELECT TOP 50
    x.Item,
    COUNT(*)
FROM dbo.reviews p
CROSS APPLY dbo.DelimitedSplitN4K(p.comments, ' ') x
WHERE LTRIM(RTRIM(x.Item)) <> ''
GROUP BY x.Item
ORDER BY COUNT(*) DESC

--		3. After creating function dbo.DelimitedSplitN4K and splitting words, 
--		this statement uses key words combination pattern to search and filter 
--		comments into positive and negative categories.

WITH cte AS
(SELECT *
	, CASE 
		WHEN comments LIKE '%not_clean%' 
		OR comments LIKE '%not_nice%'
		OR comments LIKE '%not_recommend%'
		OR comments LIKE '%not_perfect%'
		OR comments LIKE '%not_comfortable%'
		OR comments LIKE '%not_good%'
		OR comments LIKE '%not_well%'
		OR comments LIKE '%not_wonderful%'
		OR comments LIKE '%not_enjoyed%'
		OR comments LIKE '%not_recommend%'
		OR comments LIKE '%not_beautiful%'
		OR comments LIKE '%not_responsive%'
		OR comments LIKE '%not_quite%'
		OR comments LIKE '%not_amazing%'
		OR comments LIKE '%not_convenient%'
		THEN 'negative'
		ELSE 'positive'
     END AS feedback
FROM dbo.reviews)
SELECT DISTINCT feedback, count(*) AS number_of_reviews
FROM cte
GROUP BY feedback

