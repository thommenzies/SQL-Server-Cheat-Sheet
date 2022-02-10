Declare @searchString			varchar(MAX)
		,@SQL					varchar(MAX)
		,@currentDB				varchar(50)
		,@includeSchemas		bit = 1
		,@includeObjects		bit = 1
		,@includeCode			bit = 1
;

Set @searchString = '<<ENTER YOUR SEARCH STRING>>';

Declare @DBs Table 
	(
	[db] varchar(50)
	)
;

Declare @results Table 
	(
	[db]			varchar(50)
	,[schema]		varchar(50)
	,[object]		varchar(100)
	,[objectType]	varchar(50)
	,[foundIn]		varchar(50)
	)
;

Insert into @DBs	
	(
	[db]
	)
Select
	[name] As [db]
From
	[sys].[databases]
Order By
	[name]
; 

While (Select Count(*) From @DBs) > 0
Begin

	Select Top 1 @currentDB = [db] From @DBs
	
	Print 'Current DB = ' + @currentDB;

	If @includeObjects = 1
	Begin

		Set @SQL = '
		Select
			''' + @currentDB + ''' As [db]
			,s.[name] As [schema]
			,o.[name] As [object]
			,o.[type_desc] As [objectType]
			,''Name'' As [foundIn]
		From
			[' + @currentDB + '].[sys].[objects] o
		Join
			[' + @currentDB + '].[sys].[schemas] s
		On
			o.[schema_id] = s.[schema_id]
		Where
			o.[name] Like ''%' + @searchString + '%''
		;';

		Print @SQL;

		Insert into @results
			(
			[db]
			,[schema]
			,[object]
			,[objectType]
			,[foundIn]
			)
		Exec(@SQL)
		;
	End

	If @includeSchemas = 1
	Begin

		Set @SQL = '
		Select
			''' + @currentDB + ''' As [db]
			,Null As [schema]
			,s.[name] As [object]
			,''Schema'' As [objectType]
			,''Name'' As [foundIn]
		From
			[' + @currentDB + '].[sys].[schemas] s
		Where
			s.[name] Like ''%' + @searchString + '%''
		;';

		Print @SQL;

		Insert into @results
			(
			[db]
			,[schema]
			,[object]
			,[objectType]
			,[foundIn]
			)
		Exec(@SQL)
		;
	End

	If @includeCode = 1
	Begin

		Set @SQL = '
		Select 
			''' + @currentDB + ''' As [db]
			,s.[name] As [schema]
			,o.[name] As [object]
			,o.[type_desc] As [objectType]
			,''Code'' As [foundIn]
		From 
			[' + @currentDB + '].[sys].[syscomments] c
		Join
			[' + @currentDB + '].[sys].[objects] o
		On
			c.[id] = o.[object_id]
		Join
			[' + @currentDB + '].[sys].[schemas] s
		On
			o.[schema_id] = s.[schema_id]
		Where
			c.[text] Like ''%' + @searchString + '%''
		Group By
			s.[name]
			,o.[name]
			,o.[type_desc]
		'

		--Print @SQL;

		Insert into @results
			(
			[db]
			,[schema]
			,[object]
			,[objectType]
			,[foundIn]
			)
		Exec(@SQL)
		;

	End
	Delete From @DBs Where [db] = @currentDB;
End

Select 
	[db] As [Database]
	,[schema] As [Schema]
	,[object] As [Object]
	,[objectType] As [Object Type]
	,[foundIn] As [Found In]
From 
	@results
Order By
	[db]
	,[foundIn]
;

