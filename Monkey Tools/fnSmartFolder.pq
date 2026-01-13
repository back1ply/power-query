//// Query written by Ken Puls, FCPA, FCMA, MS MVP (Excel) (www.excelguru.ca)
// Injected into this workbook via Monkey Tools at the model designer's request
// For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
//
// To use this function you must pass it the path to either a local folder or the equivalent
// path for Office 365's SharePoint url.  The easiest way to acquire this information is to place
// the following formula in a cell in the Excel Workbook:
// =IFERROR(LEFT(@CELL("filename",A1),FIND("[",@CELL("filename",A1),1)-1),"Workbook needs to be saved!")

let 
	fnSmartFolder = (FullFolderPath as text, optional IncludeSubfolders as logical) as table =>

	let
		IncludeSubfolders = if IncludeSubfolders = null then true else IncludeSubfolders,
		BlankTable = Table.FromRows({},{"Content","Name","Extension","Date accesssed","Date modified","Date created","Attributes","Folder Path"}),
		Source = if Text.StartsWith(FullFolderPath,"https://") then
			let
				FullFolderPath = Text.Replace(FullFolderPath,"\","/"),
				FolderPath = 
					if Text.EndsWith(FullFolderPath,"/") 
					then Text.Start(FullFolderPath,Text.Length(FullFolderPath)-1) 
					else FullFolderPath,
				SharePointSite = Text.BeforeDelimiter(FolderPath,"/",4),
				SharePointFiles = if IncludeSubfolders = true then
					let
						Source = SharePoint.Files(Text.BeforeDelimiter(FolderPath,"/",4), [ApiVersion = 15]),
						#"Filtered Rows" = Table.SelectRows(Source, each Text.StartsWith([Folder Path], FolderPath))
					in
						#"Filtered Rows"
				else
					let
						Source = SharePoint.Contents(Text.BeforeDelimiter(FolderPath,"/",4), [ApiVersion = 15]),
						Folders = Text.Split(Text.AfterDelimiter(FolderPath,"/",4),"/"),

						NavigateToFolder = List.Accumulate(
							{0..List.Count(Folders) -1 },
							Source,
							(state, current) => state{[Name=Folders{current}]}[Content]
							)
					in
						NavigateToFolder,
				
				StripRootFolder = Table.ReplaceValue(SharePointFiles,FolderPath & "/","",Replacer.ReplaceText,{"Folder Path"})
			in 
				StripRootFolder

		else
			let
				FullFolderPath = Text.Replace(FullFolderPath,"/","\"),
				FolderPath = 
					if Text.EndsWith(FullFolderPath,"\") 
					then FullFolderPath 
					else FullFolderPath & "\",
				Source = if IncludeSubfolders = true then
					Folder.Files(FolderPath)
				else
					Folder.Contents(FolderPath),
				StripRootFolder = Table.ReplaceValue(Source,FolderPath ,"",Replacer.ReplaceText,{"Folder Path"})
			in 
				StripRootFolder
				,
		DesiredOutput = Table.ReplaceValue(Source,"/","\",Replacer.ReplaceText,{"Folder Path"}),
		ActiveTable = try DesiredOutput otherwise BlankTable,
		Output = Table.TransformColumns(ActiveTable,{{"Extension", Text.Lower, type text}})
	in
		Output,

	fnDocumentation = type function
		(
			FullFolderPath as (type text meta [
				Documentation.FieldCaption = "FullFolderPath",
				Documentation.FieldDescription = "Enter full path to local or SharePoint (sub)folder",
				Documentation.SampleValues = {"C:\DataFiles\SubFolder"}
			]),
			optional IncludeSubfolders as (type logical meta [
				Documentation.FieldCaption = "IncludeSubfolders",
				Documentation.FieldDescription = "Would you like to include files in subfolders?",
				Documentation.SampleValues = {"true (default), false"}
			])
		) as table meta
			[
				Documentation.Name = "fnSmartFolder",
				Documentation.MTVersion = 2.1,
				Documentation.LongDescription = "The <code>fnSmartFolder</code> function will accept a <i>full folder path</i> (local or SharePoint hosted) and display all files contained within it. It also:"
					& "<ul>"
					& "<li>-Removes the folder path from the beginning of the Folder column (to allow easier location of subfolders)</li>"
					& "<li>-Replaces all / separators with \ (to allow for filters that work when dynamically switch from local to SharePoint folders)</li>"
					& "<li>-Contains an optional <code>true</code> or <code>false</code> parameter to display files in subfolders (true) or not (false)</li>"
					& "</ul>"
					& "Technical info you may not care about: This function dynamically switches between the <code>SharePoint.Files()</code> and <code>Folder.Files()</code> connections by default, or <code>SharePoint.Contents()</code> and <code>Folder.Contents()</code> if you set the optional <code>IncludeSubfolders</code> parameter to <code>false</code>.",
				Documentation.Examples = 
					{
						[
							Description = "Working with a local file path to retrieve files in folder and subfolders (using the Folder.Files() function).",
							Code = "=fnSmartFolder(""C:\Users\<username>\<companyname>\MonkeyTools - General\Demos"",true)",
							Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
									&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
									&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
									&"| [Binary] | Csv1.csv   | .csv      | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   | CSVs\       | #(lf)"
									&"-------------------------------------------------------------------------------------------------------------------------"
						],
						[
							Description = "Working with a local file path to retrieve files in selected folder only (using the Folder.Contents() function).",
							Code = "=fnSmartFolder(""C:\Users\<username>\<companyname>\MonkeyTools - General\Demos"",false)",
							Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
									&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
									&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
									&"-------------------------------------------------------------------------------------------------------------------------"
						],
						[
							Description = "Working with a SharePoint file path to retrieve files in folder and subfolders (using the SharePoint.Files() function).",
							Code = "=fnSmartFolder(""https://domain.sharepoint.com/sites/MonkeyTools/Shared Documents/General/Demos/"",true)",
							Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
									&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
									&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
									&"| [Binary] | Csv1.csv   | .csv      | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   | CSVs\       | #(lf)"
									&"-------------------------------------------------------------------------------------------------------------------------"
						]
						,
						[
							Description = "Working with a SharePoint file path to retrieve files in selected folder only (using the SharePoint.Contents() function).",
							Code = "=fnSmartFolder(""https://domain.sharepoint.com/sites/MonkeyTools/Shared Documents/General/Demos/"",false)",
							Result = "| Content  |   Name     | Extension | Date accesssed   | Date modified    | Date created     | Attributes | Folder Path | #(lf)"
									&"------------------------------------------------------------------------------------------------------------------------- #(lf)"
									&"| [Binary] | File1.xlsx | .xlsx     | 2023-08-01 23:02 | 2023-08-01 23:02 | 2023-08-01 23:02 | [Record]   |             | #(lf)"
									&"-------------------------------------------------------------------------------------------------------------------------"
						]
					}
			],
	DocumentedFunction = Value.ReplaceType(
		fnSmartFolder,
		fnDocumentation
		)
in
	DocumentedFunction
