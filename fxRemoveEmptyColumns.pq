(fxRemoveEmptyColumns as table) as table =>
let
    // Step 1: Generate the profile of the input table.
    Custom1 = Table.Profile(fxRemoveEmptyColumns),

    // Step 2: Add a new column that subtracts NullCount from Count to find columns that are completely empty.
    InsertedSubtraction = Table.AddColumn(Custom1, "Subtraction", each [Count] - [NullCount], type number),

    // Step 3: Filter rows where Subtraction is 0, meaning all values in the column are null.
    FilteredRows = Table.SelectRows(InsertedSubtraction, each ([Subtraction] = 0)),

    // Step 4: Get the list of column names where all values are null.
    ColumnsToRemove = FilteredRows[Column],

    // Step 5: Remove the empty columns from the original table.
    FilterOriginalTable = Table.RemoveColumns(fxRemoveEmptyColumns, ColumnsToRemove)
    
in
    FilterOriginalTable
