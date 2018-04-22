CREATE DATABASE group1_ec

USE group1_ec

CREATE TABLE MOVEMENT
	(MovementID INT identity(1,1) primary key not null,
	CountryID INT FOREIGN KEY REFERENCES COUNTRY(CountryID),
	OriginTypeID INT FOREIGN KEY REFERENCES ORIGIN_TYPE(OriginTypeID),
	PopTypeID INT FOREIGN KEY REFERENCES POP_TYPE(PopTypeID),
	Value INT not null,
	[Year] INT not null)
GO

CREATE TABLE COUNTRY
	(CountryID INT identity(1,1) primary key not null,
	CountryName varchar(50))
GO

CREATE TABLE ORIGIN_TYPE
	(OriginTypeID INT identity(1,1) primary key not null,
	OriginTypeName varchar(100))
GO

CREATE TABLE POP_TYPE
	(PopTypeID INT identity(1,1) primary key not null,
	PopTypeName varchar(300))
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

DECLARE @PID int
EXEC uspGetCountryID 'Sweden', @CID = @PID OUTPUT
print @PID

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

INSERT INTO COUNTRY
SELECT DISTINCT Country
FROM WorkingRefugeeData

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

	IF @Value < 0 
	BEGIN
		RAISERROR('Cannot have negative people coming in on a given year', 11, 1)
		RETURN
	END

	--Error handling
	--Error if CountryID, OriginTypeID, PopTypeID is null
	--Error if Value is < 0

	EXEC uspGetCountryID @CountryName, @CID = @CountryID OUTPUT
	EXEC uspGetOriginTypeID @OriginName, @OTID = @OriginTypeID OUTPUT
	EXEC uspGetPopTypeID @PopTypeName, @PID = @PopTypeID OUTPUT

	IF @CountryID IS NULL 
	BEGIN
		RAISERROR('Country ID is NULL, should be labeled Various/Unknown instead', 11, 1)
		RETURN
	END

	IF @OriginTypeID IS NULL 
	BEGIN
		RAISERROR('OriginTypeID is NULL, should be labeled Various/Unknown instead', 11, 1)
		RETURN
	END

	IF @PopTypeID IS NULL
	BEGIN
		RAISERROR('PopTypeID is NULL, should be known', 11, 1)
		RETURN
	END

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

SELECT (CASE
 WHEN ([Year] BETWEEN 1950 and 1953 
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Korea%' OR OriginTypeName = 'Various/Unknown')
 THEN 'Korean War'

 WHEN ([Year] BETWEEN 1954 and 1959 
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown'))
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Cuba%')
 THEN 'Cuban Revolution'

 WHEN ([Year] BETWEEN 1960 and 1975
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Vietnam%' OR
 OriginTypeName LIKE '%Myanmar%' OR
 OriginTypeName LIKE '%Indonesia' OR
 OriginTypeName LIKE '%Philippines' OR
 OriginTypeName = 'Various/Unknown')
 THEN 'Vietnam War'

 WHEN ([Year] BETWEEN 1975 and 1978
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Ghana%' OR
 OriginTypeName LIKE '%Mozambique%' OR
 OriginTypeName LIKE '%Central African Rep.%' OR
 OriginTypeName LIKE '%Uganda%' OR
 OriginTypeName LIKE '%Mauritania%' OR
 OriginTypeName LIKE '%Libya%' OR
 OriginTypeName LIKE '%Tanzania%' OR
 OriginTypeName LIKE '%Congo%' OR
 OriginTypeName LIKE '%Nigeria%' OR
 OriginTypeName LIKE '%Chad%' OR
 OriginTypeName LIKE '%Benin%' OR
 OriginTypeName LIKE '%Tunisia%' OR
 OriginTypeName LIKE '%Morocco%' OR
 OriginTypeName LIKE '%Sierra Leone%' OR
 OriginTypeName LIKE '%Ethiopia%' OR
 OriginTypeName LIKE '%Liberia%' OR
 OriginTypeName LIKE '%Nambia%' OR
 OriginTypeName LIKE '%Somalia%' OR
 OriginTypeName LIKE '%Burundi%' OR
 OriginTypeName LIKE '%Sudan%' OR
 OriginTypeName LIKE '%Botswana%' OR
 OriginTypeName LIKE '%Kenya%' OR
 OriginTypeName LIKE '%Algeria%' OR
 OriginTypeName LIKE '%Rwanda%' OR
 OriginTypeName = 'Various/Unknown')
 THEN 'African Civil Wars'

 WHEN ([Year] BETWEEN 1979 and 1981 
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Afghanistan%' OR
 OriginTypeName LIKE '%Iran%' OR
 OriginTypeName LIKE '%Iraq%' OR
 OriginTypeName LIKE '%Palestinian%')
 THEN 'Soviet Invasion of Afghanistan'

 WHEN ([Year] BETWEEN 1982 and 1982
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Argentina%')
 THEN 'Falklands War'

 WHEN ([Year] BETWEEN 1983 and 1983
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Grenada%' OR
 OriginTypeName LIKE '%Cuba%')
 THEN 'Invasion of Grenada'

 WHEN ([Year] BETWEEN 1984 and 1987
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%India%' OR 
 OriginTypeName LIKE '%Pakistan%')
 THEN 'Siachen Conflict'

 WHEN ([Year] BETWEEN 1988 and 1988
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Uganda%' OR
 OriginTypeName LIKE '%Sudan%' OR 
 OriginTypeName LIKE '%Congo%' OR 
 OriginTypeName LIKE '%Central African Rep.%')
 THEN 'Lords Resistance Army Insurgency'

 WHEN ([Year] BETWEEN 1989 and 1989
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%India%' OR 
 OriginTypeName LIKE '%Pakistan%')
 THEN 'Kashmiri Insurgency'
 ELSE 'Other Conflicts'
 END) AS 'Major Conflict', SUM(Value) AS NumDisplaced 
FROM MOVEMENT
GROUP BY (CASE
 WHEN ([Year] BETWEEN 1950 and 1953 
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Korea%' OR OriginTypeName = 'Various/Unknown')
 THEN 'Korean War'

 WHEN ([Year] BETWEEN 1954 and 1959 
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown'))
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Cuba%')
 THEN 'Cuban Revolution'

 WHEN ([Year] BETWEEN 1960 and 1975
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Vietnam%' OR
 OriginTypeName LIKE '%Myanmar%' OR
 OriginTypeName LIKE '%Indonesia' OR
 OriginTypeName LIKE '%Philippines' OR
 OriginTypeName = 'Various/Unknown')
 THEN 'Vietnam War'

 WHEN ([Year] BETWEEN 1975 and 1978
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID IN (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Ghana%' OR
 OriginTypeName LIKE '%Mozambique%' OR
 OriginTypeName LIKE '%Central African Rep.%' OR
 OriginTypeName LIKE '%Uganda%' OR
 OriginTypeName LIKE '%Mauritania%' OR
 OriginTypeName LIKE '%Libya%' OR
 OriginTypeName LIKE '%Tanzania%' OR
 OriginTypeName LIKE '%Congo%' OR
 OriginTypeName LIKE '%Nigeria%' OR
 OriginTypeName LIKE '%Chad%' OR
 OriginTypeName LIKE '%Benin%' OR
 OriginTypeName LIKE '%Tunisia%' OR
 OriginTypeName LIKE '%Morocco%' OR
 OriginTypeName LIKE '%Sierra Leone%' OR
 OriginTypeName LIKE '%Ethiopia%' OR
 OriginTypeName LIKE '%Liberia%' OR
 OriginTypeName LIKE '%Nambia%' OR
 OriginTypeName LIKE '%Somalia%' OR
 OriginTypeName LIKE '%Burundi%' OR
 OriginTypeName LIKE '%Sudan%' OR
 OriginTypeName LIKE '%Botswana%' OR
 OriginTypeName LIKE '%Kenya%' OR
 OriginTypeName LIKE '%Algeria%' OR
 OriginTypeName LIKE '%Rwanda%' OR
 OriginTypeName = 'Various/Unknown')
 THEN 'African Civil Wars'

 WHEN ([Year] BETWEEN 1979 and 1981 
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Afghanistan%' OR
 OriginTypeName LIKE '%Iran%' OR
 OriginTypeName LIKE '%Iraq%' OR
 OriginTypeName LIKE '%Palestinian%')
 THEN 'Soviet Invasion of Afghanistan'

 WHEN ([Year] BETWEEN 1982 and 1982
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Argentina%')
 THEN 'Falklands War'

 WHEN ([Year] BETWEEN 1983 and 1983
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Grenada%' OR
 OriginTypeName LIKE '%Cuba%')
 THEN 'Invasion of Grenada'

 WHEN ([Year] BETWEEN 1984 and 1987
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%India%' OR 
 OriginTypeName LIKE '%Pakistan%')
 THEN 'Siachen Conflict'

 WHEN ([Year] BETWEEN 1988 and 1988
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%Uganda%' OR
 OriginTypeName LIKE '%Sudan%' OR 
 OriginTypeName LIKE '%Congo%' OR 
 OriginTypeName LIKE '%Central African Rep.%')
 THEN 'Lords Resistance Army Insurgency'

 WHEN ([Year] BETWEEN 1989 and 1989
 AND OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName = 'Various/Unknown')) 
 OR OriginTypeID = (SELECT OriginTypeID from ORIGIN_TYPE
 WHERE OriginTypeName LIKE '%India%' OR 
 OriginTypeName LIKE '%Pakistan%')
 THEN 'Kashmiri Insurgency'
 ELSE 'Other Conflicts'
END)

Select * from ORIGIN_TYPE