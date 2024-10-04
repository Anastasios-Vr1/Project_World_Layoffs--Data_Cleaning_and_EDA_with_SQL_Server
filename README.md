# Introduction
### Overview
📊 **This project focuses on analyzing global layoffs data** in two parts: **data cleaning** and **exploratory data analysis (EDA)**. The dataset was sourced from **Kaggle**, and after an initial data cleaning phase, which involved **removing duplicates**, **fixing format issues**, and **handling missing values**, the cleaned data was used for analysis. 

The exploratory data analysis uncovered **key trends and insights**, such as **industry-specific layoffs**, **company-wise impacts**, and **geographical distribution of layoffs**. Detailed steps for each part of the project are covered later in the readme.

##### 🔍 SQL queries? Check them out here: [Data Cleaning](Data_Cleaning_Project_World_layoffs.sql) & [Exploratory Data Analysis](Exploratory_Data_Analysis_Project_World_Layoffs.sql).

### Data Source
Layoffs Dataset: This dataset includes information on layoffs across multiple industries, although many companies operate with a tech-driven focus. The data provides details such as company name, location, number of employees laid off, and the percentage of workforce affected. The dataset was sourced from Kaggle to explore global layoffs amid economic slowdowns. [Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022)🗃️

### Tools Used
SQL Server: Utilized for data cleaning, transformations, and conducting exploratory data analysis.

# Part 1: Data Cleaning 🧼

### Objective
- **Goal**: Ensure data accuracy and consistency for meaningful analysis by removing duplicates, handling null values, and standardizing key columns
  
### Steps Taken
1. Created the Staging Table  
2. Standardized the data  
3. Handled NULL values, converted data types & applied a self-join to enhance highly correlated records with NULL values  
4. Eliminated Useless Rows and Columns  
5. Removed duplicates


#### 1.1 Creating the Staging Table
A staging table (`layoffs_staging`) was created to preserve the original data and safely perform data cleaning operations.
The `layoffs_staging` table replicates the structure of the original `layoffs` table, and all data was copied into it for processing.

```sql
SELECT * 
INTO layoffs_staging
FROM layoffs
```

### 1.2 Standardizing Data
Fixing format issues: Addressed country data, standardizing "United States" and correcting location names like "Düsseldorf," "Florianópolis," and "Malmö."
Industry data: Standardized industry names, such as combining "Crypto" and "Crypto Currency" into one.

```sql
UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United States.'

UPDATE layoffs_staging
SET location = 'Düsseldorf'
WHERE location LIKE '%sseldorf'

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'
```

- **Trimming leading and trailing whitespace from columns for enhanced data integrity**

```sql
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
```

### 1.3 Handling & Standardizing NULL Values, Blanks

- **Spotted interesting NULL values** in the `industry` column (Airbnb, Juul, Carvana, Bally's Interactive) and cleaned them.

```sql
UPDATE layoffs_staging
SET industry = NULL
WHERE industry IN ('Null', 'NULL', 'null', '')
```

- Cleaned `total_laid_off`, `percentage_laid_off`, `date`, `stage`, and `funds_raised_millions` columns by setting invalid values to `NULL`.

```sql
UPDATE layoffs_staging
SET total_laid_off = NULL
WHERE total_laid_off IN ('Null', 'NULL', 'null', '')

UPDATE layoffs_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off IN ('Null', 'NULL', 'null', '')
```

- **Used a self-join** to populate missing `industry` values when the information was available for the same company elsewhere.

```sql
UPDATE layoff2
SET layoff2.industry = layoff1.industry
FROM layoffs_staging layoff2
JOIN layoffs_staging layoff1
ON layoff2.company = layoff1.company
WHERE layoff2.industry IS NULL
AND layoff1.industry IS NOT NULL
```

- **Converted data types** for important columns (`date` to `DATE`, `total_laid_off` to `INT`, `percentage_laid_off` and `funds_raised_millions` to `DECIMAL`).

```sql
ALTER TABLE layoffs_staging
ALTER COLUMN date DATE

ALTER TABLE layoffs_staging
ALTER COLUMN total_laid_off INT

ALTER TABLE layoffs_staging
ALTER COLUMN percentage_laid_off DECIMAL

ALTER TABLE layoffs_staging
ALTER COLUMN funds_raised_millions DECIMAL
```


### 1.4 Eliminating Useless Rows and Columns to Enhance Performance

- Removed rows where both `total_laid_off` and `percentage_laid_off` were `NULL` to optimize performance

```sql
DELETE 
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
```

### 1.5 Removing Duplicates

- Used `ROW_NUMBER()` to identify and remove duplicate rows based on key columns like `company`, `location`, and `industry`

```sql
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
      ORDER BY company ASC) AS row_num
  FROM layoffs_staging
)

DELETE 
FROM cte_duplicates
WHERE row_num > 1  -- Deletes duplicates where row number is greater than 1
```

 **Note**: The complete set of queries and the detailed data cleaning process can be found in the accompanying SQL file in this repository: [Data_Cleaning_Project_World_layoffs.sql](Data_Cleaning_Project_World_layoffs.sql).

# Part 2: Exploratory Data Analysis (EDA) 🔍

### Objective
- Analyze the cleaned data to uncover trends, patterns, and insights across industries, companies, and geographical locations affected by layoffs.

### Key Insights💡

#### 2.1 Highest Number of Layoffs in a Single Day
- The **highest number of layoffs on a single day** was 12,000.

```sql
SELECT MAX(total_laid_off) AS Max_laid_off
FROM dbo.layoffs_staging
WHERE total_laid_off IS NOT NULL
```

#### 2.2 Top 5 Companies with the Most Layoffs
- The top 5 companies with the highest total layoffs are all **major U.S. tech giants**(Amazon (18,150), Google (12,000), Meta (11,000), Salesforce (10,090), and Microsoft (10,000)
- These layoffs reflect the significant industry adjustments following the pandemic-driven hiring surge.

```sql
SELECT TOP 5
	company,
	SUM(total_laid_off) as total_laid_off
FROM
	dbo.layoffs_staging
GROUP BY 
	company
ORDER BY
	total_laid_off DESC
```

#### 2.3 Layoffs by Location (City)
- The **SF Bay Area, Seattle, and NYC** are the top three cities with the highest layoffs, all located in the U.S.
- There’s a **significant gap** between SF Bay Area (1st) and Seattle (2nd), with SF having 90,888 more layoffs.

```sql
SELECT TOP 10 
	location, 
	SUM(total_laid_off) AS total_laid_off_per_location
FROM 
	dbo.layoffs_staging
GROUP BY 
	location
ORDER BY 2 DESC

```

#### 2.4 Layoffs by Country
- The **United States leads** with 256,559 layoffs, far surpassing other countries like India (35,993).
- The top five countries are rounded out by the Netherlands, Sweden, and Brazil.

```sql
SELECT
	country,
	SUM(total_laid_off) AS total_laid_off
FROM
	dbo.layoffs_staging
GROUP BY
	country
ORDER BY
	total_laid_off DESC
```

#### 2.5 Layoffs by Year
- 2022 had the **highest number of layoffs** at 160,661, with 2023 already showing 125,677 layoffs (with only 3 months of data).
- The year 2020 saw 80,998 layoffs, likely due to the early pandemic impact, while 2021 had a sharp decrease (15,823), indicating some recovery.

```sql
SELECT
	YEAR(date) AS year, 
	SUM(total_laid_off) AS total_laid_off
FROM
	dbo.layoffs_staging
GROUP BY
	YEAR(date)
ORDER BY
	total_laid_off DESC
```

#### 2.6 Layoffs by Industry
- **Consumer and Retail sectors** lead the layoffs with over 45,000 and 43,000 job cuts, respectively.
- Other notable sectors include **Transportation** (15,227 layoffs in 2022) and **Finance**.
- Specialized sectors like **Legal**, **Energy**, and **Aerospace** experienced fewer layoffs, reflecting their resilience or smaller workforce.

```sql
SELECT
	industry,
	SUM(total_laid_off) AS total_laid_off
FROM
	dbo.layoffs_staging
GROUP BY
	industry
ORDER BY
	total_laid_off DESC
```

#### 2.7 Companies with Full Workforce Layoffs
- The **majority of companies** where 100% of employees were laid off were startups, primarily in Series A to C funding stages.
- Some notable examples include **OneWeb** and **BritishVolt**, which raised $3 billion and $2.4 billion, respectively, but still went out of business.

```sql
SELECT
	stage, 
	COUNT(*) AS cnt
FROM
	dbo.layoffs_staging
WHERE
	percentage_laid_off = 1
GROUP BY
	stage
ORDER BY
	cnt DESC
```

#### 2.8 Layoffs per Month
- **January** stands out with the highest number of layoffs (92,037), followed by **November** (55,758), likely due to seasonal adjustments or year-end restructuring efforts.

```sql
SELECT
	MONTH(date) AS Months,
	SUM(total_laid_off) AS total_laid_off
FROM
	dbo.layoffs_staging
GROUP BY
	MONTH(date)
ORDER BY
	Months ASC
```

#### 2.9 Companies with the Most Layoffs by Year (Top 5)
- **Travel & Hospitality**: In 2020, companies like **Uber** and **Booking.com** saw substantial layoffs due to COVID-19’s impact.
- **Tech Sector Trends**: Major U.S. tech giants such as **Google**, **Amazon**, and **Microsoft** experienced significant layoffs in both 2022 and 2023, reflecting ongoing industry adjustments following the pandemic-driven hiring spree.

```sql
WITH year_cte AS (
    SELECT 
        company,
        YEAR(date) AS year,
        SUM(total_laid_off) AS total_laid_off
    FROM
	dbo.layoffs_staging
    WHERE
	YEAR(date) IS NOT NULL
    GROUP BY
	company,
	YEAR(date)
), 
Ranking_cte AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) as d_rank
    FROM year_cte
)
SELECT * 
FROM Ranking_cte 
WHERE d_rank <= 5
```

**Note**: The complete SQL queries and additional exploratory data analysis can be found in the accompanying SQL file in this repository: [Exploratory_Data_Analysis_Project_World_Layoffs.sql](Exploratory_Data_Analysis_Project_World_Layoffs.sql).


# 3. Conclusions 🖋️

### Insights 
From the analysis of global layoffs data, several key trends and insights emerged:

1. **Tech Industry Dominance**: U.S. tech giants, such as Amazon, Google, and Microsoft, led the layoffs in both 2022 and 2023, reflecting significant post-pandemic adjustments.
2. **Geographical Impact**: The U.S. saw the highest number of layoffs, with the SF Bay Area, Seattle, and NYC being the most affected cities. Global hotspots include India, the Netherlands, and Sweden.
3. **Sector-Specific Layoffs**: Consumer and Retail sectors were hit hardest, while specialized industries like Legal, Energy, and Aerospace experienced minimal reductions.
4. **Pandemic-Driven Layoffs**: Travel and hospitality companies, such as Uber and Booking.com, faced major layoffs in 2020 due to COVID-19, while other sectors showed more resilience.
5. **Emerging Trends**: Increased layoffs in 2023 in sectors like Hardware and Marketing reflect ongoing market shifts and cost-cutting efforts.

### Final Remarks 
This project provided valuable insights into global layoffs trends, highlighting the sectors and regions most affected by workforce reductions. By leveraging SQL Server for both data cleaning and exploratory data analysis, the analysis uncovered trends that reflect economic shifts and industry-specific challenges.

The conclusions drawn from this project offer actionable insights into the industries most impacted by the economic slowdown. As the dataset continues to grow, there may be further opportunities to analyze additional trends, particularly with visualizations or deeper sector-specific analyses.
