(DateColumn1 as list, optional DateColumn2 as list, optional Prefix as text) =>
let
    // Handle null parameters
    SafeDateColumn1 = if DateColumn1 = null then {} else DateColumn1,
    SafeDateColumn2 = if DateColumn2 = null then {} else DateColumn2,
    SafePrefix = if Prefix = null then "" else Prefix,
    
    // Combine the two date lists (keeping duplicates)
    Source = SafeDateColumn1 & SafeDateColumn2,
    
    // Define the earliest date based on the combined list
    EarliestDate = List.Min(Source),
    
    // Define the latest date based on the combined list
    LatestDate = List.Max(Source),

    // Create a range of dates between the minimum and maximum in the combined list
    Custom1 = { Number.From(EarliestDate)..Number.From(LatestDate) },
    
    // Convert the list to a table
    #"Converted to Table" = Table.FromList(Custom1, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    
    // Rename the column to "Date"
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table", {{"Column1", "Date"}}),
    
    // Change type to Date
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns", {{"Date", type date}}),
    
    // Insert Year, Month, Quarter, Week, and other derived columns
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
    
    // Add additional derived columns for sorting and formatting
    #"Added SortYearMonth" = Table.AddColumn(#"Added Weekend Flag", "SortYearMonth", each Date.Year([Date]) * 100 + Date.Month([Date]), Int64.Type),
    #"Inserted Year Month" = Table.AddColumn(#"Added SortYearMonth", "Year Month", each Text.Combine({Text.From([Year], "en-US"), [Month Name]}, " "), type text),
    #"Added SortYearWeek" = Table.AddColumn(#"Inserted Year Month", "SortYearWeek", each Date.Year([Date]) * 100 + Date.WeekOfYear([Date]), Int64.Type),
    #"Inserted Year Week" = Table.AddColumn(#"Added SortYearWeek", "Year Week", each Text.Combine({Text.From([Year], "en-US"), Text.PadStart(Text.From([Week of Year], "en-US"), 2, "0")}, " "), type text),
    #"Added SortYearQuarter" = Table.AddColumn(#"Inserted Year Week", "SortYearQuarter", each Date.Year([Date]) * 10 + Date.QuarterOfYear([Date]), Int64.Type),
    #"Inserted Year Quarter" = Table.AddColumn(#"Added SortYearQuarter", "Year Quarter", each Text.Combine({Text.From([Year], "en-US"), "Q" & Text.From([Quarter], "en-US")}, " "), type text),
    
    // Add special formatting columns for Month Name and Week Day
    #"Added Month Name S" = Table.AddColumn(#"Inserted Year Quarter", "Month Name S", each Text.Repeat(Character.FromNumber(8203), 12 - Date.Month([Date])) & Text.Start(Date.MonthName([Date]), 1), type text),
    #"Added Week Day S" = Table.AddColumn(#"Added Month Name S", "Week Day S", each Text.Repeat(Character.FromNumber(8203), 7 - Date.DayOfWeek([Date])) & Text.Start(Date.DayOfWeekName([Date]), 1), type text),

    // Define the latest date components based on the latest date in the combined list
    LatestYear = Date.Year(LatestDate),
    LatestWeek = Date.WeekOfYear(LatestDate),
    LatestMonth = Date.Month(LatestDate),
    LatestQuarter = Date.QuarterOfYear(LatestDate),
    
    // Add flag columns for latest date, year-week, year-month, and year-quarter
    #"Added Latest Date Flag" = Table.AddColumn(#"Added Week Day S", "Is Latest Date", each [Date] = LatestDate, Logical.Type),
    #"Added Latest Year Week Flag" = Table.AddColumn(#"Added Latest Date Flag", "Is Latest Year Week", each [Year] = LatestYear and [Week of Year] = LatestWeek, Logical.Type),
    #"Added Latest Year Month Flag" = Table.AddColumn(#"Added Latest Year Week Flag", "Is Latest Year Month", each [Year] = LatestYear and [Month] = LatestMonth, Logical.Type),
    #"Added Latest Year Quarter Flag" = Table.AddColumn(#"Added Latest Year Month Flag", "Is Latest Year Quarter", each [Year] = LatestYear and [Quarter] = LatestQuarter, Logical.Type),
    
    // Add the prefix to all column names in a final step
    ColumnsToRename = Table.ColumnNames(#"Added Latest Year Quarter Flag"),
    RenamedColumns = if SafePrefix = "" then #"Added Latest Year Quarter Flag" else 
                      Table.RenameColumns(#"Added Latest Year Quarter Flag", List.Transform(ColumnsToRename, each {_, SafePrefix & _}))
    
in
    RenamedColumns
