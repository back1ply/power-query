let
    // Source table
    Source = FactInternetSales,
 
    // Ensure OrderDate is Date type
    DatesOnly = Table.TransformColumns(Source, {{"OrderDate", each Date.From(_), type date}}),
 
    // Get min/max dates from fact table
    MinDate = Record.Field(Table.Min(DatesOnly, "OrderDate"), "OrderDate"),
    MaxDate = Record.Field(Table.Max(DatesOnly, "OrderDate"), "OrderDate"),
 
    // Generate full date list
    Dates = List.Dates(MinDate, Duration.Days(MaxDate - MinDate) + 1, #duration(1,0,0,0)),
    DateTable = Table.FromList(Dates, Splitter.SplitByNothing(), {"Date"}),
 
    // Add DayOfWeek (1=Monday..7=Sunday)
    AddDayOfWeek = Table.AddColumn(DateTable, "DayOfWeek", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
 
    // Add FiscalYear
    AddYear = Table.AddColumn(AddDayOfWeek, "FiscalYear", each Date.Year([Date]), Int64.Type),
 
    // Week of Fiscal Year
    WeekOfFiscalYear = Table.AddColumn(AddYear, "WeekOfYear",
        each
            let
                YearStart = #date([FiscalYear],1,1),
                DaysDiff = Duration.Days([Date] - YearStart),
                Week = Number.IntegerDivide(DaysDiff,7) + 1
            in Week, Int64.Type),
 
    // Count total weeks per fiscal year
    WeeksPerYear = Table.Group(WeekOfFiscalYear, {"FiscalYear"}, {{"MaxWeek", each List.Max([WeekOfYear]), type number}}),
 
    // Merge total weeks into main table
    MergeWeeks = Table.NestedJoin(WeekOfFiscalYear, {"FiscalYear"}, WeeksPerYear, {"FiscalYear"}, "YearInfo", JoinKind.LeftOuter),
    ExpandWeeks = Table.ExpandTableColumn(MergeWeeks, "YearInfo", {"MaxWeek"}, {"WeeksInYear"}),
 
    // Calculate FiscalQuarter
    AddQuarter = Table.AddColumn(ExpandWeeks, "FiscalQuarter",
        each Number.RoundUp([WeekOfYear] / 13), Int64.Type),
 
    // Calculate FiscalMonth445
    AddFiscalMonth = Table.AddColumn(AddQuarter, "FiscalMonth445",
        each 
            let
                WeekInQuarter = Number.Mod([WeekOfYear]-1,13) + 1,
                MonthIndex = if WeekInQuarter <= 4 then 1 
                             else if WeekInQuarter <= 8 then 2 
                             else 3,
                BaseMonth = ( ([FiscalQuarter]-1) * 3 ) + MonthIndex,
                FinalMonth = if [WeeksInYear]=53 and [WeekOfYear]=53 then 12 else BaseMonth
            in
                FinalMonth, Int64.Type),
 
    // Add Month Names
    AddMonthName = Table.AddColumn(AddFiscalMonth, "FiscalMonthName", each "Month " & Text.From([FiscalMonth445]), type text),
 
    // Add Quarter Names
    AddQuarterName = Table.AddColumn(AddMonthName, "FiscalQuarterName", each "Q" & Text.From([FiscalQuarter]), type text),
 
    // Add IsLastWeekOfYear flag
    AddLastWeekFlag = Table.AddColumn(AddQuarterName, "IsLastWeekOfYear", each [WeekOfYear] = [WeeksInYear], type logical),
    #"Changed Type" = Table.TransformColumnTypes(AddLastWeekFlag,{{"Date", type date}})
in
    #"Changed Type"
