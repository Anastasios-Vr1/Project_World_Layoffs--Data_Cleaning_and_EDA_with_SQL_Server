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

#### 2.1 Removing Duplicates
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

#### 2.2 Standardizing Data and Converting Data Types
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

#### 2.3 Handling Null Values
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

#### 2.4 Removing Useless Rows and Columns 🧹🗑️
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
