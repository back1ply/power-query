let
    // Load the source table
    Source = FactInternetSales,
 
    // Convert OrderDate to Date type
    OrderDateOnly = Table.TransformColumnTypes(Source, {{"OrderDate", type date}}),
 
    // Determine min and max dates
    MinDate = List.Min(OrderDateOnly[OrderDate]),
    MaxDate = List.Max(OrderDateOnly[OrderDate]),
 
    // Generate a continuous list of dates
    DateList = List.Dates(MinDate, Duration.Days(MaxDate - MinDate) + 1, #duration(1,0,0,0)),
 
    // Convert list to table
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),
 
    // Add DateKey column (yyyyMMdd)
    AddDateKey = Table.AddColumn(DateTable, "DateKey", each 
        Number.ToText(Date.Year([Date])) & 
        Text.PadStart(Number.ToText(Date.Month([Date])),2,"0") & 
        Text.PadStart(Number.ToText(Date.Day([Date])),2,"0"), type text),
 
    // Add Year
    AddYear = Table.AddColumn(AddDateKey, "Year", each Date.Year([Date]), Int64.Type),
 
    // Add MonthNumber
    AddMonthNum = Table.AddColumn(AddYear, "MonthNumber", each Date.Month([Date]), Int64.Type),
 
    // Add MonthName
    AddMonthName = Table.AddColumn(AddMonthNum, "MonthName", each Date.ToText([Date], "MMMM"), type text),
 
    // Add QuarterNumber
    AddQuarterNum = Table.AddColumn(AddMonthName, "QuarterNumber", each Date.QuarterOfYear([Date]), Int64.Type),
 
    // Add QuarterName
    AddQuarterName = Table.AddColumn(AddQuarterNum, "QuarterName", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
 
    // Add Day
    AddDay = Table.AddColumn(AddQuarterName, "Day", each Date.Day([Date]), Int64.Type),
 
    // Add DayOfWeek (1 = Monday .. 7 = Sunday)
    AddDayOfWeek = Table.AddColumn(AddDay, "DayOfWeek", each Date.DayOfWeek([Date], Day.Monday)+1, Int64.Type),
 
    // Add WeekOfYear
    AddWeekOfYear = Table.AddColumn(AddDayOfWeek, "WeekOfYear", each Date.WeekOfYear([Date], Day.Monday), Int64.Type)
in
    AddWeekOfYear
