--Check Rows Count
SELECT Count(*) as rowscount_2009_2010 from [H&MCustomerAnalytics].dbo.[2009_2010]
SELECT Count(*) as rowscount_2010_2011 from [H&MCustomerAnalytics].dbo.[2010_2011]


-- COMBINE BOTH YEARS AND CONVERT TYPES SAFELY

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,

    COALESCE(
        TRY_CONVERT(datetime2, InvoiceDate, 120),
        TRY_CONVERT(datetime2, InvoiceDate, 105)
    ) AS InvoiceDate,

    TRY_CONVERT(decimal(10,2), Price) AS Price,
    Customer_ID,
    Country,
    '2009-2010' AS SourceSheet

INTO dbo.RetailCombined

FROM dbo.[2009_2010]

UNION ALL

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,

    COALESCE(
        TRY_CONVERT(datetime2, InvoiceDate, 120),
        TRY_CONVERT(datetime2, InvoiceDate, 105)
    ) AS InvoiceDate,

    TRY_CONVERT(decimal(10,2), Price) AS Price,
    Customer_ID,
    Country,
    '2010-2011' AS SourceSheet

FROM dbo.[2010_2011];


-- CONFIRM THE CONVERSION WORKED CLEANLY

SELECT COUNT(*) AS Total_Rows
FROM dbo.RetailCombined;

SELECT COUNT(*) AS Failed_Dates
FROM dbo.RetailCombined
WHERE InvoiceDate IS NULL;

SELECT COUNT(*) AS Failed_Prices
FROM dbo.RetailCombined
WHERE Price IS NULL;





-- CHECK 1 – MISSING CUSTOMER ID
SELECT COUNT(*) AS Missing_CustomerID
FROM dbo.RetailCombined
WHERE Customer_ID IS NULL;


-- CHECK 2 – NEGATIVE OR ZERO QUANTITY
SELECT COUNT(*) AS Negative_Qty
FROM dbo.RetailCombined
WHERE Quantity <= 0;


-- CHECK 3 – MISSING DESCRIPTION
SELECT COUNT(*) AS Missing_Description
FROM dbo.RetailCombined
WHERE Description IS NULL;


-- CHECK 4 – EXACT DUPLICATE ROWS
SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country,
    COUNT(*) AS ExactDuplicateCount
FROM dbo.RetailCombined
GROUP BY
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country
HAVING COUNT(*) > 1;


-- DEDUPLICATE AND PRODUCE THE FINAL CLEANED TABLE

WITH Deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice, StockCode, Description,
                         Quantity, InvoiceDate, Price,
                         Customer_ID, Country
            ORDER BY (SELECT NULL)
        ) AS RowNum
    FROM dbo.RetailCombined
)

SELECT Invoice, StockCode, Description, Quantity,
       InvoiceDate, Price, Customer_ID, Country, SourceSheet
INTO dbo.RetailCleaned
FROM Deduped
WHERE RowNum = 1;




SELECT * From dbo.RetailCleaned