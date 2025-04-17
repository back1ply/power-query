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
    #"Inserted Num Year" = Table.AddColumn(#"Changed Type", "Num Year", each Date.Year([Date]), Int64.Type),
    #"Inserted Num Month" = Table.AddColumn(#"Inserted Num Year", "Num Month", each Date.Month([Date]), Int64.Type),
    #"Inserted Txt Month Name" = Table.AddColumn(#"Inserted Num Month", "Txt Month Name", each Text.Start(Date.MonthName([Date]), 3), type text),
    #"Inserted Num Quarter" = Table.AddColumn(#"Inserted Txt Month Name", "Num Quarter", each Date.QuarterOfYear([Date]), Int64.Type),
    
    // Add new column "Q" + quarter number
    #"Inserted Txt Quarter Format" = Table.AddColumn(#"Inserted Num Quarter", "Txt Quarter Format", each "Q" & Text.From([Num Quarter]), type text),
    
    #"Inserted Num Week" = Table.AddColumn(#"Inserted Txt Quarter Format", "Num Week", each Date.WeekOfYear([Date]), Int64.Type),
    
    // Add new column "W" + week of year number (padded to 2 digits)
    #"Inserted Txt Week Format" = Table.AddColumn(#"Inserted Num Week", "Txt Week Format", each "W" & Text.PadStart(Text.From([Num Week]), 2, "0"), type text),
    
    #"Inserted Num Day" = Table.AddColumn(#"Inserted Txt Week Format", "Num Day", each Date.DayOfWeek([Date]), Int64.Type),
    #"Inserted Txt Day Name" = Table.AddColumn(#"Inserted Num Day", "Txt Day Name", each Text.Start(Date.DayOfWeekName([Date]), 3), type text),
    
    // Add Weekend Flag column (simplified logic)
    #"Added Bool Is Weekend" = Table.AddColumn(#"Inserted Txt Day Name", "Bool Is Weekend", each [Txt Day Name] = "Sat" or [Txt Day Name] = "Sun", type logical),

    // Add explicit sort columns and formatted display columns
    // Year-Month sorting and display
    #"Added Num Sort Year Month" = Table.AddColumn(#"Added Bool Is Weekend", "Num Sort Year Month", each [Num Year] * 100 + [Num Month], Int64.Type),
    #"Added Txt Year Month" = Table.AddColumn(#"Added Num Sort Year Month", "Txt Year Month", each Text.From([Num Year]) & " " & [Txt Month Name], type text),
    
    // Year-Week sorting and display
    #"Added Num Sort Year Week" = Table.AddColumn(#"Added Txt Year Month", "Num Sort Year Week", each [Num Year] * 100 + [Num Week], Int64.Type),
    #"Added Txt Year Week" = Table.AddColumn(#"Added Num Sort Year Week", "Txt Year Week", each Text.From([Num Year]) & " W" & Text.PadStart(Text.From([Num Week]), 2, "0"), type text),
    
    // Year-Quarter sorting and display
    #"Added Num Sort Year Quarter" = Table.AddColumn(#"Added Txt Year Week", "Num Sort Year Quarter", each [Num Year] * 10 + [Num Quarter], Int64.Type),
    #"Added Txt Year Quarter" = Table.AddColumn(#"Added Num Sort Year Quarter", "Txt Year Quarter", each Text.From([Num Year]) & " Q" & Text.From([Num Quarter]), type text),
    
    // Add special formatting columns for Month Name and Week Day
    #"Added Txt Month Name Short" = Table.AddColumn(#"Added Txt Year Quarter", "Txt Month Name Short", each Text.Repeat(Character.FromNumber(8203), 12 - [Num Month]) & Text.Start(Date.MonthName([Date]), 1), type text),
    #"Added Txt Week Day Short" = Table.AddColumn(#"Added Txt Month Name Short", "Txt Week Day Short", each Text.Repeat(Character.FromNumber(8203), 7 - [Num Day]) & Text.Start(Date.DayOfWeekName([Date]), 1), type text),

    // Define the latest date components based on the latest date
    LatestYear = Date.Year(MaxDate),
    LatestWeek = Date.WeekOfYear(MaxDate),
    LatestMonth = Date.Month(MaxDate),
    LatestQuarter = Date.QuarterOfYear(MaxDate),
    
    // Add flag columns for latest date, year-week, year-month, and year-quarter
    #"Added Bool Is Latest Date" = Table.AddColumn(#"Added Txt Week Day Short", "Bool Is Latest Date", each [Date] = MaxDate, type logical),
    #"Added Bool Is Latest Year Week" = Table.AddColumn(#"Added Bool Is Latest Date", "Bool Is Latest Year Week", each [Num Year] = LatestYear and [Num Week] = LatestWeek, type logical),
    #"Added Bool Is Latest Year Month" = Table.AddColumn(#"Added Bool Is Latest Year Week", "Bool Is Latest Year Month", each [Num Year] = LatestYear and [Num Month] = LatestMonth, type logical),
    #"Added Bool Is Latest Year Quarter" = Table.AddColumn(#"Added Bool Is Latest Year Month", "Bool Is Latest Year Quarter", each [Num Year] = LatestYear and [Num Quarter] = LatestQuarter, type logical),
    
    // Keep the sort columns as they're more explicit and reliable
    #"Final Columns" = #"Added Bool Is Latest Year Quarter",
    
    // Add the prefix to all column names in a final step
    FinalTable = if SafePrefix = "" then #"Final Columns" else
                Table.RenameColumns(#"Final Columns", 
                    List.Transform(
                    Table.ColumnNames(#"Final Columns"),
                    each {_, SafePrefix & _}
                    )
                )
in
    FinalTable
