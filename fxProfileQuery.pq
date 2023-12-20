let
    ProfileQuery = (query as table) as table =>
        let
            // Profile the table, count errors and unique values for each column
            ProfiledTable = Table.Profile(query, {
                {"Errors", each true, each Table.RowCount(Table.SelectRowsWithErrors(Table.FromValue(_)))},
                {"UniqueCount", each true, each List.Count(List.Distinct(_))}
            }),
            
            // Remove unnecessary statistical columns
            FinalTable = Table.RemoveColumns(ProfiledTable,{"Min", "Max", "Average", "StandardDeviation"})
        in
            FinalTable
in
    ProfileQuery
