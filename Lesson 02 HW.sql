-- Домашнее задание

-- Запросы SELECT:
-- * Написать по 1му запросу с примерами каждого вида JOIN, и фильтров.
-- * Выберите 10 последних заказов с именем клиента и именем сотрудника, который оформил заказ.

-- 2019.02.11 - Исправления по результатам проверки преподавателя

-- Комментарии проверяющего (Кучерова Кристина):
-- Про первый вариант про Cross и про Inner join вопросов нет, а про left, right и full есть вопросы.
-- Вы делаете выборку из таблицы Заказы, и потом присоединяете 2 таблицы Клиенты и Сотрудники (аналог) тут OUTER join досточно бесполезная штука, так как в современных базах нет практики удаления неактивных клиентов или сотрудников, поэтому все заказы будут иметь соответствие и в клиентах и в сотруднике, который обработал заказ 



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

-- LEFT OUTER JOIN - Выберем менеджеров у которых за январь 2013 года не было заказов

	SELECT
		 ap.PersonID
		,ap.FullName
	FROM
		Application.People ap
		LEFT OUTER JOIN Sales.Orders so ON ap.PersonID = so.SalespersonPersonID
	WHERE
		ap.IsSalesperson = 1
		AND so.OrderID IS NULL
		AND so.OrderDate BETWEEN '20130101' AND '20130131'
	ORDER BY
		ap.PersonID

	GO

-- RIGHT OUTER JOIN - Выберем города в которые не делает поставки ни один поставщик

	SELECT
		 ac.CityID
		,ac.CityName
	FROM
		Purchasing.Suppliers ps
		RIGHT OUTER JOIN Application.Cities ac ON ps.DeliveryCityID = ac.CityID
	WHERE
		ps.SupplierID IS NULL

	GO

-- FULL OUTER JOIN - заказы с ФИО клиента за январь 2013 г.

	SELECT
		  sc.CustomerName AS [Customer Name]
		 ,so.OrderID
	FROM
		Sales.Orders AS so
		FULL OUTER JOIN Sales.Customers sc ON so.CustomerID = sc.CustomerID
	WHERE
		(
			sc.CustomerID IS NOT NULL
			OR so.CustomerID IS NOT NULL
		)
		AND so.OrderDate BETWEEN '20130101' AND '20130131'

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
