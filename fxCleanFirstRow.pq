let
    CleanFirstRow = (table as table) as table =>
    let
        FirstRow = Table.FirstN(table,1),
        ColumnNames = Table.ColumnNames(FirstRow),
        TransformList = List.Transform(ColumnNames, each {_, each Text.Trim(Text.Clean(_)), type text}),
        CleanFirstRow = Table.TransformColumns(FirstRow, TransformList),
        RemainingRows = Table.Skip(table,1),
        FinalTable = Table.Combine({CleanFirstRow, RemainingRows})
    in
        FinalTable
in
    CleanFirstRow
