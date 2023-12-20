let
    CustomFunction = (table as table, N as number) as table =>
    let
        ColumnNames = List.Skip(Table.ColumnNames(table), N),
        CustomColumn = Table.AddColumn(table, "Info Check", each let row = Record.FieldValues(_) in if List.IsEmpty(List.RemoveMatchingItems(List.Skip(row, N), {null, ""})) then "No Info" else "Has Info")
    in
        CustomColumn
in
    CustomFunction
