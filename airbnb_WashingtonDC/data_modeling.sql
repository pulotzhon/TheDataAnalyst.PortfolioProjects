/*
	Airbnb Data Modeling in SQL Server Queries
*/

-- 1. This statement convert host_location column of dbo.listings_cleaned 
--    table into a standartized and consistent format of spelling.

SELECT DISTINCT host_location,
	   TRIM(PARSENAME(REPLACE(host_location, ',', '.'), 2)) as City,
	   TRIM(PARSENAME(REPLACE(host_location, ',', '.'), 1)) as State
FROM dbo.listings_cleaned
WHERE host_location in ('Washington D.C., DC','Washington, D.C., DC')
UPDATE dbo.listings_cleaned
SET host_location = 'Washington, DC'
WHERE host_location in ('Washington D.C., DC','Washington, D.C., DC')

-- 2. This statement select host_location column of dbo.listings_cleaned table split 
--	  into City and State columns and store data into a new dbo.location table.

SELECT host_location
	, TRIM(PARSENAME(REPLACE(host_location, ',', '.'), 2)) as City
	, TRIM(PARSENAME(REPLACE(host_location, ',', '.'), 1)) as State
INTO dbo.location
FROM dbo.listings_cleaned

-- 3. This statement dublicate rows from dbo.location table.

WITH CTE AS(
SELECT host_location,
RN = ROW_NUMBER()OVER(PARTITION BY host_location ORDER BY host_location)
FROM dbo.location
)
DELETE FROM CTE WHERE RN > 1

-- 4. This statement add location_id column with unique values to dbo.location table.

ALTER TABLE dbo.location
add location_id int identity(1,1)

-- 5. This statement add a new location_id column to dbo.listings_cleaned, populate 
--	  its values from dbo.location table creating relationship, and finally drop
--	  redundant column host_location from dbo.listings_cleaned.

ALTER TABLE dbo.listings_cleaned
ADD location_id int

UPDATE dbo.listings_cleaned
SET location_id = loc.location_id
FROM dbo.location loc
INNER JOIN dbo.listings_cleaned lis on loc.host_location = lis.host_location

ALTER TABLE dbo.listings_cleaned
DROP COLUMN host_location

-- 6. This statement set apart host_name, host_since and host_about columns from
--	  dbo.listings_cleaned table into a new dbo.host_profile table by avoiding 
--	  dublicate values.

SELECT DISTINCT host_id
	 , host_name
	 , host_since
	 , host_about
INTO dbo.host_profile
FROM dbo.listings_cleaned
ORDER BY host_since

ALTER TABLE dbo.listings_cleaned
DROP COLUMN host_name, host_since, host_about