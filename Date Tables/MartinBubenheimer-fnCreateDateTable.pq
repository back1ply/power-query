let
    Source = let   
fnCreateDateTable=(CalendarYearStart, NumberYearsFuture, optional Culture, optional MonthStartFiscalYear, optional WeekStartDay )=>

let
/*
Example:
CalendarYearStart = 2019,
NumberYearsFuture = 1,
Culture = "en-US", 
MonthStartFiscalYear = "Apr",
WeekStartDay = "Mo", 
*/
    // Today-Calculation: Subtract one day if you want to treat yesterday (the last complete day) as "today".
    Today = Date.AddDays(Date.From(DateTime.LocalNow()), 0),
    TodayNaturalKey = Date.Year(Today) * 10000 + Date.Month(Today) * 100 + Date.Day(Today),
    TodayIsLeapYear = Number.From( Date.IsLeapYear( Today ) ),
    TodayIsEndOfMonth = if Today = Date.EndOfMonth(Today) then 1 else 0,
    TodayMonthDayKey = if Number.Mod ( TodayNaturalKey, 10000 ) = 228 and TodayIsLeapYear = 0 then 229 else Number.Mod ( TodayNaturalKey, 10000 ),
    TodayMonthDayKeyOtherHalfyear = (Number.Mod(Date.Month(Today) + 5, 12) + 1) * 100 + (if TodayIsEndOfMonth = 1 then 31 else Number.Mod(TodayMonthDayKey, 100)),
    TodayMonthDayKeyNextQuarter = (Number.Mod(Date.Month(Today) + 2, 12) + 1) * 100 + (if TodayIsEndOfMonth = 1 then 31 else Number.Mod(TodayMonthDayKey, 100)),
    TodayMonthDayKeyPreviousQuarter = (Number.Mod(Date.Month(Today) + 8, 12) + 1) * 100 + (if TodayIsEndOfMonth = 1 then 31 else Number.Mod(TodayMonthDayKey, 100)),
    Source = fnCreateDateTable(2019, 1, "en-US", "Apr", "Mo"),
    LastYear = Date.Year(Date.From(DateTime.LocalNow())) + NumberYearsFuture,
    StartFiscalYear = if MonthStartFiscalYear = null then "Jan" else MonthStartFiscalYear,
    GetStartDay = if StartFiscalYear = "Jan" then #date(CalendarYearStart,1,1) else Date.FromText("01."&StartFiscalYear &Number.ToText(CalendarYearStart)),
    GetEndDay = if StartFiscalYear = "Jan" then #date(LastYear,12,31) else Date.EndOfMonth(Date.AddMonths(Date.AddYears(Date.FromText("01-" & StartFiscalYear & "-" & Number.ToText(LastYear), [Format="dd-MMM-yyyy", Culture="en-US"]), 1), -1) ),
    GetCultureDefaultEnUs = if Culture = null then "en-US" else Culture,
    DayCount = Duration.Days(Duration.From(GetEndDay - GetStartDay)) + 1,
    GetListOfDates = List.Dates(GetStartDay,DayCount,#duration(1,0,0,0)),
    TableFromList = Table.FromList(GetListOfDates, Splitter.SplitByNothing()),
    ChangedType = Table.TransformColumnTypes(TableFromList,{{"Column1", type date}}),
    DateColumn = Table.Buffer(Table.RenameColumns(ChangedType,{{"Column1", "Date"}})),
    #"Add Full Date Description" = Table.AddColumn(DateColumn, "Full Date Description", each 
        if (Text.Start(Culture, 2) = "en") then 
            if Date.Day([Date]) = 1 or Date.Day([Date]) = 21 or Date.Day([Date]) = 31 then Date.ToText([Date], "MMMM dˢᵗ, yyyy", Culture) else
            if Date.Day([Date]) = 2 or Date.Day([Date]) = 22 then Date.ToText([Date], "MMMM dⁿᵈ, yyyy", Culture) else
            if Date.Day([Date]) = 3 or Date.Day([Date]) = 23 then Date.ToText([Date], "MMMM dʳᵈ, yyyy", Culture) else
            Date.ToText([Date], "MMMM dᵗʰ, yyyy", Culture)
        else Date.ToText([Date], "dd. MMMM yyyy", Culture), 
        type text),
    
    //================================================
    CalculateWeekStartDay = 
        if WeekStartDay = null then 
          1 
        else  
            List.Select({
              [DayOfWeek="Mo", WeekStartDay= Day.Monday],
              [DayOfWeek="Tu", WeekStartDay= Day.Tuesday],
              [DayOfWeek="We", WeekStartDay= Day.Wednesday],
              [DayOfWeek="Th", WeekStartDay= Day.Thursday],
              [DayOfWeek="Fr", WeekStartDay= Day.Friday],
              [DayOfWeek="Sa", WeekStartDay= Day.Saturday],
              [DayOfWeek="Su", WeekStartDay= Day.Sunday]
              }, each _[DayOfWeek] = WeekStartDay){0}[WeekStartDay],
    //================================================
    
    AddWeekDaySort = Table.AddColumn(#"Add Full Date Description", "Day of Week #", each Date.DayOfWeek([Date], CalculateWeekStartDay) + 1, Int64.Type),
    AddMonthDaySort = Table.AddColumn(AddWeekDaySort, "Day of Month #", each Date.Day([Date]), Int64.Type),
    #"Day of Year Added" = Table.AddColumn(AddMonthDaySort, "Day of Year #", each Date.DayOfYear([Date]), Int64.Type),
    AddDayKey = Table.AddIndexColumn(#"Day of Year Added", "Date Surrogate Key #", 1, 1, Int64.Type),
    AddDateNaturalKey = Table.AddColumn(AddDayKey, "Date Natural Key #", each Date.Year([Date]) * 10000 + Date.Month([Date]) * 100 + Date.Day([Date]), Int64.Type),
    AddDayName = Table.AddColumn(AddDateNaturalKey, "Name of Day (long)", each Date.DayOfWeekName([Date], Culture), type text),
    AddDaysName2digits = Table.AddColumn(AddDayName, "Name of Day (short)", each Date.ToText([Date],"ddd", Culture), type text),
    AddDaysName1digit = Table.AddColumn(AddDaysName2digits, "Name of Day (letter)", each Text.Start(Date.DayOfWeekName([Date], Culture),1) /* & Text.Repeat(Character.FromNumber(8203), [#"Day of Week #"]) */, type text),
    WD_WE_flag = Table.AddColumn(AddDaysName1digit, "Working Day Flag", each if Number.Mod([#"Day of Week #"] + 5 + CalculateWeekStartDay, 7) + 1 < 6 then "Working Day" else "Weekend", type text),
    AddWeekOfYear = Table.AddColumn(WD_WE_flag, "Week of Year #", each Date.WeekOfYear([Date]), Int64.Type),
    #"Added Start of Week" = Table.AddColumn(AddWeekOfYear, "Start of Week Date", each Date.StartOfWeek([Date]), type date),
    #"Added End of Week" = Table.AddColumn(#"Added Start of Week", "End of Week Date", each Date.EndOfWeek([Date]), type date),
    AddYearWeek = Table.AddColumn(#"Added End of Week", "Year & Week #", each Date.Year([Date])*100+[#"Week of Year #"], Int64.Type),
    TableWeekKey = /*List.Distinct(#"Changed Type"[#"Year & Week #"])*/ Table.TransformColumnTypes(Table.AddIndexColumn(Table.TransformColumnTypes(Table.RenameColumns(Table.FromList(List.Sort(List.Distinct(AddYearWeek[#"Year & Week #"]),Order.Ascending), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "YearWeek"}}),{{"YearWeek", Int64.Type}}), "Week Surrogate Key #", 1, 1), {{"Week Surrogate Key #", Int64.Type}}),
    AddWeeKey = Table.NestedJoin(AddYearWeek,{"Year & Week #"},TableWeekKey,{"YearWeek"},"WK",JoinKind.LeftOuter),
    #"Expanded WK" = Table.ExpandTableColumn(AddWeeKey, "WK", {"Week Surrogate Key #"}, {"Week Surrogate Key #"}),
    RemovedYearWeek = Table.RemoveColumns(#"Expanded WK",{"Year & Week #"}),
    AddCW_Year = Table.AddColumn(RemovedYearWeek, "Week & Year", each "CW " & Text.PadStart(Number.ToText([#"Week of Year #"]), 2, "0") & "/" & Number.ToText(Date.Year([Date])), type text),
    AddYear_CW = Table.AddColumn(AddCW_Year, "Year & Week", each Number.ToText(Date.Year([Date])) & "-CW " & Text.PadStart(Number.ToText([#"Week of Year #"]), 2, "0"), type text),
    fnGetIsoWeekNumber = (MyDate as date) =>
      //Source --> https://blogs.office.com/en-us/2009/06/30/week-numbers-in-excel/
      // ISO week by definition always starts on Monday
    let
      //MyDate = #date(2016,1,3),
      Part1 = Number.From(MyDate) - Number.From(#date(Date.Year(Date.From(Number.From(MyDate) - (Date.DayOfWeek(Date.AddDays(MyDate,-1), Day.Sunday) + 1) + 4)),1,3)),
      Part2 = Date.DayOfWeek(#date(Date.Year(Date.From(Number.From(MyDate) - (Date.DayOfWeek(Date.AddDays(MyDate,-1), Day.Sunday) +1) + 4)),1,3), Day.Sunday)+1 + 5,
      ISOWeekNumber = Number.IntegerDivide(Part1 + Part2, 7)
    in
      ISOWeekNumber,
    AddIsoWeek = Table.AddColumn(AddYear_CW, "ISO Week #", each fnGetIsoWeekNumber([Date]), Int64.Type),
    AddIsoYear = Table.AddColumn(AddIsoWeek,"ISO Year #",each Date.Year(Date.AddDays([Date],3 - Date.DayOfWeek([Date], 1))), Int64.Type),
    AddIsoYear_IsoCW = Table.AddColumn(AddIsoYear, "ISO Year & ISO Week", each Text.From([#"ISO Year #"]) & "-CW " & Text.PadStart(Text.From([#"ISO Week #"]), 2, "0") , type text),
    AddIsoCW_IsoYear = Table.AddColumn(AddIsoYear_IsoCW, "ISO Week & ISO Year", each "CW " & Text.PadStart(Text.From([#"ISO Week #"]), 2, "0") & "/" & Text.From([#"ISO Year #"]), type text),
    GetIsoWeekKey = Table.TransformColumnTypes(Table.AddIndexColumn( Table.Distinct( Table.SelectColumns(AddIsoCW_IsoYear, {"ISO Year & ISO Week"}), {"ISO Year & ISO Week"}), "ISO Week Surrogate Key #", 1, 1), {{"ISO Week Surrogate Key #", Int64.Type}}),
    AddIsoWeekKey = Table.AddJoinColumn(AddIsoCW_IsoYear, {"ISO Year & ISO Week"}, GetIsoWeekKey, {"ISO Year & ISO Week"}, "NEW"),
    ExpandIsoWeekKey = Table.ExpandTableColumn(AddIsoWeekKey, "NEW", {"ISO Week Surrogate Key #"}, {"ISO Week Surrogate Key #"}),
    AddMonthSort = Table.AddColumn(ExpandIsoWeekKey, "Month #", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthSort, "Month Name (long)", each Date.MonthName([Date], Culture), type text),
    AddMonthName3digits = Table.AddColumn(AddMonthName, "Month Name (short)", each Date.ToText([Date], "MMM", Culture), type text),
    AddMonthName1digit = Table.AddColumn(AddMonthName3digits, "Month Name (letter)", each Text.Start(Date.MonthName([Date], Culture),1) /* & Text.Repeat(Character.FromNumber(8203), [#"Month #"]) */, type text),
    AddMonthNameShort_Year = Table.AddColumn(AddMonthName1digit, "Month & Year", each [#"Month Name (short)"] &" "& Number.ToText(Date.Year([Date])), type text),
    AddMonthYear = Table.AddColumn(AddMonthNameShort_Year, "Year & Month", each Number.ToText(Date.Year([Date])) &" "&[#"Month Name (short)"], type text),
    AddYearMonth = Table.TransformColumnTypes(Table.AddColumn(AddMonthYear, "Year Month #", each Date.Year([Date])*100 + [#"Month #"]),{{"Year Month #", Int64.Type}}),
    TableYearMonth = Table.TransformColumnTypes(Table.AddIndexColumn(Table.TransformColumnTypes(Table.RenameColumns(Table.FromList(List.Sort(List.Distinct(AddYearMonth[#"Year Month #"]),Order.Ascending), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "YearMonth"}}),{{"YearMonth", Int64.Type}}), "Month Surrogate Key #", 1, 1), {{"Month Surrogate Key #", Int64.Type}}),
    #"Merged Queries" = Table.NestedJoin(AddYearMonth,{"Year Month #"},TableYearMonth,{"YearMonth"},"MK",JoinKind.LeftOuter),
    #"Expanded MK" = Table.ExpandTableColumn(#"Merged Queries", "MK", {"Month Surrogate Key #"}, {"Month Surrogate Key #"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded MK",{"Year Month #"}),
    AddSoM = Table.AddColumn(#"Removed Columns1", "Start of Month Date", each Date.StartOfMonth([Date]), type date),
    AddEoM = Table.AddColumn(AddSoM, "End of Month Date", each Date.EndOfMonth([Date]), type date),
    AddQuarter = Table.AddColumn(AddEoM, "Quarter (CY) #", each Date.QuarterOfYear([Date]), Int64.Type),
    AddQuarterName = Table.AddColumn(AddQuarter, "Quarter (CY)", each "Q " & Number.ToText([#"Quarter (CY) #"]), type text),
    AddQuarterYear = Table.AddColumn(AddQuarterName, "Quarter (CY) & Year", each "Q " & Number.ToText([#"Quarter (CY) #"]) & "/" & Number.ToText(Date.Year([Date])), type text),
    AddYearQuarterName = Table.AddColumn(AddQuarterYear, "Year & Quarter (CY)", each Number.ToText(Date.Year([Date])) & "-Q " & Number.ToText([#"Quarter (CY) #"]), type text),
    AddYearQuarter = Table.AddColumn(AddYearQuarterName, "Year Quarter (CY) Surrogate Key #", each Date.Year([Date]) * 100 + [#"Quarter (CY) #"], Int64.Type),
    TableYearQuarter = Table.TransformColumnTypes(Table.AddIndexColumn(Table.TransformColumnTypes(Table.RenameColumns(Table.FromList(List.Sort(List.Distinct(AddYearQuarter[#"Year Quarter (CY) Surrogate Key #"]),Order.Ascending), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "Year Quarter (CY) Surrogate Key #"}}),{{"Year Quarter (CY) Surrogate Key #", Int64.Type}}), "Quarter (CY) Surrogate Key #", 1, 1), {{"Quarter (CY) Surrogate Key #", Int64.Type}}),
    GetQuarterKey = Table.NestedJoin(AddYearQuarter,{"Year Quarter (CY) Surrogate Key #"},TableYearQuarter,{"Year Quarter (CY) Surrogate Key #"},"QK",JoinKind.LeftOuter),
    AddQuarterKey = Table.ExpandTableColumn(GetQuarterKey, "QK", {"Quarter (CY) Surrogate Key #"}, {"Quarter (CY) Surrogate Key #"}),
    RemoveColumnsYearQuarterCY = Table.RemoveColumns(AddQuarterKey,{"Year Quarter (CY) Surrogate Key #"}),
    AddHalfYearSort = Table.TransformColumnTypes(Table.AddColumn(AddQuarterKey, "Halfyear (CY) #", each if Date.Month([Date]) < 7 then 1 else 2),{{"Halfyear (CY) #", Int64.Type}}),
    AddHalfYearName = Table.AddColumn(AddHalfYearSort, "Halfyear (CY)", each "HY " & Number.ToText([#"Halfyear (CY) #"]), type text),
    AddHalfyearYear = Table.AddColumn(AddHalfYearName, "Halfyear (CY) & Year", each "HY " & Number.ToText([#"Halfyear (CY) #"]) & "/" & Number.ToText(Date.Year([Date])), type text),
    AddYearHalfyear = Table.AddColumn(AddHalfyearYear, "Year & Halfyear (CY)", each Number.ToText(Date.Year([Date])) & "-" & "HY "&Number.ToText([#"Halfyear (CY) #"]), type text),
    AddYearHalfyearKey = Table.TransformColumnTypes(Table.AddColumn(AddYearHalfyear, "Halfyear (CY) Natural Key #", each Date.Year([Date])*100+[#"Halfyear (CY) #"]),{{"Halfyear (CY) Natural Key #", Int64.Type}}),
    TableYearHalfYear = Table.TransformColumnTypes(Table.AddIndexColumn(Table.TransformColumnTypes(Table.RenameColumns(Table.FromList(List.Sort(List.Distinct(AddYearHalfyearKey[#"Halfyear (CY) Natural Key #"]),Order.Ascending), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "YearHalfYear"}}),{{"YearHalfYear", Int64.Type}}), "HalfYearKey", 1, 1), {{"HalfYearKey", Int64.Type}}),
    GetHalfYearKey = Table.NestedJoin(AddYearHalfyearKey,{"Halfyear (CY) Natural Key #"},TableYearHalfYear,{"YearHalfYear"},"HYK",JoinKind.LeftOuter),
    AddHalfYearKey = Table.ExpandTableColumn(GetHalfYearKey, "HYK", {"HalfYearKey"}, {"Halfyear (CY) Surrogate Key #"}),
    RemoveColumnHalfyearCYNaturalKey = Table.RemoveColumns(AddHalfYearKey,{"Halfyear (CY) Natural Key #"}),
    AddYear = Table.AddColumn(RemoveColumnHalfyearCYNaturalKey, "Year #", each Date.Year([Date]), Int64.Type),
    AddJahrKey = Table.AddColumn(AddYear, "Year Surrogate Key #", each [#"Year #"] - List.Min(AddYear[#"Year #"]) + 1, Int64.Type),
    IsLeapYear = Table.Buffer(Table.TransformColumnTypes(Table.AddColumn(AddJahrKey, "Leap Year", each Number.From( Date.IsLeapYear( [Date] ))),{{"Leap Year", Int64.Type}})),

    fnKeysTodayRecord =
      let
      GetTodayRow = Table.SelectRows(IsLeapYear, each _[Date] = Today),
      Output = 
        [
          DateKeyToday = GetTodayRow[#"Date Surrogate Key #"]{0}, 
          WeekKeyToday = GetTodayRow[#"Week Surrogate Key #"]{0},
          IsoWeekKeyToday = GetTodayRow[#"ISO Week Surrogate Key #"]{0},
          MonthKeyToday = GetTodayRow[#"Month Surrogate Key #"]{0},
          QuarterKeyToday = GetTodayRow[#"Quarter (CY) Surrogate Key #"]{0},
          HalfyearKeyToday = GetTodayRow[#"Halfyear (CY) Surrogate Key #"]{0},
          YearKeyToday = GetTodayRow[#"Year Surrogate Key #"]{0}
        ]
      in
      Output, 
    AddDayOffset = Table.AddColumn(IsLeapYear, "Day Offset #", each [#"Date Surrogate Key #"] - fnKeysTodayRecord[DateKeyToday], Int64.Type),
    AddWeekOffset = Table.AddColumn(AddDayOffset, "Week Offset #", each [#"Week Surrogate Key #"] - fnKeysTodayRecord[WeekKeyToday], Int64.Type),
    AddIsoWeekOffset = Table.AddColumn(AddWeekOffset, "ISO Week Offset #", each [#"ISO Week Surrogate Key #"] - fnKeysTodayRecord[IsoWeekKeyToday], Int64.Type),
    AddMonthOffset = Table.AddColumn(AddIsoWeekOffset, "Month Offset #", each [#"Month Surrogate Key #"] - fnKeysTodayRecord[MonthKeyToday], Int64.Type),
    AddCalendarQuarterOffset = Table.AddColumn(AddMonthOffset, "Quarter (CY) Offset #", each [#"Quarter (CY) Surrogate Key #"] - fnKeysTodayRecord[QuarterKeyToday], Int64.Type),
    AddCalendarHalfyearOffset = Table.AddColumn(AddCalendarQuarterOffset, "Halfyear (CY) Offset #", each [#"Halfyear (CY) Surrogate Key #"] - fnKeysTodayRecord[HalfyearKeyToday], Int64.Type),
    AddCalendarYearOffset = Table.AddColumn(AddCalendarHalfyearOffset, "Calendar Year Offset #", each [#"Year Surrogate Key #"] - fnKeysTodayRecord[YearKeyToday], Int64.Type),
    
    //Days 2 Go-Calculation ("2 Go" are days in the current period and in the future, i.e., days to go until the current period ends.)
    ListGetWeek2Go = List.Buffer(Table.SelectRows(AddCalendarYearOffset, each [#"Week Offset #"] = 0 and [Date] > Today)[Date]),
    ListGetIsoWeek2Go = List.Buffer(Table.SelectRows(AddCalendarYearOffset, each [#"ISO Week Offset #"] = 0 and [Date] > Today)[Date]),
    ListGetMonth2Go = List.Buffer(Table.SelectRows(AddCalendarYearOffset, each [#"Month Offset #"] = 0 and [Date] > Today)[Date]),
    ListGetQuarter2Go = List.Buffer(Table.SelectRows(AddCalendarYearOffset, each [#"Quarter (CY) Offset #"] = 0 and [Date] > Today)[Date]),
    ListGetHalfYear2Go = List.Buffer(Table.SelectRows(AddCalendarYearOffset, each [#"Halfyear (CY) Offset #"] = 0 and [Date] > Today)[Date]),
    ListGetYear2Go = List.Buffer(Table.SelectRows(AddCalendarYearOffset, each [#"Calendar Year Offset #"] = 0 and [Date] > Today)[Date]),
    
    AddWeek2Go = Table.AddColumn( AddCalendarYearOffset, "Week Days 2 Go", each Number.From(List.Contains(ListGetWeek2Go, [Date])), Int64.Type),
    AddIsoWeek2Go = Table.AddColumn( AddWeek2Go, "ISO Week Days 2 Go", each Number.From(List.Contains(ListGetIsoWeek2Go, [Date])), Int64.Type),
    AddMonth2Go = Table.AddColumn( AddIsoWeek2Go, "Month Days 2 Go", each Number.From(List.Contains(ListGetMonth2Go, [Date])), Int64.Type),
    AddQuarter2Go = Table.AddColumn( AddMonth2Go, "Quarter (CY) Days 2 Go", each Number.From(List.Contains(ListGetQuarter2Go, [Date])), Int64.Type),
    AddHalfyear2Go = Table.AddColumn( AddQuarter2Go, "Halfyear (CY) Days 2 Go", each Number.From(List.Contains(ListGetHalfYear2Go, [Date])), Int64.Type),
    AddYear2Go = Table.AddColumn( AddHalfyear2Go, "Calendar Year Days 2 Go", each Number.From(List.Contains(ListGetYear2Go, [Date])), Int64.Type),

    AddYTD = Table.AddColumn(AddYear2Go, "YTD", each if Date.Month(Today) = 12 and Date.Day(Today) = 31 then 1 else 
            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey or (TodayMonthDayKey = 228 and TodayIsLeapYear = 0 and Number.Mod ( [#"Date Natural Key #"], 10000 ) = 229)
            then 1 
            else null, 
        Int64.Type),
    AddHYTD = Table.AddColumn(AddYTD, "HYTD", each if (Date.Month(Today) = 6 and Date.Day(Today) = 30) or (Date.Month(Today) = 12 and Date.Day(Today) = 31) then 1 else 
        if Date.Month(Today) <= 6
        then
            if [#"Month #"] <= 6
            then 
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                then 1
                else null
            else
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                then 1
                else null
        else
            if [#"Month #"] > 6
            then 
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                then 1
                else null
            else
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                then 1
                else null,
        Int64.Type),
    AddQTD = Table.AddColumn(AddHYTD, "QTD", each 
    if (Date.Month(Today) = 3 and Date.Day(Today) = 31)
        or (Date.Month(Today) = 6 and Date.Day(Today) = 30) 
        or (Date.Month(Today) = 9 and Date.Day(Today) = 30) 
        or (Date.Month(Today) = 12 and Date.Day(Today) = 31)
    then 1 
    else 
        if Date.Month(Today) <= 3
        then
            if [#"Month #"] <= 3
            then 
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                then 1
                else null
            else
                if [#"Month #"] <= 6
                then 
                    if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyNextQuarter
                    then 1
                    else null
                else 
                    if [#"Month #"] <= 9
                    then
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                        then 1
                        else null
                    else
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyPreviousQuarter
                        then 1
                        else null
        else
            if Date.Month(Today) <= 6
            then
                if [#"Month #"] <= 3
                then 
                    if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyPreviousQuarter
                    then 1
                    else null
                else
                    if [#"Month #"] <= 6
                    then 
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                        then 1
                        else null
                    else 
                        if [#"Month #"] <= 9
                        then
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyNextQuarter
                            then 1
                            else null
                        else
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                            then 1
                            else null
            else
                if Date.Month(Today) <= 9
                then
                    if [#"Month #"] <= 3
                    then 
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                        then 1
                        else null
                    else
                        if [#"Month #"] <= 6
                        then 
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyPreviousQuarter
                            then 1
                            else null
                        else 
                            if [#"Month #"] <= 9
                            then
                                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                                then 1
                                else null
                            else
                                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyNextQuarter
                                then 1
                                else null
                else
                    if [#"Month #"] <= 3
                    then 
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyNextQuarter
                        then 1
                        else null
                    else
                        if [#"Month #"] <= 6
                        then 
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                            then 1
                            else null
                        else 
                            if [#"Month #"] <= 9
                            then
                                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyPreviousQuarter
                                then 1
                                else null
                            else
                                if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                                then 1
                                else null,
        Int64.Type),
    AddMTD = Table.AddColumn(AddQTD, "MTD", each if TodayIsEndOfMonth = 1 then 1 else if Date.Day([Date]) <= Date.Day(Today) then 1 else null, Int64.Type),

    //============================================================================== Fiscal Year Calculations Start =================================================================
    GetStartMonthNumberFiscalYear = List.PositionOf({"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}, MonthStartFiscalYear ) + 1,
    
    AddFiscalYearNumber = Table.AddColumn(AddMTD, "Fiscal Year #", each (if Date.Month([Date]) < GetStartMonthNumberFiscalYear then Date.Year([Date]) else Date.Year([Date]) + 1) - (if GetStartMonthNumberFiscalYear <= 6 then 1 else 0), Int64.Type),
    AddFiscalYearLabel = Table.AddColumn(AddFiscalYearNumber, "Fiscal Year", each "FY " & Number.ToText([#"Fiscal Year #"]), type text),
    AddFiscalMonthNumber = Table.AddColumn(AddFiscalYearLabel, "Fiscal Month #", each if ( Date.Month([Date]) >= GetStartMonthNumberFiscalYear) then Date.Month([Date]) - GetStartMonthNumberFiscalYear +1 else Date.Month([Date])+13-GetStartMonthNumberFiscalYear, Int64.Type),
    AddFiscalMonthLong = Table.AddColumn(#"AddFiscalMonthNumber", "Fiscal Month (long)", each Date.MonthName([Date]), type text),
    AddFiscalMonthShort = Table.AddColumn(AddFiscalMonthLong, "Fiscal Month (short)", each Date.ToText([Date], "MMM", Culture), type text),
    AddFiscalMonthLetter = Table.AddColumn(AddFiscalMonthShort, "Fiscal Month (letter)", each Text.Start(Date.MonthName([Date], Culture),1) /* & Text.Repeat(Character.FromNumber(8203), [#"Month #"]) */, type text),
    AddFiscalQuarterNumber = Table.TransformColumnTypes(Table.AddColumn(AddFiscalMonthLetter , "Fiscal Quarter #", each Number.RoundUp([#"Fiscal Month #"]/3 ,0)), {{"Fiscal Quarter #", Int64.Type}}),
    AddFiscalQuarterLabel = Table.AddColumn(AddFiscalQuarterNumber, "Fiscal Quarter", each "FQ " & Number.ToText([#"Fiscal Quarter #"]), type text),
    AddFiscalYearFiscalQuarter = Table.AddColumn(AddFiscalQuarterLabel, "Fiscal Quarter & Fiscal Year", each [Fiscal Quarter]&"-FY "&Number.ToText([#"Fiscal Year #"]), type text),
    AddFiscalYearQuarterName = Table.AddColumn(AddFiscalYearFiscalQuarter, "Fiscal Year & Fiscal Quarter", each "FY "&Text.From([#"Fiscal Year #"]) &"-FQ " & Text.From([#"Fiscal Quarter #"]), type text),
    AddFiscalYearQuarterNumber = Table.AddColumn(AddFiscalYearQuarterName, "Fiscal Year & Quarter #", each [#"Fiscal Year #"]* 100 + [#"Fiscal Quarter #"], Int64.Type),
    TableFiscalYearQuarter = Table.TransformColumnTypes(Table.AddIndexColumn(Table.TransformColumnTypes(Table.RenameColumns(Table.FromList(List.Sort(List.Distinct(AddFiscalYearQuarterNumber[#"Fiscal Year & Quarter #"]),Order.Ascending), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "Fiscal Year & Quarter #"}}),{{"Fiscal Year & Quarter #", Int64.Type}}), "Fiscal Quarter Surrogate Key #", 1, 1), {{"Fiscal Quarter Surrogate Key #", Int64.Type}}),
    GetFiscalYearQuarterKey = Table.NestedJoin(AddFiscalYearQuarterNumber,{"Fiscal Year & Quarter #"},TableFiscalYearQuarter,{"Fiscal Year & Quarter #"},"FYQ",JoinKind.LeftOuter),
    ExpandFYQ = Table.ExpandTableColumn(GetFiscalYearQuarterKey, "FYQ", {"Fiscal Quarter Surrogate Key #"}, {"Fiscal Quarter Surrogate Key #"}),
    RemoveFiscalYearQuarterNumber = Table.RemoveColumns(ExpandFYQ,{"Fiscal Year & Quarter #"}),
    AddFiscalHalfYear = Table.TransformColumnTypes(Table.AddColumn(RemoveFiscalYearQuarterNumber, "Fiscal Halfyear #", each if [#"Fiscal Month #"]<7 then 1 else 2), {{"Fiscal Halfyear #", Int64.Type}}),
    AddFiscalHalfYearName = Table.AddColumn(AddFiscalHalfYear, "Fiscal Halfyear", each "FHY " & Number.ToText([#"Fiscal Halfyear #"]), type text),
    AddFiscalYearHalfYearName = Table.AddColumn(AddFiscalHalfYearName, "Fiscal Year & Fiscal Halfyear", each "FY " & Text.From([#"Fiscal Year #"]) & "-FHY " & Text.From([#"Fiscal Halfyear #"]), type text),
    AddFiscalHalfyearFiscalYearName = Table.AddColumn(AddFiscalYearHalfYearName, "Fiscal Halfyear & Fiscal Year", each "FHY " & Text.From([#"Fiscal Halfyear #"])&"-FY " &Text.From([#"Fiscal Year #"]), type text),
    AddFiscalYearHalfYear = Table.AddColumn(AddFiscalHalfyearFiscalYearName, "Fiscal Year & Halfyear #", each [#"Fiscal Year #"] * 100 + [#"Fiscal Halfyear #"], Int64.Type),
    TableFiscalYearHalfYear = Table.TransformColumnTypes(Table.AddIndexColumn(Table.TransformColumnTypes(Table.RenameColumns(Table.FromList(List.Sort(List.Distinct(AddFiscalYearHalfYear[#"Fiscal Year & Halfyear #"]),Order.Ascending), Splitter.SplitByNothing(), null, null, ExtraValues.Error),{{"Column1", "Fiscal Year & Halfyear #"}}),{{"Fiscal Year & Halfyear #", Int64.Type}}), "Fiscal Halfyear Surrogate Key #", 1, 1), {{"Fiscal Halfyear Surrogate Key #", Int64.Type}}),
    GetFiscalYearHalfYearKey = Table.NestedJoin(AddFiscalYearHalfYear,{"Fiscal Year & Halfyear #"},TableFiscalYearHalfYear,{"Fiscal Year & Halfyear #"},"FYHY",JoinKind.LeftOuter),
    ExpandFYHY = Table.ExpandTableColumn(GetFiscalYearHalfYearKey, "FYHY", {"Fiscal Halfyear Surrogate Key #"}, {"Fiscal Halfyear Surrogate Key #"}),
    AddFiscalYearKey = Table.AddColumn(ExpandFYHY, "Fiscal Year Surrogate Key #", each [#"Fiscal Year #"] - List.Min(ExpandFYHY[#"Fiscal Year #"]) + 1, Int64.Type),
    RemoveFiscalYearHalfyearNumber = Table.RemoveColumns(AddFiscalYearKey,{"Fiscal Year & Halfyear #"}),


fnKeysTodayRecordFiscal =
      let
      GetTodayRow = Table.SelectRows(RemoveFiscalYearHalfyearNumber, each _[Date] = Today),
      Output = 
        [
          FiscalQuarterKeyToday = GetTodayRow[#"Fiscal Quarter Surrogate Key #"]{0},
          FiscalHalfyearKeyToday = GetTodayRow[#"Fiscal Halfyear Surrogate Key #"]{0},
          FiscalYearKeyToday = GetTodayRow[#"Fiscal Year Surrogate Key #"]{0}
        ]
      in
      Output,

    //Fiscal Periods Offset
    AddFiscalQuarterOffset = Table.AddColumn(RemoveFiscalYearHalfyearNumber, "Fiscal Quarter Offset #", each [#"Fiscal Quarter Surrogate Key #"] - fnKeysTodayRecordFiscal[FiscalQuarterKeyToday], Int64.Type),
    AddFiscalHalfyearOffset = Table.AddColumn(AddFiscalQuarterOffset, "Fiscal Halfyear Offset #", each [#"Fiscal Halfyear Surrogate Key #"] - fnKeysTodayRecordFiscal[FiscalHalfyearKeyToday], Int64.Type),
    AddFiscalYearOffset = Table.AddColumn(AddFiscalHalfyearOffset, "Fiscal Year Offset #", each [#"Fiscal Year Surrogate Key #"] - fnKeysTodayRecordFiscal[FiscalYearKeyToday], Int64.Type),

    //Days 2 Go-Calculation ("2 Go" are days in the current period and in the future, i.e., days to go until the current period ends.)
    ListGetFiscalQuarter2Go = List.Buffer( Table.SelectRows(AddFiscalYearOffset, each [#"Fiscal Quarter Offset #"] = 0 and [Date] > Today)[Date] ),
    ListGetFiscalHalfYear2Go = List.Buffer( Table.SelectRows(AddFiscalYearOffset, each [#"Fiscal Halfyear Offset #"] = 0 and [Date] > Today)[Date] ),
    ListGetFiscalYear2Go = List.Buffer( Table.SelectRows(AddFiscalYearOffset, each [#"Fiscal Year Offset #"] = 0 and [Date] > Today)[Date] ),

    AddFiscalQuarter2Go = Table.AddColumn( AddFiscalYearOffset, "Fiscal Quarter Days 2 Go", each Number.From( List.Contains(ListGetFiscalQuarter2Go, [Date]) ), Int64.Type),
    AddFiscalHalfyear2Go = Table.AddColumn( AddFiscalQuarter2Go, "Fiscal Halfyear Days 2 Go", each Number.From( List.Contains(ListGetFiscalHalfYear2Go, [Date]) ), Int64.Type),
    AddFiscalYear2Go = Table.AddColumn( AddFiscalHalfyear2Go, "Fiscal Year Days 2 Go", each Number.From( List.Contains(ListGetFiscalYear2Go, [Date]) ), Int64.Type),

    AddFYTD = Table.AddColumn(AddFiscalYear2Go, "FYTD", each 
        if ((GetStartMonthNumberFiscalYear - 1) = Number.Mod(Date.Month(Today), 12)) and (Date.Day(Today) = Date.EndOfMonth(Today))
        then 1 
        else 
            if Date.Month(Today) >= GetStartMonthNumberFiscalYear
            then
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) < GetStartMonthNumberFiscalYear * 100
                then null
                else 
                    if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey or (TodayMonthDayKey = 228 and TodayIsLeapYear = 0 and Number.Mod ( [#"Date Natural Key #"], 10000 ) = 229)
                    then 1 
                    else null
            else
                if Number.Mod ( [#"Date Natural Key #"], 10000 ) >= GetStartMonthNumberFiscalYear * 100
                then 1
                else
                    if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey or (TodayMonthDayKey = 228 and TodayIsLeapYear = 0 and Number.Mod ( [#"Date Natural Key #"], 10000 ) = 229)
                    then 1 
                    else null, 
        Int64.Type),
    AddFHYTD = Table.AddColumn(AddFYTD, "FHYTD", each 
        if (Date.Month(Today) = Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12) + 1 and Today = Date.EndOfMonth(Today)) 
            or (Date.Month(Today) = Number.Mod(12 + GetStartMonthNumberFiscalYear - 1, 12) + 1 and Today = Date.EndOfMonth(Today)) 
        then 1 
        else
            if Date.Month(Today) >= GetStartMonthNumberFiscalYear
            then
                if Date.Month(Today) <= Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12)
                then
                    if [#"Month #"] <= Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12)
                    then 
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                        then 1
                        else null
                    else
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                        then 1
                        else null
                else
                    if [#"Month #"] > Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12)
                    then 
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                        then 1
                        else null
                    else
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                        then 1
                        else null
            else
                if [#"Month #"] >= GetStartMonthNumberFiscalYear
                then 1
                else
                    if Date.Month(Today) <= Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12)
                    then
                        if [#"Month #"] <= Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12)
                        then 
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                            then 1
                            else null
                        else
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                            then 1
                            else null
                    else
                        if [#"Month #"] > Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12)
                        then 
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKey
                            then 1
                            else null
                        else
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= TodayMonthDayKeyOtherHalfyear
                            then 1
                            else null,
        Int64.Type),
    AddFQTD = Table.AddColumn(AddFHYTD, "FQTD", each 
        if (Date.Month(Today) = Number.Mod(3 + GetStartMonthNumberFiscalYear - 1, 12) + 1 and Today = Date.EndOfMonth(Today))      // if today is end of quarter, fill all dates with QTD = 1
            or (Date.Month(Today) = Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12) + 1 and Today = Date.EndOfMonth(Today)) 
            or (Date.Month(Today) = Number.Mod(9 + GetStartMonthNumberFiscalYear - 1, 12) + 1 and Today = Date.EndOfMonth(Today)) 
            or (Date.Month(Today) = Number.Mod(12 + GetStartMonthNumberFiscalYear - 1, 12) + 1 and Today = Date.EndOfMonth(Today))
        then 1
        else
            if ([#"Month #"] = 12 and Date.Month(Today) < 12 and List.Contains({2,3,5,6,8,9,11,12}, GetStartMonthNumberFiscalYear))                      // If today is Jan or Feb and a fraction of the quarter is in the previous calendar year,
                    or ([#"Month #"] = 11 and Date.Month(Today) < 11 and List.Contains({2,5,8,11}, GetStartMonthNumberFiscalYear) and [#"Month #"] = 11) // then fill previous year fraction with QTD = 1
            then 1
            else
                if ([#"Month #"] > Number.Mod(12 + GetStartMonthNumberFiscalYear - 2, 12) + 1) and ([#"Month #"] <= Number.Mod(3 + GetStartMonthNumberFiscalYear - 2, 12) + 1) // Current ROW is in the first FQ of the FY
                then 
                    if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= List.Select({TodayMonthDayKey, TodayMonthDayKeyNextQuarter, TodayMonthDayKeyOtherHalfyear, TodayMonthDayKeyPreviousQuarter}, each _ > Number.Mod(0 + GetStartMonthNumberFiscalYear - 1, 12) * 100 + 31 and _ <=  (Number.Mod(3 + GetStartMonthNumberFiscalYear - 2, 12) + 1) * 100 + 31){0}
                    then 1
                    else null
                else
                    if ([#"Month #"] > Number.Mod(3 + GetStartMonthNumberFiscalYear - 2, 12) + 1) and ([#"Month #"] <= Number.Mod(6 + GetStartMonthNumberFiscalYear - 2, 12) + 1) // Current ROW is in the second FQ of the FY
                    then 
                        if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= List.Select({TodayMonthDayKey, TodayMonthDayKeyNextQuarter, TodayMonthDayKeyOtherHalfyear, TodayMonthDayKeyPreviousQuarter}, each _ > Number.Mod(3 + GetStartMonthNumberFiscalYear - 1, 12) * 100 + 31 and _ <=  (Number.Mod(6 + GetStartMonthNumberFiscalYear - 2, 12) + 1) * 100 + 31){0}
                        then 1
                        else null
                    else 
                        if ([#"Month #"] > Number.Mod(6 + GetStartMonthNumberFiscalYear - 2, 12) + 1) and ([#"Month #"] <= Number.Mod(9 + GetStartMonthNumberFiscalYear - 2, 12) + 1) // Current ROW is in the third FQ of the FY
                        then
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= List.Select({TodayMonthDayKey, TodayMonthDayKeyNextQuarter, TodayMonthDayKeyOtherHalfyear, TodayMonthDayKeyPreviousQuarter}, each _ > Number.Mod(6 + GetStartMonthNumberFiscalYear - 1, 12) * 100 + 31 and _ <=  (Number.Mod(9 + GetStartMonthNumberFiscalYear - 2, 12) + 1) * 100 + 31){0}
                            then 1
                            else null
                        else // Current ROW is in the fourth FQ of the FY
                            if Number.Mod ( [#"Date Natural Key #"], 10000 ) <= List.Select({TodayMonthDayKey, TodayMonthDayKeyNextQuarter, TodayMonthDayKeyOtherHalfyear, TodayMonthDayKeyPreviousQuarter}, each _ > Number.Mod(9 + GetStartMonthNumberFiscalYear - 1, 12) * 100 + 31 and _ <=  (Number.Mod(12 + GetStartMonthNumberFiscalYear - 2, 12) + 1) * 100 + 31){0}
                            then 1
                            else null,
        Int64.Type),

    //============================================================================== Fiscal Year Calculations End =================================================================

    Output = if MonthStartFiscalYear = "Jan" then AddMTD else AddFQTD
in
    Output

  ,
    fnType = type function(
              CalendarYearStart as number,
              NumberYearsFuture as number, 
              optional Culture as (type text meta [Documentation.AllowedValues={"da", "de-de", "el", "en-US", "es-ES", "fi", "fr-FR", "it-it", "nl", "nn", "pt-PT", "sv"}]), 
              optional MonthStartFiscalYear as (type text meta[Documentation.AllowedValues={"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}]),
              optional WeekStartDay as (type text meta[Documentation.AllowedValues={"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}])
               ) as table meta [
                                Documentation.Name="fnDateTable (by Lars Schreiber --> ssbi-blog.de; translated by Martin Bubenheimer)",
                                Documentation.LongDescription="This function creates a date table, based on the proposals of the Kimball-Group.",
                                Documentation.Author="Lars Schreiber, ssbi-blog.de",
                                Documentation.Examples=
                                    {[
                                        Description = "This example returns a date table, that stats in January 2019 (fix) and extends one year into the future (dynamic) based on the current date (refresh date).",
                                        Code = "fnDateTable(2019, 1, null, null, null)",
                                        Result =""
                                        
                                    ],[
                                        Description = "This example returns a date table, that starts April 2019 (fix) and extends one year into the future (dynamic) based on the current date (refresh date). Columns for fiscal year calculations are added. Each fiscal year start April 1st and ends March 31st of the next calendar year.",
                                        Code = "fnDateTable(2019, 1, null, ""Apr"", null)",
                                        Result =""
                                        
                                    ]} 
                                ]
in
Value.ReplaceType(fnCreateDateTable, fnType)
in
    Source
