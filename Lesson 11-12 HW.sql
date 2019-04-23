--Пишем динамические запросы
--1. Загрузить данные из файла StockItems.xml в таблицу StockItems.
--Существующие записи в таблице обновить, отсутствующие добавить (искать по StockItemName).
--Файл StockItems.xml в личном кабинете.

DECLARE 
	 @query	nvarchar(MAX)
	,@path nvarchar(256) = 'C:\BCP\'
	,@fileName nvarchar(256) = 'StockItems.xml'
	,@dbName varchar(255) = '[WideWorldImporters]'
	,@TargetTable varchar(255) = '[Warehouse].[StockItems]';

BEGIN TRY

	IF @FileName IS NOT NULL
	BEGIN

		IF @TargetTable = '[Warehouse].[StockItems]'
		BEGIN

			SET @query = 
			'
				USE '+@dbName+'

				MERGE '+@TargetTable+' AS target
				USING
				(
					SELECT 
						 [Name] = MY_XML.Item.value(''@Name'', ''nvarchar(100)'')
						,[SupplierID] = MY_XML.Item.value(''SupplierID[1]'', ''int'')
						,[UnitPackageID] = MY_XML.Item.value(''Package[1]/UnitPackageID[1]'', ''int'')
						,[OuterPackageID] = MY_XML.Item.value(''Package[1]/OuterPackageID[1]'', ''int'')
						,[QuantityPerOuter] = MY_XML.Item.value(''Package[1]/QuantityPerOuter[1]'', ''int'')
						,[TypicalWeightPerUnit] = MY_XML.Item.value(''Package[1]/TypicalWeightPerUnit[1]'', ''decimal(18,3)'')
						,[LeadTimeDays] = MY_XML.Item.value(''LeadTimeDays[1]'', ''int'')
						,[IsChillerStock] = MY_XML.Item.value(''IsChillerStock[1]'', ''bit'')
						,[TaxRate] = MY_XML.Item.value(''TaxRate[1]'', ''decimal(18,3)'')
						,[UnitPrice] = MY_XML.Item.value(''UnitPrice[1]'', ''decimal(18,2)'')
					FROM
					(
						SELECT cast(MY_XML AS xml)
						FROM OPENROWSET( BULK N'''+@path+@fileName+''', SINGLE_BLOB ) AS T(MY_XML)
					) AS T(MY_XML)
					CROSS APPLY MY_XML.nodes(''StockItems/Item'') AS MY_XML (Item)
				) AS source ([Name], [SupplierID], [UnitPackageID], [OuterPackageID], [QuantityPerOuter], [TypicalWeightPerUnit], [LeadTimeDays], [IsChillerStock], [TaxRate], [UnitPrice])
				ON (target.[StockItemName] = source.[Name])
				WHEN MATCHED
				THEN 
					UPDATE
					SET
						 target.[SupplierID] = source.[SupplierID]
						,target.[UnitPackageID] = source.[UnitPackageID]
						,target.[OuterPackageID] = source.[OuterPackageID]
						,target.[QuantityPerOuter] = source.[QuantityPerOuter]
						,target.[TypicalWeightPerUnit] = source.[TypicalWeightPerUnit]
						,target.[LeadTimeDays] = source.[LeadTimeDays]
						,target.[IsChillerStock] = source.[IsChillerStock]
						,target.[TaxRate] = source.[TaxRate]
						,target.[UnitPrice] = source.[UnitPrice]
				WHEN NOT MATCHED
				THEN 
					INSERT 
						(
							 [StockItemName]
							,[SupplierID]
							,[UnitPackageID]
							,[OuterPackageID]
							,[QuantityPerOuter]
							,[TypicalWeightPerUnit]
							,[LeadTimeDays]
							,[IsChillerStock]
							,[TaxRate]
							,[UnitPrice]
							,[LastEditedBy]
						)
					VALUES 
						(
							 source.[Name]
							,source.[SupplierID]
							,source.[UnitPackageID]
							,source.[OuterPackageID]
							,source.[QuantityPerOuter]
							,source.[TypicalWeightPerUnit]
							,source.[LeadTimeDays]
							,source.[IsChillerStock]
							,source.[TaxRate]
							,source.[UnitPrice]
							,2
						);
			';

			PRINT @query;

			EXEC sp_executesql @query;

			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

		END
		ELSE
		BEGIN

			PRINT 'Не найдено инструкций для указанного объекта';

		END

	END

END TRY
BEGIN CATCH

	SELECT   
		 ERROR_NUMBER() AS ErrorNumber  
		,ERROR_MESSAGE() AS ErrorMessage;

	PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(), 120);

END CATCH

--2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml

DECLARE @query1 nvarchar(max) = 'SELECT [@Name] = [StockItemName], [Package] = (cast((SELECT [UnitPackageID], [OuterPackageID], [QuantityPerOuter], [TypicalWeightPerUnit] FROM [WideWorldImporters].[Warehouse].[StockItems] sip WHERE si.[StockItemID] = sip.[StockItemID] FOR XML PATH ('''''''')) as XML)), [LeadTimeDays], [IsChillerStock], [TaxRate], [UnitPrice] FROM [WideWorldImporters].[Warehouse].[StockItems] si FOR XML PATH (''''Item''''), ROOT (''''StockItems'''')';

-- Запрос сборки xml

--SELECT 
--		 [@Name] = [StockItemName]
--		,[Package] = 
--		(
--			cast
--			(
--				(
--					SELECT 
--						 [UnitPackageID]
--						,[OuterPackageID]
--						,[QuantityPerOuter]
--						,[TypicalWeightPerUnit]
--					FROM [WideWorldImporters].[Warehouse].[StockItems] sip 
--					WHERE si.[StockItemID] = sip.[StockItemID] 
--					FOR XML PATH ('')
--				) 
--				as XML
--			)
--		) 
--		,[LeadTimeDays]
--		,[IsChillerStock]
--		,[TaxRate]
--		,[UnitPrice]
--FROM 
--	[WideWorldImporters].[Warehouse].[StockItems] si
--FOR XML 
--	 PATH ('Item')
--	,ROOT ('StockItems')

DECLARE @bcp nvarchar(max) = 'EXEC xp_cmdshell ''bcp "'+@query1+'" QUERYOUT "C:\BCP\StockItems_OUT.xml" -T -c -t''';

EXEC sp_executesql @bcp;

--3. В таблице StockItems в колонке CustomFields есть данные в json.
--Написать select для вывода:
--- StockItemID
--- StockItemName
--- CountryOfManufacture (из CustomFields)
--- Range (из CustomFields)

SELECT 
	 StockItemID
	,StockItemName
	,JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS [CountryOfManufacture]
	,JSON_VALUE(CustomFields, '$.Range') AS [Range]
FROM [Warehouse].[StockItems];

--4. Найти в StockItems строки, где есть тэг "Vintage"
--Запрос написать через функции работы с JSON.
--Тэги искать в поле CustomFields, а не в Tags.

SELECT si.*
FROM 
	[Warehouse].[StockItems] si
	CROSS APPLY OPENJSON (CustomFields, '$.Tags')
WHERE Value = 'Vintage';

--5. Пишем динамический PIVOT. 
--По заданию из 8го занятия про CROSS APPLY и PIVOT 
--Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
--Название клиента
--МесяцГод Количество покупок

--Нужно написать запрос, который будет генерировать результаты для всех клиентов 
--имя клиента указывать полностью из CustomerName
--дата должна иметь формат dd.mm.yyyy например 25.12.2019

DECLARE @pvtlist nvarchar(max) = 
(
	SELECT
			'[' + c.CustomerName + ']' + ', ' as 'data()'
	FROM
		(
			SELECT DISTINCT CustomerName
			FROM [Sales].[Customers] c
		) c
	FOR XML PATH ('')
)

SET @pvtlist = left(@pvtlist, (len(@pvtlist) - 1))

DECLARE @query nvarchar(max) = 
'
	SELECT selpvt.*
	FROM
	(
		SELECT 
			 [OrderDate]
			,[CustomerName]
			,[OrderID]
		FROM 
			[Sales].[Customers] c
			CROSS APPLY
			(
				SELECT 
					 [OrderDate] = FORMAT(o.[OrderDate], ''d'', ''de-de'')
					,o.[OrderID]
				FROM 
					[Sales].[Orders] o
					INNER JOIN [Sales].[Invoices] i ON o.[OrderID] = i.[OrderID]
				WHERE
					EXISTS
					(
						SELECT ct.[CustomerTransactionID]
						FROM [Sales].[CustomerTransactions] ct
						WHERE 
						ct.[InvoiceID] = i.[InvoiceID]
					)
					AND c.[CustomerID] = o.[CustomerID]
			) oc
	) AS sel
	PIVOT
	(
		count([OrderID])
		FOR [CustomerName] 
		IN 
		('+@pvtlist+')
	) AS selpvt
';

EXEC sp_executesql @query;

