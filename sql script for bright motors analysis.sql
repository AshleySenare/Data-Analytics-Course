-- Quick preview (returns first rows)
SELECT *
FROM Car_Sales
LIMIT 10;


-- 1) Basic counts
SELECT COUNT(*) AS total_rows
FROM Car_Sales;


-- 2) Detect exact duplicate rows
--    (Group by all columns present in the table)
SELECT
    YEAR, MAKE, MODEL, TRIM, BODY, TRANSMISSION, VIN, STATE,
    CONDITION, ODOMETER, COLOR, INTERIOR, SELLER, MMR, SELLINGPRICE, SALEDATE,
    COUNT(*) AS dup_count
FROM Car_Sales
GROUP BY
    YEAR, MAKE, MODEL, TRIM, BODY, TRANSMISSION, VIN, STATE,
    CONDITION, ODOMETER, COLOR, INTERIOR, SELLER, MMR, SELLINGPRICE, SALEDATE
HAVING COUNT(*) > 1
ORDER BY dup_count DESC;


-- 3) Missing / NULL checks (rows where any critical field is null)
SELECT *
FROM Car_Sales
WHERE YEAR IS NULL
   OR MAKE IS NULL
   OR MODEL IS NULL
   OR TRIM IS NULL
   OR BODY IS NULL
   OR TRANSMISSION IS NULL
   OR VIN IS NULL
   OR STATE IS NULL
   OR CONDITION IS NULL
   OR ODOMETER IS NULL
   OR COLOR IS NULL
   OR INTERIOR IS NULL
   OR SELLER IS NULL
   OR MMR IS NULL
   OR SELLINGPRICE IS NULL
   OR SALEDATE IS NULL
LIMIT 200;


-- 4) Example of normalising missing body values using COALESCE (Snowflake uses COALESCE or NVL)
SELECT BODY,
       COALESCE(BODY, 'No_Data') AS BODY2
FROM Car_Sales
LIMIT 20;


-- 5) Robustly parse sale timestamps into a Snowflake TIMESTAMP_NTZ and DATE
--    Many of your sample values looked like: 'Tue Dec 16 2014 12:30:00'
--    We'll try a few formats; any non-parseable entries will return NULL.
SELECT
    SALEDATE AS raw_saledate,
    TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS')        AS sale_ts_dy_mon,
    TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH:MI:SS')          AS sale_ts_dy_mon_12h,
    CAST(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS') AS DATE)  AS sale_date,
    CAST(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH:MI:SS')    AS DATE)  AS sale_date_alt
FROM Car_Sales
LIMIT 50;


-- 6) Distinct make & model list (fixed trailing comma & ORDER syntax)
SELECT DISTINCT MAKE, MODEL
FROM Car_Sales
ORDER BY MAKE, MODEL;


-- 7) Count of sales per make
SELECT MAKE,
       COUNT(*) AS total_cars
FROM Car_Sales
GROUP BY MAKE
ORDER BY total_cars DESC;


-- 8) Average selling price per make (fixed table name typo 'Motors' -> 'Motor')
SELECT MAKE,
       ROUND(AVG(SELLINGPRICE), 2) AS AVG_PRICE
FROM Car_Sales
GROUP BY MAKE
ORDER BY AVG_PRICE ASC;


-- 9) Monthly average selling price
--    Convert SALEDATE to a DATE first, then truncate to month.
SELECT DATE_TRUNC('month',
        CAST(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS') AS DATE)
       ) AS sale_month,
       ROUND(AVG(SELLINGPRICE), 2) AS avg_price
FROM Car_Sales
GROUP BY sale_month
ORDER BY sale_month;


-- 10) Total cars sold per year (robust extraction)
SELECT EXTRACT(YEAR FROM CAST(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS') AS DATE)) AS sale_year,
FROM Car_Sales
GROUP BY sale_year
ORDER BY sale_year;


-- 11) Detailed timestamp breakdown: date, time, day name
SELECT
    TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS')                       AS sale_timestamp,
    DAYNAME(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS'))              AS day_name,
    CAST(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS') AS DATE)         AS sale_date,
    TO_CHAR(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS')::TIME, 'HH24:MI:SS') AS sale_time
FROM Car_Sales
LIMIT 50;


-- 12) Compare selling price with MMR by make/model
SELECT MAKE,
       MODEL,
       ROUND(AVG(SELLINGPRICE), 2) AS AVG_SELLINGPRICE,
       ROUND(AVG(MMR), 2)          AS AVG_MMR,
       ROUND(AVG(SELLINGPRICE - MMR), 2) AS AVG_DIFFERENCE
FROM Car_Sales
GROUP BY MAKE, MODEL
ORDER BY AVG_DIFFERENCE ASC;


-- 13) Cars sold above MMR
SELECT *
FROM Car_Sales
WHERE SELLINGPRICE > MMR
LIMIT 200;


-- 14) Average selling Price by CONDITION
SELECT CONDITION,
       ROUND(AVG(SELLINGPRICE), 2) AS AVG_PRICE
FROM Car_Sales
GROUP BY CONDITION
ORDER BY CONDITION ASC;


-- 15) Relationship between mileage and price (use CASE then group)
SELECT
  CASE
    WHEN TRY_TO_NUMBER(ODOMETER) < 20000 THEN 'Low Mileage'
    WHEN TRY_TO_NUMBER(ODOMETER) BETWEEN 20000 AND 60000 THEN 'Medium Mileage'
    WHEN TRY_TO_NUMBER(ODOMETER) IS NULL THEN 'Unknown Mileage'
    ELSE 'High Mileage'
  END AS mileage_category,
  ROUND(AVG(SELLINGPRICE), 2) AS avg_price
FROM Car_Sales
GROUP BY mileage_category
ORDER BY avg_price ASC;


-- 16) Average price per state
SELECT STATE,
       ROUND(AVG(SELLINGPRICE), 2) AS avg_price
FROM Car_Sales
GROUP BY STATE
ORDER BY avg_price ASC;


-- 17) Top 10 states (by total sales) -- fixed ORDER direction and limit
SELECT STATE,
       COUNT(*) AS total_sales
FROM Car_Sales
GROUP BY STATE
ORDER BY total_sales DESC
LIMIT 10;


-- 18) Most sold color (top colors)
SELECT COLOR,
       COUNT(*) AS total
FROM Car_Sales
GROUP BY COLOR
ORDER BY total DESC
LIMIT 20;


-- 19) Transmission counts & avg price
SELECT TRANSMISSION,
       COUNT(*) AS total_sales,
       ROUND(AVG(SELLINGPRICE), 2) AS avg_price
FROM Car_Sales
GROUP BY TRANSMISSION
ORDER BY total_sales DESC;


-- 20) Seller with highest average selling price (only sellers with >10 sales)
SELECT SELLER,
       COUNT(*) AS total_sales,
       ROUND(AVG(SELLINGPRICE), 2) AS avg_price
FROM Car_Sales
GROUP BY SELLER
HAVING COUNT(*) > 10
ORDER BY avg_price DESC;


-- =========================================================
-- 21) CREATE A CLEAN TABLE (canonical typed columns)
--    This is the proper "clean" layer to downstream.
-- =========================================================

SELECT
    -- Parse and cast date safely
    CAST(TRY_TO_TIMESTAMP_NTZ(SALEDATE, 'DY MON DD YYYY HH24:MI:SS') AS DATE)          AS SALE_DATE,

    -- Numeric columns using TRY_TO_NUMBER to avoid failure on bad strings
    TRY_TO_NUMBER(SELLINGPRICE)                                                       AS SALES,
    TRY_TO_NUMBER(MMR)                                                                AS COST_OF_SALES,

    -- One car per row
    1                                                                                 AS QUANTITY_SOLD,

    -- Keep canonical descriptive columns (trim strings)
    TRY_TO_NUMBER(YEAR)                                                              AS YEAR_NUM,
    TRIM(MAKE)                                                                       AS MAKE,
    TRIM(MODEL)                                                                      AS MODEL,
    TRIM(TRIM)                                                                       AS MODEL_TRIM,
    TRIM(BODY)                                                                        AS BODY,
    TRIM(TRANSMISSION)                                                                AS TRANSMISSION,
    TRIM(VIN)                                                                         AS VIN,
    TRIM(STATE)                                                                       AS STATE,
    TRY_TO_NUMBER(CONDITION)                                                          AS CONDITION_SCORE,
    TRY_TO_NUMBER(ODOMETER)                                                           AS ODOMETER,
    TRIM(COLOR)                                                                       AS COLOR,
    TRIM(INTERIOR)                                                                    AS INTERIOR,
    TRIM(SELLER)                                                                      AS SELLER
FROM Car_Sales;


-- Quick sanity preview
SELECT *
FROM Car_Sales
LIMIT 20;


-- =========================================================
-- 22) CREATE PROCESSED TABLE (derived metrics)
-- =========================================================

-- =========================================================

SELECT
    -- parse/alias the date column from the raw table (handles formats like "Tue Dec 16 2014 12:30:00")
    CAST(
      TRY_TO_TIMESTAMP_NTZ(saledate, 'DY MON DD YYYY HH24:MI:SS')
      AS DATE
    ) AS SALE_DATE,

    -- numeric conversions (use TRY_TO_NUMBER so bad strings become NULL instead of breaking the query)
    TRY_TO_NUMBER(sellingprice) AS SALES,
    TRY_TO_NUMBER(mmr)         AS COST_OF_SALES,

    -- one row per car
    1                          AS QUANTITY_SOLD,

    -- keep other descriptive columns (trim strings and cast where appropriate)
    TRY_TO_NUMBER("YEAR")      AS YEAR_NUM,
    TRIM(MAKE)                 AS MAKE,
    TRIM(MODEL)                AS MODEL,
    TRIM(TRIM)                 AS MODEL_TRIM,
    TRIM(BODY)                 AS BODY,
    TRIM(TRANSMISSION)         AS TRANSMISSION,
    TRIM(VIN)                  AS VIN,
    TRIM(STATE)                AS STATE,
    TRY_TO_NUMBER(CONDITION)   AS CONDITION_SCORE,
    TRY_TO_NUMBER(ODOMETER)    AS ODOMETER,
    TRIM(COLOR)                AS COLOR,
    TRIM(INTERIOR)             AS INTERIOR,
    TRIM(SELLER)               AS SELLER

FROM CAR_SALES;  



-- Preview processed
SELECT *
FROM Car_Sales
LIMIT 20;

----cleaned up colmns
SELECT
    -- base / cleaned columns
    CAST(TRY_TO_TIMESTAMP_NTZ(saledate, 'DY MON DD YYYY HH24:MI:SS') AS DATE) AS SALE_DATE,
    TRY_TO_NUMBER(sellingprice) AS SALES,
    TRY_TO_NUMBER(mmr)         AS COST_OF_SALES,
    1                          AS QUANTITY_SOLD,
    TRY_TO_NUMBER("YEAR")      AS YEAR_NUM,
    TRIM(MAKE)                 AS MAKE,
    TRIM(MODEL)                AS MODEL,
    TRIM(TRIM)                 AS MODEL_TRIM,
    TRIM(BODY)                 AS BODY,
    TRIM(TRANSMISSION)         AS TRANSMISSION,
    TRIM(VIN)                  AS VIN,
    TRIM(STATE)                AS STATE,
    TRY_TO_NUMBER(CONDITION)   AS CONDITION_SCORE,
    TRY_TO_NUMBER(ODOMETER)    AS ODOMETER,
    TRIM(COLOR)                AS COLOR,
    TRIM(INTERIOR)             AS INTERIOR,
    TRIM(SELLER)               AS SELLER,

    -- derived metrics
    (COALESCE(TRY_TO_NUMBER(sellingprice),0) * 1) AS TOTAL_REVENUE,

    CASE WHEN 1 = 0 THEN NULL
         ELSE ROUND(TRY_TO_NUMBER(sellingprice) / 1, 2)
    END AS PRICE_PER_UNIT,

    (TRY_TO_NUMBER(sellingprice) - TRY_TO_NUMBER(mmr)) AS GROSS_PROFIT,

    CASE WHEN TRY_TO_NUMBER(sellingprice) IS NULL OR TRY_TO_NUMBER(sellingprice) = 0 THEN NULL
         ELSE ROUND(((TRY_TO_NUMBER(sellingprice) - TRY_TO_NUMBER(mmr)) / TRY_TO_NUMBER(sellingprice)) * 100, 2)
    END AS PROFIT_MARGIN_PERCENT,

    CASE
      WHEN TRY_TO_NUMBER(sellingprice) IS NULL OR TRY_TO_NUMBER(mmr) IS NULL THEN 'UNKNOWN'
      WHEN ((TRY_TO_NUMBER(sellingprice) - TRY_TO_NUMBER(mmr)) / NULLIF(TRY_TO_NUMBER(sellingprice),0)) * 100 >= 40 THEN 'HIGH MARGIN'
      WHEN ((TRY_TO_NUMBER(sellingprice) - TRY_TO_NUMBER(mmr)) / NULLIF(TRY_TO_NUMBER(sellingprice),0)) * 100 BETWEEN 20 AND 39.99 THEN 'MEDIUM MARGIN'
      ELSE 'LOW MARGIN'
    END AS MARGIN_CATEGORY,

    DATE_TRUNC('month', CAST(TRY_TO_TIMESTAMP_NTZ(saledate, 'DY MON DD YYYY HH24:MI:SS') AS DATE))   AS SALE_MONTH,
    DATE_TRUNC('quarter', CAST(TRY_TO_TIMESTAMP_NTZ(saledate, 'DY MON DD YYYY HH24:MI:SS') AS DATE)) AS SALE_QUARTER,
    DATE_TRUNC('year', CAST(TRY_TO_TIMESTAMP_NTZ(saledate, 'DY MON DD YYYY HH24:MI:SS') AS DATE))    AS SALE_YEAR

FROM CAR_SALES;




-- =========================================================
-- 23) SUMMARY AGGREGATES (examples)
-- =========================================================
-- Total Revenue
SELECT ROUND(SUM(sellingprice),2) AS TOTAL_REVENUE
FROM CAR_SALES;


--- margin ranking
SELECT 
    *,
    CASE
        WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 40 THEN 'HIGH MARGIN'
        WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 BETWEEN 20 AND 39.99 THEN 'MEDIUM MARGIN'
        ELSE 'LOW MARGIN'
    END AS MARGIN_CATEGORY
FROM CAR_SALES;

-- 
SELECT
   CASE
        WHEN ((sellingprice - mmr) / NULLIF(sellingprice,0)) * 100 >= 40 THEN 'HIGH MARGIN'
        WHEN ((sellingprice - mmr) / NULLIF(sellingprice,0)) * 100 BETWEEN 20 AND 39.99 THEN 'MEDIUM MARGIN'
        ELSE 'LOW MARGIN'
   END AS MARGIN_CATEGORY,
   COUNT(*)
FROM CAR_SALES
GROUP BY 1;



--- revenue by month
SELECT
    DATE_TRUNC('month', TRY_TO_TIMESTAMP_NTZ(saledate, 'DY MON DD YYYY HH24:MI:SS')) AS sale_month,
    ROUND(SUM(sellingprice), 2) AS monthly_revenue
FROM CAR_SALES
GROUP BY sale_month
ORDER BY sale_month;

-- =========================================================
-- 24) FINAL EXPORT TABLE (ready for CSV export)
-- =========================================================

SELECT *
FROM CAR_SALES;


-- Quick check
SELECT *
from CAR_SALES
LIMIT 50;


-- =========================================================
-- 25) final processed data
--   
-- =========================================================


SELECT 
    MAX(TRY_TO_TIMESTAMP(saledate, 'DY MON DD YYYY HH:MI:SS')) AS New_SaleDate,
    YEAR(MAX(TRY_TO_TIMESTAMP(saledate, 'DY MON DD YYYY HH:MI:SS'))) AS New_Year,
    MONTHNAME(MAX(TRY_TO_TIMESTAMP(saledate, 'DY MON DD YYYY HH:MI:SS'))) AS Month,
    MAKE,
    MODEL,
    MAX(sellingprice) AS max_selling_price,
    MIN(sellingprice) AS min_selling_price,
    AVG(sellingprice) AS avg_selling_price,
    AVG(odometer) AS avg_mileage,
    MAX(odometer) AS max_mileage,
    MIN(odometer) AS min_mileage,
    COUNT(*) AS total_sales,
    SUM(COALESCE(sellingprice,0)) AS total_revenue,
    CASE
        WHEN MAX(sellingprice) < 100000 THEN 'BUDGET'
        WHEN MAX(sellingprice) BETWEEN 100000 AND 220000 THEN 'MID_RANGE'
        ELSE 'EXPENSIVE'
    END AS price_bucket,
    CASE 
        WHEN MAX(odometer) < 20000 THEN 'Low Mileage'
        WHEN MAX(odometer) BETWEEN 20000 AND 60000 THEN 'Medium Mileage'
        ELSE 'High Mileage'
    END AS mileage_category
FROM CAR_SALES
GROUP BY MAKE, MODEL;
