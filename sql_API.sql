USE [DEMO_IOT]
GO
/****** Object:  Table [dbo].[Sensor]    Script Date: 15/05/2024 1:59:50 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sensor](
	[SID] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Unit] [nvarchar](50) NULL,
	[Value] [decimal](18, 2) NULL,
	[Time] [datetime] NULL,
 CONSTRAINT [PK_Sensor] PRIMARY KEY CLUSTERED 
(
	[SID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SensorHistory]    Script Date: 15/05/2024 1:59:50 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SensorHistory](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SID] [int] NULL,
	[Value] [decimal](18, 2) NULL,
	[Time] [datetime] NULL,
 CONSTRAINT [PK_SensorHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SensorHistory]  WITH CHECK ADD  CONSTRAINT [FK_SensorHistory_Sensor] FOREIGN KEY([SID])
REFERENCES [dbo].[Sensor] ([SID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[SensorHistory] CHECK CONSTRAINT [FK_SensorHistory_Sensor]
GO
/****** Object:  StoredProcedure [dbo].[SP_Chart]    Script Date: 15/05/2024 1:59:50 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Do DUy Cop
-- Create date: 13.5.2024
-- Description:	Get data json for google chart
-- =============================================
CREATE PROCEDURE [dbo].[SP_Chart]
	@sid int,
	@timeFrom datetime=null,
	@timeEnd  datetime=null
AS
BEGIN
	if(@timeEnd is null or @timeEnd>GetDate())set @timeEnd=getdate();
	if(@timeFrom is null or @timeFrom>@timeEnd)set @timeFrom=dateAdd(HOUR,-48,@timeEnd);
	declare @name nvarchar(50);
	select @name = name from Sensor where sid=@sid;
	declare c cursor for 
		select value,time 
		from SensorHistory
		where (sid = @sid) and (time between @timeFrom and @timeEnd)
		order by time;
	open c;
	declare @value decimal(18,2), @time datetime, @value_old decimal(18,2)=0, @time_old datetime=null;
	declare @kq table(id int identity,value decimal(18,2), time datetime);
	fetch next from c into @value,@time;
	while (@@FETCH_STATUS = 0)
	begin
		declare @ss int = DateDiff(SECOND,@time_old,@time);
		if(@value != @value_old OR @time_old IS NULL OR @ss>60)
		begin
			if(@time_old is not null)
				insert into @kq(value,time)values(@value_old,@time_old);
			if(@ss>60)
			begin
				insert into @kq(value,time)values(0,@time_old),(0,@time);
			end
			insert into @kq(value,time)values(@value,@time);
		end
		select @value_old = @value, @time_old=@time; --copy 2 biến
		fetch next from c into @value,@time;
	end; --ket thuc while
	insert into @kq(value,time)values(@value,@time);
	close c;
	deallocate c;
	select @name as name,(select value as v,time as t from @kq for json path) as data
	for json path, WITHOUT_ARRAY_WRAPPER;
END
GO
