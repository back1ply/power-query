let
    // Load source table
    Source = FactInternetSales,
 
    // Convert OrderDate to Date type
    OrderDateOnly = Table.TransformColumnTypes(Source, {{"OrderDate", type date}}),
 
    // Determine min and max dates
    MinDate = List.Min(OrderDateOnly[OrderDate]),
    MaxDate = List.Max(OrderDateOnly[OrderDate]),
 
    // Fiscal start month (change this to 1..12)
    FiscalStartMonth = 4,
 
    // Generate continuous date list
    DateList = List.Dates(MinDate, Duration.Days(MaxDate - MinDate) + 1, #duration(1,0,0,0)),
 
    // Convert list to table
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),
 
    // Add DateKey (yyyyMMdd)
    AddDateKey = Table.AddColumn(DateTable, "DateKey", each 
        Text.PadStart(Text.From(Date.Year([Date])),4,"0") &
        Text.PadStart(Text.From(Date.Month([Date])),2,"0") &
        Text.PadStart(Text.From(Date.Day([Date])),2,"0"), type text),
 
    // Add Year, MonthNumber, MonthName
    AddYear = Table.AddColumn(AddDateKey, "Year", each Date.Year([Date]), Int64.Type),
    AddMonthNumber = Table.AddColumn(AddYear, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthNumber, "MonthName", each Date.ToText([Date], "MMMM"), type text),
 
    // Add FiscalMonthNumber
    AddFiscalMonth = Table.AddColumn(AddMonthName, "FiscalMonthNumber", each Number.Mod(Date.Month([Date]) - FiscalStartMonth + 12, 12) + 1, Int64.Type),
 
    // Add FiscalYear
    AddFiscalYear = Table.AddColumn(AddFiscalMonth, "FiscalYear", each 
        if Date.Month([Date]) >= FiscalStartMonth then Date.Year([Date]) else Date.Year([Date]) - 1, Int64.Type),
 
    // Add FiscalQuarter
    AddFiscalQuarter = Table.AddColumn(AddFiscalYear, "FiscalQuarter", each Number.IntegerDivide(Number.Mod(Date.Month([Date]) - FiscalStartMonth + 12, 12),3) + 1, Int64.Type),
 
    // Add WeekOfYear (Monday = 1)
    AddWeekOfYear = Table.AddColumn(AddFiscalQuarter, "WeekOfYear", each Date.WeekOfYear([Date], Day.Monday), Int64.Type)
in
    AddWeekOfYear
