-- Exploratory Data Analysis - Project World Layoffs

--Dataset: https://www.kaggle.com/datasets/swaptr/layoffs-2022

SELECT * 
FROM dbo.layoffs_staging

-- Initial Data Standardization Queries

ALTER TABLE dbo.layoffs_staging
ALTER COLUMN total_laid_off INT

UPDATE dbo.layoffs_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off  = 'NULL'

ALTER TABLE dbo.layoffs_staging
ALTER COLUMN percentage_laid_off DECIMAL

UPDATE dbo.layoffs_staging
SET funds_raised_millions = NULL
WHERE funds_raised_millions  = 'NULL'

ALTER TABLE dbo.layoffs_staging
ALTER COLUMN funds_raised_millions DEC

-- Beginning of Exploratory Data Analysis (EDA)

-- Identifing the highest number of layoffs on a single day, which is 12,000

SELECT MAX(total_laid_off) AS Max_laid_off
FROM dbo.layoffs_staging
WHERE total_laid_off IS NOT NULL

-- The top 5 companies with the highest total layoffs are all major U.S. tech giants 
--These significant reductions highlight widespread adjustments in the tech industry following the pandemic-driven hiring surge.
/*
Amazon	18150
Google	12000
Meta	11000
Salesf	10090
Micsft	10000
*/

SELECT TOP 5
	company,
	SUM(total_laid_off) as total_laid_off
FROM
	dbo.layoffs_staging
GROUP BY 
	company
ORDER BY
	total_laid_off DESC

-- Alternative approach using a CTE, Window Function, and Subquery
-- If TOP 5 is not desired or if you want to include companies tied with the same total layoffs

WITH CTE_layoffs AS 
(
    SELECT
        company,
        SUM(total_laid_off) AS total_laid_off
    FROM 
		dbo.layoffs_staging
    GROUP BY 
		company
)
SELECT *
FROM 
	(SELECT
		company,
		total_laid_off,
		DENSE_RANK () OVER (ORDER BY total_laid_off DESC) AS d_rnk
	 FROM
		CTE_layoffs
	) AS Ranked_companies
WHERE d_rnk < 6

	
-- Analyzing total employees laid off by location (city):

-- The top 3 cities with the highest layoffs— SF Bay Area, Seattle, and NYC—are all located in the U.S.
-- The gap between SF Bay Area (1st) and Seattle (2nd) is significant, with 90,888 more layoffs in SF
-- Finally, 6 out of the top 10 cities with the highest layoffs are located in the U.S.

SELECT TOP 10 
	location, 
	SUM(total_laid_off) AS total_laid_off_per_location
FROM 
	dbo.layoffs_staging
GROUP BY 
	location
ORDER BY 2 DESC


-- Analyzing total employees laid off by country:

-- The United States leads significantly with 256,559 layoffs, far surpassing other countries.
-- India follows with 35,993 layoffs, reflecting a notable difference from the U.S.
-- The Netherlands, Sweden, and Brazil round out the top five, with considerably fewer layoffs, highlighting the global impact but with varying scales by country

SELECT 
	Country,
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE 
	total_laid_off IS NOT NULL
GROUP BY 
	country
ORDER BY 
	total_laid_off DESC

-- Layoffs per year analysis:

-- 2022 saw the highest number of layoffs at 160,661, indicating a peak year for job cuts
-- Despite having only 3 months! of data, 2023 already shows 125,677 layoffs, suggesting a potentially higher figure by year-end
-- 2020 had significant layoffs (80,998), likely driven by the early pandemic impact, while 2021 showed a stark decrease to 15,823, perhaps reflecting a recovery period.

SELECT 
	YEAR(date) AS year, 
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE 
	total_laid_off IS NOT NULL AND
	YEAR(date) IS NOT NULL
GROUP BY 
	YEAR(date)
ORDER BY 2 DESC


-- Layoffs by industry analysis:
-- Consumer and Retail sectors lead the layoffs, with over 45,000 and 43,000 job cuts, reflecting economic shifts impacting consumer behavior
-- Other industries, including Transportation and Finance, also faced substantial layoffs, each exceeding 28,000 employees affected
-- In contrast, highly specialized sectors like Legal, Energy, Aerospace, Fin-Tech, and Manufacturing experienced minimal layoffs, with Manufacturing recording just 20 layoffs, highlighting their resilience or smaller workforce.

SELECT 
	industry, 
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY 2 DESC

-- Layoffs by industry per year analysis:

-- Transportation had high layoffs in 2022 (15,227) and 2020 (14,656), with Healthcare close behind in 2022 (15,058) indicating a significant impact on these sectors over recent years
-- Consumer & Retail: Significant layoffs in 2023, with Consumer at 15,663 and Retail at 13,609, reflect ongoing adjustments and cost-cutting
-- Emerging Trends: Increased layoffs in Hardware and Marketing in 2023 highlight shifting industry dynamics and cost-cutting.

SELECT 
	industry, 
	YEAR(DATE) AS year,
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE 
	industry IS NOT NULL AND
	total_laid_off IS NOT NULL
GROUP BY 
	industry,
	YEAR(DATE)
ORDER BY 
	total_laid_off DESC,
	year desc

--Identifing companies where 100% of employees were laid off (percentage_laid_off = 1).
--The majority are startups (124 out of 173), mostly in Series A to C funding stages, and all went out of business during this period.
/*
Series B 39
Seed	 34
Series A 29
Series C 22
...
*/

SELECT 
	stage, 
	COUNT(*) AS cnt
FROM 
	dbo.layoffs_staging
WHERE 
	percentage_laid_off = 1
AND 
	stage NOT IN( 'NULL', 'Unknown')
GROUP BY stage
ORDER BY 
	cnt DESC, 
	stage ASC

-- Further researching companies where 100% of employees were laid off (percentage_laid_off = 1)
-- The results are ordered by the amount of funds raised to show the largest companies first, highlighting those with the highest financial backing

-- Note: Both London based companies OneWeb and BritishVolt, are among the top 4. Despite raising $3 billion and $2.4 billion respectively, both went out of business
-- Also, Magic Leap, a Miami-based company, despite raising $2.6 billion, went under.

SELECT 
	company,
	location,
	industry,
	stage,
	country,
	funds_raised_millions,
	SUM (total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE  
	percentage_laid_off = 1 AND
	total_laid_off IS NOT NULL AND
	funds_raised_millions IS NOT NULL
GROUP BY
	company,
	location,
	industry,
	stage,
	country,
	funds_raised_millions
ORDER BY 
	funds_raised_millions DESC


-- Total Layoffs per Month Analysis

-- January stands out with the highest number of layoffs, exceeding 92,000, likely due to seasonal adjustments or economic downturns.
-- November is the second-highest with over 55,000 layoffs, potentially reflecting year-end restructuring efforts
-- Layoffs taper off significantly from August to October, with September recording the lowest figure of just 6,651, suggesting a relative stabilization in the job market during this period
-- The mid-year months (April to July) show consistent layoff activity, hovering between 23,000 and 38,000.

SELECT 
	MONTH(date) AS Months,
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE 
	MONTH(date) IS NOT NULL
GROUP BY
	MONTH(date)
ORDER BY
	Months ASC

	
-- Using a CTE to compute the "Rolling Total of Layoffs Per Month"
-- This allows to track cumulative layoffs over time and analyze trends in workforce reductions.

WITH Monthly_cte AS 
(
SELECT 
	MONTH(date) AS Months,
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE 
	MONTH(date) IS NOT NULL
GROUP BY
	MONTH(date)
)
SELECT 
	Months, 
	total_laid_off,
	SUM(total_laid_off) OVER (ORDER BY Months ASC) as rolling_total_layoffs
FROM 
	Monthly_cte
ORDER BY 
	Months ASC

-- Analysis of companies with most layoffs by year ranked (top-5)

--Key Insights:
--Travel & Hospitality: In 2020, companies like Uber and Booking.com experienced significant layoffs due to COVID-19's impact
--Tech Sector Trends: Major U.S. tech giants, including Google, Amazon, and Microsoft, have had substantial layoffs in both 2022 and 2023, reflecting ongoing industry adjustments following the pandemic-driven hiring surge.

WITH year_cte AS 
(
SELECT 
	company,
	Year(date) AS year,
	SUM(total_laid_off) AS total_laid_off
FROM 
	dbo.layoffs_staging
WHERE 
	YEAR(date) IS NOT NULL
GROUP BY
	company,
	YEAR(date)
), 

Ranking_cte AS
(
SELECT *, DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) as d_rank
FROM year_cte
)

SELECT * 
FROM Ranking_cte 
WHERE d_rank <= 5
