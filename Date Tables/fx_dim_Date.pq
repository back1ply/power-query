(DateColumn as list, Prefix as text) =>
let
    // Get distinct list of dates
    Source = List.Distinct(DateColumn),
    
    // Define the earliest date
    EarliestDate = List.Min(Source),
    
    // Define the latest date
    LatestDate = List.Max(Source),

    // Create a range of dates between the minimum and maximum in the list
    Custom1 = { Number.From(EarliestDate)..Number.From(LatestDate)},
    
    // Convert list to table
    #"Converted to Table" = Table.FromList(Custom1, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    
    // Rename the column to "Date"
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table", {{"Column1", "Date"}}),
    
    // Change type to Date
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns", {{"Date", type date}}),
    
    // Insert Year, Month, Quarter, Week, and other columns
    #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), Int64.Type),
    #"Inserted Month" = Table.AddColumn(#"Inserted Year", "Month", each Date.Month([Date]), Int64.Type),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month", "Month Name", each Date.MonthName([Date]), type text),
    #"Extracted First Characters Month Name" = Table.TransformColumns(#"Inserted Month Name", {{"Month Name", each Text.Start(_, 3), type text}}),
    #"Inserted Quarter" = Table.AddColumn(#"Extracted First Characters Month Name", "Quarter", each Date.QuarterOfYear([Date]), Int64.Type),
    #"Inserted Week of Year" = Table.AddColumn(#"Inserted Quarter", "Week of Year", each Date.WeekOfYear([Date]), Int64.Type),
    #"Inserted Day of Week" = Table.AddColumn(#"Inserted Week of Year", "Day of Week", each Date.DayOfWeek([Date]), Int64.Type),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted Day of Week", "Day Name", each Date.DayOfWeekName([Date]), type text),
    #"Extracted First Characters Day Name" = Table.TransformColumns(#"Inserted Day Name", {{"Day Name", each Text.Start(_, 3), type text}}),
    
    // Add Weekend Flag column
    #"Added Weekend Flag" = Table.AddColumn(#"Extracted First Characters Day Name", "Is Weekend", each [Day Name] = "Sat" or [Day Name] = "Sun", type logical),
    
    // Add SortYearMonth, Year Month, SortYearWeek, Year Week, SortYearQuarter, Year Quarter
    #"Added SortYearMonth" = Table.AddColumn(#"Added Weekend Flag", "SortYearMonth", each Date.Year([Date]) * 100 + Date.Month([Date]), Int64.Type),
    #"Inserted Year Month" = Table.AddColumn(#"Added SortYearMonth", "Year Month", each Text.Combine({Text.From([Year], "en-US"), [Month Name]}, " "), type text),
    #"Added SortYearWeek" = Table.AddColumn(#"Inserted Year Month", "SortYearWeek", each Date.Year([Date]) * 100 + Date.WeekOfYear([Date]), Int64.Type),
    #"Inserted Year Week" = Table.AddColumn(#"Added SortYearWeek", "Year Week", each Text.Combine({Text.From([Year], "en-US"), Text.PadStart(Text.From([Week of Year], "en-US"), 2, "0")}, " "), type text),
    #"Added SortYearQuarter" = Table.AddColumn(#"Inserted Year Week", "SortYearQuarter", each Date.Year([Date]) * 10 + Date.QuarterOfYear([Date]), Int64.Type),
    #"Inserted Year Quarter" = Table.AddColumn(#"Added SortYearQuarter", "Year Quarter", each Text.Combine({Text.From([Year], "en-US"), "Q" & Text.From([Quarter], "en-US")}, " "), type text),
    
    // Added Month Name S (Special formatting for Month name)
    #"Added Month Name S" = Table.AddColumn(#"Inserted Year Quarter", "Month Name S", each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Date])) & Text.Start(Date.MonthName([Date]), 1), type text),
    #"Added Week Day S" = Table.AddColumn(#"Added Month Name S", "Week Day S", each Text.Repeat(Character.FromNumber(8203), 7 - Date.DayOfWeek([Date])) & Text.Start(Date.DayOfWeekName([Date]), 1), type text),


    // Define the latest year, week, month, quarter based on the latest date
    LatestYear = Date.Year(LatestDate),
    LatestWeek = Date.WeekOfYear(LatestDate),
    LatestMonth = Date.Month(LatestDate),
    LatestQuarter = Date.QuarterOfYear(LatestDate),
    
    // Calculate start dates for the last 3, 6, 9, 12 months
    Start3Months = Date.AddMonths(LatestDate, -3),
    Start6Months = Date.AddMonths(LatestDate, -6),
    Start9Months = Date.AddMonths(LatestDate, -9),
    Start12Months = Date.AddMonths(LatestDate, -12),
    
    // Add flag columns for latest date, year-week, year-month, and year-quarter
    #"Added Latest Date Flag" = Table.AddColumn(#"Added Week Day S", "Is Latest Date", each if [Date] = LatestDate then true else false, Logical.Type),
    #"Added Latest Year Week Flag" = Table.AddColumn(#"Added Latest Date Flag", "Is Latest Year Week", each if [Year] = LatestYear and [Week of Year] = LatestWeek then true else false, Logical.Type),
    #"Added Latest Year Month Flag" = Table.AddColumn(#"Added Latest Year Week Flag", "Is Latest Year Month", each if [Year] = LatestYear and [Month] = LatestMonth then true else false, Logical.Type),
    #"Added Latest Year Quarter Flag" = Table.AddColumn(#"Added Latest Year Month Flag", "Is Latest Year Quarter", each if [Year] = LatestYear and [Quarter] = LatestQuarter then true else false, Logical.Type),
    
    // Add flags for last 3, 6, 9, 12 months
    #"Added Last 3 Months Flag" = Table.AddColumn(#"Added Latest Year Quarter Flag", "Last 3 Months", each [Date] >= Start3Months and [Date] <= LatestDate, type logical),
    #"Added Last 6 Months Flag" = Table.AddColumn(#"Added Last 3 Months Flag", "Last 6 Months", each [Date] >= Start6Months and [Date] <= LatestDate, type logical),
    #"Added Last 9 Months Flag" = Table.AddColumn(#"Added Last 6 Months Flag", "Last 9 Months", each [Date] >= Start9Months and [Date] <= LatestDate, type logical),
    #"Added Last 12 Months Flag" = Table.AddColumn(#"Added Last 9 Months Flag", "Last 12 Months", each [Date] >= Start12Months and [Date] <= LatestDate, type logical),
    
    // Add the prefix to all columns in a final step
    ColumnsToRename = Table.ColumnNames(#"Added Last 12 Months Flag"),
    RenamedColumns = Table.RenameColumns(#"Added Last 12 Months Flag", List.Transform(ColumnsToRename, each {_, Prefix & _}))
    
in
    RenamedColumns
