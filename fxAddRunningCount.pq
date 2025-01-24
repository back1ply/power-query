let
    AddRunningCount = (dataTable as table, columnName as text) as table =>
    let
        // Step 1: Get distinct groups in original order
        DistinctGroups = Table.Distinct(dataTable, {columnName}),
        // Step 2: Add running count to distinct groups
        IndexedGroups = Table.AddIndexColumn(DistinctGroups, "Running Count", 1, 1),
        // Step 3: Merge running count back to original table
        Merged = Table.NestedJoin(
            dataTable, 
            {columnName}, 
            IndexedGroups, 
            {columnName}, 
            "RunningCountTable", 
            JoinKind.LeftOuter
        ),
        // Step 4: Expand the running count column
        Expanded = Table.ExpandTableColumn(
            Merged, 
            "RunningCountTable", 
            {"Running Count"}, 
            {columnName & " Running Count"}
        )
    in
        Expanded
in
    AddRunningCount
