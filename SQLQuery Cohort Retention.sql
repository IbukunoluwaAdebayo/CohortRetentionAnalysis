SELECT *
FROM [Online Retail]

--Cleaning Data in SQL
-- Total records = 541909

SELECT *
FROM [Online Retail]
WHERE CustomerID IS NULL

-- 135080 Records have no CustomerID
-- Creating CTE

;With [Online Retail] AS
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [Retention Analysys].[dbo].[Online Retail]
	  WHERE CustomerID IS NOT NULL
), Quantity_unit_price AS
(
	SELECT *
	FROM [Online Retail]
	WHERE  Quantity > 0 AND UnitPrice > 0
)
, Duplicate_check AS
-- Checking for duplicates
(
	SELECT *, ROW_NUMBER () over (partition by InvoiceNo, StockCode, Quantity Order by InvoiceDate) AS DuplicateFlag
	FROM Quantity_unit_price
)

-- Create a temp table

SELECT *
INTO #ONLINE_RETAIL_MAIN
FROM Duplicate_check
WHERE DuplicateFlag = 1

-- Clean data
SELECT *
FROM #ONLINE_RETAIL_MAIN

-- Begin Cohort Analysis
-- Unique identifier (CustomerID)
-- Initial Start Date ( First Invoice Date)
-- Revenue Data 

SELECT CustomerID, 
	MIN(InvoiceDate) AS First_Purchase_Date,
	DATEFROMPARTS (YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) AS CohortDate
INTO #COHORT
FROM #ONLINE_RETAIL_MAIN
GROUP BY CustomerID

SELECT *
FROM #COHORT

-- Creating a Cohort Index
-- Joining tables #Cohort and #Online_Retail_Main
-- Creating Subqueries

	SELECT
		PRA.*,
		cohort_index = year_diff * 12 + month_diff + 1
		INTO #Cohort_retention
	FROM 
	(
		SELECT 
			PR.*,
			year_diff = Invoice_year - Cohort_year,
			month_diff = Invoice_month - Cohort_month
			FROM 
				(
				SELECT 
					RETAIL.*,
					COH.CohortDate,
					YEAR(retail.InvoiceDate) AS Invoice_Year,
					MONTH(RETAIL.INVOICEDATE) AS Invoice_Month,
					YEAR( COH.COHORTDATE) AS Cohort_Year,
					MONTH(COH.COHORTDATE) AS Cohort_Month
			FROM #ONLINE_RETAIL_MAIN AS RETAIL
			LEFT JOIN #COHORT AS COH
			ON RETAIL.CustomerID = COH.CustomerID
		)PR
	)PRA

-- Pivot data to see the cohort table

SELECT *
INTO #Cohort_pivot
FROM
	(
SELECT DISTINCT
	CustomerID,
	CohortDate,
	cohort_index
 FROM #Cohort_retention
) TBL
PIVOT(
	COUNT (CUSTOMERID)
	FOR COHORT_INDEX IN
	(
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[8],
	[9],
	[10],
	[11],
	[12],
	[13])
) AS PIVOT_TABLE

SELECT 
		1.0 * [1]/[1] * 100 AS [1stMonthPrcnt],
		1.0 * [2]/[1] * 100 AS [2ndMonthPrcnt],
		1.0 * [3]/[1] * 100 AS [3rdMonthPrcnt],
		1.0 * [4]/[1] * 100 AS [4thMonthPrcnt],
		1.0 * [5]/[1] * 100 AS [5thMonthPrcnt],
		1.0 * [6]/[1] * 100 AS [6thMonthPrcnt],
		1.0 * [7]/[1] * 100 AS [7thMonthPrcnt],
		1.0 * [8]/[1] * 100 AS [8thMonthPrcnt],
		1.0 * [9]/[1] * 100 AS [9thMonthPrcnt],
		1.0 * [10]/[1] * 100 AS [10thMonthPrcnt],
		1.0 * [11]/[1] * 100 AS [11thMonthPrcnt],
		1.0 * [12]/[1] * 100 AS [12thMonthPrcnt],
		1.0 * [13]/[1] * 100 AS [13thMonthPrcnt]
FROM #Cohort_pivot
ORDER BY CohortDate