--Домашнее задание
--Insert, Update, Merge
--1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers
--2. удалите 1 запись из Customers, которая была вами добавлена
--3. изменить одну запись, из добавленных через UPDATE
--4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert


--1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers

DECLARE @tmp table (id int);

INSERT INTO Sales.Customers(CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, ValidFrom, ValidTo)
OUTPUT inserted.CustomerID INTO @tmp
VALUES
	 (DEFAULT, 'New Customer 01', 1061, 5, 3261, 3, '19881', '19881', 1000.00, getdate(), 0.000, 0, 0, 7, '(206) 555-0100', '(206) 555-0100', 'http://www.microsoft.com/', 'Shop 12', '652 Victoria Lane', '90243', geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656 )', 4326), 'PO Box 8112', 'Milicaville', '90243', 1, DEFAULT, DEFAULT)
	,(DEFAULT, 'New Customer 02', 1061, 5, 3261, 3, '19881', '19881', 1000.00, getdate(), 0.000, 0, 0, 7, '(206) 555-0100', '(206) 555-0100', 'http://www.microsoft.com/', 'Shop 12', '652 Victoria Lane', '90243', geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656 )', 4326), 'PO Box 8112', 'Milicaville', '90243', 1, DEFAULT, DEFAULT)
	,(DEFAULT, 'New Customer 03', 1061, 5, 3261, 3, '19881', '19881', 1000.00, getdate(), 0.000, 0, 0, 7, '(206) 555-0100', '(206) 555-0100', 'http://www.microsoft.com/', 'Shop 12', '652 Victoria Lane', '90243', geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656 )', 4326), 'PO Box 8112', 'Milicaville', '90243', 1, DEFAULT, DEFAULT)
	,(DEFAULT, 'New Customer 04', 1061, 5, 3261, 3, '19881', '19881', 1000.00, getdate(), 0.000, 0, 0, 7, '(206) 555-0100', '(206) 555-0100', 'http://www.microsoft.com/', 'Shop 12', '652 Victoria Lane', '90243', geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656 )', 4326), 'PO Box 8112', 'Milicaville', '90243', 1, DEFAULT, DEFAULT)
	,(DEFAULT, 'New Customer 05', 1061, 5, 3261, 3, '19881', '19881', 1000.00, getdate(), 0.000, 0, 0, 7, '(206) 555-0100', '(206) 555-0100', 'http://www.microsoft.com/', 'Shop 12', '652 Victoria Lane', '90243', geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656 )', 4326), 'PO Box 8112', 'Milicaville', '90243', 1, DEFAULT, DEFAULT);

--2. удалите 1 запись из Customers, которая была вами добавлена

DELETE FROM Sales.Customers
WHERE CustomerID = (SELECT TOP (1) id FROM @tmp);

--3. изменить одну запись, из добавленных через UPDATE

UPDATE sc
SET DeliveryLocation = geography::STGeomFromText('LINESTRING(-122.360 47.656, -123.345 47.656 )', 4326)
--SELECT *
FROM Sales.Customers sc
WHERE sc.CustomerID = (SELECT TOP (1) id FROM @tmp);

SELECT TOP 10 * FROM Sales.Customers order by CustomerID desc;

--4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
DECLARE @tmp1 table (DeletedCustomerID int, Action varchar(10), InsertedCustomerID int)

MERGE Sales.Customers AS target
USING
(
	SELECT TOP 1 * FROM Sales.Customers ORDER BY CustomerID DESC
) AS source
ON (target.CustomerID = source.CustomerID)
WHEN MATCHED
	THEN UPDATE
	SET
		CustomerName = 'New Customer 06'
WHEN NOT MATCHED
	THEN INSERT (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, ValidFrom, ValidTo)
	VALUES (DEFAULT, 'New Customer 07', 1061, 5, 3261, 3, '19881', '19881', 1000.00, getdate(), 0.000, 0, 0, 7, '(206) 555-0100', '(206) 555-0100', 'http://www.microsoft.com/', 'Shop 12', '652 Victoria Lane', '90243', geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656 )', 4326), 'PO Box 8112', 'Milicaville', '90243', 1, DEFAULT, DEFAULT)
OUTPUT deleted.CustomerID, $action, inserted.CustomerID
INTO @tmp1;

SELECT TOP 10 * 
FROM Sales.Customers 
ORDER BY CustomerID DESC

SELECT * 
FROM @tmp1

--5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert

EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

EXEC master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Customers]" out  "C:\BCP\Customers.txt" -T -w -t"@#$!"'

--NULL
--Starting copy...
--SQLState = S1000, NativeError = 0
--Error = [Microsoft][ODBC Driver 13 for SQL Server]Warning: BCP import with a format file will convert empty strings in delimited columns to NULL.
--NULL
--667 rows copied.
--Network packet size (bytes): 4096
--Clock Time (ms.) Total     : 172    Average : (3877.91 rows per sec.)
--NULL

CREATE TABLE [Sales].[CustomersDemo](
	[CustomerID] [int] NOT NULL IDENTITY(1, 1),
	[CustomerName] [nvarchar](100) NOT NULL,
	[BillToCustomerID] [int] NOT NULL,
	[CustomerCategoryID] [int] NOT NULL,
	[BuyingGroupID] [int] NULL,
	[PrimaryContactPersonID] [int] NOT NULL,
	[AlternateContactPersonID] [int] NULL,
	[DeliveryMethodID] [int] NOT NULL,
	[DeliveryCityID] [int] NOT NULL,
	[PostalCityID] [int] NOT NULL,
	[CreditLimit] [decimal](18, 2) NULL,
	[AccountOpenedDate] [date] NOT NULL,
	[StandardDiscountPercentage] [decimal](18, 3) NOT NULL,
	[IsStatementSent] [bit] NOT NULL,
	[IsOnCreditHold] [bit] NOT NULL,
	[PaymentDays] [int] NOT NULL,
	[PhoneNumber] [nvarchar](20) NOT NULL,
	[FaxNumber] [nvarchar](20) NOT NULL,
	[DeliveryRun] [nvarchar](5) NULL,
	[RunPosition] [nvarchar](5) NULL,
	[WebsiteURL] [nvarchar](256) NOT NULL,
	[DeliveryAddressLine1] [nvarchar](60) NOT NULL,
	[DeliveryAddressLine2] [nvarchar](60) NULL,
	[DeliveryPostalCode] [nvarchar](10) NOT NULL,
	[DeliveryLocation] [geography] NULL,
	[PostalAddressLine1] [nvarchar](60) NOT NULL,
	[PostalAddressLine2] [nvarchar](60) NULL,
	[PostalPostalCode] [nvarchar](10) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
	[ValidTo] [datetime2](7) NOT NULL
)

DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;

	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'C:\BCP\';
	SET @FileName = 'Customers.txt';
	/*******************************************************************/
	/*******************************************************************/
	/*******************************************************************/

	SET @onlyScript = 1;

	BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[CustomersDemo]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@#$!'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH

SELECT * FROM Sales.CustomersDemo

	--BULK INSERT [WideWorldImporters].[Sales].[CustomersDemo]
	--			   FROM "C:\BCP\Customers.txt"
	--			   WITH 
	--				 (
	--					BATCHSIZE = 1000, 
	--					DATAFILETYPE = 'widechar',
	--					FIELDTERMINATOR = '@#$!',
	--					ROWTERMINATOR ='\n',
	--					KEEPNULLS,
	--					TABLOCK        
	--				  );