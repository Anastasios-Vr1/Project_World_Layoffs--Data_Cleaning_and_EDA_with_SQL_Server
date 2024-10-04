-- SQL Project - Data Cleaning - World Layoffs

--Dataset: https://www.kaggle.com/datasets/swaptr/layoffs-2022

-----Data Cleaning Steps-----

-- 1. Creating the Staging Table
-- 2. Standarizing the data
-- 3. Handling NULL values, converting data types where nessesary & applying a self-join to enhance records with NULL values by correlating them with closely matched entries
-- 4. Eliminating Useless Rows and Columns 
-- 5. Removing duplicates

---------- 1. Creating the Staging Table

SELECT *
FROM layoffs

--Firstly, the layoffs_staging table is created. This is the one to work in and clean the data. The initial layoffs table stays intact with the raw data in case something happens
--This following query will create the table layoffs_staging with the same structure as dbo.layoffs and insert all data from dbo.layoffs into it

SELECT *
INTO layoffs_staging
FROM layoffs

---------- 2. Standarizing the Data

SELECT * FROM layoffs_staging

--Country data format issues found and standarized
--"United States." 

SELECT DISTINCT country
FROM layoffs_staging
ORDER BY  country ASC

UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United States.'

--Location data format issues found(some special charachers weren't recognized by the import wizard) so they got standarized:

--Düsseldorf vs. Dusseldorf
--Florianópolis vs. Florianapolis 
--Malmö vs. Malmo
--Non-U.S.?? noted

SELECT DISTINCT location
FROM layoffs_staging
ORDER BY location ASC

UPDATE layoffs_staging
SET location = 'Düsseldorf'
WHERE location LIKE '%sseldorf'

UPDATE layoffs_staging
SET location = 'Florianópolis'
WHERE location LIKE 'Florian%polis'

UPDATE layoffs_staging
SET location = 'Malmö'
WHERE location LIKE 'Malm%'

--Industry data format issues found and standarized:
--'Crypto' & 'Crypto Currency' are and should be treated as one industry essentialy, so	Updated that below

SELECT DISTINCT industry 
FROM layoffs_staging
ORDER BY industry ASC

SELECT industry , COUNT(*) CNT
FROM layoffs_staging
GROUP BY industry
ORDER BY industry ASC

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'

-------- 2.1 Trimming leading and trailing whitespace from columns for enhanced data integrity

SELECT * FROM layoffs_staging

UPDATE layoffs_staging
SET
	company = TRIM(company),
	location = TRIM(location),
	industry = TRIM(industry),
	total_laid_off = TRIM(total_laid_off),
    percentage_laid_off = TRIM(percentage_laid_off),
    date = TRIM(date),
    stage = TRIM(stage),
	country = TRIM(country),
	funds_raised_millions = TRIM(funds_raised_millions)

---------- 3. Handling & Standardizing NULL values, Blanks

---Spotted interesting NULL values (industry column) that will populate later below:
	--Airbnb
	--Juul
	--Carvana
	--Bally's Interactive

SELECT 
	industry, 
	COUNT(*) AS CNT
FROM layoffs_staging
WHERE 
	industry IN ('Null', 'NULL', 'null', '')
OR industry IS NULL
GROUP BY industry

UPDATE layoffs_staging
SET industry = NULL
WHERE industry IN ('Null', 'NULL', 'null', '')

---total_laid_off column

SELECT 
	total_laid_off, 
	COUNT(*) AS CNT
FROM layoffs_staging
WHERE 
	total_laid_off IN ('Null', 'NULL', 'null', '')
OR total_laid_off IS NULL
GROUP BY total_laid_off

UPDATE layoffs_staging
SET total_laid_off = NULL
WHERE total_laid_off IN ('Null', 'NULL', 'null', '')

---percentage_laid_off column

SELECT 
	percentage_laid_off, 
	COUNT(*) AS CNT
FROM layoffs_staging
WHERE 
	percentage_laid_off IN ('Null', 'NULL', 'null', '')
OR percentage_laid_off IS NULL
GROUP BY percentage_laid_off

UPDATE layoffs_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off IN ('Null', 'NULL', 'null', '')

---date column

SELECT 
	date, 
	COUNT(*) AS CNT
FROM layoffs_staging
WHERE 
	date IN ('Null', 'NULL', 'null', '')
OR date IS NULL
GROUP BY date

UPDATE layoffs_staging
SET  date = NULL
WHERE date IN ('Null', 'NULL', 'null', '')

---stage column

SELECT 
	stage, 
	COUNT(*) AS CNT
FROM layoffs_staging
WHERE 
	stage IN ('Null', 'NULL', 'null', '')
OR stage IS NULL
GROUP BY stage

UPDATE layoffs_staging
SET  stage = NULL
WHERE stage IN ('Null', 'NULL', 'null', '')

---funds_raised_millions column

SELECT 
	funds_raised_millions, 
	COUNT(*) AS CNT
FROM layoffs_staging
WHERE 
	funds_raised_millions IN ('Null', 'NULL', 'null', '')
OR funds_raised_millions IS NULL
GROUP BY funds_raised_millions

UPDATE layoffs_staging
SET  funds_raised_millions = NULL
WHERE funds_raised_millions IN ('Null', 'NULL', 'null', '')

-------- 3.1 Using a self join to populate the NULL industry values where info is available in another row with the same company name etc.

--This query makes it easy so if there were thousands NULL industry values it would match and populate them instead of having to manually check them all

SELECT 
	layoff1.company, 
	layoff1.industry, 
	layoff1.location, 
	layoff2.company, 
	layoff2.industry, 
	layoff2.location
FROM 
	layoffs_staging layoff1
JOIN layoffs_staging layoff2
	ON layoff1.company = layoff2.company
WHERE 
	layoff1.industry IS NOT NULL
AND layoff2.industry IS NULL
	
UPDATE layoff2
SET layoff2.industry = layoff1.industry
FROM 
	layoffs_staging layoff2
JOIN 
	layoffs_staging layoff1
	ON layoff2.company = layoff1.company
WHERE 
	layoff2.industry IS NULL
AND layoff1.industry IS NOT NULL

--Only Bally's Interactive remained NULL as there wasn't any other recocd(row) for Bally's to populate its indusrty value with

-------- 3.2 Converting data types where nessesary:
		--The "date" column to a DATE type, 
		--"total_laid_off" column to an INTEGER, 
		--"percentage_laid_off" column to a DECIMAL, 
		--"funds_raised_millions" to a DECIMAL

ALTER TABLE layoffs_staging
ALTER COLUMN date DATE

ALTER TABLE layoffs_staging
ALTER COLUMN total_laid_off INT

ALTER TABLE layoffs_staging
ALTER COLUMN percentage_laid_off DECIMAL

ALTER TABLE layoffs_staging
ALTER COLUMN funds_raised_millions DECIMAL

---------- 4. Eliminating Useless Rows and Columns to enhance performance

SELECT * FROM layoffs_staging

DELETE 
FROM layoffs_staging
WHERE total_laid_off  IS NULL
AND percentage_laid_off  IS NULL;

----------5. Removing duplicates

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
FROM layoffs_staging
)

DELETE 
FROM cte_duplicates
WHERE row_num > 1  -- these are the ones to delete where the row number is > 1 or 2 or greater essentially