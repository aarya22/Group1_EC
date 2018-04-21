CREATE DATABASE group1_ec

USE group1_ec

CREATE TABLE CONTINENT
	(ContinentID INT IDENTITY(1, 1) primary key,
	ContinentName varchar(50) UNIQUE)
GO

CREATE TABLE COUNTRY
	(CountryID INT identity(1,1) primary key,
	CountryName varchar(50),
	ContinentID INT FOREIGN KEY REFERENCES CONTINENT(ContinentID) not null)
GO

CREATE TABLE ORIGIN_TYPE
	(OriginTypeID INT identity(1,1) primary key not null,
	OriginTypeName varchar(100))
GO

CREATE TABLE POP_TYPE
	(PopTypeID INT identity(1,1) primary key not null,
	PopTypeName varchar(300))
GO

CREATE TABLE MOVEMENT
	(MovementID INT identity(1,1) primary key not null,
	CountryID INT FOREIGN KEY REFERENCES COUNTRY(CountryID),
	OriginTypeID INT FOREIGN KEY REFERENCES ORIGIN_TYPE(OriginTypeID),
	PopTypeID INT FOREIGN KEY REFERENCES POP_TYPE(PopTypeID),
	Value INT not null,
	[Year] INT not null)
GO

CREATE PROCEDURE uspGetCountryID 
	@CountryName varchar(50),
	@CID INT OUTPUT
	AS
	SET @CID = (SELECT CountryID 
	FROM COUNTRY
	WHERE CountryName = @CountryName)
GO

CREATE PROCEDURE uspGetOriginTypeID
	@OriginTypeName varchar(100),
	@OTID INT OUTPUT
	AS
	SET @OTID = (SELECT OriginTypeID
	FROM ORIGIN_TYPE
	WHERE OriginTypeName = @OriginTypeName)
GO

CREATE PROCEDURE uspGetPopTypeID
	@PopTypeName varchar(300),
	@PID INT OUTPUT
	AS
	SET @PID = (SELECT PopTypeID
	FROM POP_TYPE
	WHERE PopTypeName = @PopTypeName)
GO

/*
DECLARE @PID int
EXEC uspGetCountryID 'Sweden', @CID = @PID OUTPUT
print @PID
*/

CREATE TABLE WorkingRefugeeData
	(RowID INT identity(1,1) primary key,
	[Year] int,
	Country varchar(50),
	Origin varchar(100),
	PopType varchar(300),
	[Value] int)
GO

INSERT INTO WorkingRefugeeData 
SELECT *
FROM RAW_refugee 

INSERT INTO CONTINENT (ContinentName)
	SELECT DISTINCT(Continent) FROM dbo.ImportCont
GO

CREATE TABLE PopCountry
	(CountryName varchar(50) not null UNIQUE)
GO

INSERT INTO PopCountry (CountryName)
	SELECT DISTINCT Country FROM WorkingRefugeeData
GO


INSERT INTO COUNTRY (CountryName, ContinentID)
select P.CountryName, C.ContinentID from #PopCountry P
	JOIN ImportCont I ON P.CountryName = I.Country
	JOIN CONTINENT C ON I.Continent = C.ContinentName 
GO

INSERT INTO ORIGIN_TYPE
SELECT DISTINCT Origin
FROM WorkingRefugeeData

INSERT INTO POP_TYPE
SELECT DISTINCT PopType
FROM WorkingRefugeeData

DECLARE @Run INT = (SELECT COUNT(*) FROM WorkingRefugeeData)
DECLARE @MovementID INT
DECLARE @ID INT
DECLARE @CountryID INT
DECLARE @OriginTypeID INT
DECLARE @PopTypeID INT
DECLARE @Value INT
DECLARE @Year INT
DECLARE @CountryName varchar(50)
DECLARE @OriginName varchar(50)
DECLARE @PopTypeName varchar(50)

WHILE @Run > 0
	BEGIN 
	SET @ID = (SELECT MIN(RowID) FROM WorkingRefugeeData)
	SET @Value = (SELECT [Value] from WorkingRefugeeData WHERE RowID = @ID)
	SET @Year = (SELECT [Year] from WorkingRefugeeData WHERE RowID = @ID)
	SET @CountryName = (SELECT Country from WorkingRefugeeData WHERE RowID = @ID)
	SET @OriginName = (SELECT Origin from WorkingRefugeeData WHERE RowID = @ID)
	SET @PopTypeName = (SELECT PopType from WorkingRefugeeData WHERE RowID = @ID)

	EXEC uspGetCountryID @CountryName, @CID = @CountryID OUTPUT
	EXEC uspGetOriginTypeID @OriginName, @OTID = @OriginTypeID OUTPUT
	EXEC uspGetPopTypeID @PopTypeName, @PID = @PopTypeID OUTPUT

	BEGIN TRAN G1
	INSERT INTO MOVEMENT (CountryID, OriginTypeID, PopTypeID, [Value], [Year])
	VALUES (@CountryID, @OriginTypeID, @PopTypeID, @Value, @Year)
	SET @MovementID = (SCOPE_IDENTITY())

	IF @@ERROR <> 0
	ROLLBACK TRAN G1
	ELSE
	COMMIT TRAN G1

	DELETE FROM WorkingRefugeeData 
	WHERE RowID = @ID

	SET @Run = @Run - 1
END

-- Case Statement that indicates the number of refugees that traveled
--   to each continent.
SELECT (CASE
	WHEN ContinentName LIKE '%Africa%'
		THEN 'Africa'
	WHEN ContinentName LIKE '%Asia%'
		THEN 'Asia'
	WHEN ContinentName LIKE '%Europe'
		THEN 'Europe'
	WHEN ContinentName LIKE '%North America%'
		THEN 'North America'
	WHEN ContinentName LIKE '%Ocenia%'
		THEN 'Ocenia'
	WHEN ContinentName LIKE '%South America%'
		THEN 'South America'
	ELSE 'NOT sure'
	END) AS 'Continent Traveled to', COUNT(*) AS 'NumberOfPeople'
FROM MOVEMENT M
	JOIN COUNTRY C ON M.CountryID=C.CountryID
	JOIN CONTINENT CO ON C.ContinentID=CO.ContinentID
GROUP BY (CASE
	WHEN ContinentName LIKE '%Africa%'
		THEN 'Africa'
	WHEN ContinentName LIKE '%Asia%'
		THEN 'Asia'
	WHEN ContinentName LIKE '%Europe'
		THEN 'Europe'
	WHEN ContinentName LIKE '%North America%'
		THEN 'North America'
	WHEN ContinentName LIKE '%Ocenia%'
		THEN 'Ocenia'
	WHEN ContinentName LIKE '%South America%'
		THEN 'South America'
	ELSE 'NOT sure'
	END)
GO