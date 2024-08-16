// NormalizeAndAddKeyColumn: A function to normalize a column in a table by creating a dimension table 
// with unique values and an associated key, then adds this key back to the original table.
//
// Parameters:
// - SourceTable (table): The table containing the data you want to normalize.
// - ColumnName (text): The name of the column to be normalized.
//
// Returns:
// - A table with the normalized column replaced by a key column. The original column remains unchanged.
//   The key column is added to the original table, associating each unique value with a unique key.

let
    NormalizeAndAddKeyColumn = (SourceTable as table, ColumnName as text) as table =>
    let
        // Step 1: Create the dimension table by selecting unique values from the specified column and adding an index key
        DistinctValuesWithKey = Table.Distinct(Table.AddIndexColumn(Table.SelectColumns(SourceTable, {ColumnName}), ColumnName & "_key", 1, 1, Int64.Type)),
        
        // Step 2: Join the dimension table back to the original table using the specified column
        MergedTable = Table.NestedJoin(SourceTable, {ColumnName}, DistinctValuesWithKey, {ColumnName}, "DimTable", JoinKind.LeftOuter),
        
        // Step 3: Expand the dimension table to add the key column to the original table
        ExpandedTable = Table.ExpandTableColumn(MergedTable, "DimTable", {ColumnName & "_key"}, {ColumnName & "_key"})
    in
        ExpandedTable  // Return the modified table with the added key column
in
    NormalizeAndAddKeyColumn
