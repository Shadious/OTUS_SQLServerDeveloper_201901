--Оконные функции
--1.Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
--Вывести Ид продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
--Пример 
--Дата продажи Нарастающий итог по месяцу
--2015-01-29	4801725.31
--2015-01-30	4801725.31
--2015-01-31	4801725.31
--2015-02-01	9626342.98
--2015-02-02	9626342.98
--2015-02-03	9626342.98
--Продажи можно взять из таблицы Invoices. Сумму из 2х таблиц, из какой будет удобнее.
--Сделать 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;
--2. Вывести список 2х самых популярного продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)
--3. Функции одним запросом
--Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
--пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
--посчитайте общее количество товаров и выведете полем в этом же запросе
--посчитайте общее количество товаров в зависимости от буквы начала называния товара
--следующий ид товара на следующей строки (по имени) и включите в выборку 
--предыдущий ид товара (по имени)
--названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
--сформируйте 30 групп товаров по полю вес товара на 1 шт
--Для этой задачи НЕ нужно писать аналог без аналитических функций
--4. По каждому сотруднику выведете последнего клиента, которому сотрудник что-то продал
--В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки
--5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

--Опционально можно сделать вариант запросов для заданий 2,4,5 без использования windows function и сравнить скорость как в задании 1. 

--Bonus из предыдущей темы
--Напишите запрос, который выбирает 10 клиентов, которые сделали больше 30 заказов и последний заказ был не позднее апреля 2016.



--1.Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
--Вывести Ид продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
--Пример 
--Дата продажи Нарастающий итог по месяцу
--2015-01-29	4801725.31
--2015-01-30	4801725.31
--2015-01-31	4801725.31
--2015-02-01	9626342.98
--2015-02-02	9626342.98
--2015-02-03	9626342.98
--Продажи можно взять из таблицы Invoices. Сумму из 2х таблиц, из какой будет удобнее.
--Сделать 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;

SET STATISTICS TIME ON;

-- Вариант С windows function

SELECT
	 i.InvoiceID
	,c.CustomerName
	,i.InvoiceDate
	,ct.TransactionAmount
	,SUM(ct.TransactionAmount) OVER (PARTITION BY i.CustomerID ORDER BY i.InvoiceID) AS [Running Total]
FROM
	Sales.Invoices i
	INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
	INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
WHERE
	year(ct.TransactionDate) >= 2015
ORDER BY c.CustomerName;

GO

-- Вариант БЕЗ windows function

SELECT
	 i.InvoiceID
	,c.CustomerName
	,i.InvoiceDate
	,ct.TransactionAmount
	,( 
		SELECT SUM(ct1.TransactionAmount) 
		FROM
			Sales.Invoices i1
			INNER JOIN Sales.CustomerTransactions ct1 ON i1.InvoiceID = ct1.InvoiceID
			INNER JOIN Sales.Customers c1 ON i1.CustomerID = c1.CustomerID
		WHERE 
			c1.CustomerID = c.CustomerID
			AND i1.InvoiceID <= i.InvoiceID
			AND year(ct1.TransactionDate) >= 2015
		GROUP BY c1.CustomerID
	 ) AS [Running Total]
FROM
	Sales.Invoices i
	INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
	INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
WHERE
	year(ct.TransactionDate) >= 2015
ORDER BY c.CustomerName, i.InvoiceID ASC;

GO

-- Запрос с windows function выполняется быстрее:
--(31440 rows affected)
-- SQL Server Execution Times:
--   CPU time = 843 ms,  elapsed time = 1419 ms.
--(31440 rows affected)
-- SQL Server Execution Times:
--   CPU time = 81016 ms,  elapsed time = 82595 ms.

--2. Вывести список 2х самых популярного продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

SET STATISTICS TIME ON;

-- Вариант С windows function

SELECT 
	 b.Month
	,b.StockItemName
	,b.Quantity
	,b.Rank
FROM
	(
		SELECT 
			 a.*
			,row_number() OVER (PARTITION BY  a.Month ORDER BY a.[Quantity] DESC) AS [Rank]
		FROM
			(
				SELECT DISTINCT
					 month(ct.TransactionDate) AS [Month]
					,si.StockItemName
					,SUM(il.Quantity) OVER (PARTITION BY month(ct.TransactionDate), si.StockItemName) AS [Quantity]
				FROM 
					Sales.InvoiceLines il
					INNER JOIN Sales.CustomerTransactions ct ON il.InvoiceID = ct.InvoiceID
					INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
				WHERE
					year(ct.TransactionDate) = 2016
			) a
	) b
WHERE [Rank] <= 2
ORDER BY 
	 b.Month ASC
	,b.Quantity DESC;

GO

-- Вариант БЕЗ windows function

SELECT DISTINCT
	  month(ct.TransactionDate) AS [Month]
	 ,a.StockItemName
	 ,a.Quantity
FROM
	Sales.CustomerTransactions ct
	CROSS APPLY
	(
		SELECT TOP 2
			 month(ct1.TransactionDate) AS [Month]
			,si1.StockItemName
			,SUM(il1.Quantity) AS [Quantity]
		FROM
			Sales.InvoiceLines il1
			INNER JOIN Sales.CustomerTransactions ct1 ON il1.InvoiceID = ct1.InvoiceID
			INNER JOIN Warehouse.StockItems si1 ON il1.StockItemID = si1.StockItemID
		WHERE
			year(ct1.TransactionDate) = 2016
		GROUP BY 
			 month(ct1.TransactionDate)
			,si1.StockItemName
		HAVING month(ct1.TransactionDate) = month(ct.TransactionDate)
		ORDER BY
			[Quantity] DESC
	) a
ORDER BY Month ASC;

GO

-- Запрос с windows function выполняется быстрее:
--(10 rows affected)
-- SQL Server Execution Times:
--   CPU time = 156 ms,  elapsed time = 154 ms.
--(10 rows affected)
-- SQL Server Execution Times:
--   CPU time = 35641 ms,  elapsed time = 35977 ms.

-- 3. Функции одним запросом:
-- Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена

SELECT
	 row_number() OVER(ORDER BY StockItemName ASC) AS [№]
	,StockItemID
	,StockItemName
	,Brand
	,UnitPrice
FROM Warehouse.StockItems;

-- Пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново

SELECT
	 row_number() OVER (PARTITION BY left(StockItemName, 1) ORDER BY StockItemName ASC) AS [№ by Letter]
	,StockItemName
FROM Warehouse.StockItems;

-- посчитайте общее количество товаров и выведете полем в этом же запросе

SELECT
	 row_number() OVER (PARTITION BY left(StockItemName, 1) ORDER BY StockItemName ASC) AS [№ by Letter]
	,si.StockItemName
	,SUM(sih.QuantityOnHand) OVER (PARTITION BY si.StockItemName) AS [QuantityOnHand]
FROM
	Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID;

-- посчитайте общее количество товаров в зависимости от буквы начала называния товара

SELECT DISTINCT
	 left(si.StockItemName, 1)
	,SUM(sih.QuantityOnHand) OVER (PARTITION BY left(si.StockItemName, 1) ORDER BY left(si.StockItemName, 1) ASC)
FROM
	Warehouse.StockItems si
	INNER JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID;

-- следующий ид товара на следующей строки (по имени) и включите в выборку 

SELECT
	 si.StockItemName
	,lead(si.StockItemName) OVER (ORDER BY si.StockItemName) AS [Next StockItemName]
FROM Warehouse.StockItems si

-- предыдущий ид товара (по имени)

SELECT
	 si.StockItemName
	,lead(si.StockItemName) OVER (ORDER BY si.StockItemName) AS [Next StockItemName]
	,lag(si.StockItemID) OVER (ORDER BY si.StockItemName) AS [Previous StockItemID]
FROM Warehouse.StockItems si

-- названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"

SELECT
	 si.StockItemName
	,lead(si.StockItemName) OVER (ORDER BY si.StockItemName) AS [Next StockItemName]
	,lag(si.StockItemID) OVER (ORDER BY si.StockItemName) AS [Previous StockItemID]
	,isnull(lag(si.StockItemName, 2) OVER (ORDER BY si.StockItemName), 'No items') AS [Previous by 2 StockItemName]
FROM Warehouse.StockItems si;

-- сформируйте 30 групп товаров по полю вес товара на 1 шт

SELECT DISTINCT TOP 30
	 si.TypicalWeightPerUnit
	,dense_rank() OVER (ORDER BY si.TypicalWeightPerUnit)
FROM Warehouse.StockItems si;

-- 4. По каждому сотруднику выведете последнего клиента, которому сотрудник что-то продал
-- В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки

SET STATISTICS TIME ON;

-- Вариант С windows function

WITH cte AS
(
	SELECT DISTINCT
		 o.SalespersonPersonID
		,p.FullName
		,max(ct.InvoiceID) OVER (PARTITION BY o.SalespersonPersonID) AS [InvoiceID]
	FROM
		Application.People p
		INNER JOIN Sales.Orders o ON p.PersonID = o.SalespersonPersonID
		INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID
		INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
)
SELECT 
	 cte.SalespersonPersonID
	,cte.FullName
	,c.CustomerID
	,c.CustomerName
	,ct.TransactionDate
	,ct.TransactionAmount
FROM 
	cte cte
	INNER JOIN Sales.Invoices i ON cte.InvoiceID = i.InvoiceID
	INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	INNER JOIN Sales.CustomerTransactions ct ON cte.InvoiceID = ct.InvoiceID
ORDER BY cte.SalespersonPersonID;

GO

-- Вариант БЕЗ windows function

SELECT
	 p.PersonID
	,p.FullName
	,a.*
FROM
	Application.People p
	CROSS APPLY
	(
		SELECT TOP 1
			 c.CustomerID
			,c.CustomerName
			,ct.TransactionDate
			,ct.TransactionAmount
		FROM
			Sales.Orders o
			INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID
			INNER JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
			INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
		WHERE p.PersonID = o.SalespersonPersonID
		ORDER BY ct.TransactionDate DESC
	) a
WHERE p.IsSalesperson = 1
ORDER BY p.PersonID ASC;

GO

-- Запрос БЕЗ windows function быстрее:
--(10 rows affected)
-- SQL Server Execution Times:
--   CPU time = 453 ms,  elapsed time = 478 ms.
--(10 rows affected)
-- SQL Server Execution Times:
--   CPU time = 16 ms,  elapsed time = 5 ms.

--5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
--В результатах должно быть ид клиента, его название, ид товара, цена, дата покупки

SET STATISTICS TIME ON;

-- Вариант С windows function:

SELECT DISTINCT
	 a.CustomerID
	,a.CustomerName
	,a.StockItemID
	,a.UnitPrice
	,a.TransactionDate
FROM
	(
		SELECT
			 c.CustomerID
			,c.CustomerName
			,si.StockItemID
			,si.UnitPrice
			,max(ct.TransactionDate) OVER (PARTITION BY c.CustomerID, si.StockItemID) AS [TransactionDate]
			,dense_rank() OVER (PARTITION BY c.CustomerID ORDER BY si.UnitPrice DESC) AS [Rank]
		FROM
			Sales.Orders o
			INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
			INNER JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
			INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID
			INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
			INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	) a
WHERE a.Rank <=2
ORDER BY 
	 a.CustomerID ASC
	,a.UnitPrice DESC;

-- Вариант БЕЗ windows function:

SELECT o.CustomerID, ol.StockItemID FROM Sales.Orders o INNER JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID INNER JOIN Sales.Invoices i ON o.OrderID = i.OrderID INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
WHERE o.CustomerID = 2 AND ol.StockItemID = 75

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

GO

--Bonus из предыдущей темы
--Напишите запрос, который выбирает 10 клиентов, которые сделали больше 30 заказов и последний заказ был не позднее апреля 2016.

SELECT DISTINCT
	a.CustomerID
	,a.CustomerName
	,max(a.OrderDate) OVER (PARTITION BY a.CustomerID)
FROM
(
	SELECT 
		 c.CustomerID
		,c.CustomerName
		,o.OrderID
		,o.OrderDate
		,rank() OVER (PARTITION BY c.CustomerID ORDER BY o.OrderID ASC) AS [Rank]
	FROM
		Sales.Customers c
		INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
) a
WHERE a.Rank >= 30
ORDER BY a.CustomerID;