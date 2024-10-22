// fxSortDelimitedColumn
// Function to Sort delimited text input "B, C, A" output "A, B, C"
(inputTable as table, columnName as text, delimiter as text) as table =>
let    
    SortDelimitedColumn = Table.TransformColumns(
        inputTable,
        {
            {columnName, each Text.Combine(List.Sort(Text.Split(_, delimiter)), delimiter)}
        }
    )
in
    SortDelimitedColumn
