let
    /*
    ****This Calendar was created and provided by Avi Singh****
    ****This can be freely shared as long as this text comment is retained.****
    http://www.youtube.com/PowerBIPro
    www.LearnPowerBI.com by Avi Singh
    */
    #"LearnPowerBI.com by Avi Singh" = 1,
    StartDate = #date(2014, 1, 1),
    EndDate = Date.EndOfYear(DateTime.Date(DateTime.FixedLocalNow())) /*was "#date(2017, 1, 1)" Updated on 201802027: hard Coded End of Year caused some formulas to break, switching to dynamic date*/,
    //Used for 'Offset' Column calculations, you may Hard code CurrentDate for testing e.g. #date(2017,9,1)
    CurrentDate = DateTime.Date(DateTime.FixedLocalNow()),
    // Specify the last month in your Fiscal Year, e.g. if June is the last month of your Fiscal Year, specify 6
    FiscalYearEndMonth = 6,
    #"==SET PARAMETERS ABOVE==" = 1,
    #"==Build Date Column==" = #"==SET PARAMETERS ABOVE==",
    ListDates = List.Dates(StartDate, Number.From(EndDate - StartDate)+1, #duration(1,0,0,0)),
    #"Converted to Table" = Table.FromList(ListDates, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns as Date" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Date"}}),
    // As far as Power BI is concerned, the 'Date' column is all that is needed :-) But we will continue and add a few Human-Friendly Columns
    #"Changed Type to Date" = Table.TransformColumnTypes(#"Renamed Columns as Date",{{"Date", type date}}),
    #"==Add Calendar Columns==" = #"Changed Type to Date",
    #"Added Calendar MonthNum" = Table.AddColumn(#"==Add Calendar Columns==", "MonthNum", each Date.Month([Date]), Int64.Type),
    #"Added Month Name" = Table.AddColumn(#"Added Calendar MonthNum", "Month", each Text.Start(Date.MonthName([Date]),3), type text),
    #"Added Month Name Long" = Table.AddColumn(#"Added Month Name", "MonthLong", each Date.MonthName([Date]), type text),
    #"Added Calendar Quarter" = Table.AddColumn(#"Added Month Name Long", "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date]))),
    #"Added Calendar Year" = Table.AddColumn(#"Added Calendar Quarter", "Year", each Date.Year([Date]), Int64.Type),
    #"==Add General Columns==" = #"Added Calendar Year",
    // Used as 'Sort by Column' for MonthYear columns
    #"Added MonthYearNum" = Table.AddColumn(#"==Add General Columns==", "MonthYearNum", each [Year]*100 + [MonthNum] /*e.g. Sep-2016 would become 201609*/, Int64.Type),
    #"Added MonthYear" = Table.AddColumn(#"Added MonthYearNum", "MonthYear", each [Month] & "-" & Text.End(Text.From([Year]),2)),
    #"Added MonthYearLong" = Table.AddColumn(#"Added MonthYear", "MonthYearLong", each [Month] & "-" & Text.From([Year])),
    #"Added WeekdayNum" = Table.AddColumn(#"Added MonthYearLong", "WeekdayNum", each Date.DayOfWeek([Date]), Int64.Type),
    #"Added Weekday Name" = Table.AddColumn(#"Added WeekdayNum", "Weekday", each Text.Start(Date.DayOfWeekName([Date]),3), type text),
    #"Added WeekdayWeekend" = Table.AddColumn(#"Added Weekday Name", "WeekdayWeekend", each if [WeekdayNum] = 0 or [WeekdayNum] = 6
then "Weekend"
else "Weekday")
in
    #"Added WeekdayWeekend"