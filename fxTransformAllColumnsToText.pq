(table as table) as table =>
    Table.TransformColumnTypes(table, List.Transform(Table.ColumnNames(table), each {_, type text}))
