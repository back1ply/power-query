let
    // Get the start date from the parameter 'Calendar Start Date'
    StartDate = CalendarStartDate,

    // Set end date as today's date (dynamic current date)
    EndDate = Date.From(DateTime.FixedLocalNow()),

    // Calculate the number of days between StartDate and EndDate
    DayCount = Duration.Days(Duration.From(EndDate - StartDate)) + 1,

    // Generate a list of dates from StartDate to EndDate
    DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),

    // Convert the list to a table and change the type of the Date column to date
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),

    // Change Date column to Date type
    #"Changed Date Type" = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),

    // Add multiple date attributes in one step
    AddDateAttributes = Table.AddColumn(#"Changed Date Type", "Attributes", each [
        // Basic Date Fields
        DayOfMonth = Date.Day([Date]),
        DayOfYear = Date.DayOfYear([Date]),
        DayOfWeek = Date.DayOfWeek([Date],1) + 1,  // Monday = 1, Sunday = 7
        Weekday = Date.DayOfWeekName([Date]),
        WeekdayShort = Date.ToText([Date], "ddd"),
        DaysInMonth = Date.DaysInMonth([Date]),

        // Week-Based Fields
        WeekOfMonth = Date.WeekOfMonth([Date]),
        WeekOfYear = Date.WeekOfYear([Date]),
        WeekStart = Date.StartOfWeek([Date]),
        WeekEnd = Date.EndOfWeek([Date]),

        // Month-Based Fields
        Month = Date.Month([Date]),
        MonthName = Date.MonthName([Date]),
        MonthNameShort = Date.ToText([Date], "MMM"),
        MonthStart = Date.StartOfMonth([Date]),
        MonthEnd = Date.EndOfMonth([Date]),

        // Quarter & Year-Based Fields
        Quarter = "Q" & Number.ToText(Date.QuarterOfYear([Date])),
        QuarterStart = Date.StartOfQuarter([Date]),
        QuarterEnd = Date.EndOfQuarter([Date]),
        Year = Date.Year([Date]),
        YearStart = Date.StartOfYear([Date]),
        YearEnd = Date.EndOfYear([Date]),

        // Fiscal Year Fields (using FiscalStartMonth parameter)
        FiscalMonth = if Date.Month([Date]) >= FiscalStartMonth 
                      then Date.Month([Date]) - FiscalStartMonth + 1 
                      else Date.Month([Date]) + (12 - FiscalStartMonth + 1),

        FiscalQuarter = if FiscalMonth <= 3 then "Q1"
            else if FiscalMonth <= 6 then "Q2"
            else if FiscalMonth <= 9 then "Q3"
            else "Q4",
        FiscalYear = if Date.Month([Date]) >= FiscalStartMonth 
                     then Date.Year([Date]) + 1 
                     else Date.Year([Date]),

        FiscalYearText = "FY" & Number.ToText(if Date.Month([Date]) >= FiscalStartMonth 
                                             then Date.Year([Date]) + 1 
                                             else Date.Year([Date])),

        FiscalYearStart = #date(if Date.Month([Date]) >= FiscalStartMonth then Date.Year([Date]) else Date.Year([Date]) - 1, FiscalStartMonth, 1),
        FiscalYearEnd = Date.EndOfMonth(Date.AddMonths(FiscalYearStart, 11)),

        // Relative Date Boolean Flags
        IsLeapYear = Date.IsLeapYear([Date]),
        IsWeekday = (DayOfWeek < 6),
        IsWeekend = (DayOfWeek > 5),
        IsToday = Date.IsInCurrentDay([Date]),
        IsYesterday = Date.IsInPreviousDay([Date]),
        IsCurrentWeek = Date.IsInCurrentWeek([Date]),
        IsLastWeek = Date.IsInPreviousWeek([Date]),
        IsCurrentMonth = Date.IsInCurrentMonth([Date]),
        IsLastMonth = Date.IsInPreviousMonth([Date]),
        IsCurrentQuarter = Date.IsInCurrentQuarter([Date]),
        IsPreviousQuarter = Date.IsInPreviousQuarter([Date]),
        IsCurrentYear = Date.IsInCurrentYear([Date]),
        IsPreviousYear = Date.IsInPreviousYear([Date]),

        // Fiscal Year Flags
        TodayDate = EndDate,
        CurrentFiscalYear = if Date.Month(TodayDate) >= FiscalStartMonth then Date.Year(TodayDate) + 1 else Date.Year(TodayDate),
        IsCurrentFiscalYear = (FiscalYear = CurrentFiscalYear),
        IsPreviousFiscalYear = (FiscalYear = (CurrentFiscalYear - 1))
    ], type record),

    // Expand the Attributes column into separate columns
    ExpandedDateAttributes = Table.ExpandRecordColumn(AddDateAttributes, "Attributes", 
        {"DayOfMonth", "DayOfYear", "DayOfWeek", "Weekday", "WeekdayShort", "DaysInMonth",
         "WeekOfMonth", "WeekOfYear", "WeekStart", "WeekEnd",
         "Month", "MonthName", "MonthNameShort", "MonthStart", "MonthEnd",
         "Quarter", "QuarterStart", "QuarterEnd",
         "Year", "YearStart", "YearEnd",
         "FiscalMonth", "FiscalQuarter", "FiscalYear", "FiscalYearText", "FiscalYearStart", "FiscalYearEnd",
         "IsLeapYear", "IsWeekday", "IsWeekend", "IsToday", "IsYesterday", "IsCurrentWeek", "IsLastWeek", 
         "IsCurrentMonth", "IsLastMonth", "IsCurrentQuarter", "IsPreviousQuarter", "IsCurrentYear", 
         "IsPreviousYear", "IsCurrentFiscalYear", "IsPreviousFiscalYear"
        }),

    // Change types of all columns
    #"Changed Types" = Table.TransformColumnTypes(ExpandedDateAttributes,{{"DayOfMonth", Int64.Type}, {"DayOfYear", Int64.Type}, {"DayOfWeek", Int64.Type}, {"DaysInMonth", Int64.Type}, {"WeekOfMonth", Int64.Type}, {"WeekOfYear", Int64.Type}, {"Month", Int64.Type}, {"Year", Int64.Type}, {"FiscalMonth", Int64.Type}, {"FiscalYear", Int64.Type}, {"Weekday", type text}, {"WeekdayShort", type text}, {"MonthName", type text}, {"MonthNameShort", type text}, {"Quarter", type text}, {"FiscalQuarter", type text}, {"FiscalYearText", type text}, {"WeekStart", type date}, {"WeekEnd", type date}, {"MonthStart", type date}, {"MonthEnd", type date}, {"QuarterStart", type date}, {"QuarterEnd", type date}, {"YearStart", type date}, {"YearEnd", type date}, {"FiscalYearStart", type date}, {"FiscalYearEnd", type date}, {"IsLeapYear", type logical}, {"IsToday", type logical}, {"IsYesterday", type logical}, {"IsCurrentWeek", type logical}, {"IsLastWeek", type logical}, {"IsCurrentMonth", type logical}, {"IsLastMonth", type logical}, {"IsCurrentQuarter", type logical}, {"IsPreviousQuarter", type logical}, {"IsCurrentYear", type logical}, {"IsPreviousYear", type logical}, {"IsCurrentFiscalYear", type logical}, {"IsPreviousFiscalYear", type logical}, {"IsWeekend", type logical}, {"IsWeekday", type logical}})
in
    #"Changed Types"
