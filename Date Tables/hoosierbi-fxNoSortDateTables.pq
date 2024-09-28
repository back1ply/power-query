let
  StartDate = #date(2020, 1, 1),  // or use List.Min and List.Max of a column in another query                                                                                                                                                                                    
  EndDate = #date(2021, 12, 31),
  DateList = List.Dates(StartDate, Number.From(EndDate - StartDate), #duration(1, 0, 0, 0)),
  InitialTable = Table.FromColumns({DateList}, {"Date"}),
  #"Changed Type" = Table.TransformColumnTypes(InitialTable, {{"Date", type date}}),
  #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), Int64.Type),
  #"Inserted Month Name" = Table.AddColumn(#"Inserted Year", "Month", each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Date])) & Text.Start(Date.MonthName([Date]), 3), type text),
  #"Inserted Day Name" = Table.AddColumn(#"Inserted Month Name", "DayName", each Text.Repeat(Character.FromNumber(8203), 6 - Date.DayOfWeek([Date])) & Text.Start(Date.DayOfWeekName([Date]), 3), type text),
  #"Inserted YearMonth" = Table.AddColumn(#"Inserted Day Name", "YearMonth", each Text.From([Year]) & " " & [Month], type text),
  #"Inserted YearQuarter" = Table.AddColumn(#"Inserted YearMonth", "YearQuarter", each Text.From([Year]) & "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
  #"Inserted YearWeek" = Table.AddColumn(#"Inserted YearQuarter", "YearWeek", each Text.From([Year]) & Text.PadStart(Text.From(Date.WeekOfYear([Date])), 2, "0"), type text),
  #"Added WorkingDay" = Table.AddColumn(#"Inserted YearWeek", "WorkingDay", each if List.Contains({0, 6}, Date.DayOfWeek([Date])) then "N" else "Y", type text)
in
    #"Added WorkingDay"
