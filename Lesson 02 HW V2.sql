-- �������� �������

-- ������� SELECT.
-- �������� ������� ��� ����, ����� ��������:
-- 1. ��� ������, � ������� � �������� ���� ������� urgent ��� �������� ���������� � Animal
-- 2. �����������, � ������� �� ���� ������� �� ������ ������ (����� ������� ��� ��� ������ ����� ���������, ������ �������� ����� JOIN)
-- 3. ������� � ��������� ������, � ������� ���� �������, ������� ��������, � �������� ��������� �������, �������� ����� � ����� ����� ���� ��������� ���� - ������ ����� �� 4 ������, ���� ������ ������ ������ ���� ������, � ����� ������ ����� 100$ ���� ���������� ������ ������ ����� 20. �������� ������� ����� ������� � ������������ �������� ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� ������ ��������, ����� ����, ���� �������. 
-- 4. ������ �����������, ������� ���� ��������� �� 2014� ��� � ��������� Road Freight ��� Post, �������� �������� ����������, ��� ����������� ���� ������������ �����
-- 5. 10 ��������� �� ���� ������ � ������ ������� � ������ ����������, ������� ������� �����.
-- 6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g

	USE WideWorldImporters

	GO

-- 1. ��� ������, � ������� � �������� ���� ������� urgent ��� �������� ���������� � Animal

	SELECT 
		 StockItemID
		,StockItemName
		,UnitPrice
		,RecommendedRetailPrice
	FROM Warehouse.StockItems
	WHERE
		StockItemName LIKE '%urgent%'
		OR StockItemName LIKE 'Animal%'

	GO

-- 2. �����������, � ������� �� ���� ������� �� ������ ������ (����� ������� ��� ��� ������ ����� ���������, ������ �������� ����� JOIN)

	-- ����� JOIN

	SELECT 
		 ps.SupplierID
		,ps.SupplierName
		,count(ppo.PurchaseOrderID) AS [Orders Quantity]
	FROM 
		Purchasing.Suppliers ps
		LEFT OUTER JOIN Purchasing.PurchaseOrders ppo ON ps.SupplierID = ppo.SupplierID
	GROUP BY ps.SupplierID, ps.SupplierName
	HAVING count(ppo.PurchaseOrderID) = 0

	-- ����� ���������

	SELECT 
		 ps.SupplierID
		,ps.SupplierName
	FROM Purchasing.Suppliers ps
	WHERE 
		SupplierID NOT IN 
		(
			SELECT DISTINCT SupplierID 
			FROM Purchasing.PurchaseOrders
		)

	GO

-- 3. ������� � ��������� ������, � ������� ���� �������, ������� ��������, � �������� ��������� �������, �������� ����� � ����� ����� ���� ��������� ���� - ������ ����� �� 4 ������, ���� ������ ������ ������ ���� ������, � ����� ������ ����� 100$ ���� ���������� ������ ������ ����� 20. �������� ������� ����� ������� � ������������ �������� ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� ������ ��������, ����� ����, ���� �������. 

	SELECT DISTINCT
		 so.OrderID
		,sct.TransactionDate AS [SalesDate]
		,CASE
			WHEN MONTH(sct.TransactionDate) = 1
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 2
			THEN '�������'
			WHEN MONTH(sct.TransactionDate) = 3
			THEN '����'
			WHEN MONTH(sct.TransactionDate) = 4
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 5
			THEN '���'
			WHEN MONTH(sct.TransactionDate) = 6
			THEN '����'
			WHEN MONTH(sct.TransactionDate) = 7
			THEN '����'
			WHEN MONTH(sct.TransactionDate) = 8
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 9
			THEN '��������'
			WHEN MONTH(sct.TransactionDate) = 10
			THEN '�������'
			WHEN MONTH(sct.TransactionDate) = 11
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 12
			THEN '�������'
			END AS [SalesMonth]
		,CASE
			WHEN MONTH(sct.TransactionDate) in (1, 2, 3)
			THEN 1
			WHEN MONTH(sct.TransactionDate) in (4, 5, 6)
			THEN 2
			WHEN MONTH(sct.TransactionDate) in (7, 8, 9)
			THEN 3
			WHEN MONTH(sct.TransactionDate) in (10, 11, 12)
			THEN 4
			END AS [SalesQuater]
		,CASE
			WHEN MONTH(sct.TransactionDate) in (1, 2, 3, 4)
			THEN 1
			WHEN MONTH(sct.TransactionDate) in (5, 6, 7, 8)
			THEN 2
			WHEN MONTH(sct.TransactionDate) in (9, 10, 11, 12)
			THEN 3
			END AS [SalesThird]
		,NULL AS [OrderLinesQuantity]
	FROM 
		Sales.Orders so
		INNER JOIN Sales.Invoices si ON so.OrderID = si.OrderID
		INNER JOIN Sales.CustomerTransactions sct ON si.InvoiceID = sct.InvoiceID
		INNER JOIN Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
	WHERE
		(
			sil.UnitPrice > 100
			OR so.OrderID IN 
			(
				SELECT dt.OrderID
				FROM
					(
						SELECT
							 so.OrderID
							,count(sol.OrderLineID) AS [OrderLinesQuantity]
						FROM 
							Sales.Orders so
							INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
						GROUP BY so.OrderID
						HAVING count(sol.OrderLineID) > 20
					) dt
			)
		)
		AND sct.TransactionDate IS NOT NULL
		AND so.PickingCompletedWhen IS NOT NULL

	GO

	-- ������� � ������������ ��������

		SELECT DISTINCT
		 so.OrderID
		,sct.TransactionDate AS [SalesDate]
		,CASE
			WHEN MONTH(sct.TransactionDate) = 1
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 2
			THEN '�������'
			WHEN MONTH(sct.TransactionDate) = 3
			THEN '����'
			WHEN MONTH(sct.TransactionDate) = 4
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 5
			THEN '���'
			WHEN MONTH(sct.TransactionDate) = 6
			THEN '����'
			WHEN MONTH(sct.TransactionDate) = 7
			THEN '����'
			WHEN MONTH(sct.TransactionDate) = 8
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 9
			THEN '��������'
			WHEN MONTH(sct.TransactionDate) = 10
			THEN '�������'
			WHEN MONTH(sct.TransactionDate) = 11
			THEN '������'
			WHEN MONTH(sct.TransactionDate) = 12
			THEN '�������'
			END AS [SalesMonth]
		,CASE
			WHEN MONTH(sct.TransactionDate) in (1, 2, 3)
			THEN 1
			WHEN MONTH(sct.TransactionDate) in (4, 5, 6)
			THEN 2
			WHEN MONTH(sct.TransactionDate) in (7, 8, 9)
			THEN 3
			WHEN MONTH(sct.TransactionDate) in (10, 11, 12)
			THEN 4
			END AS [SalesQuater]
		,CASE
			WHEN MONTH(sct.TransactionDate) in (1, 2, 3, 4)
			THEN 1
			WHEN MONTH(sct.TransactionDate) in (5, 6, 7, 8)
			THEN 2
			WHEN MONTH(sct.TransactionDate) in (9, 10, 11, 12)
			THEN 3
			END AS [SalesThird]
		,NULL AS [OrderLinesQuantity]
	FROM 
		Sales.Orders so
		INNER JOIN Sales.Invoices si ON so.OrderID = si.OrderID
		INNER JOIN Sales.CustomerTransactions sct ON si.InvoiceID = sct.InvoiceID
		INNER JOIN Sales.InvoiceLines sil ON si.InvoiceID = sil.InvoiceID
	WHERE
		(
			sil.UnitPrice > 100
			OR so.OrderID IN 
			(
				SELECT dt.OrderID
				FROM
					(
						SELECT
							 so.OrderID
							,count(sol.OrderLineID) AS [OrderLinesQuantity]
						FROM 
							Sales.Orders so
							INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
						GROUP BY so.OrderID
						HAVING count(sol.OrderLineID) > 20
					) dt
			)
		)
		AND sct.TransactionDate IS NOT NULL
		AND so.PickingCompletedWhen IS NOT NULL
	ORDER BY 
		 [SalesQuater]
		,[SalesThird]
		,[SalesDate]
	OFFSET 1000 ROWS
	FETCH NEXT 100 ROWS ONLY

	GO

-- 4. ������ �����������, ������� ���� ��������� �� 2014� ��� � ��������� Road Freight ��� Post, �������� �������� ����������, ��� ����������� ���� ������������ �����

	SELECT
		 ppo.PurchaseOrderID
		,ppo.OrderDate
		,ppo.ExpectedDeliveryDate
		,adm.DeliveryMethodName
		,ps.SupplierName
		,ap.FullName AS [Contact Person Name]
	FROM 
		Purchasing.PurchaseOrders ppo
		INNER JOIN Application.DeliveryMethods adm ON ppo.DeliveryMethodID = adm.DeliveryMethodID
		LEFT OUTER JOIN Purchasing.Suppliers ps ON ppo.SupplierID = ps.SupplierID
		LEFT OUTER JOIN Application.People ap ON ppo.ContactPersonID = ap.PersonID
	WHERE
		ppo.ExpectedDeliveryDate BETWEEN '20140101' AND '20141231'
		AND ppo.IsOrderFinalized = 1
		AND adm.DeliveryMethodName IN ('Road Freight', 'Post')

	GO

-- 5. 10 ��������� �� ���� ������ � ������ ������� � ������ ����������, ������� ������� �����.

	SELECT TOP 10
		 so.OrderID
		,so.OrderDate
		,sc.CustomerName AS [Customer Name]
		,ap.FullName AS [Salesperson Name]
	FROM
		Sales.Orders AS so
		LEFT OUTER JOIN Sales.Customers sc ON so.CustomerID = sc.CustomerID
		LEFT OUTER JOIN Application.People ap ON so.SalespersonPersonID = ap.PersonID
	ORDER BY
		so.OrderID DESC

	GO

-- 6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g

	SELECT DISTINCT
		 sc.CustomerID
		,sc.CustomerName
		,sc.PhoneNumber
	FROM 
		Sales.Customers sc
		INNER JOIN Sales.Orders so ON sc.CustomerID = so.CustomerID
		INNER JOIN Sales.OrderLines sol ON so.OrderID = sol.OrderID
		INNER JOIN Warehouse.StockItems wsi ON sol.StockItemID = wsi.StockItemID
	WHERE
		wsi.StockItemName = 'Chocolate frogs 250g'

	GO