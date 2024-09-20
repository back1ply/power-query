let
   //courtesy of AccessAnalytic.com.au


    Today = Date.From(DateTime.LocalNow() ),  

   // Change start date to begining of year
    StartDate= #date(2021, 1, 1),        

    YearsInFuture = 0,
    EndDate = Date.EndOfYear(Date.AddYears(Today,YearsInFuture )),


    //set this as the last month number of your fiscal year : June = 6, July =7 etc   use 0 if FY not required
    MonthNumberForEndFinancialYear = 6,

   // Change to Day.Sunday or Day.Tuesday etc to impact the sort order number so you can then display your days in your visuals in the preferred way
    FirstDayOfWeek = Day.Monday,   



    DateList = {Number.From(StartDate)..Number.From(EndDate)},
    

    #"Converted to Table" = Table.FromList(DateList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Named as Date" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Date"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Named as Date",{{"Date", type date}}),
    #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), type number),
    #"Inserted Month Number" = Table.AddColumn(#"Inserted Year", "Month Number", each Date.Month([Date]), type number),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month Number", "Month", each Text.Start(Date.MonthName([Date]),3), type text),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted Month Name", "Day", each Text.Start( Date.DayOfWeekName([Date]),3), type text),
    #"Inserted Day of Week" = Table.AddColumn(#"Inserted Day Name", "Day of Week", each Date.DayOfWeek([Date],FirstDayOfWeek), Int64.Type),
    #"Inserted Quarter Number" = Table.AddColumn(#"Inserted Day of Week", "Quarter", each Date.QuarterOfYear([Date]),Int64.Type),
    #"Changed Type2" = Table.TransformColumnTypes(#"Inserted Quarter Number",{{"Quarter", type text}, {"Year", type text}}),
    #"Added Quarter Name" = Table.AddColumn(#"Changed Type2", "Custom", each "Q"&[Quarter]),
    #"Removed Quarter Name" = Table.RemoveColumns(#"Added Quarter Name",{"Quarter"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Quarter Name",{{"Custom", "Quarter"}}),
    #"Changed Type3" = Table.TransformColumnTypes(#"Renamed Columns",{{"Quarter", type text}}),
    #"Added YYQQ" = Table.AddColumn(#"Changed Type3", "YY-QQ", each Text.End( [Year],2) & "-"& [Quarter]),
    #"Changed Type4" = Table.TransformColumnTypes(#"Added YYQQ",{{"YY-QQ", type text}, {"Year", Int64.Type}}),
    #"Renamed SortByCols" = Table.RenameColumns(#"Changed Type4",{{"Month Number", "SortBy Month Number"}, {"Day of Week", "SortBy Day of Week"}}),
    #"▶ DatesSinceTodayFields" = #"Renamed SortByCols",
    DateToday = Today,
    DaysAgo = Table.AddColumn(#"▶ DatesSinceTodayFields", "Days Since Today", each Duration.Days([Date] -  DateToday), Int32.Type),
    #"Future Past Present" = Table.AddColumn(DaysAgo, "Future Past Present", each if [Days Since Today] > 0  then "Future" else "Past and Present"),
    #"Changed Type7" = Table.TransformColumnTypes(#"Future Past Present",{{"Future Past Present", type text}}),
    MonthsAgo = Table.AddColumn(#"Changed Type7", "Months Since Today", each ([Year] * 12 + [SortBy Month Number]) - (Date.Year(DateToday ) * 12 + Date.Month(DateToday )), Int32.Type),
    YearsAgo = Table.AddColumn(MonthsAgo, "Years Since Today", each [Year] - Date.Year(DateToday ), Int32.Type),
    #"◀ Dates Since Today" = YearsAgo,
    #"▶Financial Year Calcs" = #"◀ Dates Since Today",
    #"FY Month Number" = Table.AddColumn(#"▶Financial Year Calcs", "SortBy Financial Month Number", each if [SortBy Month Number] > MonthNumberForEndFinancialYear  then [SortBy Month Number]-MonthNumberForEndFinancialYear  else 12-MonthNumberForEndFinancialYear+[SortBy Month Number]),
    #"Changed Type1" = Table.TransformColumnTypes(#"FY Month Number",{{"SortBy Financial Month Number", Int64.Type}}),
    #"Financial Year End" = Table.AddColumn(#"Changed Type1", "Financial Year End", each if [SortBy Financial Month Number] <=12-MonthNumberForEndFinancialYear  then [Year]+1 else [Year]),
    #"Financial Year Start" = Table.AddColumn(#"Financial Year End", "Financial Year Start", each [Financial Year End] - 1, type number),
    #"Changed Type5" = Table.TransformColumnTypes(#"Financial Year Start",{{"Financial Year End", type text}, {"Financial Year Start", type text}}),
    #"Added Financial Year Range" = Table.AddColumn(#"Changed Type5", "Financial Year", each Text.End( [Financial Year Start],2) & "-" & Text.End([Financial Year End],2)),
    #"Removed FY Helpers" = Table.RemoveColumns(#"Added Financial Year Range",{"Financial Year End", "Financial Year Start"}),
    // To work out Financial Quarter
    #"DivideFinancialMonth by 3" = Table.AddColumn(#"Removed FY Helpers", "Financial Qtr Number", each [SortBy Financial Month Number] / 3, type number),
    #"Rounded Up to get Quarter" = Table.TransformColumns(#"DivideFinancialMonth by 3",{{"Financial Qtr Number", Number.RoundUp, Int64.Type}}),
    #"Added Financial Quarter" = Table.AddColumn(#"Rounded Up to get Quarter", "Financial Quarter", each "FQ-"&Text.From([Financial Qtr Number])),
    #"Removed FYQ Helper" = Table.RemoveColumns(#"Added Financial Quarter",{"Financial Qtr Number"}),
    #"Changed Type6" = Table.TransformColumnTypes(#"Removed FYQ Helper",{{"Financial Quarter", type text}, {"Financial Year", type text}}),
    #"◀ Financial Year Calcs" = #"Changed Type6",
    // If FY Month is set to 0 then Financial Year related columns will be excluded
    LOADTHIS = if MonthNumberForEndFinancialYear = 0 then  #"◀ Dates Since Today" else #"◀ Financial Year Calcs"
in
    LOADTHIS
