let
    Source = {0..1439},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Changed Type" = Table.TransformColumnTypes(#"Converted to Table",{{"Column1", Int64.Type}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Column1", "Minute Number"}}),
    #"Inserted Division" = Table.AddColumn(#"Renamed Columns", "Division", each [Minute Number] / 1440, type number),
    #"Changed Type1" = Table.TransformColumnTypes(#"Inserted Division",{{"Division", type time}}),
    #"Renamed Columns1" = Table.RenameColumns(#"Changed Type1",{{"Division", "Time to the Minute"}}),
    #"Inserted Integer-Division" = Table.AddColumn(#"Renamed Columns1", "5 min bucket", each Number.IntegerDivide([Minute Number], 5), Int64.Type),
    #"Inserted Integer-Division1" = Table.AddColumn(#"Inserted Integer-Division", "10 min bucket", each Number.IntegerDivide([Minute Number], 10), Int64.Type),
    #"Inserted Integer-Division2" = Table.AddColumn(#"Inserted Integer-Division1", "1 hour bucket", each Number.IntegerDivide([Minute Number], 60), Int64.Type),
    #"Added Custom" = Table.AddColumn(#"Inserted Integer-Division2", "5 minute time slot", each [5 min bucket] * 5 / 1440),
    #"Changed Type2" = Table.TransformColumnTypes(#"Added Custom",{{"5 minute time slot", type time}}),
    #"Added Custom1" = Table.AddColumn(#"Changed Type2", "10 minute time slot", each [10 min bucket] * 10/1440),
    #"Changed Type3" = Table.TransformColumnTypes(#"Added Custom1",{{"10 minute time slot", type time}}),
    #"Added Custom2" = Table.AddColumn(#"Changed Type3", "1 hour time slot", each [1 hour bucket] * 60/1440),
    #"Changed Type4" = Table.TransformColumnTypes(#"Added Custom2",{{"1 hour time slot", type time}})
in
    #"Changed Type4"
