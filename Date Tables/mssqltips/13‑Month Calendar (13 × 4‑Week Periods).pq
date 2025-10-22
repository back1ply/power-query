let
    // Load FactInternetSales and get OrderDate range
    Source = FactInternetSales,
    DatesOnly = Table.SelectColumns(Source, {"OrderDate"}),
    MinDate = Date.From(List.Min(DatesOnly[OrderDate])),
    MaxDate = Date.From(List.Max(DatesOnly[OrderDate])),
 
    // Generate continuous list of dates
    Dates = List.Dates(MinDate, Duration.Days(MaxDate - MinDate) + 1, #duration(1,0,0,0)),
    Table = Table.FromList(Dates, Splitter.SplitByNothing(), {"Date"}),
 
    // Add columns for 13-month logic
    AddDayIndex = Table.AddColumn(Table, "DayIndex", each Duration.Days([Date]-MinDate), Int64.Type),
    AddYear13 = Table.AddColumn(AddDayIndex, "Year13", each Date.Year(MinDate) + Number.IntegerDivide([DayIndex],364), Int64.Type),
    AddDayOfYear13 = Table.AddColumn(AddYear13, "DayOfYear13", each Number.Mod([DayIndex],364)+1, Int64.Type),
    AddPeriod13 = Table.AddColumn(AddDayOfYear13, "Period13", each if [DayOfYear13] > 364 then 13 else Number.IntegerDivide([DayOfYear13]-1,28)+1, Int64.Type),
    AddFiscalMonth = Table.RenameColumns(Table.DuplicateColumn(AddPeriod13, "Period13", "FiscalMonth"), {"FiscalMonth","FiscalMonth"}),
 
    // FiscalYear: shift logic (FiscalStartMonth=1 by default)
    FiscalStartMonth = 1,
    AddFiscalYear = Table.AddColumn(AddFiscalMonth, "FiscalYear",
        each if [FiscalMonth] >= FiscalStartMonth 
             then [Year13] 
             else [Year13] - 1, Int64.Type),
 
    // Quarters mapping
    AddQuarter13 = Table.AddColumn(AddFiscalYear, "Quarter13",
        each if [Period13] <= 3 then "Q1"
             else if [Period13] <= 6 then "Q2"
             else if [Period13] <= 9 then "Q3"
             else "Q4"),
 
    // Composite labels
    AddYearPeriod = Table.AddColumn(AddQuarter13, "YearPeriod", each "FY" & Text.From([FiscalYear]) & "-P" & Text.PadStart(Text.From([FiscalMonth]),2,"0")),
    AddYearQuarter = Table.AddColumn(AddYearPeriod, "YearQuarter", each "FY" & Text.From([FiscalYear]) & "-" & [Quarter13])
in
    AddYearQuarter
