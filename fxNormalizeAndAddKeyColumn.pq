// NormalizeAndAddKeyColumn: A function to normalize a column in a table by creating a dimension table 
// with unique values and an associated key, then adds this key back to the original table.
//
// Parameters:
// - SourceTable (table): The table containing the data you want to normalize.
// - ColumnName (text): The name of the column to be normalized.
//
// Returns:
// - A table with the normalized column replaced by a key column. The original column remains unchanged.

let
    NormalizeAndAddKeyColumn = (SourceTable as table, ColumnName as text) as table =>
    let
        // Step 1: Create the dimension table by selecting the unique values from the specified column
        SelectedColumn = Table.SelectColumns(SourceTable, {ColumnName}),  // Select the column to be normalized
        DistinctValues = Table.Distinct(SelectedColumn),  // Remove duplicates to ensure only unique values
        DimensionTable = Table.AddIndexColumn(DistinctValues, ColumnName & "_key", 1, 1, Int64.Type),  // Add an index column as the key
        
        // Step 2: Join the dimension table back to the original table using the specified column
        MergedTable = Table.NestedJoin(SourceTable, {ColumnName}, DimensionTable, {ColumnName}, "DimTable", JoinKind.LeftOuter),  // Perform a left join
        
        // Step 3: Expand the dimension table to add the key column to the original table
        ExpandedTable = Table.ExpandTableColumn(MergedTable, "DimTable", {ColumnName & "_key"}, {ColumnName & "_key"})  // Add the key column from the dimension table
    in
        ExpandedTable  // Return the modified table with the added key column
in
    NormalizeAndAddKeyColumn
