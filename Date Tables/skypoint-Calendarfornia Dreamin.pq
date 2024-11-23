//Calendarfornia Dreamin - Brian Grant - 2020-05-08 0901
let
    #"»»»» Table Setup ««««" = Table.FromRecords( { [] } ),
    // Which day should the calendar start on?
    // #date(2019, 7, 1) for Jul 1st 2019
    #"SET start date" = Table.AddColumn(#"»»»» Table Setup ««««", "Start", each #date( 2018, 1, 1 )),
    // How many years past the current calendar year should this run?
    #"SET years past current" = Table.AddColumn(#"SET start date", "Years Past Current", each 1),
    // What day of the week is the first?
    #"SET first day of week" = Table.AddColumn(#"SET years past current", "First Day of Wk Num", each Day.Sunday),
    // Which month of the calendar year does the fiscal year start on?
    #"SET first month of fiscal" = Table.AddColumn(#"SET first day of week","FirstMonthOfFiscal", each 7),
    #"»»»» (End Setup) ««««" = #"SET first month of fiscal",
    #"----------------" = #"»»»» (End Setup) ««««",
    #"--Build Dates--" = #"----------------",
    #"DEFINE first month of fiscal" = Table.AddColumn(#"--Build Dates--", "LastMonthOfFiscal", each Number.Mod( [FirstMonthOfFiscal] + 10, 12 ) + 1 ),
    #"DEFINE end" = Table.AddColumn(#"DEFINE first month of fiscal", "End", each Date.AddYears(
    Date.EndOfYear(
        Date.From(
            DateTime.FixedLocalNow()
        )
    ),
    [Years Past Current]
), type date ),
    #"DEFINE date" = Table.AddColumn(#"DEFINE end", "Date", each
List.Dates(
    [Start],
    Number.From( [End] - [Start] ) + 1,
    Duration.From(1)
)
),
    #"KEEP essential columns" = Table.SelectColumns(#"DEFINE date",{"First Day of Wk Num", "LastMonthOfFiscal", "FirstMonthOfFiscal", "Date"}),
    #"EXPAND date" = Table.ExpandListColumn(#"KEEP essential columns", "Date"),
    #"CAST as date" = Table.TransformColumnTypes(#"EXPAND date",{{"Date", type date}, {"LastMonthOfFiscal", Int64.Type}, {"FirstMonthOfFiscal", Int64.Type}}),
    #"--Add Helper Columns--" = #"CAST as date",
    #"DEFINE date fis equiv" = Table.AddColumn(#"--Add Helper Columns--", "FisRefDate", each Date.AddMonths( [Date], 12 - [LastMonthOfFiscal] )),
    #"--Date Columns--" = #"DEFINE date fis equiv",
    #"ADD date relative" = Table.AddColumn(#"--Date Columns--", "Date Relative Num", each Duration.Days( 
    [Date] - 
    Date.From( DateTime.FixedLocalNow() ) 
), type number),
    #"--Year Columns--" = #"ADD date relative",
    #"ADD year" = Table.AddColumn(#"--Year Columns--", "Year", each Date.Year([Date]), Int64.Type),
    #"ADD year start date" = Table.AddColumn(#"ADD year", "Year Start Date", each Date.StartOfYear([Date]), type date),
    #"ADD year relative num" = Table.AddColumn(#"ADD year start date", "Year Relative Num", each Date.Year([Date]) - 
Date.Year(DateTime.From(DateTime.FixedLocalNow())), Int64.Type),
    #"ADD fis year" = Table.AddColumn(#"ADD year relative num", "Fis Year", each Date.Year([FisRefDate]), Int64.Type),
    #"ADD fis year start date" = Table.AddColumn(#"ADD fis year", "Fis Year Start Date", each 
Date.AddMonths( Date.StartOfYear([FisRefDate]) , -1 * (12 - [LastMonthOfFiscal] ) )

, type date),
    #"ADD fis year relative num" = Table.AddColumn(#"ADD fis year start date", "Fis Year Relative Num", each [
vrSysDate = Date.From(DateTime.FixedLocalNow()),
vrLastMonFY = [LastMonthOfFiscal], 

vrSysEquivDate = 
    Date.AddMonths( 
        vrSysDate, 
        12 - vrLastMonFY 
    ),
vrSysFY = Date.Year( vrSysEquivDate ),
vrRowFY = Date.Year([FisRefDate]),
vrRelativeFY = vrRowFY - vrSysFY
][vrRelativeFY], Int64.Type),
    #"--Qtr Columns--" = #"ADD fis year relative num",
    #"ADD quarter num" = Table.AddColumn(#"--Qtr Columns--", "Qtr Num", each Date.QuarterOfYear([Date]), Int64.Type),
    #"ADD quarter" = Table.AddColumn(#"ADD quarter num", "Qtr", each "Q" & Text.From( Date.QuarterOfYear([Date]) ), type text),
    #"ADD qtr qq-yy" = Table.AddColumn(#"ADD quarter", "Qtr qq-yy", each 
"Q" & Text.From( Date.QuarterOfYear([Date]) ) & 
"-" & Date.ToText([Date], "yy"), type text),
    #"ADD qtr start" = Table.AddColumn(#"ADD qtr qq-yy", "Qtr Start Date", each Date.StartOfQuarter([Date]), type date),
    #"ADD fis qtr num" = Table.AddColumn(#"ADD qtr start", "Fis Qtr Num", each Date.QuarterOfYear( [FisRefDate] ), type number),
    #"ADD fis qtr" = Table.AddColumn(#"ADD fis qtr num", "Fis Qtr", each "Q" & Text.From( Date.QuarterOfYear( [FisRefDate]) ), type text),
    #"ADD fis qtr start date" = Table.AddColumn(#"ADD fis qtr", "Fis Qtr Start Date", each Date.StartOfQuarter([Date]), type date),
    #"ADD fis qtr qq-yy" = Table.AddColumn(#"ADD fis qtr start date", "Fis Qtr qq-yy", each "Q" & Text.From( Date.QuarterOfYear( [FisRefDate] ) ) & 
"-" & Date.ToText( [FisRefDate], "yy"), type text),
    #"ADD qtr relative num" = Table.AddColumn(#"ADD fis qtr qq-yy", "Qtr Relative Num", each
(
    Date.Year(Date.From([Date])) * 4 + 
    Date.QuarterOfYear(Date.From([Date])) 
) -
(
    Date.Year(Date.From(DateTime.FixedLocalNow())) * 4 + 
    Date.QuarterOfYear(Date.From(DateTime.FixedLocalNow())) 
),
type number),
    #"--Month Columns--" = #"ADD qtr relative num",
    #"ADD month num" = Table.AddColumn(#"--Month Columns--", "Month Num", each Date.Month([Date]), Int64.Type),
    #"ADD month" = Table.AddColumn(#"ADD month num", "Month", each Date.ToText( [Date], "MMM" ), type text),
    #"ADD month mmm-yyyy" = Table.AddColumn(#"ADD month", "Month mmm-yyyy", each Date.ToText( [Date], "MMM-yyyy" ), type text),
    #"ADD month start date" = Table.AddColumn(#"ADD month mmm-yyyy", "Month Start Date", each Date.StartOfMonth([Date]), type date),
    #"ADD fis month num" = Table.AddColumn(#"ADD month start date", "Fis Month Num", each Date.Month([FisRefDate]), Int64.Type),
    #"ADD fis month mmm-yyyy" = Table.AddColumn(#"ADD fis month num", "Fis Month mmm-yyyy", each Date.ToText( [Date], "MMM" ) & "-" & Date.ToText( [FisRefDate], "yyyy" ), type text),
    #"ADD fis month start date" = Table.AddColumn(#"ADD fis month mmm-yyyy", "Fis Month Start Date", each Date.StartOfMonth([Date]), type date),
    #"ADD fis month" = Table.AddColumn(#"ADD fis month start date", "Fis Month", each Date.ToText( [Date], "MMM" ), type text),
    #"ADD relative month num" = Table.AddColumn(#"ADD fis month", "Month Relative Num", each 
( Date.Year([Date]) * 12 + Date.Month([Date]) )- 
( Date.Year( Date.From( DateTime.FixedLocalNow() ) ) * 12 + Date.Month(Date.From( DateTime.FixedLocalNow() )) )
, type number),
    #"--Week Columns--" = #"ADD relative month num",
    #"ADD wk of year usa" = Table.AddColumn(#"--Week Columns--", "Week of Year (USA)", each [
//Get the assumptions
vrRowDate  = [Date],
vrYrStartMon = [FirstMonthOfFiscal],
vrDowStart = [First Day of Wk Num],

//Figure out the FisYrs start date for this row
vrRowYear  = Date.Year( vrRowDate ),
vrRefDateRaw = #date( vrRowYear, 1, 1 ),

//Get the first day of the week for each
vrYrWkStart = Date.StartOfWeek( vrRefDateRaw, vrDowStart ),
vrRowWkStart = Date.StartOfWeek( vrRowDate, vrDowStart ),

//Get the days between and divide by 7 to get wks between.
vrWeekNum = 
    Duration.Days(  vrRowWkStart - vrYrWkStart ) 
    / 7 
    + 1
][vrWeekNum], type number),
    #"ADD we start date" = Table.AddColumn(#"ADD wk of year usa", "Week Start Date", each Date.StartOfWeek([Date], [First Day of Wk Num]), type date),
    #"ADD fis wk of year usa" = Table.AddColumn(#"ADD we start date", "Fis Week Of Year (USA)", each [
//Get the assumptions
vrRowDate  = [Date],
vrYrStartMon = [FirstMonthOfFiscal],
vrDowStart = [First Day of Wk Num],

//Figure out the FisYrs start date for this row
vrRowMonth = Date.Month( vrRowDate ),
vrRowYear  = Date.Year( vrRowDate ),
vrDateInCurrCalYear = ( vrRowMonth >= vrYrStartMon ),
vrRefDateRaw =
    if   vrDateInCurrCalYear
    then #date( vrRowYear,     vrYrStartMon, 1 )
    else #date( vrRowYear - 1, vrYrStartMon, 1 ),

//Get the first day of the week for each
vrYrWkStart = Date.StartOfWeek( vrRefDateRaw, vrDowStart ),
vrRowWkStart = Date.StartOfWeek( vrRowDate, vrDowStart ),

//Get the days between and divide by 7 to get wks between.
vrWeekNum = 
    Duration.Days(  vrRowWkStart - vrYrWkStart ) 
    / 7 
    + 1
][vrWeekNum], type number),
    #"ADD wk relative" = Table.AddColumn(#"ADD fis wk of year usa", "Week Relative", each [
vrRowDate = [Date],
vrSysDate = Date.From( DateTime.FixedLocalNow() ),
vrWeeksStart = [First Day of Wk Num],

vrRowWkStart = Date.StartOfWeek( vrRowDate, vrWeeksStart ),
vrSysWkStart = Date.StartOfWeek( vrSysDate, vrWeeksStart ),
vrRelativeWeek = 
    Duration.Days( vrRowWkStart - vrSysWkStart ) / 7
][vrRelativeWeek], type number),
    #"ADD day of wk name" = Table.AddColumn(#"ADD wk relative", "Day of Week", each Date.ToText([Date], "ddd"), type text),
    #"ADD day of wk num" = Table.AddColumn(#"ADD day of wk name", "Day of Wk Num", each Date.DayOfWeek( [Date], [First Day of Wk Num] ) + 1, Int64.Type),
    #"ADD weekday flag" = Table.AddColumn(#"ADD day of wk num", "Weekday Flag", each if Date.DayOfWeek( [Date], Day.Monday ) <= 4
then 1
else 0, Int64.Type),
    #"ADD weekday label" = Table.AddColumn(#"ADD weekday flag", "Weekday Label", each if Date.DayOfWeek( [Date], Day.Monday ) <= 4
then "Weekday"
else "Weekend", type text),
    #"DELETE helper columns" = Table.RemoveColumns(#"ADD weekday label",{"First Day of Wk Num", "LastMonthOfFiscal", "FirstMonthOfFiscal", "FisRefDate"}),
    #"--Keep Reorder Rename--" = #"DELETE helper columns"
in
    #"--Keep Reorder Rename--"