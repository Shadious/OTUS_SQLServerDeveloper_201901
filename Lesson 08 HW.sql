-- Pivot и Cross Apply
-- 1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
-- Название клиента/МесяцГод/Количество покупок
   
-- Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
-- имя клиента нужно поменять так чтобы осталось только уточнение 
-- например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
-- дата должна иметь формат dd.mm.yyyy например 25.12.2019
   
-- 2. Для всех клиентов с именем, в котором есть Tailspin Toys
-- вывести все адреса, которые есть в таблице в одной колоке
   
-- 3. В таблице стран есть поля с кодом страны цифровым и буквенным
-- сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код
   
-- 4. Перепишите ДЗ из оконных функций через CROSS APPLY 
-- Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
-- В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки
   
-- 5. Code review (опционально). Запрос приложен в материалы Hometask_code_review.sql. 
-- Что делает запрос? 
-- Чем можно заменить CROSS APPLY - можно ли использовать другую стратегию выборки\запроса?

--========================================================================================================

-- 1. Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
-- Название клиента/МесяцГод/Количество покупок

-- Клиентов взять с ID 2-6, это все подразделение Tailspin Toys
-- имя клиента нужно поменять так чтобы осталось только уточнение 
-- например исходное Tailspin Toys (Gasport, NY) - вы выводите в имени только Gasport,NY
-- дата должна иметь формат dd.mm.yyyy например 25.12.2019

SELECT selpvt.*
FROM
(
	SELECT 
		 [OrderDate]
		,[CustomerName] = replace(replace([CustomerName], left([CustomerName], charindex('(', [CustomerName], 0)), ''), ')', '')
		,[OrderID]
	FROM 
		[Sales].[Customers] c
		CROSS APPLY
		(
			SELECT 
				 [OrderDate] = FORMAT(o.[OrderDate], 'd', 'de-de')
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
	WHERE
		c.[CustomerID] BETWEEN 2 AND 6
) AS sel
PIVOT
(
	count([OrderID])
	FOR [CustomerName] 
	IN 
	(
		 [Sylvanite, MT]
		,[Peeples Valley, AZ]
		,[Medicine Lodge, KS]
		,[Gasport, NY]
		,[Jessie, ND]
	)
) AS selpvt

-- 2. Для всех клиентов с именем, в котором есть Tailspin Toys
-- вывести все адреса, которые есть в таблице в одной колонке

-- Вариант с UNION:
SELECT DISTINCT 
	 c.[CustomerName]
	,[Address]
FROM 
	[Sales].[Customers] c
	CROSS APPLY
	(
		SELECT [DeliveryAddressLine1] AS [Address]
		FROM [Sales].[Customers] c1
		WHERE c.[CustomerID] = c1.[CustomerID]

		UNION

		SELECT [DeliveryAddressLine2] AS [Address]
		FROM [Sales].[Customers] c1
		WHERE c.[CustomerID] = c1.[CustomerID]

		UNION

		SELECT [PostalAddressLine1] AS [Address]
		FROM [Sales].[Customers] c1
		WHERE c.[CustomerID] = c1.[CustomerID]

		UNION

		SELECT [PostalAddressLine2] AS [Address]
		FROM [Sales].[Customers] c1
		WHERE c.[CustomerID] = c1.[CustomerID]
	) adr
WHERE
	c.[CustomerName] LIKE 'Tailspin Toys%'
ORDER BY [Address] ASC;

-- Вариант с UNPIVOT:
SELECT 
	 CustomerName
	,cunpvt.[Address]
FROM
(
	SELECT
		 [CustomerName]
		,[DeliveryAddressLine1]
		,[DeliveryAddressLine2]
		,[PostalAddressLine1]
		,[PostalAddressLine2]
	FROM [Sales].[Customers] c
	WHERE c.[CustomerName] LIKE 'Tailspin Toys%'
) c
UNPIVOT
(
	[Address] 
	FOR [AddressType] 
	IN ([DeliveryAddressLine1], [DeliveryAddressLine2], [PostalAddressLine1], [PostalAddressLine2])
) cunpvt

-- 3. В таблице стран есть поля с кодом страны цифровым и буквенным
-- сделайте выборку ИД страны, название, код - чтобы в поле был либо цифровой либо буквенный код

SELECT
	 [CountryID]
	,[CountryName]
	,ac.[CountryCode]
FROM 
	[Application].[Countries] c
	OUTER APPLY
	(
		SELECT [IsoAlpha3Code] AS [CountryCode]
		FROM [Application].[Countries] c1
		WHERE c.[CountryID] = c1.[CountryID]

		UNION

		SELECT CAST([IsoNumericCode] AS nvarchar(3)) AS [CountryCode]
		FROM [Application].[Countries] c1
		WHERE c.[CountryID] = c1.[CountryID]
	) ac

-- 4. Перепишите ДЗ из оконных функций через CROSS APPLY 
-- Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
-- В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

SELECT  
	 c1.CustomerID
	,c1.CustomerName
	,c1.StockItemID
	,c1.UnitPrice
	,b.[TransactionDate]
FROM 
	(
		SELECT
			 c.CustomerID
			,c.CustomerName
			,a.StockItemID
			,a.UnitPrice
		FROM
			Sales.Customers c
			CROSS APPLY
			(
				SELECT DISTINCT TOP 2 
					 si.StockItemID
					,si.UnitPrice
				FROM
					Sales.Orders o
					INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
					INNER JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
					INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID
				WHERE 
					c.CustomerID = o.CustomerID
					AND EXISTS
					(
						SELECT InvoiceID
						FROM Sales.CustomerTransactions ct1
						WHERE ct1.InvoiceID = i.InvoiceID
					)
				ORDER BY si.UnitPrice DESC
			) a
	) c1
	CROSS APPLY
	(
		SELECT TOP 1 ct.TransactionDate
		FROM
			Sales.Orders o
			INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
			INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID
			INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
		WHERE
			ol.StockItemID = c1.StockItemID
			AND o.CustomerID = c1.CustomerID
		ORDER BY ct.TransactionDate DESC
	) b
ORDER BY 
	 CustomerID ASC
	,UnitPrice DESC;

-- 5. Code review (опционально). Запрос приложен в материалы Hometask_code_review.sql. 
-- Что делает запрос? 
-- Чем можно заменить CROSS APPLY - можно ли использовать другую стратегию выборки\запроса?

--SELECT 
--	 T.FolderId
--	,T.FileVersionId
--	,T.FileId		
--FROM 
--	dbo.vwFolderHistoryRemove FHR
--	CROSS APPLY 
--	(
--		SELECT TOP 1 
--			 FileVersionId
--			,FileId
--			,FolderId
--			,DirId
--		FROM #FileVersions V
--		WHERE 
--			RowNum = 1
--			AND DirVersionId <= FHR.DirVersionId
--		ORDER BY V.DirVersionId DESC
--	) T 
--WHERE 
--	FHR.[FolderId] = T.FolderId
--	AND FHR.DirId = T.DirId
--	AND EXISTS 
--	(
--		SELECT 1 
--		FROM #FileVersions V 
--		WHERE V.DirVersionId <= FHR.DirVersionId
--	)
--	AND NOT EXISTS 
--	(
--		SELECT 1
--		FROM dbo.vwFileHistoryRemove DFHR
--		WHERE 
--			DFHR.FileId = T.FileId
--			AND DFHR.[FolderId] = T.FolderId
--			AND DFHR.DirVersionId = FHR.DirVersionId
--			AND NOT EXISTS 
--			(
--				SELECT 1
--				FROM dbo.vwFileHistoryRestore DFHRes
--				WHERE 
--					DFHRes.[FolderId] = T.FolderId
--					AND DFHRes.FileId = T.FileId
--					AND DFHRes.PreviousFileVersionId = DFHR.FileVersionId
--			)
--	)

--Запрос выбирает предыдущую версию файла

SELECT 
	 FV.FolderId
	,FV.FileVersionId
	,FV.FileId		
FROM 
	dbo.vwFolderHistoryRemove FHR
	INNER JOIN #FileVersions FV ON
		FHR.[FolderId] = FV.FolderId
		AND FHR.DirId = FV.DirId
		AND FV.RowNum = 1
		AND FV.DirVersionId <= FHR.DirVersionId
		AND FHR.PreviousFileVersionId = FV.FileVersionId
