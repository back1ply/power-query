// fnSmartFile
// Query written by Ken Puls, FCPA, FCMA, MS MVP (Excel) (www.excelguru.ca)
// Injected into this workbook via Monkey Tools at the model designer's request
// For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
//
// To use this function you must pass it the path to either a local file or the equivalent
// path for Office 365's SharePoint url.  The easiest way to acquire this information for the 
// current workbook is to place the following formula in a cell in the Excel Workbook:
// =IFERROR(SUBSTITUTE(LEFT(@CELL("filename",A1),FIND("]",@CELL("filename",A1),1)-1),"[",""),"Workbook needs to be saved!")

let
	fnSmartFile = (FilePath as text) as any =>

let
	BlankTable_Excel = Table.FromRows( {}, { "Name", "Data", "Item", "Kind", "Hidden" } ),
	BlankTable_Access = Table.FromRows( {}, { "Name", "Data", "Schema", "Item", "Kind" } ),
	FileExtension = Text.Lower(List.Reverse(Splitter.SplitTextByDelimiter(".")(FilePath)){0}),
 	Source = 
	 	if Text.StartsWith( FilePath, "https://" ) 
	 	then 
			let 
				FilePath = Text.Replace( Text.Replace( FilePath, "\", "/" ), " ", "%20" ),  
				Source = Web.Contents(FilePath)
			in 
				Source 
		else 
			let Source = File.Contents(FilePath) 
		in 
			Source,
	Output = 
		if Text.StartsWith(FileExtension,"xls")
		then try Excel.Workbook( Source, null, true) otherwise BlankTable_Excel
		else if FileExtension = "accdb" or FileExtension = "mdb"
		then try Access.Database( Source ) otherwise BlankTable_Access
		else Source
in
    Output,
	fnDocumentation = type function (
		FilePath as (
			type text meta [
				Documentation.FieldCaption = "FilePath",
				Documentation.SampleValues = "{C:\DataFiles\Filename.xlsx}"
				]
			)
		)
		as any meta [
			Documentation.Name = "fnSmartFile",
			Documentation.MTVersion = 1.1,
			Documentation.LongDescription = "The <code>fnSmartFile</code> function will accept a <i>the full path</i> to a local or SharePoint hosted file and is designed to 'smart switch' between the Web and Local required connectors should the file path dynamically change.<br>"
					&"Note that the behaviour of the connector depends on the type of files you connect to:<br>"
					&"<ul>"
					&"<li>Excel: Displays a table including the standard columns found when connecting to an external Excel file.</li>"
					&"<li>Access: Excel: Displays a table including the standard columns found when connecting to an external Access database.</li>"
					&"<li>All others: Due to the fact that each file needs to be interpreted differently by Power Query, our Monkey displays the file itself. Double click the file to allow Power Query to interpret it, or right click it and tell Power Query what type of file it is that you are looking at.</li>"
					&"</ul>"
					&"To learn more about how this function works, see https://monkeytools.ca/smartfile-function/",
			Documentation.Examples =
			{
				[   Description= "Working with an Excel file",
					Code = "fnSmartFile(""C:\DataFiles\Filename.xlsx"")",
					Result = "|  Name     |  Data     |  Item     |  Kind         |  Hidden    |#(lf)"
					&"------------------------------------------------------------------#(lf)"
					&"|  Summary  |  [Table]  |  Summary  |  Sheet        |  FALSE     |#(lf)"
					&"|  Data     |  [Table]  |  Data     |  Sheet        |  FALSE     |#(lf)"
					&"|  Table1   |  [Table]  |  Table    |  Sheet        |  FALSE     |#(lf)"
					&"|  Sales    |  [Table]  |  Sales    |  Sheet        |  FALSE     |#(lf)"
					&"|  rngHome  |  [Table]  |  rngHome  |  Named Range  |  FALSE     |"
				],
				[   Description= "Working with an Access database",
					Code = "=fnSmartFile(""C:\DataFiles\Access.accdb"")",
					Result = "|  Name       |  Data     |   Schema    |  Item        |  Kind    |#(lf)"
					&"-------------------------------------------------------------------#(lf)"
					&"|  tblBudgets |  [Table]  |             |  tblBudgets  |  Table   |#(lf)"
					&"|  tblSales   |  [Table]  |             |  tblSales    |  Table   |"
				],
				[   Description= "Working with a csv, text, json or other file type",
					Code = "=fnSmartFile(""C:\DataFiles\Data.csv"")",
					Result = "Data.csv file (with logo)"
				]
			}
		],
	DocumentedFunction = Value.ReplaceType(
		fnSmartFile,
		fnDocumentation
		)
in
	DocumentedFunction
