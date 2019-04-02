-- Написать скрипт создание вашей учебной базы данных.
-- Написать скрипт для создания таблиц.
-- Добавить constraint в ваши таблицы по смыслу, через инструкцию ALTER.
-- Написать скрипт для добавления хотя бы одного пользователя.


-- 1. Написать скрипт создание вашей учебной базы данных.

CREATE DATABASE [ESB]
	CONTAINMENT = NONE
ON PRIMARY 
	( NAME = N'ESB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\ESB.mdf' , SIZE = 8192KB , FILEGROWTH = 524288KB )
LOG ON 
	( NAME = N'ESB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\ESB_log.ldf' , SIZE = 8192KB , FILEGROWTH = 524288KB )
COLLATE Cyrillic_General_CI_AI;

GO

ALTER DATABASE [ESB] SET COMPATIBILITY_LEVEL = 140;

GO

ALTER DATABASE [ESB] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF);

GO

ALTER DATABASE [ESB] SET AUTO_UPDATE_STATISTICS ON;

GO

ALTER DATABASE [ESB] SET RECOVERY FULL; 

GO

ALTER DATABASE [ESB] SET PAGE_VERIFY CHECKSUM;  

GO

ALTER DATABASE [ESB] SET TARGET_RECOVERY_TIME = 0 SECONDS; 

GO

-- 2. Написать скрипт для создания таблиц.

USE [ESB];

GO

CREATE SCHEMA [ESB] 
AUTHORIZATION [db_owner];

GO

CREATE TABLE [ESB].[ESB].[Events]
(
	 [EventGUID] uniqueidentifier DEFAULT newsequentialid() PRIMARY KEY
	,[ParentEvent] uniqueidentifier NULL
	,[Service] int NOT NULL
	,[EventDate] datetime NOT NULL
	,[EventType] int NOT NULL
	,[EventData] XML NOT NULL
);

CREATE TABLE [ESB].[ESB].[EventTypes]
(
	 [EventTypeID] int PRIMARY KEY NOT NULL
	,[EventTypeName] nvarchar(100) NOT NULL
	,[EventTypeDescription] nvarchar(max) NOT NULL
	,[EventTypeSchema] XML NOT NULL
);

CREATE TABLE [ESB].[ESB].[Services]
(
	 [ServiceID] int PRIMARY KEY NOT NULL
	,[ServiceName] nvarchar(100) NOT NULL
	,[ServiceDescription] nvarchar(max) NOT NULL
	,[ServiceURL] nvarchar(512) NOT NULL
	,[ServiceLogin] nvarchar(128) NOT NULL
	,[ServicePassword] nvarchar(128) NOT NULL
	,[ServiceCertificateThumbprint] nvarchar(40) NULL
	,[ServiceInactive] bit NOT NULL DEFAULT 0
);

-- 3. Добавить constraint в ваши таблицы по смыслу, через инструкцию ALTER.

ALTER TABLE [ESB].[ESB].[Events]
	ADD CONSTRAINT FK_Events_EventTypes 
		FOREIGN KEY ([EventType])
		REFERENCES [ESB].[EventTypes] ([EventTypeID]);

ALTER TABLE [ESB].[ESB].[Events]
	ADD CONSTRAINT FK_Events_Services 
		FOREIGN KEY ([Service])
		REFERENCES [ESB].[Services] ([ServiceID]);

-- 4. Написать скрипт для добавления хотя бы одного пользователя.

CREATE USER [ESBAdmin] FOR LOGIN [sa] WITH DEFAULT_SCHEMA=[ESB];

GO

ALTER AUTHORIZATION ON SCHEMA::[ESB] TO [ESBAdmin];

GO
