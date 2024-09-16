# Introduction
### Overview
📊This project focuses on analyzing global layoffs data in two parts: data cleaning and exploratory data analysis (EDA). The dataset was sourced from Kaggle, and after an initial data cleaning phase, which involved removing duplicates, fixing format issues, and handling missing values, the cleaned data was used for analysis. The exploratory data analysis uncovered key trends and insights, such as industry-specific layoffs, company-wise impacts, and geographical distribution of layoffs. Detailed steps for each part of the project are covered later in the readme.

##### 🔍 SQL queries? Check them out here: [Data Cleaning](Data_Cleaning_Project_World_layoffs.sql) & [Exploratory Data Analysis](Exploratory_Data_Analysis_Project_World_Layoffs.sql).

### Data Source
Layoffs Dataset: This dataset includes information on layoffs across multiple industries, although many companies operate with a tech-driven focus. The data provides details such as company name, location, number of employees laid off, and the percentage of workforce affected. The dataset was sourced from Kaggle to explore global layoffs amid economic slowdowns. [Kaggle](https://www.kaggle.com/datasets/swaptr/layoffs-2022)🗃️

### Tools Used
SQL Server: Utilized for data cleaning, transformations, and conducting exploratory data analysis.

# Part 1: Data Cleaning 🧼

### Objective
- **Goal**: Ensure data accuracy and consistency for meaningful analysis by removing duplicates, handling null values, and standardizing key columns
- **Focus**: Remove duplicates, handle null values, and standardize key columns.
  
### Steps Taken

#### 2.1 Creating the Staging Table
A staging table (layoffs_staging) was created to preserve the original data and safely perform data cleaning operations.
The layoffs_staging table replicates the structure of the original dbo.layoffs table, and all data was copied into it for processing.

```sql
SELECT * 
INTO layoffs_staging
FROM dbo.layoffs

```

#### 2.2 Removing Duplicates
- Used `ROW_NUMBER()` to identify duplicate rows based on key columns such as company, location, industry, total laid off, and other fields
- Deleted all duplicate rows, keeping only the first occurrence for each group.

```sql
WITH cte_duplicates AS (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY
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
  FROM dbo.layoffs_staging
)
DELETE FROM cte_duplicates
WHERE row_num > 1
```

#### 2.3 Standardizing Data and Converting Data Types
- **Trimming spaces**: Cleaned unnecessary spaces in the `company` column
- **Standardizing industry names**: Fixed inconsistent naming for industry categories like "Crypto" and "Crypto Currency"
- **Correcting location names**: Updated non-standard location names (e.g., "Dusseldorf" to "Düsseldorf")
- **Converting `date` column**: Converted `date` from `varchar` to `DATE` type after cleaning invalid date entries.

```sql
UPDATE dbo.layoffs_staging
SET company = TRIM(company)

UPDATE dbo.layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'

ALTER TABLE dbo.layoffs_staging
ALTER COLUMN date DATE
```

#### 2.4 Handling Null Values
- Identified rows with `NULL` or blank values in key columns like `industry`
- Used a self-join to populate missing `industry` values from matching rows.

```sql
UPDATE t2
SET t2.industry = t1.industry
FROM dbo.layoffs_staging t2
JOIN dbo.layoffs_staging t1 ON t2.company = t1.company AND t2.location = t1.location
WHERE t2.industry IS NULL
AND t1.industry IS NOT NULL
```

#### 2.5 Removing Useless Rows and Columns 🧹🗑️
- Removed rows where both `total_laid_off` and `percentage_laid_off` were marked as `NULL`
- Dropped unnecessary columns after cleaning.

```sql
DELETE FROM dbo.layoffs_staging
WHERE total_laid_off = 'NULL'
AND percentage_laid_off = 'NULL'

ALTER TABLE dbo.layoffs_staging
DROP COLUMN row_num
```

 **Note**: The complete set of queries and the detailed data cleaning process can be found in the accompanying SQL file in this repository: [Data_Cleaning_Project_World_layoffs.sql](Data_Cleaning_Project_World_layoffs.sql).

## Part 2: Exploratory Data Analysis (EDA)

### Objective
- Analyze the cleaned data to uncover trends, patterns, and insights across industries, companies, and geographical locations affected by layoffs.

### Key Insights

#### 3.1 Highest Number of Layoffs in a Single Day
- The **highest number of layoffs on a single day** was 12,000.

```sql
SELECT MAX(total_laid_off) AS Max_laid_off
FROM dbo.layoffs_staging
WHERE total_laid_off IS NOT NULL
```

#### 3.2 Top 5 Companies with the Most Layoffs
- The top 5 companies with the highest total layoffs are all **major U.S. tech giants**(Amazon (18,150), Google (12,000), Meta (11,000), Salesforce (10,090), and Microsoft (10,000). These layoffs reflect the significant industry adjustments following the pandemic-driven hiring surge.

```sql
SELECT TOP 5
	company,
	SUM(total_laid_off) AS total_laid_off
FROM dbo.layoffs_staging
GROUP BY company
ORDER BY total_laid_off DESC
```

#### 3.3 Layoffs by Location (City)
- The **SF Bay Area, Seattle, and NYC** are the top three cities with the highest layoffs, all located in the U.S.
- There’s a **significant gap** between SF Bay Area (1st) and Seattle (2nd), with SF having 90,888 more layoffs.

```sql
SELECT TOP 10
	location, 
	SUM(total_laid_off) AS total_laid_off_per_location
FROM dbo.layoffs_staging
GROUP BY location
ORDER BY total_laid_off_per_location DESC
```

#### 3.4 Layoffs by Country
- The **United States leads** with 256,559 layoffs, far surpassing other countries like India (35,993).
- The top five countries are rounded out by the Netherlands, Sweden, and Brazil.

```sql
SELECT country,
	SUM(total_laid_off) AS total_laid_off
FROM dbo.layoffs_staging
GROUP BY country
ORDER BY total_laid_off DESC
```

#### 3.5 Layoffs by Year
- 2022 had the **highest number of layoffs** at 160,661, with 2023 already showing 125,677 layoffs (with only 3 months of data).
- The year 2020 saw 80,998 layoffs, likely due to the early pandemic impact, while 2021 had a sharp decrease (15,823), indicating some recovery.

```sql
SELECT YEAR(date) AS year, 
	SUM(total_laid_off) AS total_laid_off
FROM dbo.layoffs_staging
GROUP BY YEAR(date)
ORDER BY total_laid_off DESC
```

#### 3.6 Layoffs by Industry
- **Consumer and Retail sectors** lead the layoffs with over 45,000 and 43,000 job cuts, respectively.
- Other notable sectors include **Transportation** (15,227 layoffs in 2022) and **Finance**.
- Specialized sectors like **Legal**, **Energy**, and **Aerospace** experienced fewer layoffs, reflecting their resilience or smaller workforce.

```sql
SELECT industry,
	SUM(total_laid_off) AS total_laid_off
FROM dbo.layoffs_staging
GROUP BY industry
ORDER BY total_laid_off DESC
```

#### 3.7 100% Layoffs per Company
- The **majority of companies** where 100% of employees were laid off were startups, primarily in Series A to C funding stages.
- Some notable examples include **OneWeb** and **BritishVolt**, which raised $3 billion and $2.4 billion, respectively, but still went out of business.

```sql
SELECT stage, 
	COUNT(*) AS cnt
FROM dbo.layoffs_staging
WHERE percentage_laid_off = 1
GROUP BY stage
ORDER BY cnt DESC
```

#### 3.8 Layoffs per Month
- **January** stands out with the highest number of layoffs (92,037), followed by **November** (55,758), likely due to seasonal adjustments or year-end restructuring efforts.

```sql
SELECT MONTH(date) AS Months,
	SUM(total_laid_off) AS total_laid_off
FROM dbo.layoffs_staging
GROUP BY MONTH(date)
ORDER BY Months ASC
```

Yes, that query is significant, as it highlights the companies with the most layoffs by year and includes insights into the impact of COVID-19 on the travel and hospitality sectors, as well as ongoing tech industry adjustments. Here's how we can include it:

---

#### 3.9 Companies with the Most Layoffs by Year (Top 5)
- **Travel & Hospitality**: In 2020, companies like **Uber** and **Booking.com** saw substantial layoffs due to COVID-19’s impact.
- **Tech Sector Trends**: Major U.S. tech giants such as **Google**, **Amazon**, and **Microsoft** experienced significant layoffs in both 2022 and 2023, reflecting ongoing industry adjustments following the pandemic-driven hiring spree.

```sql
WITH year_cte AS (
    SELECT 
        company,
        YEAR(date) AS year,
        SUM(total_laid_off) AS total_laid_off
    FROM dbo.layoffs_staging
    WHERE YEAR(date) IS NOT NULL
    GROUP BY company, YEAR(date)
), 
Ranking_cte AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) as d_rank
    FROM year_cte
)
SELECT * 
FROM Ranking_cte 
WHERE d_rank <= 5
```

> **Note**: The complete SQL queries and additional exploratory data analysis can be found in the accompanying SQL file in this repository: [Exploratory_Data_Analysis_Project_World_Layoffs.sql](Exploratory Data Analysis_Project_World_Layoffs.sql)

