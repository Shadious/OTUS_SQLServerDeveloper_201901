-- Домашнее задание

-- Запросы SELECT.
-- Напишите выборки для того, чтобы получить:
-- 1. Все товары, в которых в название есть пометка urgent или название начинается с Animal
-- 2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)
-- 3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, включите также к какой трети года относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20. Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. Соритровка должна быть по номеру квартала, трети года, дате продажи. 
-- 4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ
-- 5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.
-- 6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g

	USE WideWorldImporters

	GO

-- 1. Все товары, в которых в название есть пометка urgent или название начинается с Animal

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

-- 2. Поставщиков, у которых не было сделано ни одного заказа (потом покажем как это делать через подзапрос, сейчас сделайте через JOIN)

	-- Через JOIN

	SELECT 
		 ps.SupplierID
		,ps.SupplierName
		,count(ppo.PurchaseOrderID) AS [Orders Quantity]
	FROM 
		Purchasing.Suppliers ps
		LEFT OUTER JOIN Purchasing.PurchaseOrders ppo ON ps.SupplierID = ppo.SupplierID
	GROUP BY ps.SupplierID, ps.SupplierName
	HAVING count(ppo.PurchaseOrderID) = 0

	-- Через подзапрос

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

-- 3. Продажи с названием месяца, в котором была продажа, номером квартала, к которому относится продажа, включите также к какой трети года относится дата - каждая треть по 4 месяца, дата забора заказа должна быть задана, с ценой товара более 100$ либо количество единиц товара более 20. Добавьте вариант этого запроса с постраничной выборкой пропустив первую 1000 и отобразив следующие 100 записей. Соритровка должна быть по номеру квартала, трети года, дате продажи.

	SELECT DISTINCT
		 so.OrderID
		,sct.TransactionDate AS [SalesDate]
		,CASE
			WHEN MONTH(sct.TransactionDate) = 1
			THEN 'ßíâàðü'
			WHEN MONTH(sct.TransactionDate) = 2
			THEN 'Ôåâðàëü'
			WHEN MONTH(sct.TransactionDate) = 3
			THEN 'Ìàðò'
			WHEN MONTH(sct.TransactionDate) = 4
			THEN 'Àïðåëü'
			WHEN MONTH(sct.TransactionDate) = 5
			THEN 'Ìàé'
			WHEN MONTH(sct.TransactionDate) = 6
			THEN 'Èþíü'
			WHEN MONTH(sct.TransactionDate) = 7
			THEN 'Èþëü'
			WHEN MONTH(sct.TransactionDate) = 8
			THEN 'Àâãóñò'
			WHEN MONTH(sct.TransactionDate) = 9
			THEN 'Ñåíòÿáðü'
			WHEN MONTH(sct.TransactionDate) = 10
			THEN 'Îêòÿáðü'
			WHEN MONTH(sct.TransactionDate) = 11
			THEN 'Íîÿáðü'
			WHEN MONTH(sct.TransactionDate) = 12
			THEN 'Äåêàáðü'
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

	-- Вариант с постраничной выборкой

		SELECT DISTINCT
		 so.OrderID
		,sct.TransactionDate AS [SalesDate]
		,CASE
			WHEN MONTH(sct.TransactionDate) = 1
			THEN 'ßíâàðü'
			WHEN MONTH(sct.TransactionDate) = 2
			THEN 'Ôåâðàëü'
			WHEN MONTH(sct.TransactionDate) = 3
			THEN 'Ìàðò'
			WHEN MONTH(sct.TransactionDate) = 4
			THEN 'Àïðåëü'
			WHEN MONTH(sct.TransactionDate) = 5
			THEN 'Ìàé'
			WHEN MONTH(sct.TransactionDate) = 6
			THEN 'Èþíü'
			WHEN MONTH(sct.TransactionDate) = 7
			THEN 'Èþëü'
			WHEN MONTH(sct.TransactionDate) = 8
			THEN 'Àâãóñò'
			WHEN MONTH(sct.TransactionDate) = 9
			THEN 'Ñåíòÿáðü'
			WHEN MONTH(sct.TransactionDate) = 10
			THEN 'Îêòÿáðü'
			WHEN MONTH(sct.TransactionDate) = 11
			THEN 'Íîÿáðü'
			WHEN MONTH(sct.TransactionDate) = 12
			THEN 'Äåêàáðü'
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

-- 4. Заказы поставщикам, которые были исполнены за 2014й год с доставкой Road Freight или Post, добавьте название поставщика, имя контактного лица принимавшего заказ

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

-- 5. 10 последних по дате продаж с именем клиента и именем сотрудника, который оформил заказ.


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

-- 6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g

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
