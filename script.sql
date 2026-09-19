/****** Object:  Database [Attendance]    Script Date: 10.09.2026 23:27:23 ******/
CREATE DATABASE [Attendance]
GO
USE [Attendance]
/****** Object:  UserDefinedFunction [dbo].[GetAttendance]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetAttendance]
(
    @idStudent int,
    @date date
)
RETURNS @table TABLE (AttendChar nchar(1)
					, IsReasonable bit NULL
					, IdLesson int NULL
					, IdStudent int NULL)
AS
BEGIN
DECLARE @i tinyint;
DECLARE @j tinyint;
DECLARE @firstPair tinyint;
DECLARE	@lastPair tinyint;

SELECT @firstPair = FirstPair, @lastPair = LastPair
FROM Days
WHERE Date = @date;

SET @i = 1;

WHILE @i<@firstPair
	BEGIN
		INSERT INTO @table
		SELECT '', null, null, null;
		SET @i= @i+1;
	END

SET @j = @i;
WHILE @j <= @lastPair
	BEGIN
		INSERT INTO @table
		SELECT '+', NULL, Lessons.IdLesson, @idStudent
		FROM Lessons INNER JOIN
             Days ON Lessons.IdDay = Days.IdDay
		WHERE OrderNumber = @j AND (Date = @date) AND IdLesson NOT IN(SELECT IdLesson 
													FROM  LessonAttends
													WHERE IdStudent = @idStudent);
		SET @j = @j+1;
	END

SET @j = @i;
WHILE @j<=@lastPair
	BEGIN
		INSERT INTO @table
		SELECT LessonAttends.AttendChar, LessonAttends.IsReasonable, Lessons.IdLesson, @idStudent AS Expr1
		FROM Lessons INNER JOIN
             LessonAttends ON Lessons.IdLesson = LessonAttends.IdLesson INNER JOIN
             Days ON Lessons.IdDay = Days.IdDay
        WHERE (Lessons.OrderNumber = @j) AND (LessonAttends.IdStudent = @idStudent) AND (Date = @date);
		SET @j= @j+1;
	END
RETURN
END


GO
/****** Object:  UserDefinedFunction [dbo].[GetAttendCharValue]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetAttendCharValue] 
(
	@char nchar(1)
)
RETURNS INT
AS
BEGIN
	DECLARE @ResultVar int
	SELECT @ResultVar =	CASE @char
							WHEN '-' THEN 2 
							WHEN '/' THEN 1
							ELSE 0
						END
	RETURN @ResultVar
END
GO
/****** Object:  Table [dbo].[PeriodReasonableMissings]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PeriodReasonableMissings](
	[Name] [nvarchar](50) NOT NULL,
	[Date] [date] NOT NULL,
	[Reasonable] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ReasonableSumView]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ReasonableSumView]
AS
SELECT        Name, SUM(Reasonable) AS Reasonable
FROM            dbo.PeriodReasonableMissings
GROUP BY Name
GO
/****** Object:  Table [dbo].[PeriodAttendance]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PeriodAttendance](
	[Name] [nvarchar](50) NOT NULL,
	[Date] [date] NOT NULL,
	[Missing] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[MissingSumView]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[MissingSumView]
AS
SELECT        Name, SUM(Missing) AS Missing
FROM            dbo.PeriodAttendance
GROUP BY Name
GO
/****** Object:  View [dbo].[AttendanceSumView]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AttendanceSumView]
AS
SELECT        dbo.MissingSumView.Name, dbo.MissingSumView.Missing, dbo.ReasonableSumView.Reasonable, dbo.MissingSumView.Missing - dbo.ReasonableSumView.Reasonable AS UnReasonable
FROM            dbo.MissingSumView INNER JOIN
                         dbo.ReasonableSumView ON dbo.MissingSumView.Name = dbo.ReasonableSumView.Name
GO
/****** Object:  View [dbo].[StudentsWithoutMissings]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[StudentsWithoutMissings]
AS
SELECT        Name
FROM            dbo.PeriodAttendance
GROUP BY Name
HAVING        (SUM(Missing) = 0)
GO
/****** Object:  Table [dbo].[Days]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Days](
	[IdDay] [int] IDENTITY(1,1) NOT NULL,
	[Date] [date] NOT NULL,
	[FirstPair] [tinyint] NOT NULL,
	[LastPair] [tinyint] NOT NULL,
 CONSTRAINT [PK_Days] PRIMARY KEY CLUSTERED 
(
	[IdDay] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Editors]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Editors](
	[IdUser] [int] NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Redactors] PRIMARY KEY CLUSTERED 
(
	[IdUser] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Guests]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Guests](
	[IdUser] [int] NOT NULL,
	[IsPrime] [bit] NOT NULL,
 CONSTRAINT [PK_Guests] PRIMARY KEY CLUSTERED 
(
	[IdUser] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LessonAttends]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LessonAttends](
	[IdLesson] [int] NOT NULL,
	[IdStudent] [int] NOT NULL,
	[AttendChar] [nchar](1) NOT NULL,
	[IsReasonable] [bit] NULL,
 CONSTRAINT [PK_LessonAttends] PRIMARY KEY CLUSTERED 
(
	[IdLesson] ASC,
	[IdStudent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Lessons]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Lessons](
	[IdLesson] [int] IDENTITY(1,1) NOT NULL,
	[IdDay] [int] NOT NULL,
	[IdSubject] [int] NOT NULL,
	[OrderNumber] [tinyint] NOT NULL,
 CONSTRAINT [PK_Lessons] PRIMARY KEY CLUSTERED 
(
	[IdLesson] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Schedules]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Schedules](
	[IdSubject] [int] NOT NULL,
	[DayOfWeek] [tinyint] NOT NULL,
	[OrderNumber] [tinyint] NOT NULL,
	[IsEven] [bit] NOT NULL,
 CONSTRAINT [PK_Schedules] PRIMARY KEY CLUSTERED 
(
	[DayOfWeek] ASC,
	[OrderNumber] ASC,
	[IsEven] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Students]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Students](
	[IdStudent] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[IsDismissed] [bit] NOT NULL,
 CONSTRAINT [PK_Students] PRIMARY KEY CLUSTERED 
(
	[IdStudent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Subjects]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Subjects](
	[IdSubject] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[IsActual] [bit] NOT NULL,
 CONSTRAINT [PK_Subjects] PRIMARY KEY CLUSTERED 
(
	[IdSubject] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SummaryMissings]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SummaryMissings](
	[Name] [nvarchar](50) NOT NULL,
	[2026-09-10] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[IdUser] [int] IDENTITY(1,1) NOT NULL,
	[Login] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[IdUser] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[Days] ON 
GO
INSERT [dbo].[Days] ([IdDay], [Date], [FirstPair], [LastPair]) VALUES (1, CAST(N'2026-09-10' AS Date), 1, 3)
GO
SET IDENTITY_INSERT [dbo].[Days] OFF
GO
INSERT [dbo].[Editors] ([IdUser], [Password]) VALUES (6, N'editor')
GO
INSERT [dbo].[Guests] ([IdUser], [IsPrime]) VALUES (7, 0)
GO
INSERT [dbo].[Guests] ([IdUser], [IsPrime]) VALUES (8, 1)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (329, 13, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (330, 2, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (330, 6, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (330, 9, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (330, 11, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (330, 15, N'/', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (331, 6, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (331, 11, N'-', 0)
GO
INSERT [dbo].[LessonAttends] ([IdLesson], [IdStudent], [AttendChar], [IsReasonable]) VALUES (331, 12, N'-', 0)
GO
SET IDENTITY_INSERT [dbo].[Lessons] ON 
GO
INSERT [dbo].[Lessons] ([IdLesson], [IdDay], [IdSubject], [OrderNumber]) VALUES (329, 1, 1, 1)
GO
INSERT [dbo].[Lessons] ([IdLesson], [IdDay], [IdSubject], [OrderNumber]) VALUES (330, 1, 1, 2)
GO
INSERT [dbo].[Lessons] ([IdLesson], [IdDay], [IdSubject], [OrderNumber]) VALUES (331, 1, 2, 3)
GO
SET IDENTITY_INSERT [dbo].[Lessons] OFF
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Аверин Е.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Бородяев С.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Брызгунов И.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Васильев А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Гриб Я.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Демьянюк Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Елисеев Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Носов К.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Поликина Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Поспелов П.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Садовский Р.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Танашев Р.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Федорцов Г.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Шаньгин М.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Шевцов А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Шефов Н.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Щукин Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Андронов Н.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Зайцев Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Рангелов Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Шонин М.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Кулагин Д.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Боровская А.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Васильев Р.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Дорофеев К.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Зайцев А.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Олонкин А.', CAST(N'2026-09-10' AS Date), 1)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Васильев Р.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Зайцев А.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodAttendance] ([Name], [Date], [Missing]) VALUES (N'Знатных Д.', CAST(N'2026-09-10' AS Date), 2)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Аверин Е.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Боровская А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Бородяев С.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Брызгунов И.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Васильев А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Васильев Р.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Гриб Я.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Демьянюк Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Дорофеев К.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Елисеев Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Зайцев А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Знатных Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Кулагин Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Носов К.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Олонкин А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Поликина Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Поспелов П.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Садовский Р.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Танашев Р.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Федорцов Г.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Шаньгин М.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Шевцов А.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Шефов Н.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Щукин Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Андронов Н.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Зайцев Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Рангелов Д.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[PeriodReasonableMissings] ([Name], [Date], [Reasonable]) VALUES (N'Шонин М.', CAST(N'2026-09-10' AS Date), 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 1, 3, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 1, 4, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 2, 1, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (6, 2, 2, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (6, 2, 2, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 2, 3, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 2, 3, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 2, 4, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 2, 4, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (4, 3, 2, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 3, 3, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (3, 3, 4, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (5, 5, 1, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (5, 5, 2, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (5, 5, 2, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (4, 5, 3, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (4, 5, 3, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (4, 5, 4, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (2, 6, 1, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (2, 6, 1, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (2, 6, 2, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (2, 6, 2, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (2, 6, 3, 0)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (2, 6, 3, 1)
GO
INSERT [dbo].[Schedules] ([IdSubject], [DayOfWeek], [OrderNumber], [IsEven]) VALUES (1, 6, 4, 0)
GO
SET IDENTITY_INSERT [dbo].[Students] ON 
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (1, N'Аверин Е.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (2, N'Боровская А.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (3, N'Бородяев С.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (4, N'Брызгунов И.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (5, N'Васильев А.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (6, N'Васильев Р.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (7, N'Гриб Я.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (8, N'Демьянюк Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (9, N'Дорофеев К.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (10, N'Елисеев Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (11, N'Зайцев А.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (12, N'Знатных Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (13, N'Кулагин Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (14, N'Носов К.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (15, N'Олонкин А.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (16, N'Поликина Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (17, N'Поспелов П.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (18, N'Садовский Р.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (19, N'Танашев Р.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (20, N'Федорцов Г.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (21, N'Шаньгин М.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (22, N'Шевцов А.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (23, N'Шефов Н.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (24, N'Щукин Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (25, N'Макаров К.', 1)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (26, N'Андронов Н.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (27, N'Зайцев Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (28, N'Рангелов Д.', 0)
GO
INSERT [dbo].[Students] ([IdStudent], [Name], [IsDismissed]) VALUES (30, N'Шонин М.', 0)
GO
SET IDENTITY_INSERT [dbo].[Students] OFF
GO
SET IDENTITY_INSERT [dbo].[Subjects] ON 
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (1, N'МДК.01.02', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (2, N'МДК.02.02', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (3, N'Английский язык', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (4, N'БЖД', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (5, N'Философия', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (6, N'Физкультура', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (8, N'МДК.02.01', 0)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (9, N'МДК.04.01', 0)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (10, N'Экономика', 0)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (11, N'УП.01', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (12, N'УП.02', 1)
GO
INSERT [dbo].[Subjects] ([IdSubject], [Name], [IsActual]) VALUES (15, N'МДК.01.01', 0)
GO
SET IDENTITY_INSERT [dbo].[Subjects] OFF
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Аверин Е.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Андронов Н.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Боровская А.', 2)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Бородяев С.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Брызгунов И.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Васильев А.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Васильев Р.', 4)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Гриб Я.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Демьянюк Д.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Дорофеев К.', 2)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Елисеев Д.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Зайцев А.', 4)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Зайцев Д.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Знатных Д.', 2)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Кулагин Д.', 2)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Носов К.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Олонкин А.', 1)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Поликина Д.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Поспелов П.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Рангелов Д.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Садовский Р.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Танашев Р.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Федорцов Г.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Шаньгин М.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Шевцов А.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Шефов Н.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Шонин М.', 0)
GO
INSERT [dbo].[SummaryMissings] ([Name], [2026-09-10]) VALUES (N'Щукин Д.', 0)
GO
SET IDENTITY_INSERT [dbo].[Users] ON 
GO
INSERT [dbo].[Users] ([IdUser], [Login]) VALUES (6, N'editor')
GO
INSERT [dbo].[Users] ([IdUser], [Login]) VALUES (7, N'guest')
GO
INSERT [dbo].[Users] ([IdUser], [Login]) VALUES (8, N'guestEx')
GO
SET IDENTITY_INSERT [dbo].[Users] OFF
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_Subjects]    Script Date: 10.09.2026 23:27:23 ******/
ALTER TABLE [dbo].[Subjects] ADD  CONSTRAINT [UQ_Subjects] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_Users]    Script Date: 10.09.2026 23:27:23 ******/
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [UQ_Users] UNIQUE NONCLUSTERED 
(
	[IdUser] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Guests] ADD  CONSTRAINT [DF_Guests_IsPrime]  DEFAULT ((0)) FOR [IsPrime]
GO
ALTER TABLE [dbo].[LessonAttends] ADD  CONSTRAINT [DF_LessonAttends_AttendChar]  DEFAULT (N'-') FOR [AttendChar]
GO
ALTER TABLE [dbo].[Students] ADD  CONSTRAINT [DF_Students_IsDismissed]  DEFAULT ((0)) FOR [IsDismissed]
GO
ALTER TABLE [dbo].[Subjects] ADD  CONSTRAINT [DF_Subjects_IsAtual]  DEFAULT ((1)) FOR [IsActual]
GO
ALTER TABLE [dbo].[Editors]  WITH CHECK ADD  CONSTRAINT [FK_Redactors_Users] FOREIGN KEY([IdUser])
REFERENCES [dbo].[Users] ([IdUser])
GO
ALTER TABLE [dbo].[Editors] CHECK CONSTRAINT [FK_Redactors_Users]
GO
ALTER TABLE [dbo].[Guests]  WITH CHECK ADD  CONSTRAINT [FK_Guests_Users] FOREIGN KEY([IdUser])
REFERENCES [dbo].[Users] ([IdUser])
GO
ALTER TABLE [dbo].[Guests] CHECK CONSTRAINT [FK_Guests_Users]
GO
ALTER TABLE [dbo].[LessonAttends]  WITH CHECK ADD  CONSTRAINT [FK_LessonAttends_Lessons] FOREIGN KEY([IdLesson])
REFERENCES [dbo].[Lessons] ([IdLesson])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LessonAttends] CHECK CONSTRAINT [FK_LessonAttends_Lessons]
GO
ALTER TABLE [dbo].[LessonAttends]  WITH CHECK ADD  CONSTRAINT [FK_LessonAttends_Students] FOREIGN KEY([IdStudent])
REFERENCES [dbo].[Students] ([IdStudent])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[LessonAttends] CHECK CONSTRAINT [FK_LessonAttends_Students]
GO
ALTER TABLE [dbo].[Lessons]  WITH CHECK ADD  CONSTRAINT [FK_Lessons_Days] FOREIGN KEY([IdDay])
REFERENCES [dbo].[Days] ([IdDay])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Lessons] CHECK CONSTRAINT [FK_Lessons_Days]
GO
ALTER TABLE [dbo].[Lessons]  WITH CHECK ADD  CONSTRAINT [FK_Lessons_Subjects] FOREIGN KEY([IdSubject])
REFERENCES [dbo].[Subjects] ([IdSubject])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Lessons] CHECK CONSTRAINT [FK_Lessons_Subjects]
GO
ALTER TABLE [dbo].[Schedules]  WITH CHECK ADD  CONSTRAINT [FK_Schedules_Subjects] FOREIGN KEY([IdSubject])
REFERENCES [dbo].[Subjects] ([IdSubject])
GO
ALTER TABLE [dbo].[Schedules] CHECK CONSTRAINT [FK_Schedules_Subjects]
GO
ALTER TABLE [dbo].[Lessons]  WITH CHECK ADD  CONSTRAINT [CK_Lessons_OrderNumber] CHECK  (([OrderNumber]>(0) AND [OrderNumber]<=(6)))
GO
ALTER TABLE [dbo].[Lessons] CHECK CONSTRAINT [CK_Lessons_OrderNumber]
GO
ALTER TABLE [dbo].[Schedules]  WITH CHECK ADD  CONSTRAINT [CK_Shedules_DayOfWeek] CHECK  (([DayOfWeek]>(0) AND [DayOfWeek]<(7)))
GO
ALTER TABLE [dbo].[Schedules] CHECK CONSTRAINT [CK_Shedules_DayOfWeek]
GO
ALTER TABLE [dbo].[Schedules]  WITH CHECK ADD  CONSTRAINT [CK_Shedules_OrderNumber] CHECK  (([OrderNumber]>(0) AND [OrderNumber]<=(6)))
GO
ALTER TABLE [dbo].[Schedules] CHECK CONSTRAINT [CK_Shedules_OrderNumber]
GO
/****** Object:  StoredProcedure [dbo].[AddGuest]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddGuest]
	@login nvarchar(50), 
	@isPrime bit
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Users(Login)
	VALUES (@login)
    INSERT INTO Guests(IdUser, IsPrime)
	VALUES (SCOPE_IDENTITY(), @isPrime)
END
GO
/****** Object:  StoredProcedure [dbo].[AddRedactor]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[AddRedactor]
	@login nvarchar(50), 
	@password nvarchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Users(Login)
	VALUES (@login)
    INSERT INTO Redactors(IdUser, Password)
	VALUES (SCOPE_IDENTITY(), @password)
END
GO
/****** Object:  StoredProcedure [dbo].[ClearSchedule]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ClearSchedule] 
	@dayOfWeek tinyInt,
	@isEven bit = 0
AS
BEGIN
	SET NOCOUNT ON;
    DELETE FROM Schedules
	WHERE DayOfWeek = @dayOfWeek AND IsEven = @isEven
END
GO
/****** Object:  StoredProcedure [dbo].[MissingsByPeriod]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MissingsByPeriod] 
    @startDate date,
	@endDate date
AS
BEGIN
	IF OBJECT_ID ('dbo.PeriodAttendance', 'U') IS NOT NULL  
	DROP TABLE dbo.PeriodAttendance;  
	IF OBJECT_ID ('dbo.PeriodReasonableMissings', 'U') IS NOT NULL  
	DROP TABLE dbo.PeriodReasonableMissings;  

	SELECT			dbo.Students.Name, 
					dbo.Days.Date, 
					dbo.GetAttendCharValue(dbo.LessonAttends.AttendChar) AS Missing
	INTO			dbo.PeriodMissings
    FROM            dbo.Students INNER JOIN
                         dbo.LessonAttends ON dbo.Students.IdStudent = dbo.LessonAttends.IdStudent INNER JOIN
                         dbo.Lessons ON dbo.LessonAttends.IdLesson = dbo.Lessons.IdLesson INNER JOIN
                         dbo.Days ON dbo.Lessons.IdDay = dbo.Days.IdDay
	WHERE Date>=@startDate AND Date<=@endDate AND Students.IsDismissed = 0;

	SELECT			dbo.Students.Name, dbo.Days.Date, 0 AS Missing
	INTO			dbo.PeriodAttends
	FROM            dbo.Students CROSS JOIN
                    dbo.Days
	WHERE Date>=@startDate AND Date<=@endDate AND Students.IsDismissed = 0;;

	--
	SELECT	Name, 
			Date,
			Missing
	INTO PeriodAttendance
	FROM PeriodAttends
	WHERE NOT EXISTS (	SELECT Name, Date
						FROM PeriodMissings
						WHERE PeriodAttends.Name = PeriodMissings.Name AND PeriodAttends.Date = PeriodMissings.Date)
	UNION ALL
	SELECT	Name, 
			Date,
			Missing
	FROM PeriodMissings;
	--

	
	SELECT			dbo.Students.Name, 
					dbo.Days.Date, 
					dbo.GetAttendCharValue(dbo.LessonAttends.AttendChar) AS Missing

	INTO			dbo.PeriodReasonable
	FROM            dbo.Students INNER JOIN
                    dbo.LessonAttends ON dbo.Students.IdStudent = dbo.LessonAttends.IdStudent INNER JOIN
                    dbo.Lessons ON dbo.LessonAttends.IdLesson = dbo.Lessons.IdLesson INNER JOIN
                    dbo.Days ON dbo.Lessons.IdDay = dbo.Days.IdDay
	WHERE Date>=@startDate AND Date<=@endDate AND IsReasonable = 1 AND Students.IsDismissed = 0;

	SELECT	Name, 
		Date,
		Missing as Reasonable
	INTO PeriodReasonableMissings
	FROM PeriodAttends
	WHERE NOT EXISTS (	SELECT Name, Date
					FROM PeriodReasonable
					WHERE PeriodAttends.Name = PeriodReasonable.Name AND PeriodAttends.Date = PeriodReasonable.Date)
	UNION ALL
	SELECT	Name, 
			Date,
			Missing
	FROM PeriodReasonable;

	DROP TABLE dbo.PeriodReasonable;
	
	DROP TABLE dbo.PeriodMissings;  
	DROP TABLE dbo.PeriodAttends;  

    RETURN
END
GO
/****** Object:  StoredProcedure [dbo].[SP_Dynamic_Pivot]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   -- Создаем универсальную процедуру для динамического PIVOT   
   CREATE PROCEDURE [dbo].[SP_Dynamic_Pivot]
   (
        @TableSRC NVARCHAR(100),   --Таблица источник (Представление)
        @ColumnName NVARCHAR(100), --Столбец, содержащий значения, которые станут именами столбцов
        @Field NVARCHAR(100),      --Столбец, над которым проводить агрегацию
        @FieldRows NVARCHAR(100),  --Столбец (столбцы) для группировки по строкам (Column1, Column2)
        @FunctionType NVARCHAR(20) = 'SUM',--Агрегатная функция (SUM, COUNT, MAX, MIN, AVG), по умолчанию SUM
        @Condition NVARCHAR(200) = '', --Условие (WHERE и т.д.). По умолчанию без условия
		@OutputTable NVARCHAR(100)
   )
   AS 
   BEGIN
        --Отключаем вывод количества строк
        SET NOCOUNT ON;
        
        --Переменная для хранения строки запроса
        DECLARE @Query NVARCHAR(MAX);                     
         --Переменная для хранения имен столбцов
        DECLARE @ColumnNames NVARCHAR(MAX);              
        --Переменная для хранения заголовков результирующего набора данных
        DECLARE @ColumnNamesHeader NVARCHAR(MAX); 

        --Обработчик ошибок
        BEGIN TRY

				IF OBJECT_ID (@OutputTable, 'U') IS NOT NULL  
				EXEC ('DROP TABLE '+@OutputTable+';');

                --Таблица для хранения уникальных значений, 
                --которые будут использоваться в качестве столбцов      
                CREATE TABLE #ColumnNames(ColumnName NVARCHAR(100) NOT NULL PRIMARY KEY);
        
                --Формируем строку запроса для получения уникальных значений для имен столбцов
                SET @Query = N'INSERT INTO #ColumnNames (ColumnName)
                                                  SELECT DISTINCT COALESCE(' + @ColumnName + ', ''Пусто'') 
                                                  FROM ' + @TableSRC + ' ' + @Condition + ';'
                
                --Выполняем строку запроса
                EXEC (@Query);

                --Формируем строку с именами столбцов
                SELECT @ColumnNames = ISNULL(@ColumnNames + ', ','') + QUOTENAME(ColumnName) 
                FROM #ColumnNames;
                
                --Формируем строку для заголовка динамического перекрестного запроса (PIVOT)
                SELECT @ColumnNamesHeader = ISNULL(@ColumnNamesHeader + ', ','') 
                                                                        + 'COALESCE('
                                                                        + QUOTENAME(ColumnName) 
                                                                        + ', 0) AS '
                                                                        + QUOTENAME(ColumnName)
                FROM #ColumnNames;
        
                --Формируем строку с запросом PIVOT
                SET @Query = N'SELECT ' + @FieldRows + ' , ' + @ColumnNamesHeader + '
										   INTO ' + @OutputTable +'
                                           FROM (SELECT ' + @FieldRows + ', ' + @ColumnName + ', ' + @Field 
                                                         + ' FROM ' + @TableSRC  + ' ' + @Condition + ') AS SRC
                                           PIVOT ( ' + @FunctionType + '(' + @Field + ')' +' FOR ' +  
                                                                   @ColumnName + ' IN (' + @ColumnNames + ')) AS PVT
                                           ORDER BY ' + @FieldRows + ';'
                
                --Удаляем временную таблицу
                DROP TABLE #ColumnNames;

                --Выполняем строку запроса с PIVOT
                EXEC (@Query);
                
                --Включаем обратно вывод количества строк
                SET NOCOUNT OFF;
                
        END TRY
        BEGIN CATCH
                --В случае ошибки, возвращаем номер и описание этой ошибки
                SELECT ERROR_NUMBER() AS [Номер ошибки], 
                           ERROR_MESSAGE() AS [Описание ошибки]
        END CATCH
   END
GO
/****** Object:  Trigger [dbo].[TR_DeleteEditorUser]    Script Date: 10.09.2026 23:27:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_DeleteEditorUser]
   ON  [dbo].[Editors]
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	DELETE 
	FROM Users
	WHERE idUser IN (SELECT idUser FROM deleted)
END
/****** Object:  Trigger [dbo].[TR_DeleteGuestUser]    Script Date: 10.05.2022 22:46:12 ******/
SET ANSI_NULLS ON
GO
ALTER TABLE [dbo].[Editors] ENABLE TRIGGER [TR_DeleteEditorUser]
GO
/****** Object:  Trigger [dbo].[TR_DeleteGuestUser]    Script Date: 10.09.2026 23:27:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_DeleteGuestUser]
   ON  [dbo].[Guests]
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	DELETE 
	FROM Users
	WHERE idUser IN (SELECT idUser FROM deleted)
END
GO
ALTER TABLE [dbo].[Guests] ENABLE TRIGGER [TR_DeleteGuestUser]
GO
/****** Object:  Trigger [dbo].[TR_DeleteStudent]    Script Date: 10.09.2026 23:27:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_DeleteStudent] 
   ON  [dbo].[Students]
   INSTEAD OF DELETE
AS 
BEGIN
	SET NOCOUNT ON;

	DELETE Students
	WHERE IdStudent IN (SELECT IdStudent FROM deleted WHERE IsDismissed = 1);

	UPDATE Students
	SET IsDismissed = 1
	WHERE IdStudent IN (SELECT IdStudent FROM deleted);
END
/****** Object:  Trigger [dbo].[TR_DeleteEditorUser]    Script Date: 10.05.2022 22:46:11 ******/
SET ANSI_NULLS ON
GO
ALTER TABLE [dbo].[Students] ENABLE TRIGGER [TR_DeleteStudent]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "MissingSumView"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 102
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ReasonableSumView"
            Begin Extent = 
               Top = 6
               Left = 250
               Bottom = 102
               Right = 424
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AttendanceSumView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'AttendanceSumView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PeriodAttendance"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 119
               Right = 228
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'MissingSumView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'MissingSumView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PeriodReasonableMissings"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 119
               Right = 228
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReasonableSumView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ReasonableSumView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PeriodAttendance"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 119
               Right = 228
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'StudentsWithoutMissings'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'StudentsWithoutMissings'
GO
ALTER DATABASE [Attendance] SET  READ_WRITE 
GO
