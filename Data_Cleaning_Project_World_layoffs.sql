-- SQL Project - Data Cleaning - World Layoffs

--Dataset: https://www.kaggle.com/datasets/swaptr/layoffs-2022


SELECT *
FROM dbo.layoffs

--Firstly, the layoffs_staging table is created. This is the one to work in and clean the data. The initial layoffs table stays intact with the raw data in case something happens
--This following query will create the table layoffs_staging with the same structure as dbo.layoffs and insert all data from dbo.layoffs into it

SELECT *
INTO layoffs_staging
FROM dbo.layoffs


-----Data Cleaning Steps-----

--1. Check for Duplicates and remove any
--2. Standarize the data & fix errors
--3. Look at Null values or Blank values
--4. Remove Useless Columns & Rows


----------1. Remove Duplicates


WITH cte_duplicates AS
(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY 
		company, 
		location, 
		industry, 
		total_laid_off, 
		percentage_laid_off, 
		date,
		stage, 
		country, 
		funds_raised_millions 
		ORDER BY company asc) AS row_num
FROM dbo.layoffs_staging
)

DELETE 
FROM cte_duplicates
WHERE row_num>1		-- these are the ones to delete where the row number is > 1 or 2 or greater essentially


----------2.Standarize the Data

--Trimming off the unwanted spacing before & after the values in the company column

SELECT company, TRIM(company) AS trim
FROM dbo.layoffs_staging
ORDER BY company ASC


UPDATE dbo.layoffs_staging
SET company = TRIM(company)

--Industry data format issues found and standarized:

--'Crypto' & 'Crypto Currency' are and should be treated as one industry essentialy, so	Updated that below

SELECT industry 
FROM dbo.layoffs_staging
GROUP BY industry
ORDER BY industry ASC

UPDATE dbo.layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'

--Location data format issues found(some special charachers weren't recognized by the import wizard) so they got standarized:

--Düsseldorf vs. Dusseldorf
--Florianópolis vs. Florianapolis 
--Malmö vs. Malmo
--Non-U.S.?? noted

SELECT location
FROM dbo.layoffs_staging
GROUP BY location
ORDER BY location ASC

UPDATE dbo.layoffs_staging
SET location = 'Düsseldorf'
WHERE location LIKE 'Dusseldorf'

UPDATE dbo.layoffs_staging
SET location = 'Florianópolis'
WHERE location LIKE 'Florianapolis'

UPDATE dbo.layoffs_staging
SET location = 'Malmö'
WHERE location LIKE 'Malm%'

--Country data format issues found and standarized

--United States. 

SELECT DISTINCT country	
FROM dbo.layoffs_staging
ORDER BY country 

UPDATE dbo.layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United States.'

--Converting the date column into a DATE type
--Found one row had a value not in a valid date format, so addressed/Updated that and Altered the column afterwards

SELECT *
FROM dbo.layoffs_staging
WHERE ISDATE(date) = 0

UPDATE dbo.layoffs_staging
SET date = NULL
WHERE ISDATE(date) = 0

ALTER TABLE dbo.layoffs_staging
ALTER COLUMN date DATE

----------3. Null Values or Blank Values

SELECT *
FROM dbo.layoffs_staging
WHERE
	industry IS NULL 
	OR
	industry = '' 
	OR
	industry = 'NULL'
ORDER BY 
	industry ASC

--Spotted the NULL values(industry column):

--Airbnb
--Juul
--Carvana
--Bally's Interactive

SELECT *
FROM dbo.layoffs_staging
WHERE industry IS NULL

--Changing it to NULL from initialy being Blank or text ='NULL'

UPDATE dbo.layoffs_staging 
SET industry = NULL
WHERE industry LIKE ''
OR industry LIKE 'NULL'

--Using a self join to populate the NULL industry values where info is available in another row with the same company name etc.
--This query makes it easy so if there were thousands NULL industry values it would match and populate them instead of having to manually check them all

SELECT *
FROM dbo.layoffs_staging t1
JOIN dbo.layoffs_staging t2
	ON t1.company = t2.company
	AND t1.location = t2.location 
WHERE t2.industry IS NULL   
AND t1.industry  IS NOT NULL
order by 1
 

UPDATE t2 
SET t2.industry = t1.industry
FROM dbo.layoffs_staging t2
JOIN dbo.layoffs_staging t1
	ON t2.company = t1.company
	AND t2.location = t1.location
WHERE t2.industry IS NULL   
AND t1.industry  IS NOT NULL

--Only Bally's Interactive remained NULL as there wasn't any other recocd(row) for Bally's to populate its indusrty value with

----------4. Remove Useless Columns & Rows

DELETE 
FROM dbo.layoffs_staging
WHERE total_laid_off = 'NULL'
AND percentage_laid_off = 'NULL'


ALTER TABLE dbo.layoffs_staging
DROP COLUMN row_num