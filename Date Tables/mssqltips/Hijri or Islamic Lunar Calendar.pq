let
    // 1. Load source dates
    Source = FactInternetSales,
    DatesOnly = Table.SelectColumns(Source, {"OrderDate"}),
 
    // 2. Get min and max dates
    MinDate = Date.From(List.Min(DatesOnly[OrderDate])),
    MaxDate = Date.From(List.Max(DatesOnly[OrderDate])),
 
    // 3. Generate continuous date list
    Dates = List.Dates(MinDate, Duration.Days(MaxDate - MinDate)+1, #duration(1,0,0,0)),
    DateTable = Table.FromList(Dates, Splitter.SplitByNothing(), {"Date"}),
 
    // 4. Convert to Hijri text (yyyy-MM-dd)
    AddHijriText = Table.AddColumn(
        DateTable,
        "HijriText",
        each Date.ToText([Date], "yyyy-MM-dd", "ar-SA"),
        type text
    ),
 
    // 5. Split Hijri text into Year/Month/Day
    SplitHijri = Table.SplitColumn(
        AddHijriText,
        "HijriText",
        Splitter.SplitTextByDelimiter("-"),
        {"HijriYear", "HijriMonth", "HijriDay"}
    ),
 
    // 6. Change types to numeric
    ChangeTypes = Table.TransformColumnTypes(
        SplitHijri,
        {{"HijriYear", Int64.Type}, {"HijriMonth", Int64.Type}, {"HijriDay", Int64.Type}}
    ),
 
    // 7. Map HijriMonth to month names
    AddHijriMonthName = Table.AddColumn(
        ChangeTypes,
        "HijriMonthName",
        each
            if [HijriMonth]=1 then "Muharram"
            else if [HijriMonth]=2 then "Safar"
            else if [HijriMonth]=3 then "Rabi’ al-awwal"
            else if [HijriMonth]=4 then "Rabi’ al-thani"
            else if [HijriMonth]=5 then "Jumada al-awwal"
            else if [HijriMonth]=6 then "Jumada al-thani"
            else if [HijriMonth]=7 then "Rajab"
            else if [HijriMonth]=8 then "Sha’ban"
            else if [HijriMonth]=9 then "Ramadan"
            else if [HijriMonth]=10 then "Shawwal"
            else if [HijriMonth]=11 then "Dhul-Qi’dah"
            else if [HijriMonth]=12 then "Dhul-Hijjah"
            else "Unknown",
        type text
    ),
 
    // 8. Compute Quarter
    AddQuarter = Table.AddColumn(
        AddHijriMonthName,
        "HijriQuarter",
        each Number.RoundUp([HijriMonth]/3),
        Int64.Type
    ),
 
    // 9. Add composite labels for reporting
    AddYearPeriod = Table.AddColumn(
        AddQuarter,
        "YearPeriod",
        each "FY" & Text.From([HijriYear]) & "-M" & Text.PadStart(Text.From([HijriMonth]),2,"0"),
        type text
    ),
    AddYearQuarter = Table.AddColumn(
        AddYearPeriod,
        "YearQuarter",
        each "FY" & Text.From([HijriYear]) & "-Q" & Text.From([HijriQuarter]),
        type text
    ),
    #"Changed Type" = Table.TransformColumnTypes(AddYearQuarter,{{"Date", type date}})
in
    #"Changed Type"
