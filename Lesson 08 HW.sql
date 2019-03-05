-- Pivot � Cross Apply
-- 1. ��������� �������� ������, ������� � ���������� ������ ���������� ��������� ������� ���������� ����:
-- �������� �������/��������/���������� �������
   
-- �������� ����� � ID 2-6, ��� ��� ������������� Tailspin Toys
-- ��� ������� ����� �������� ��� ����� �������� ������ ��������� 
-- �������� �������� Tailspin Toys (Gasport, NY) - �� �������� � ����� ������ Gasport,NY
-- ���� ������ ����� ������ dd.mm.yyyy �������� 25.12.2019
   
-- 2. ��� ���� �������� � ������, � ������� ���� Tailspin Toys
-- ������� ��� ������, ������� ���� � ������� � ����� ������
   
-- 3. � ������� ����� ���� ���� � ����� ������ �������� � ���������
-- �������� ������� �� ������, ��������, ��� - ����� � ���� ��� ���� �������� ���� ��������� ���
   
-- 4. ���������� �� �� ������� ������� ����� CROSS APPLY 
-- �������� �� ������� ������� 2 ����� ������� ������, ������� �� �������
-- � ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������
   
-- 5. Code review (�����������). ������ �������� � ��������� Hometask_code_review.sql. 
-- ��� ������ ������? 
-- ��� ����� �������� CROSS APPLY - ����� �� ������������ ������ ��������� �������\�������?

--========================================================================================================

-- 1. ��������� �������� ������, ������� � ���������� ������ ���������� ��������� ������� ���������� ����:
-- �������� �������/��������/���������� �������

-- �������� ����� � ID 2-6, ��� ��� ������������� Tailspin Toys
-- ��� ������� ����� �������� ��� ����� �������� ������ ��������� 
-- �������� �������� Tailspin Toys (Gasport, NY) - �� �������� � ����� ������ Gasport,NY
-- ���� ������ ����� ������ dd.mm.yyyy �������� 25.12.2019

SELECT 
	 REPLACE(REPLACE([CustomerName], 'Tailspin Toys (', ''), ')', '') AS [CustomerName]
	,[OrderDate]
	,[OrdersQuantity]
FROM 
	[Sales].[Customers] c
	CROSS APPLY
	(
		SELECT 
			 CAST(DAY(o.[OrderDate]) AS nvarchar(2)) + '.' + CAST(MONTH(o.[OrderDate]) AS nvarchar(2)) + '.' + CAST(YEAR(o.[OrderDate]) AS nvarchar(4)) AS [OrderDate]
			,YEAR(o.[OrderDate]) AS [OrderYear]
			,MONTH(o.[OrderDate]) AS [OrderMonth]
			,DAY(o.[OrderDate]) AS [OrderDay]
			,COUNT(o.[OrderID]) AS [OrdersQuantity]
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
		GROUP BY 
			 CAST(DAY(o.[OrderDate]) AS nvarchar(2)) + '.' + CAST(MONTH(o.[OrderDate]) AS nvarchar(2)) + '.' + CAST(YEAR(o.[OrderDate]) AS nvarchar(4))
			,YEAR(o.[OrderDate])
			,MONTH(o.[OrderDate])
			,DAY(o.[OrderDate])
	) oc
WHERE
	c.[CustomerID] BETWEEN 2 AND 6
ORDER BY 
	 [CustomerName] ASC
	,[OrderYear] ASC
	,[OrderDay] ASC;

-- 2. ��� ���� �������� � ������, � ������� ���� Tailspin Toys
-- ������� ��� ������, ������� ���� � ������� � ����� �������

SELECT DISTINCT [Address]
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

-- 3. � ������� ����� ���� ���� � ����� ������ �������� � ���������
-- �������� ������� �� ������, ��������, ��� - ����� � ���� ��� ���� �������� ���� ��������� ���

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

-- 4. ���������� �� �� ������� ������� ����� CROSS APPLY 
-- �������� �� ������� ������� 2 ����� ������� ������, ������� �� �������
-- � ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������

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

-- 5. Code review (�����������). ������ �������� � ��������� Hometask_code_review.sql. 
-- ��� ������ ������? 
-- ��� ����� �������� CROSS APPLY - ����� �� ������������ ������ ��������� �������\�������?

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

--������ �������� ���������� ������ �����

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