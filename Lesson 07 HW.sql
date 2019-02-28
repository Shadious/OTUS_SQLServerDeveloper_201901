--Сравниваем временные таблицы и табличные переменные

-- 1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.
-- 2. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную
-- Дано :
-- CREATE TABLE dbo.MyEmployees 
-- ( 
-- EmployeeID smallint NOT NULL, 
-- FirstName nvarchar(30) NOT NULL, 
-- LastName nvarchar(40) NOT NULL, 
-- Title nvarchar(50) NOT NULL, 
-- DeptID smallint NOT NULL, 
-- ManagerID int NULL, 
-- CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC) 
-- ); 
-- INSERT INTO dbo.MyEmployees VALUES 
-- (1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL) 
-- ,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1) 
-- ,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273) 
-- ,(275, N'Michael', N'Blythe', N'Sales Representative',3,274) 
-- ,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274) 
-- ,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273) 
-- ,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285) 
-- ,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273) 
-- ,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16); 
   
-- Результат вывода рекурсивного CTE:
-- EmployeeID Name Title EmployeeLevel
-- 1	Ken Sánchez	Chief Executive Officer	1
-- 273	| Brian Welcker	Vice President of Sales	2
-- 16	| | David Bradley	Marketing Manager	3
-- 23	| | | Mary Gibson	Marketing Specialist	4
-- 274	| | Stephen Jiang	North American Sales Manager	3
-- 276	| | | Linda Mitchell	Sales Representative	4
-- 275	| | | Michael Blythe	Sales Representative	4
-- 285	| | Syed Abbas	Pacific Sales Manager	3
-- 286	| | | Lynn Tsoflias	Sales Representative	4


-- 1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.

SET STATISTICS TIME ON;

-- Запрос с временной таблицей:

IF (SELECT object_id('tempdb.sys.#orders', 'U')) IS NOT NULL
	DROP TABLE tempdb.sys.#orders;

PRINT 'Query with temporary table'

SELECT
	 o.OrderID
	,o.OrderDate
	,o.SalespersonPersonID
	,p.FullName AS [SalespersonFullName]
	,c.CustomerID
	,c.CustomerName
INTO #orders
FROM
	Sales.Orders o
	INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	INNER JOIN Application.People p ON o.SalespersonPersonID = p.PersonID
ORDER BY OrderID;

SELECT 
	 SalespersonPersonID
	,SalespersonFullName
	,count(OrderID) AS [Orders Quantity]
FROM #orders
GROUP BY 
	 SalespersonPersonID
	,SalespersonFullName
ORDER BY SalespersonPersonID;

GO

-- Запрос с табличной переменной:

PRINT 'Query with table variable'

DECLARE @orders table 
(
	 OrderID				int				NOT NULL
	,OrderDate				datetime		NOT NULL
	,SalespersonPersonID	int				NOT NULL
	,SalespersonFullName	nvarchar(50)	NOT NULL
	,CustomerID				int				NOT NULL
	,CustomerName			nvarchar(100)	NOT NULL
);

INSERT INTO @orders 
(
	 OrderID
	,OrderDate
	,SalespersonPersonID
	,SalespersonFullName
	,CustomerID
	,CustomerName
)
SELECT
	 o.OrderID
	,o.OrderDate
	,o.SalespersonPersonID
	,p.FullName
	,c.CustomerID
	,c.CustomerName
FROM
	Sales.Orders o
	INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
	INNER JOIN Application.People p ON o.SalespersonPersonID = p.PersonID
ORDER BY o.OrderID;

SELECT 
	 SalespersonPersonID
	,SalespersonFullName
	,count(OrderID) AS [Orders Quantity]
FROM @orders
GROUP BY 
	 SalespersonPersonID
	,SalespersonFullName
ORDER BY SalespersonPersonID;

GO

--============= Statistics =============--

--Query with temporary table:

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 130 ms.

--(73595 rows affected)
--SQL Server parse and compile time: 
--   CPU time = 478 ms, elapsed time = 478 ms.

--(10 rows affected)

-- SQL Server Execution Times:
--   CPU time = 78 ms,  elapsed time = 69 ms.
--SQL Server parse and compile time: 
--   CPU time = 41 ms, elapsed time = 41 ms.

--Query with table variable:

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 128 ms.

--(73595 rows affected)

--(10 rows affected)

-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 136 ms.

--============= Query plans =============--

-- Селект из временной таблицы:
------------------------------------------------------------------------------------------------------------------
--  |--Sort(ORDER BY:([tempdb].[dbo].[#orders].[SalespersonPersonID] ASC))
--       |--Compute Scalar(DEFINE:([Expr1003]=CONVERT_IMPLICIT(int,[Expr1006],0)))
--            |--Hash Match(Aggregate, HASH:([tempdb].[dbo].[#orders].[SalespersonPersonID], [tempdb].[dbo].[#orders].[SalespersonFullName]), RESIDUAL:([tempdb].[dbo].[#orders].[SalespersonPersonID] = [tempdb].[dbo].[#orders].[SalespersonPersonID] AND [tempd
--                 |--Table Scan(OBJECT:([tempdb].[dbo].[#orders]))

-- Селект из табличной переменной:
-------------------------------------------------------------------------------------------------------------------
--  |--Compute Scalar(DEFINE:([Expr1003]=CONVERT_IMPLICIT(int,[Expr1006],0)))
--       |--Stream Aggregate(GROUP BY:([SalespersonPersonID], [SalespersonFullName]) DEFINE:([Expr1006]=Count(*)))
--            |--Sort(ORDER BY:([SalespersonPersonID] ASC, [SalespersonFullName] ASC))
--                 |--Table Scan(OBJECT:(@orders))

-- Как вывод - в случае данного запроса наливка временной таблицы производилась дольше чем наливка табличной переменной, но выборка из временной таблицы получилась быстрее в 2 раза, что подтвердается сравнением планов запросов по выборке данных. Главным образом отличается подход к сортировке, в случае временной таблицы сортировка происходит уже после группировки данных, а в случае табличной переменной все данные сначала сортируются по SalespersonPersonID, а после этого уже происходит группировка.


-- 2. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную

-- Запрос с временной таблицей:

IF (SELECT object_id('tempdb.sys.#tmp4cte', 'U')) IS NOT NULL
	DROP TABLE tempdb.sys.#tmp4cte;

with MyEmployeesCTE as 
(
	SELECT
		 me.*
		,1 AS [EmployeeLevel]
	FROM [MyEmployees] me
	WHERE me.EmployeeID = 1

	UNION ALL

	SELECT 
		 men.*
		,cte.EmployeeLevel + 1 AS [EmployeeLevel]
	FROM 
		[MyEmployees] men
		INNER JOIN MyEmployeesCTE cte ON cte.EmployeeID = men.ManagerID
)
SELECT *
INTO #tmp4cte
FROM MyEmployeesCTE;

SELECT *
FROM #tmp4cte
ORDER BY EmployeeLevel;


-- Запрос с табличной переменной:

DECLARE @MyEmployees table 
(
	 EmployeeID		int				NOT NULL
	,FirstName		nvarchar(30)	NOT NULL
	,LastName		nvarchar(40)	NOT NULL
	,Title			nvarchar(50)	NOT NULL
	,DeptID			int				NOT NULL
	,ManagerID		int				NULL
	,EmployeeLevel	int				NOT NULL
);

with MyEmployeesCTE as 
(
	SELECT
		 me.*
		,1 AS [EmployeeLevel]
	FROM [MyEmployees] me
	WHERE me.EmployeeID = 1

	UNION ALL

	SELECT 
		 men.*
		,cte.EmployeeLevel + 1 AS [EmployeeLevel]
	FROM 
		[MyEmployees] men
		INNER JOIN MyEmployeesCTE cte ON cte.EmployeeID = men.ManagerID
)
INSERT INTO @MyEmployees
SELECT *
FROM MyEmployeesCTE;

SELECT *
FROM @MyEmployees
ORDER BY EmployeeLevel;

-- Результат вывода рекурсивного CTE:
-- EmployeeID Name Title EmployeeLevel
-- 1	Ken Sánchez	Chief Executive Officer	1
-- 273	| Brian Welcker	Vice President of Sales	2
-- 16	| | David Bradley	Marketing Manager	3
-- 23	| | | Mary Gibson	Marketing Specialist	4
-- 274	| | Stephen Jiang	North American Sales Manager	3
-- 276	| | | Linda Mitchell	Sales Representative	4
-- 275	| | | Michael Blythe	Sales Representative	4
-- 285	| | Syed Abbas	Pacific Sales Manager	3
-- 286	| | | Lynn Tsoflias	Sales Representative	4