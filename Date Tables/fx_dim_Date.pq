// fx_Dim_Date
(DateColumn1 as list, optional DateColumn2 as list, optional Prefix as text) =>
let
    // Handle null parameters
    SafeDateColumn1 = if DateColumn1 = null then {} else DateColumn1,
    SafeDateColumn2 = if DateColumn2 = null then {} else DateColumn2,
    SafePrefix = if Prefix = null then "" else Prefix,
    
    // Combine the two date lists (keeping duplicates)
    Source = SafeDateColumn1 & SafeDateColumn2,
    
    // Define the earliest date as the first day of the year of the minimum date
    MinDate = List.Min(Source),
    EarliestDate = #date(Date.Year(MinDate), 1, 1),
    
    // Define the latest date as the last day of the year of the maximum date
    MaxDate = List.Max(Source),
    LatestDate = #date(Date.Year(MaxDate), 12, 31),
    
    // Create a range of dates between the earliest and latest dates (more efficient than number conversion)
    DaysCount = Duration.Days(LatestDate - EarliestDate) + 1,
    DateList = List.Dates(EarliestDate, DaysCount, #duration(1, 0, 0, 0)),
    
    // Convert the list to a table with named column (more concise)
    #"Converted to Table" = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    
    // Change type to Date
    #"Changed Type" = Table.TransformColumnTypes(#"Converted to Table", {{"Date", type date}}),
    
    // Insert Year, Month, Quarter, Week, and other derived columns
    #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([Date]), Int64.Type),
    #"Inserted Month" = Table.AddColumn(#"Inserted Year", "Month", each Date.Month([Date]), Int64.Type),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month", "Month Name", each Text.Start(Date.MonthName([Date]), 3), type text),
    #"Inserted Quarter" = Table.AddColumn(#"Inserted Month Name", "Quarter", each Date.QuarterOfYear([Date]), Int64.Type),
    
    // Add new column "Q" + quarter number
    #"Inserted Q Format" = Table.AddColumn(#"Inserted Quarter", "Q Format", each "Q" & Text.From([Quarter]), type text),
    
    #"Inserted Week of Year" = Table.AddColumn(#"Inserted Q Format", "Week of Year", each Date.WeekOfYear([Date]), Int64.Type),
    
    // Add new column "W" + week of year number (padded to 2 digits)
    #"Inserted W Format" = Table.AddColumn(#"Inserted Week of Year", "W Format", each "W" & Text.PadStart(Text.From([Week of Year]), 2, "0"), type text),
    
    #"Inserted Day of Week" = Table.AddColumn(#"Inserted W Format", "Day of Week", each Date.DayOfWeek([Date]), Int64.Type),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted Day of Week", "Day Name", each Text.Start(Date.DayOfWeekName([Date]), 3), type text),
    
    // Add Weekend Flag column (simplified logic)
    #"Added Weekend Flag" = Table.AddColumn(#"Inserted Day Name", "Is Weekend", each [Day of Week] >= 5, type logical),
    
    // Add explicit sort columns and formatted display columns
    // Year-Month sorting and display
    #"Added SortYearMonth" = Table.AddColumn(#"Added Weekend Flag", "SortYearMonth", each [Year] * 100 + [Month], Int64.Type),
    #"Added Year Month" = Table.AddColumn(#"Added SortYearMonth", "Year Month", each Text.From([Year]) & " " & [Month Name], type text),
    
    // Year-Week sorting and display
    #"Added SortYearWeek" = Table.AddColumn(#"Added Year Month", "SortYearWeek", each [Year] * 100 + [Week of Year], Int64.Type),
    #"Added Year Week" = Table.AddColumn(#"Added SortYearWeek", "Year Week", each Text.From([Year]) & " W" & Text.PadStart(Text.From([Week of Year]), 2, "0"), type text),
    
    // Year-Quarter sorting and display
    #"Added SortYearQuarter" = Table.AddColumn(#"Added Year Week", "SortYearQuarter", each [Year] * 10 + [Quarter], Int64.Type),
    #"Added Year Quarter" = Table.AddColumn(#"Added SortYearQuarter", "Year Quarter", each Text.From([Year]) & " Q" & Text.From([Quarter]), type text),
    
    // Add special formatting columns for Month Name and Week Day
    #"Added Month Name S" = Table.AddColumn(#"Added Year Quarter", "Month Name S", each Text.Repeat(Character.FromNumber(8203), 12 - [Month]) & Text.Start(Date.MonthName([Date]), 1), type text),
    #"Added Week Day S" = Table.AddColumn(#"Added Month Name S", "Week Day S", each Text.Repeat(Character.FromNumber(8203), 7 - [Day of Week]) & Text.Start(Date.DayOfWeekName([Date]), 1), type text),

    // Define the latest date components based on the latest date
    LatestYear = Date.Year(MaxDate),
    LatestWeek = Date.WeekOfYear(MaxDate),
    LatestMonth = Date.Month(MaxDate),
    LatestQuarter = Date.QuarterOfYear(MaxDate),
    
    // Add flag columns for latest date, year-week, year-month, and year-quarter
    #"Added Latest Date Flag" = Table.AddColumn(#"Added Week Day S", "Is Latest Date", each [Date] = MaxDate, Logical.Type),
    #"Added Latest Year Week Flag" = Table.AddColumn(#"Added Latest Date Flag", "Is Latest Year Week", each [Year] = LatestYear and [Week of Year] = LatestWeek, Logical.Type),
    #"Added Latest Year Month Flag" = Table.AddColumn(#"Added Latest Year Week Flag", "Is Latest Year Month", each [Year] = LatestYear and [Month] = LatestMonth, Logical.Type),
    #"Added Latest Year Quarter Flag" = Table.AddColumn(#"Added Latest Year Month Flag", "Is Latest Year Quarter", each [Year] = LatestYear and [Quarter] = LatestQuarter, Logical.Type),
    
    // Keep the sort columns as they're more explicit and reliable
    #"Final Columns" = #"Added Latest Year Quarter Flag",
    
    // Add the prefix to all column names in a final step
    FinalTable = if SafePrefix = "" then #"Final Columns" else 
                  Table.PrefixColumns(#"Final Columns", SafePrefix)
in
    FinalTable
