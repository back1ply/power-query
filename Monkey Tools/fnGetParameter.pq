//// Query written by Ken Puls, FCPA, FCMA, MS MVP (Excel) (www.excelguru.ca)
// Injected into this workbook via Monkey Tools at the model designer's request
// For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
//// Original source can be found at the following URL:
// http://www.excelguru.ca/blog/2014/11/26/building-a-parameter-table-for-power-query/

// To use the function you must pass it a 2 column table which contains the Parameters
// The header row must contain a "Parameter" and a "Value" column (with those names)
// Data rows should list the parameter name in the first column and the value of that
// parameter in the second column

// Provided you save this query under the name "fnGetParameter", you can then reference
// it from other queries as follows:
//
//  =fnGetParameter("your_parameter_name")

// One useful sample to return the current folder:
// Parameter Name: File Path
// Parameter Value: =LEFT(CELL("filename",A1),FIND("[",CELL("filename",A1),1)-1)
// Call as  "fnGetParamater("File Path")

// Parameter Name: Folder Path
// Parameter Value: =IFERROR(LEFT(@CELL("filename",A1),FIND("[",@CELL("filename",A1),1)-1),"Workbook needs to be saved!")
// Call as  "fnGetParamater("Folder Path")

// Parameter Name: File Name
// Parameter Value: =REPLACE(C9,1,LEN(C8),"")
// Parameter Value: =REPLACE(IFERROR(SUBSTITUTE(LEFT(@CELL("filename",A1),FIND("]",@CELL("filename",A1),1)-1),"[",""),"Workbook needs to be saved!"),1,LEN(IFERROR(LEFT(@CELL("filename",A1),FIND("[",@CELL("filename",A1),1)-1),"Workbook needs to be saved!")),"")
// Call as  "fnGetParamater("File Name")

let
	fnGetParameter = (ParameterName as text) as any =>

 let
	 ParamSource = Excel.CurrentWorkbook(){[Name="XLGQuery_Parameters"]}[Content],
	 ParamRow = Table.SelectRows(ParamSource, each (Text.From([Parameter])=ParameterName)),
	 Value=
 if Table.IsEmpty(ParamRow)=true
 then null
 else Record.Field(ParamRow{0},"Value")
in
	Value,
	fnDocumentation = type function (
		ParameterName as (
			type any meta [
				Documentation.FieldCaption = "ParameterName",
				Documentation.SampleValues = "{}"
				]
			)
		)
		as text meta [
			Documentation.Name = "fnGetParameter",
			Documentation.MTVersion = 2.2,
			Documentation.LongDescription = "This function looks up the provided value in the XLGQuery_Parameters table in your workbook, and returns the matching value.<br><br>"&
				"<b>NOTE:</b> If you are planning to integrate this into an existing query, we highly recommend you edit your M code and make your fnGetParameter call the first "&
				"step in your query. This will avoid potential formula firewall conflicts later.<br><br>"&
				"To learn more about how this function works, see https://monkeytools.ca/parameter-table-and-function/"
			,
			Documentation.Examples =
			{
				[   Description= "Assuming you have the text <i>Folder Path</i> in the Parameter column of your table, and it shows a Value of <i>C:\MyData\Sales\</i>, you would call this function as follows:",
					Code = "=fnGetParameter(""Folder Path"")",
					Result = "C:\MyData\Sales\"
				]
			}
		],
	DocumentedFunction = Value.ReplaceType(
		fnGetParameter,
		fnDocumentation
		)
in
	DocumentedFunction
