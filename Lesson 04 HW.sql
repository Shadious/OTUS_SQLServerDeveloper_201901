--Сделайте 2 варианта запросов:
--1) через вложенный запрос
--2) через WITH (для производных таблиц) 
--Написать запросы:
--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса. 
--3. Выберите всех клиентов у которых было 5 максимальных оплат из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)
--4. Выберите города (ид и название), в которые были доставлены товары входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов
--5. Объясните, что делает и оптимизируйте запрос:
--SELECT 
--Invoices.InvoiceID, 
--Invoices.InvoiceDate,
--(SELECT People.FullName
--FROM Application.People
--WHERE People.PersonID = Invoices.SalespersonPersonID
--) AS SalesPersonName,
--SalesTotals.TotalSumm AS TotalSummByInvoice, 
--(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
--FROM Sales.OrderLines
--WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
--FROM Sales.Orders
--WHERE Orders.PickingCompletedWhen IS NOT NULL	
--AND Orders.OrderId = Invoices.OrderId)	
--) AS TotalSummForPickedItems
--FROM Sales.Invoices 
--JOIN
--(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
--FROM Sales.InvoiceLines
--GROUP BY InvoiceId
--HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
--ON Invoices.InvoiceID = SalesTotals.InvoiceID
--ORDER BY TotalSumm DESC
--Приложите план запроса и его анализ, а также ход ваших рассуждений по поводу оптимизации. 
--Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения.

--Опциональная часть: 
--В материалах к вебинару есть файл HT_reviewBigCTE.sql - прочтите этот запрос и напишите что он должен вернуть и в чем его смысл, можно если есть идеи по улучшению тоже их включить. 

--===========================================================================================================================================================================

--Сделайте 2 варианта запросов:
--1) через вложенный запрос

DECLARE @SalesName nvarchar(100) = 'Kayla Woodcock';
DECLARE @Year int = 2014;

SELECT count(OrderID)
FROM Sales.Orders
WHERE 
	SalespersonPersonID = 
	(
		SELECT PersonID
		FROM Application.People
		WHERE FullName = @SalesName
	)
	AND year(OrderDate) = @Year;

--2) через WITH (для производных таблиц)

WITH cte AS
(
	SELECT
		 o.OrderID
		,o.OrderDate
		,p.FullName
	FROM
		Sales.Orders o
		INNER JOIN Application.People p ON o.SalespersonPersonID = p.PersonID
)
SELECT count(OrderID)
FROM cte
WHERE 
	FullName = @SalesName
	AND year(OrderDate) = @Year;

--Написать запросы:
--1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.

-- Старый запрос:

--SELECT
--	 p.PersonID
--	,p.FullName
--	,p.EmailAddress
--	,p.PhoneNumber
--FROM
--	Application.People p
--	LEFT OUTER JOIN
--	(
--		SELECT 
--			 SalespersonPersonID
--			,count(OrderID) AS [OrdersQuantity]
--		FROM Sales.Orders
--		GROUP BY SalespersonPersonID
--	) s ON p.PersonID = s.SalespersonPersonID 
--WHERE
--	p.IsSalesperson = 1
--	AND isnull(s.OrdersQuantity, 0) = 0;

SELECT
	 p.PersonID
	,p.FullName
	,p.EmailAddress
	,p.PhoneNumber
FROM
	Application.People p
	INNER JOIN
	(
		SELECT 
			 i.SalespersonPersonID
			,count(i.InvoiceID) AS [SalesQuantity]
		FROM Sales.Invoices i
		WHERE
			EXISTS
			(
				SELECT ct.InvoiceID 
				FROM Sales.CustomerTransactions ct 
				WHERE i.InvoiceID = ct.InvoiceID
			)
		GROUP BY SalespersonPersonID
	) s ON p.PersonID = s.SalespersonPersonID 

--2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса. 

SELECT 
	 StockItemID
	,StockItemName
	,UnitPrice
FROM Warehouse.StockItems
WHERE
	UnitPrice = 
	(
		SELECT min(UnitPrice) 
		FROM Warehouse.StockItems
	);

SELECT 
	 si.StockItemID
	,si.StockItemName
	,si.UnitPrice
FROM 
	Warehouse.StockItems si
	LEFT OUTER JOIN
	(
		SELECT min(UnitPrice) as [MinPrice]
		FROM Warehouse.StockItems
	) minPrice ON si.UnitPrice = minPrice.MinPrice
WHERE
	minPrice.MinPrice IS NOT NULL;

--3. Выберите всех клиентов у которых было 5 максимальных оплат из [Sales].[CustomerTransactions] представьте 3 способа (в том числе с CTE)

SELECT DISTINCT
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber 
FROM 
	(
		SELECT TOP 5 CustomerID
		FROM Sales.CustomerTransactions 
		ORDER BY TransactionAmount DESC
	) a
	INNER JOIN Sales.Customers c ON a.CustomerID = c.CustomerID;

SELECT DISTINCT
	 CustomerID
	,CustomerName
	,PhoneNumber 
FROM Sales.Customers
WHERE
	CustomerID IN
	(
		SELECT TOP 5 CustomerID
		FROM Sales.CustomerTransactions 
		ORDER BY TransactionAmount DESC
	);

-- Старый запрос:

--WITH cte AS
--(
--	SELECT 
--		 c.CustomerID
--		,c.CustomerName
--		,c.PhoneNumber 
--	FROM
--		Sales.Customers c
--		INNER JOIN
--		(
--			SELECT TOP 5
--				 CustomerID
--				,TransactionAmount
--			FROM Sales.CustomerTransactions
--			ORDER BY TransactionAmount DESC
--		) tc ON c.CustomerID = tc.CustomerID
--)
--SELECT DISTINCT 
--	 CustomerID
--	,CustomerName
--	,PhoneNumber
--FROM cte;

WITH Top5TranAmount AS
(
	SELECT TOP 5
		 CustomerID
		,TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)
SELECT DISTINCT
	 c.CustomerID
	,c.CustomerName
	,c.PhoneNumber 
FROM
	Sales.Customers c 
	INNER JOIN Top5TranAmount t ON c.CustomerID = t.CustomerID

--4. Выберите города (ид и название), в которые были доставлены товары входящие в тройку самых дорогих товаров, а также Имя сотрудника, который осуществлял упаковку заказов

SELECT DISTINCT
	 cts.CityID
	,cts.CityName
	,p.FullName
FROM
	(
		SELECT TOP 3 StockItemID
		FROM Warehouse.StockItems
		ORDER BY UnitPrice DESC
	) si
	INNER JOIN Sales.OrderLines ol ON si.StockItemID = ol.StockItemID
	INNER JOIN Sales.Orders o ON ol.OrderID = o.OrderID
	INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	INNER JOIN Application.People p ON o.PickedByPersonID = p.PersonID
	INNER JOIN Application.Cities cts ON c.DeliveryCityID = cts.CityID

--5. Объясните, что делает и оптимизируйте запрос:
--Запрос выводит информацию о сумме выставленного счета, продавце и о сумме на которую был фактически отгружен товар, вероятно для вычисления расхождений
SELECT 
	 Invoices.InvoiceID
	,Invoices.InvoiceDate
	,(
		SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	 ) AS SalesPersonName
	,SalesTotals.TotalSumm AS TotalSummByInvoice
	,(
		SELECT SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE 
			OrderLines.OrderId = 
			(
				SELECT Orders.OrderId 
				FROM Sales.Orders
				WHERE 
					Orders.PickingCompletedWhen IS NOT NULL	
					AND Orders.OrderId = Invoices.OrderId
			)	
	 ) AS TotalSummForPickedItems
FROM 
	Sales.Invoices 
	INNER JOIN
	(
		SELECT 
			 InvoiceId
			,SUM(Quantity * UnitPrice) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY InvoiceId
		HAVING SUM(Quantity*UnitPrice) > 27000
	) AS SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC
--Приложите план запроса и его анализ, а также ход ваших рассуждений по поводу оптимизации. 
--Можно двигаться как в сторону улучшения читабельности запроса, так и в сторону упрощения плана\ускорения.

;WITH InvoiceSum AS
(
	SELECT 
		 InvoiceId
		,SUM(Quantity * UnitPrice) AS TotalSumm
	FROM 
		Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT
	 i.InvoiceID
	,i.InvoiceDate
	,p.FullName AS SalesPersonName
	,cte.TotalSumm AS TotalSummByInvoice
	,ol.TotalSummForPickedItems
FROM
	InvoiceSum cte
	INNER JOIN Sales.Invoices i ON cte.InvoiceID = i.InvoiceID 
	INNER JOIN 
	(
		SELECT ol.OrderID, SUM(ol.PickedQuantity * ol.UnitPrice) as TotalSummForPickedItems
		FROM 
			Sales.Orders o
			INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
		WHERE o.PickingCompletedWhen IS NOT NULL
		GROUP BY ol.OrderID
	) ol ON i.OrderID = ol.OrderID
	INNER JOIN Application.People p ON i.SalespersonPersonID = p.PersonID
WHERE EXISTS (SELECT InvoiceID FROM InvoiceSum WHERE cte.InvoiceID = i.InvoiceID)

--Главным образом хотелось избавиться от Clustered Index Scan по таблице Invoices с возвратом 70к+ строк. Избавился я от этого с помощью cte которая позволила задать фильтрацию по ID счетов. Что превратило Clustered Index Scan в Clustered Index Seek с возвратом сразу нужных 8 счетов. Так же долго думал как оптимизировать кусочек с таблицами Orders и OrderLines, но ничего дельного не придумал.
