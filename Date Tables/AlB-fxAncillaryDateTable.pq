
let
    currentDate_ = Date.From(DateTime.LocalNow()),
    currentDateLY_ = Date.AddYears(currentDate_, -1),
    currentYear_ = Date.Year(currentDate_),
    lastYear_ = currentYear_ - 1,
    startCY_ = Date.StartOfYear(currentDate_),
    endCY_ = Date.EndOfYear(currentDate_),
    startLY_ = Date.AddYears(startCY_,-1),
    endLY_ = Date.AddYears(endCY_,-1),
    startCMCY_ = Date.StartOfMonth(currentDate_),
    startCMLY_ = Date.AddYears(startCMCY_,-1),   
    startCWCY_ = Date.StartOfWeek(currentDate_,Day.Monday), 
    startCWLY_ = Date.AddYears(startCWCY_,-1),  
    startLast24H_ = Date.AddDays(currentDate_, -1),
    endLast24H_ = currentDate_,
    startLast24HLY_ = Date.AddYears(startLast24H_, -1),
    endLast24HLY_ = Date.AddYears(endLast24H_, -1),
    startLast48H_ = Date.AddDays(currentDate_, -2),
    endLast48H_ = currentDate_,
    startLast48HLY_ = Date.AddYears(startLast48H_, -1),
    endLast48HLY_ = Date.AddYears(endLast48H_, -1),  
    startLast72H_ = Date.AddDays(currentDate_, -3),
    endLast72H_ = currentDate_,
    startLast72HLY_ = Date.AddYears(startLast72H_, -1),
    endLast72HLY_ = Date.AddYears(endLast72H_, -1),  
    startLastWeek_ = Date.AddDays(currentDate_, -7), 
    endLastWeek_ = currentDate_,
    startLastWeekLY_ = Date.AddYears(startLastWeek_, -1),
    endLastWeekLY_ = Date.AddYears(endLastWeek_, -1),
    //*******************
    startLast4Weeks_ = Date.AddDays(currentDate_, -7-21), 
    endLast4Weeks_ = currentDate_,
    startLast4WeeksLY_ = Date.AddYears(startLast4Weeks_, -1),
    endLast4WeeksLY_ = Date.AddYears(endLast4Weeks_, -1),    
    //*******************
    startLastMonth_ = Date.AddMonths(currentDate_, -1), 
    endLastMonth_ = currentDate_,
    startLastMonthLY_ = Date.AddYears(startLastMonth_, -1),
    endLastMonthLY_ = Date.AddYears(endLastMonth_, -1),
    startLast3Months_ = Date.AddMonths(currentDate_, -3), 
    endLast3Months_ = currentDate_,
    startLast3MonthsLY_ = Date.AddYears(startLast3Months_, -1),
    endLast3MonthsLY_ = Date.AddYears(endLast3Months_, -1),    
    startLast12Months_ = Date.AddDays(Date.AddMonths(currentDate_, -12), 1),   
    endLast12Months_ = currentDate_,
    startLast12MonthsLY_ = Date.AddYears(startLast12Months_, -1),
    endLast12MonthsLY_ = Date.AddYears(endLast12Months_, -1),    
    //*******************
    base_CHANGED = Table.TransformColumnTypes(Table.FromColumns({{Number.From(#date(2020,1,1))..Number.From(currentDate_)}},{"Date"}), {{"Date", type date}}),
    #"Add Period" = Table.AddColumn(base_CHANGED, "Period", each 
    let 
      listCY_ =
        {    
        if ([Date] <= currentDate_ and [Date] >= startCY_) then "YTD" else null,  
        if ([Date] <= currentDate_ and [Date] >= startCMCY_) then "MTD" else null,
          if ([Date] <= currentDate_ and [Date] >= startCWCY_) then "WTD" else null, 
          if ([Date] <= currentDate_ and [Date] >= startLast24H_) then "Last 24H" else null,  
            if ([Date] <= currentDate_ and [Date] >= startLast48H_) then "Last 48H" else null, 
            if ([Date] <= currentDate_ and [Date] >= startLast72H_) then "Last 72H" else null,
              if ([Date] <= currentDate_ and [Date] >= startLastWeek_) then "Last Week" else null,
              if ([Date] <= currentDate_ and [Date] >= startLastMonth_) then "Last Month" else null, 
                if ([Date] <= currentDate_ and [Date] >= startLast4Weeks_) then "Last 4 Weeks" else null,
                if ([Date] <= currentDate_ and [Date] >= startLast3Months_) then "Last 3 Months" else null,
                  if ([Date] <= currentDate_ and [Date] >= startLast12Months_) then "Last 12 Months" else null,
                  if ([Date] <= endCY_ and [Date] >= startCY_) then "FY" else null        
        }, 
      listLY_ =
        {   
        if ([Date] <= currentDateLY_ and [Date] >= startLY_) then "YTD" else null, 
          if ([Date] <= currentDateLY_ and [Date] >= startCMLY_) then "MTD" else null, 
          if ([Date] <= currentDateLY_ and [Date] >= startCWLY_) then "WTD" else null, 
            if ([Date] <= currentDateLY_ and [Date] >= startLast24HLY_) then "Last 24H" else null, 
            if ([Date] <= currentDateLY_ and [Date] >= startLast48HLY_) then "Last 48H" else null,
              if ([Date] <= currentDateLY_ and [Date] >= startLast72HLY_) then "Last 72H" else null,
              if ([Date] <= currentDateLY_ and [Date] >= startLastWeekLY_) then "Last Week" else null,
                if ([Date] <= currentDateLY_ and [Date] >= startLastMonthLY_) then "Last Month" else null, 
                if ([Date] <= currentDateLY_ and [Date] >= startLast4WeeksLY_) then "Last 4 Weeks" else null, 
                  if ([Date] <= currentDateLY_ and [Date] >= startLast3MonthsLY_) then "Last 3 Months" else null,
                  if ([Date] <= currentDateLY_ and [Date] >= startLast12MonthsLY_) then "Last 12 Months" else null,
                    if ([Date] <= endLY_ and [Date] >= startLY_) then "FY" else null     
        },
      tableCY_ = Table.FromColumns({List.Repeat({"CY"}, List.Count(listCY_)), listCY_ }),
      tableLY_ = Table.FromColumns({List.Repeat({"LY"}, List.Count(listLY_)), listLY_ })  
    in 
      Table.Combine({tableCY_, tableLY_})   
    ),
    #"Expanded Period" = Table.ExpandTableColumn(#"Add Period", "Period", {"Column1", "Column2"}, {"Column1", "Column2"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded Period",{{"Column1", "CY-LY"}, {"Column2", "Period"}}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Renamed Columns",{{"CY-LY", type text}, {"Period", type text}}),

    #"Filtered Rows" = Table.SelectRows(#"Changed Type2", each ([Period] <> null)),
    #"Add PeriodSort" = Table.AddColumn(#"Filtered Rows", "PeriodSort", each 
                     if [Period] = "Last 24H" then 0 else if [Period] = "Last 48H" then 1 else if [Period] = "Last 72H" then 2 else if [Period] = "Last Week" then 3 
                      else if [Period] = "Last 4 Weeks" then 4 else if [Period] = "Last Month" then 5 else if [Period] = "Last 3 Months" then 6 else if [Period] = "Last 12 Months" then 7 
                        else if [Period] = "WTD" then 8 else if [Period] = "MTD" then 9 else if [Period] = "YTD" then 10
                          else if [Period] = "FY" then 11 else null, Int64.Type),

    #"Add Consider WeekEnds" = Table.AddColumn(#"Add PeriodSort", "Consider Weekends", each if Date.DayOfWeek([Date],Day.Monday) < 5 then {"Weekdays"} else {"Weekends"}),
    #"Expanded Consider Weekends" = Table.ExpandListColumn(#"Add Consider WeekEnds", "Consider Weekends"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Expanded Consider Weekends",{{"Consider Weekends", type text}}),
    #"Eliminate unused periods" = Table.SelectRows(#"Changed Type1", each ([Period] = "Last 12 Months" or [Period] = "Last 3 Months" or [Period] = "Last 4 Weeks" or [Period] = "Last Week" or [Period] = "YTD")),
    #"Added Custom" = Table.AddColumn(#"Eliminate unused periods", "Month", each Text.Start(Date.MonthName([Date]),3), type text),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "Month_Year", each Text.Start(Date.MonthName([Date]),3) & "-" & Text.End(Text.From(Date.Year([Date])),2), type text),

    #"Add Month CY_Basis" = Table.AddColumn(#"Added Custom1", "Text_Month_CYBasis", each Text.Start(Date.MonthName([Date]),3) & "-" & Text.End(Text.From(Date.Year([Date]) + (if [#"CY-LY"] = "CY" then 0 else 1)),2), type text),
    #"Add for sorting purposes" = Table.AddColumn(#"Add Month CY_Basis", "Year_Month_CYBasis", each let aux_= if [#"CY-LY"] = "CY" then 0 else 1 in ((Date.Year([Date])+aux_)*100) + Date.Month([Date]), Int64.Type),
   
    #"Inserted Start of Week" = Table.AddColumn(#"Add for sorting purposes", "Start of Week", each Date.StartOfWeek([Date],Day.Monday), type date),  
    AddedJan1 = Table.AddColumn(#"Inserted Start of Week", "Jan1", each #date(Date.Year([Start of Week]),1,1), type date),
    AddedWeek = Table.AddColumn(AddedJan1, "WeekNumber", each 1+Number.IntegerDivide(Number.From([Start of Week] - [Jan1]),7), Int64.Type),
    EndWeekNumbCalculation_ = Table.RemoveColumns(AddedWeek,{"Start of Week", "Jan1"}), 

    #"Add WN_text" = Table.AddColumn(EndWeekNumbCalculation_, "Week_Number_text", each "W" & Text.PadStart(Text.From([WeekNumber]),2, "0"), type text),
    #"Add Year_Week" = Table.AddColumn(#"Add WN_text", "Year_Week", each ((if Date.Month([Date])=1 and [WeekNumber] >= 50 then Date.Year([Date])-1 else Date.Year([Date]))*100) + [WeekNumber], Int64.Type),
    #"Added Custom15" = Table.AddColumn(#"Add Year_Week", "Week_Dates", each  [Week_Number_text] &" " &  Date.ToText(Date.StartOfWeek([Date], Day.Monday), "MM/dd") & "-" & Date.ToText(Date.EndOfWeek([Date], Day.Monday), "MM/dd"), type text),
    #"Renamed Columns1" = Table.RenameColumns(#"Added Custom15",{{"Week_Dates", "Week"}}),

    #"SORTED ROWS" = Table.Buffer( Table.Sort(#"Renamed Columns1",{{"Date", Order.Descending}}) ),
    #"What I'm actually interested In" = Table.Distinct(#"SORTED ROWS", {"Period", "Week_Number_text"}),
    #"Merged Queries" = Table.NestedJoin(#"SORTED ROWS", {"Period", "Week_Number_text"}, #"What I'm actually interested In", {"Period", "Week_Number_text"}, "Merge_result", JoinKind.LeftOuter),
    #"Expanded Merge_result" = Table.ExpandTableColumn(#"Merged Queries", "Merge_result", {"Year_Week", "Week"}, {"Year_Week.1", "Week.1"})
in
    #"Expanded Merge_result"
