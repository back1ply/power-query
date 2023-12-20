let
  BulkReplace = (dataTable as table, columnsToReplace as list, replacementTable as table) as table =>
    let
      Replaced = List.Accumulate(
        columnsToReplace, 
        dataTable, 
        (state, current) =>
          Table.TransformColumns(
            state,
            {{current, each try replacementTable{List.PositionOf(replacementTable[Code], _)}[New_Values] otherwise _, type text}} 
          )
      )
    in
      Replaced
in
  BulkReplace
