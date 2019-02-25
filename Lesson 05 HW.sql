-- Группировки и агрегатные функции
-- 1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
-- 2. Отобразить все месяцы, где общая сумма продаж превысила 10 000 
-- 3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.


-- 1. Посчитать среднюю цену товара, общую сумму продажи по месяцам

SELECT 
	 month(ct.TransactionDate) AS [Month]
	,SUM(ct.TransactionAmount) AS [Transaction Amount Sum]
	,AVG(ol.UnitPrice) AS [Average Unit Price]
FROM
	Sales.Invoices i
	INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
	INNER JOIN Sales.OrderLines ol ON i.OrderID = ol.OrderID
GROUP BY month(ct.TransactionDate)
ORDER BY Month ASC;

-- 2. Отобразить все месяцы, где общая сумма продаж превысила 10 000 

SELECT 
	 month(ct.TransactionDate) AS [Month]
	,SUM(ct.TransactionAmount)
FROM
	Sales.Invoices i
	INNER JOIN Sales.CustomerTransactions ct ON i.InvoiceID = ct.InvoiceID
GROUP BY month(ct.TransactionDate)
HAVING SUM(ct.TransactionAmount) > 10000
ORDER BY Month ASC;

-- 3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.

SELECT
	 si.StockItemID
	,si.StockItemName
	,month(ct.TransactionDate) AS [Month]
	,SUM(ct.TransactionAmount) AS [Sales Sum]
	,MIN(ct.TransactionDate) AS [First Sale]
	,COUNT(il.Quantity) AS [Sales Quantity]
FROM
	Sales.InvoiceLines il
	INNER JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
	INNER JOIN Sales.CustomerTransactions ct ON il.InvoiceID = ct.InvoiceID
GROUP BY
	 si.StockItemID
	,si.StockItemName
	,month(ct.TransactionDate)
HAVING COUNT(il.Quantity) < 50
ORDER BY
	 si.StockItemID ASC
	,Month ASC;
