let
    /*
    ****This Calendar was created and provided by Avi Singh****
    ****This can be freely shared as long as this text comment is retained.****
    >>>> Visit https://www.LearnPowerBI.com/calendar-download to learn how to use this Calendar Table <<<<
    http://www.youtube.com/PowerBIPro
    www.LearnPowerBI.com by Avi Singh
    */
    #"LearnPowerBI.com by Avi Singh" = 1,
    StartDate = #date(2015, 1, 1),
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
    #"==Add Fiscal Calendar Columns==" = #"Added Calendar Year",
    #"Added FiscalMonthNum" = Table.AddColumn(#"==Add Fiscal Calendar Columns==", "FiscalMonthNum", each if [MonthNum] > FiscalYearEndMonth
then [MonthNum] - FiscalYearEndMonth
else [MonthNum] + (12 - FiscalYearEndMonth), type number),
    #"Added FiscalMonth Name" = Table.AddColumn(#"Added FiscalMonthNum", "FiscalMonth", each [Month]),
    #"Added FiscalMonth Name Long" = Table.AddColumn(#"Added FiscalMonth Name", "FiscalMonthLong", each [MonthLong]),
    #"Added FiscalQuarter" = Table.AddColumn(#"Added FiscalMonth Name Long", "FiscalQuarter", each "FQ" & Text.From(Number.RoundUp([FiscalMonthNum] / 3,0))),
    #"Added FiscalYear" = Table.AddColumn(#"Added FiscalQuarter", "FiscalYear", each "FY" & 
Text.End(
  Text.From(
    if [MonthNum] > FiscalYearEndMonth
    then [Year] + 1
    else [Year]
  )
  , 2
)),

    #"==Add Calendar Date Offset Columns==" = #"Added FiscalYear",
    // Can be used to for example to show the past 3 months(CurMonthOffset = 0, -1, -2)
    #"Added CurMonthOffset" = Table.AddColumn(#"==Add Calendar Date Offset Columns==", "CurMonthOffset", each ( Date.Year([Date]) - Date.Year(CurrentDate) ) * 12
+ Date.Month([Date]) - Date.Month(CurrentDate), Int64.Type),
    // Can be used to for example to show the past 3 quarters (CurQuarterOffset = 0, -1, -2)
    #"Added CurQuarterOffset" = Table.AddColumn(#"Added CurMonthOffset", "CurQuarterOffset", each /*Year Difference*/
       ( Date.Year([Date]) - Date.Year(CurrentDate) )*4
       /*Quarter Difference*/
      + Number.RoundUp(Date.Month([Date]) / 3) 
      - Number.RoundUp(Date.Month(CurrentDate) / 3),
Int64.Type),
    // Can be used to for example to show the past 3 years (CurYearOffset = 0, -1, -2)
    #"Added CurYearOffset" = Table.AddColumn(#"Added CurQuarterOffset", "CurYearOffset", each Date.Year([Date]) - Date.Year(CurrentDate), Int64.Type),
    // Can be used to for example filter out all future dates
    #"Added FutureDate Flag" = Table.AddColumn(#"Added CurYearOffset", "FutureDate", each if [Date] > CurrentDate then "Future" else "Past" ),
    // FiscalYearOffset is the only Offset that is different.
    // FiscalQuarterOffset = is same as CurQuarterOffset
    // FiscalMonthOffset = is same as CurMonthOffset
    #"==Add FiscalYearOffset==" = #"Added FutureDate Flag",
    #"Filtered Rows to CurrentDate" = Table.SelectRows(#"==Add FiscalYearOffset==", each ([Date] = CurrentDate)),
    CurrentFiscalYear = #"Filtered Rows to CurrentDate"{0}[FiscalYear],
    #"Continue...Orig Table" = #"==Add FiscalYearOffset==",
    #"Added CurFiscalYearOffset" = Table.AddColumn(#"Continue...Orig Table", "CurFiscalYearOffset", each Number.From(Text.Range([FiscalYear],2,2)) - 
Number.From(Text.Range(CurrentFiscalYear,2,2))
/*Extract the numerical portion, e.g. FY18 = 18*/
, Int64.Type),
    #"==Add General Columns==" = #"Added CurFiscalYearOffset",
    // Used as 'Sort by Column' for MonthYear columns
    #"Added MonthYearNum" = Table.AddColumn(#"==Add General Columns==", "MonthYearNum", each [Year]*100 + [MonthNum] /*e.g. Sep-2016 would become 201609*/, Int64.Type),
    #"Added MonthYear" = Table.AddColumn(#"Added MonthYearNum", "MonthYear", each [Month] & "-" & Text.End(Text.From([Year]),2)),
    #"Added MonthYearLong" = Table.AddColumn(#"Added MonthYear", "MonthYearLong", each [Month] & "-" & Text.From([Year])),
    #"Added WeekdayNum" = Table.AddColumn(#"Added MonthYearLong", "WeekdayNum", each Date.DayOfWeek([Date]), Int64.Type),
    #"Added Weekday Name" = Table.AddColumn(#"Added WeekdayNum", "Weekday", each Text.Start(Date.DayOfWeekName([Date]),3), type text),
    #"Added WeekdayWeekend" = Table.AddColumn(#"Added Weekday Name", "WeekdayWeekend", each if [WeekdayNum] = 0 or [WeekdayNum] = 6
then "Weekend"
else "Weekday"),
    #"==Improve Ultimate Table" = #"Added WeekdayWeekend",
    #"----Add WeekSequenceNum----" = #"==Improve Ultimate Table",
    #"Filtered Rows Sundays Only (Start of Week)" = Table.SelectRows(#"----Add WeekSequenceNum----", each ([WeekdayNum] = 0)),
    #"Added Index WeekSequenceNum" = Table.AddIndexColumn(#"Filtered Rows Sundays Only (Start of Week)", "WeekSequenceNum", 2, 1),
    #"Merged Queries Ultimate Table to WeekSequenceNum" = Table.NestedJoin(#"==Improve Ultimate Table",{"Date"},#"Added Index WeekSequenceNum",{"Date"},"Added Index WeekNum",JoinKind.LeftOuter),
    #"Expanded Added Index WeekNum" = Table.ExpandTableColumn(#"Merged Queries Ultimate Table to WeekSequenceNum", "Added Index WeekNum", {"WeekSequenceNum"}, {"WeekSequenceNum"}),
    // somehow it ends up being unsorted after Expand Column, should not matter for the end table, but makes it harder to debug and check everything is correct. Thus sorting it.
    #"ReSorted Rows by Date" = Table.Sort(#"Expanded Added Index WeekNum",{{"Date", Order.Ascending}}),
    #"Filled Down WeekSequenceNum" = Table.FillDown(#"ReSorted Rows by Date",{"WeekSequenceNum"}),
    #"Replaced Value WeekSequenceNum null with 1" = Table.ReplaceValue(#"Filled Down WeekSequenceNum",null,1,Replacer.ReplaceValue,{"WeekSequenceNum"}),
    #"Inserted Start of Week (WeekDate)" = Table.AddColumn(#"Replaced Value WeekSequenceNum null with 1", "WeekDate", each Date.StartOfWeek([Date]), type date),
    // Updated Oct-2019
    #"Inserted Week of Year" = Table.AddColumn(#"Inserted Start of Week (WeekDate)", "Week of Year", each Date.WeekOfYear([Date]), Int64.Type),
    #"----WeekSequenceNum Complete----" = #"Inserted Week of Year",
    #"Sorted Rows" = Table.Sort(#"----WeekSequenceNum Complete----",{{"Date", Order.Descending}}),
    Current_WeekSequenceNum = #"Sorted Rows"{[Date = CurrentDate]}?[WeekSequenceNum],
    #"Added Custom CurWeekOffset" = Table.AddColumn(#"Sorted Rows", "CurWeekOffset", each [WeekSequenceNum] - Current_WeekSequenceNum, Int64.Type),
    // Adding a DayofYear 1 to 365
    // And YTD, QTD, MTD Columns (can help with showing YTD Numbers across multiple years)
    #"==Updates 2019-Feb DayofYear and YTD QTD MTD Columns" = #"Added Custom CurWeekOffset",
    // This maybe useful in some DAX Calculations
    #"Inserted Day of Year" = Table.AddColumn(#"==Updates 2019-Feb DayofYear and YTD QTD MTD Columns", "Day of Year", each Date.DayOfYear([Date]), Int64.Type),
    // 2025-11-13 Updated Logic: This logic is resilient to leap years (Feb 29) - being CurrentDate or when comparing Feb 29 in prior year to CurrentDate
    #"Added Flag_YTD" = Table.AddColumn(#"Inserted Day of Year", "Flag_YTD", each if Date.Month([Date]) * 100 + Date.Day([Date]) < Date.Month(CurrentDate) * 100 + Date.Day(CurrentDate)
 then "YTD"
 else null),
    #"Added Flag_MTD" = Table.AddColumn(#"Added Flag_YTD", "Flag_MTD", each if Date.Day([Date]) <= Date.Day(CurrentDate)
 then "MTD"
 else null),
    #"Added Flag_QTD" = Table.AddColumn(#"Added Flag_MTD", "Flag_QTD", each //Compare Month Number in Quarter (1,2,3) for [Date] and CurrentDate
if Number.Mod(Date.Month([Date])-1, 3) + 1
<= Number.Mod(Date.Month(CurrentDate)-1, 3) + 1
then "QTD"
else null),
    #"==Update 2019-Mar CurrentDayOffset" = #"Added Flag_QTD",
    #"Added CurrentDayOffset" = Table.AddColumn(#"==Update 2019-Mar CurrentDayOffset", "CurrentDayOffset", each Duration.Days([Date] - CurrentDate), Int64.Type),
    #"==Update 2025-Nov MonthStartDate and Month-Day" = #"Added CurrentDayOffset",
    // This can be useful on graphs where showing the "Month-Year" gets too busy. Showing a "Date" type allows Power BI to create a "continuous" axis, where it automatically decides how many labels to show on the axis based on the size and space available.
    #"Inserted MonthStartDate" = Table.AddColumn(#"==Update 2025-Nov MonthStartDate and Month-Day", "MonthStartDate", each Date.StartOfMonth([Date]), type date),
    // Added to easily show how YTD, QTD, MTD Flags work
    #"Added MonthDay" = Table.AddColumn(#"Inserted MonthStartDate", "MonthDay", each Date.ToText([Date], "MMM d")),
    // Need this simply to sort the MonthDay correctly. Use an odd enough date that it cannot be confused with real, initially tried 1900, but that does not work, because we get an error for Feb-29-1900. So need a leap year, hence 1904
    #"Added MonthDaySort" = Table.AddColumn(#"Added MonthDay", "MonthDaySort", each #date(1904,Date.Month([Date]), Date.Day([Date])), type date),
    // Useful to show Flag_MTD behavior
    #"Inserted Day" = Table.AddColumn(#"Added MonthDaySort", "Day", each Date.Day([Date]), Int64.Type)
in
    #"Inserted Day"