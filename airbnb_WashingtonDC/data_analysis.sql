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
---		1. Total Number of Accommodations Booked
SELECT SUM(number_of_reviews) AS TotalNumberOfReviews
FROM dbo.listings_cleaned
-- Outcome: 318948

---		2. Total Number of Hosts
SELECT COUNT(host_id) AS TotalNumberOfHosts
FROM dbo.host_profile
-- Outcome: 2449

---		3. Overall Number of Rates Per Star Rating
SELECT DISTINCT ROUND(review_scores_rating, 0) AS star_rating
	, COUNT(review_scores_rating) AS number_of_rates
FROM dbo.listings_cleaned
GROUP BY ROUND(review_scores_rating, 0)
ORDER BY ROUND(review_scores_rating, 0) DESC
-- Outcome: star_rating		number_of_rates
--			5				3630
--			4				359
--			3				22
--			2				5
--			1				6
--			0				14

-- B. Host Growth by Year
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
