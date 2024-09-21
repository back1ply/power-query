let
    AddValueCountColumn = (dataTable as table, columnName as text) as table =>
    let
        // Group the table by the specified column and count the number of rows for each group
        GroupedTable = Table.Group(dataTable, {columnName}, {{"Count", each Table.RowCount(_), type number}}),
        
        // Merge the grouped table back into the original table using a left join
        MergedTable = Table.NestedJoin(dataTable, {columnName}, GroupedTable, {columnName}, "CountTable", JoinKind.LeftOuter),
        
        // Expand the Count column from the nested table
        ExpandedTable = Table.ExpandTableColumn(MergedTable, "CountTable", {"Count"}, {columnName & " Count"})
    in
        ExpandedTable
in
    AddValueCountColumn
