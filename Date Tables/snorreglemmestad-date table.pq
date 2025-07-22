let  
    // Generating date table  
    StartDate = #date(Date.Year(DateTime.LocalNow()) - 8, 1, 1),  
    EndDate = #date(Date.Year(DateTime.LocalNow()) + 1, 12, 31),  
    ListOfDates = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),  
  
    AddColumns = List.Transform(ListOfDates, each [  
        Dato = _,  
        År = Date.Year(_),  
        Månednr = Date.Month(_),  
        Dag = Date.Day(_),  
        Ukedag = Text.Proper(Date.ToText(_, "dddd", "nb-NO")),  
        Måned = Text.Proper(Date.ToText(_, "MMMM", "nb-NO")),  
        Kvartal = "Q" & Text.From(Date.QuarterOfYear(_)),  
        Uke = Date.WeekOfYear(_),  
        ErHelg = if Date.DayOfWeek(_, Day.Monday) + 1 >= 6 then true else false  
    ]),  
  
    ConvertToTable = Table.FromRecords(AddColumns),  
    ChangeTypes = Table.TransformColumnTypes(ConvertToTable, {  
        {"Dato", type date}, {"År", Int64.Type}, {"Månednr", Int64.Type},  
        {"Dag", Int64.Type}, {"Ukedag", type text}, {"Måned", type text},  
        {"Kvartal", type text}, {"Uke", Int64.Type}, {"ErHelg", type logical}  
    }),  
    #"Changed column type with locale 1" = Table.TransformColumnTypes(ChangeTypes, {{"Dato", type date}}, "nb-NO"),  
  
    // Adding the "Periode" column as whole number  
    AddPeriode = Table.AddColumn(#"Changed column type with locale 1", "Periode", each [År] * 100 + [Månednr], Int64.Type),  
  
    // Fetching holiday data  
    Source = Json.Document(Web.Contents("https://opencom.no/dataset/49cb0ec9-e139-4f79-bc5e-309c4faf8396/resource/f8f57a81-a22b-4c4a-b06d-2b25ee53732f/download/helligdagskalender.json")),  
    #"Converted to table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),  
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to table", "Column1", {"år", "navn", "dato", "dag", "uke"}, {"år", "navn", "dato", "dag", "uke"}),  
    #"Changed column type" = Table.TransformColumnTypes(#"Expanded Column1", {{"år", Int64.Type}, {"navn", type text}, {"dato", type text}, {"dag", type text}, {"uke", Int64.Type}}),  
    #"Removed other columns" = Table.SelectColumns(#"Changed column type", {"navn", "dato"}),  
    #"Renamed columns" = Table.RenameColumns(#"Removed other columns", {{"dato", "Dato"}, {"navn", "Helligdag"}}),  
    #"Changed column type with locale" = Table.TransformColumnTypes(#"Renamed columns", {{"Dato", type date}}, "nb-NO"),  
  
    // Merging the two tables  
    MergedTables = Table.NestedJoin(AddPeriode, "Dato", #"Changed column type with locale", "Dato", "Holidays", JoinKind.LeftOuter),  
    ExpandedHolidays = Table.ExpandTableColumn(MergedTables, "Holidays", {"Helligdag"}, {"Helligdag"}),  
  
    // Adding the "Røde dager" column  
    AddRoedDag = Table.AddColumn(ExpandedHolidays, "Rød dag", each if ([Helligdag] <> null or [Ukedag] = "Søndag") then true else false, type logical),  
    #"Sorted rows" = Table.Sort(AddRoedDag, {{"Dato", Order.Ascending}}),  
    #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Sorted rows", "PeriodeSortDesc", each -[Periode]), {{"PeriodeSortDesc", Int64.Type}}),  
    #"Inserted conditional column" = Table.AddColumn(#"Added custom", "Tertial", each if [Månednr] <= 4 then 1 else if [Månednr] >= 9 then 3 else 2),  
  
    #"Changed column type 1" = Table.TransformColumnTypes(#"Inserted conditional column", {{"Tertial", Int64.Type}})  
in  
    #"Changed column type 1"  
