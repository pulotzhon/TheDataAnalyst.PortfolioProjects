/*
	Airbnb Data Cleaning in SQL Server Queries
*/
-- 1. This statement filters dbo.listings table from redundant columns, 
--	  duplicate id and empty rows of first_review and last_review columns. 
--	  The filtered dataset stored and saved in a new dbo.listings_cleaned table.

SELECT DISTINCT id
	, name
	, host_id
	, host_name
	, host_since
	, host_location
	, host_about
	, host_neighbourhood
	, latitude
	, longitude
	, property_type
	, room_type
	, accommodates
	, price
	, minimum_nights
	, maximum_nights
	, number_of_reviews
	, first_review
	, last_review
	, review_scores_rating
	, review_scores_cleanliness
	, review_scores_location
INTO dbo.listings_cleaned
FROM dbo.listings
WHERE first_review is not null AND last_review is not null

-- 2. This statement trim string characters of dbo.listings_cleaned table.

UPDATE dbo.listings_cleaned
SET id = TRIM(id)
	, name = TRIM(name)
	, host_name = TRIM(host_name)
	, host_location = TRIM(host_location)
	, host_about = TRIM(host_about)
	, host_neighbourhood = TRIM(host_neighbourhood)
	, property_type = TRIM(property_type)
	, room_type = TRIM(room_type)

-- 3. This statement delete those records of dbo.listings_cleaned table 
--	  where host_location column is null.

DELETE FROM dbo.listings_cleaned
WHERE host_location IS NULL

-- 4. This statement parce host_location column into 'City' and 'State' and delete
--	  those records which are outside the areas of DC, VA and MD.

DELETE FROM dbo.listings_cleaned
WHERE id IN (SELECT id FROM
				(SELECT id, 
					TRIM(PARSENAME(REPLACE(host_location, ',', '.'), 2)) as City,
					TRIM(PARSENAME(REPLACE(host_location, ',', '.'), 1)) as State
				FROM dbo.listings_cleaned) as x
				WHERE State NOT IN ('DC', 'VA', 'MD'))

-- 5. This statement delete those records of dbo.reviews table where listing_id column
--	  of dbo.reviews table doesn't exist in dbo.listings_cleaned table after being cleaned
--	  from redundant records and null values.

DELETE FROM dbo.reviews
WHERE listing_id not in (SELECT id FROM listings_cleaned )

-- 6. This statement delete those records of dbo.calendar table where listing_id column
--	  of dbo.calendar table doesn't exist in dbo.listings_cleaned table after being cleaned
--	  from redundant records and null values.

DELETE FROM dbo.calendar
WHERE listing_id not in (SELECT id FROM listings_cleaned)

