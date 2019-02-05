-- Домашнее задание

-- Запросы SELECT:
-- * Написать по 1му запросу с примерами каждого вида JOIN, и фильтров.
-- * Выберите 10 последних заказов с именем клиента и именем сотрудника, который оформил заказ.

	USE WideWorldImporters

	GO

-- INNER JOIN

	SELECT TOP 10
		 sc.CustomerName AS [Customer Name]
		,ap.FullName AS [Salesperson Name]
		,so.*
	FROM
		Sales.Orders AS so
		INNER JOIN Sales.Customers sc ON so.CustomerID = sc.CustomerID
		INNER JOIN Application.People ap ON so.SalespersonPersonID = ap.PersonID
	WHERE
		(
			so.OrderDate = '20160530'
			OR so.ExpectedDeliveryDate = '20160531'
		)
		AND sc.DeliveryMethodID = 3
		AND ISNULL(sc.CreditLimit, 0) >= 1000
	ORDER BY
		so.OrderID DESC

	GO

-- LEFT OUTER JOIN

	SELECT TOP 10
		 sc.CustomerName AS [Customer Name]
		,ap.FullName AS [Salesperson Name]
		,so.*
	FROM
		Sales.Orders AS so
		LEFT OUTER JOIN Sales.Customers sc ON so.CustomerID = sc.CustomerID
		LEFT OUTER JOIN Application.People ap ON so.SalespersonPersonID = ap.PersonID
	WHERE
		(
			so.OrderDate = '20160530'
			OR so.ExpectedDeliveryDate = '20160531'
		)
		AND sc.DeliveryMethodID = 3
		AND ISNULL(sc.CreditLimit, 0) >= 1000
	ORDER BY
		so.OrderID DESC

	GO

-- RIGHT OUTER JOIN

	SELECT TOP 10
		 sc.CustomerName AS [Customer Name]
		,ap.FullName AS [Salesperson Name]
		,so.*
	FROM
		Sales.Orders AS so
		RIGHT OUTER JOIN Sales.Customers sc ON so.CustomerID = sc.CustomerID
		RIGHT OUTER JOIN Application.People ap ON so.SalespersonPersonID = ap.PersonID
	WHERE
		(
			so.OrderDate = '20160530'
			OR so.ExpectedDeliveryDate = '20160531'
		)
		AND sc.DeliveryMethodID = 3
		AND ISNULL(sc.CreditLimit, 0) >= 1000
	ORDER BY
		so.OrderID DESC

	GO

-- FULL OUTER JOIN

	SELECT TOP 10
		 sc.CustomerName AS [Customer Name]
		,ap.FullName AS [Salesperson Name]
		,so.*
	FROM
		Sales.Orders AS so
		FULL OUTER JOIN Sales.Customers sc ON so.CustomerID = sc.CustomerID
		FULL OUTER JOIN Application.People ap ON so.SalespersonPersonID = ap.PersonID
	WHERE
		(
			so.OrderDate = '20160530'
			OR so.ExpectedDeliveryDate = '20160531'
		)
		AND sc.DeliveryMethodID = 3
		AND ISNULL(sc.CreditLimit, 0) >= 1000
	ORDER BY
		so.OrderID DESC

	GO

-- CROSS JOIN

	SELECT TOP 10
		 sc.CustomerName AS [Customer Name]
		,ap.FullName AS [Salesperson Name]
		,so.*
	FROM
		Sales.Orders AS so
		CROSS JOIN Sales.Customers sc
		CROSS JOIN Application.People ap
	WHERE
		(
			so.OrderDate = '20160530'
			OR so.ExpectedDeliveryDate = '20160531'
		)
		AND sc.DeliveryMethodID = 3
		AND ISNULL(sc.CreditLimit, 0) >= 1000
	ORDER BY
		so.OrderID DESC

	GO
