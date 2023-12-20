let
    AddCountColumn = (dataTable as table, columnName as text) as table =>
    let
        // Group the table by the specified column and count the number of rows for each group
        GroupedTable = Table.Group(dataTable, {columnName}, {{"Count", each Table.RowCount(_), type number}}),
        
        // Join the original table with the grouped table on the specified column
        JoinedTable = Table.NestedJoin(dataTable, {columnName}, GroupedTable, {columnName}, "CountColumn", JoinKind.LeftOuter),
        
        // Expand the new column to include the count of each group in the original table
        ExpandedNewColumn = Table.ExpandTableColumn(JoinedTable, "CountColumn", {"Count"}, {columnName & " Count"})
    in
        ExpandedNewColumn
in
    AddCountColumn
