// Query written by Ken Puls, FCPA, FCMA, MS MVP (Excel) (www.excelguru.ca)
// Injected into this workbook via Monkey Tools at the model designer's request
// For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
//
let
    fnCurrentWorkbook = (optional Kind as text, optional Scope as text) as table =>
        let
            Source = Excel.CurrentWorkbook(),
            Renamed_Item = Table.RenameColumns(Source, {{"Name", "Item"},{"Content","Data"}}),
            Add_Name = Table.AddColumn(Renamed_Item, "Name", each if Text.Contains([Item], "!") 
                then Text.AfterDelimiter([Item], "!") 
                else [Item]),
            Add_Scope = Table.AddColumn(Add_Name, "Scope", each if Text.Contains([Item], "!") 
                then Text.BeforeDelimiter([Item], "!") 
                else "Workbook"),
            Add_Kind = Table.AddColumn(Add_Scope, "Kind", each try 
                if Table.ColumnNames([Data]) = List.Transform({1..List.Count(Table.ColumnNames([Data]))}, each "Column" & Text.From(_)) 
                then "DefinedName" 
                else "Table" 
                otherwise "Unsupported"),
            Reordered = Table.ReorderColumns(Add_Kind, {"Name", "Data", "Item", "Kind", "Scope"}),
            FilteredByKind = if Kind <> null then Table.SelectRows(Reordered, each [Kind] = Kind) else Reordered,
            FilteredByScope = if Scope <> null then Table.SelectRows(FilteredByKind, each [Scope] = Scope) else FilteredByKind,
            SetDataTypes = Table.TransformColumnTypes(FilteredByScope,{{"Name", type text}, {"Data", type any}, {"Item", type text}, {"Kind", type text}, {"Scope", type text}})	
        in
            SetDataTypes,

    functionType = type function (
        optional Kind as text,
        optional Scope as text
    ) as table,

    documentedType = Value.ReplaceMetadata(functionType, [
        Documentation.Name = "fnCurrentWorkbook",
        Documentation.MTVersion = 1.1,
        Documentation.Description = "Returns named items from Excel.CurrentWorkbook, optionally filtered by Kind and Scope.",
        Documentation.LongDescription = "This function returns all tables and defined names from the current workbook. You can optionally filter by Kind (Table, DefinedName, or Unsupported) and/or by Scope (Workbook or worksheet name).",
        Documentation.Parameters = [
            Kind = [
                Documentation.FieldCaption = "Kind",
                Documentation.FieldDescription = "Optional filter: Table, DefinedName, or Unsupported",
                Documentation.SampleValues = {"Table", "DefinedName", "Unsupported"}
            ],
            Scope = [
                Documentation.FieldCaption = "Scope",
                Documentation.FieldDescription = "Optional filter: 'Workbook' or any valid worksheet name",
                Documentation.SampleValues = {"Workbook", "Sheet1", "Sheet2"}
            ]
        ],
        Documentation.Examples = {
            [
                Description = "Return all named items from the workbook",
                Code = "=fnCurrentWorkbook()",
                Result = "| Name           | Data     | Item                     | Kind        | Scope    | #(lf)"
                        & "|----------------|----------|--------------------------|-------------|----------| #(lf)"
                        & "| Data1          | [Table]  | Data1                    | Table       | Workbook | #(lf)"
                        & "| Data2          | [Table]  | Data2                    | Table       | Workbook | #(lf)"
                        & "| Output         | [Table]  | Output                   | Table       | Workbook | #(lf)"
                        & "| rngArray       | [Table]  | rngArray                 | DefinedName | Workbook | #(lf)"
                        & "| nm_input       | [Table]  | Sheet1!Input_1           | DefinedName | Sheet1   | #(lf)"
                        & "| nm_input       | [Table]  | Sheet2!nm_input          | DefinedName | Sheet2   | #(lf)"
                        & "| _FilterDatabase| [Error]  | Sheet1!_FilterDatabase   | Unsupported | Sheet1   | #(lf)"
            ],
            [
                Description = "Return only Table items from the workbook",
                Code = "=fnCurrentWorkbook(""Table"")",
                Result = "| Name     | Data    | Item   | Kind  | Scope    | #(lf)"
                       & "|----------|---------|--------|-------|----------| #(lf)"
                       & "| Data1    | [Table] | Data1  | Table | Workbook | #(lf)"
                       & "| Data2    | [Table] | Data2  | Table | Workbook | #(lf)"
                       & "| Output   | [Table] | Output | Table | Workbook | #(lf)"
            ],
            [
                Description = "Return only DefinedName items from Sheet1",
                Code = "=fnCurrentWorkbook(""DefinedName"", ""Sheet1"")",
                Result = "| Name      | Data    | Item           | Kind        | Scope  | #(lf)"
                       & "|-----------|---------|----------------|-------------|--------| #(lf)"
                       & "| nm_input  | [Table] | Sheet1!Input_1 | DefinedName | Sheet1 | #(lf)"
            ],
            [
                Description = "Return only unsupported named items (e.g. internal names like _FilterDatabase)",
                Code = "=fnCurrentWorkbook(""Unsupported"")",
                Result = "| Name           | Data     | Item                   | Kind        | Scope  | #(lf)"
                & "|----------------|----------|------------------------|-------------|--------| #(lf)"
                & "| _FilterDatabase| [Error]  | Sheet1!_FilterDatabase | Unsupported | Sheet1 | #(lf)"
            ]
        }

    ]),

    DocumentedFunction = Value.ReplaceType(fnCurrentWorkbook, documentedType)
in
    DocumentedFunction
