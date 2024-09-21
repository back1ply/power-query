let
    DistinctColumnsPerColumn = (InputTable as table) as table =>
    let
        // Get the list of column names from the input table
        ColumnNames = Table.ColumnNames(InputTable),
        
        // Apply distinct values for each column individually by converting each column to a list first
        DistinctColumnValues = List.Transform(
            ColumnNames,
            each List.Distinct(Table.Column(InputTable, _))
        ),
        
        // Combine the distinct lists back into columns to form a new table
        FinalTable = Table.FromColumns(DistinctColumnValues, ColumnNames)
    in
        FinalTable
in
    DistinctColumnsPerColumn
