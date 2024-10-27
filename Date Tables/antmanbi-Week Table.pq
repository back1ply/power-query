/*
    Original Code written in DAX by SQLBI -> https://www.sqlbi.com/
    DAX Based week date table -> https://www.daxpatterns.com/week-related-calculations/
    
    I have only replicated DAX into PQ and made a little bit of modifications to create a 1:1 relationship between DAX and PQ
    
    The below code is a function that you need to copy and past in PQ Editor in PBI or Excel or any other tool
    You can run it even without specifying the parameters and then later customize them once you understand the table
*/

(
    optional pFirstFiscalMonth as number, 
    optional pFirstDayOfWeek as number, 
    optional pFirstDate as date, 
    optional pLastDate as date, 
    optional pTypeStartFiscalYear as number, 
    optional pQuarterWeekType as text,
    optional pWeeklyType as text
) =>
let
    FirstFiscalMonth            = if pFirstFiscalMonth is null then 1 else pFirstFiscalMonth,
    FirstDayOfWeek              = if pFirstDayOfWeek is null then Day.Monday else pFirstDayOfWeek,
    FirstDate                   = if pFirstDate is null then #date ( 2023, 01, 01 ) else pFirstDate,
    LastDate                    = if pLastDate is null then #date ( 2025, 08, 15 ) else pLastDate,
    TypeStartFiscalYear         = if pTypeStartFiscalYear is null then 1 else pTypeStartFiscalYear,
    QuarterWeekType             = if pQuarterWeekType is null then "445" else pQuarterWeekType, //445, 454, 544
    WeeklyType                  = if pWeeklyType is null then "Last" else pWeeklyType, // Last or Nearest
    FirstYear = 
        Date.Year ( FirstDate ) + 1 * 
            ( 
                (if Date.Month ( FirstDate ) >= FirstFiscalMonth then 1 else 0) 
                    * (if FirstFiscalMonth > 1 then 1 else 0)
            ),
    LastYear = 
        Date.Year ( LastDate ) + 1 * 
            ( 
                (if Date.Month ( LastDate ) >= FirstFiscalMonth then 1 else 0) 
                    * (if FirstFiscalMonth > 1 then 1 else 0)
            ),
    WorkingDayType = "Working Day",
    NonWorkingDayType = "Non-Working Day",
    WorkingDays = { 1, 2, 3, 4, 5 },
    FirstDayCalendar = #date(FirstYear -1, 1, 1),
    LastDayCalendar = #date(LastYear + 1, 12, 31),
    WeekDayCalculationType = 
        (if FirstDayOfWeek = 0 then 0 else FirstDayOfWeek),
    OffsetFiscalYear = 
        if FirstFiscalMonth > 1 then 1 else 0,
    WeeklyFiscalPeriods = 
        Table.FromRows (
            List.Transform ( 
                { FirstYear - OffsetFiscalYear..LastYear + OffsetFiscalYear },
                (FWYearNumber)=>
                let
                    LastCalculation = 
                        let 
                            StartFiscalYearNumber = FWYearNumber - ( OffsetFiscalYear * TypeStartFiscalYear ),
                            FirstDayCurrentYear = #date ( StartFiscalYearNumber, FirstFiscalMonth, 1 ),
                            FirstDayNextYear = #date ( StartFiscalYearNumber + 1, FirstFiscalMonth, 1 ),
                            DayOfWeekNumberCurrentYear = Date.DayOfWeek ( FirstDayCurrentYear, WeekDayCalculationType ),
                            OffsetStartCurrentFiscalYear = - DayOfWeekNumberCurrentYear,
                            DayOfWeekNumberNextYear = 
                                Date.DayOfWeek ( FirstDayNextYear, WeekDayCalculationType ) + 1 ,
                            OffsetStartNextFiscalYear = - DayOfWeekNumberNextYear,
                            FirstDayOfFiscalYear = 
                                Date.AddDays ( FirstDayCurrentYear, OffsetStartCurrentFiscalYear ),
                            LastDayOfFiscalYear = 
                                Date.AddDays ( FirstDayNextYear, OffsetStartNextFiscalYear ),
                            Result = {
                                FWYearNumber,
                                FirstDayOfFiscalYear,
                                LastDayOfFiscalYear
                            }
                        in
                            Result,
                   NearestCalculations = 
                        let
                            StartFiscalYearNumber = FWYearNumber - ( OffsetFiscalYear * TypeStartFiscalYear ),
                            FirstDayCurrentYear = #date ( StartFiscalYearNumber, FirstFiscalMonth, 1 ),
                            FirstDayNextYear =  #date ( StartFiscalYearNumber + 1, FirstFiscalMonth, 1 ),
                            LastDayFiscalYear = 
                                Date.AddDays ( FirstDayNextYear, -1 ),
                            StartOfYear = 
                                let
                                    FirstDayWeekNumber =  Date.DayOfWeek ( FirstDayCurrentYear, FirstDayOfWeek ),
                                    PreviousWeekStart = Date.StartOfWeek ( FirstDayCurrentYear, FirstDayOfWeek ),
                                    NextWeekStart =  Date.AddDays ( PreviousWeekStart, 7 ),
                                    DayGapFromPrevious = Number.From ( FirstDayCurrentYear ) - Number.From ( PreviousWeekStart ), 
                                    DayGapFromNext = Number.From ( NextWeekStart ) - Number.From ( FirstDayCurrentYear ),
                                    Result =
                                        Table.Sort ( 
                                            Table.FromRows ( 
                                                {
                                                    { DayGapFromPrevious, PreviousWeekStart },
                                                    { DayGapFromNext, NextWeekStart }
                                                }, 
                                                type table [DayGap = Int64.Type, Date = date]
                                            ), 
                                            { "DayGap", Order.Ascending } 
                                        )
                                in
                                    Result[Date]{0},
                            EndOfYear = 
                                let
                                    LastDayWeekNumber =  Date.DayOfWeek ( LastDayFiscalYear, FirstDayOfWeek ),
                                    LastSaturdayCurrentMonth =  Date.AddDays ( Date.StartOfWeek ( LastDayFiscalYear, FirstDayOfWeek ), -1 ),
                                    FirstSaturdayNextMonth =  Date.AddDays ( LastSaturdayCurrentMonth, 7 ),
                                    DayGapFromLastSaturday = Number.From ( LastDayFiscalYear ) - Number.From ( LastSaturdayCurrentMonth ), 
                                    DayGapFromNextSaturday = Number.From ( FirstSaturdayNextMonth ) - Number.From ( LastDayFiscalYear ),
                                    Result =
                                        Table.Sort ( 
                                            Table.FromRows ( 
                                                {
                                                    { DayGapFromLastSaturday, LastSaturdayCurrentMonth },
                                                    { DayGapFromNextSaturday, FirstSaturdayNextMonth }
                                                }, 
                                                type table [DayGap = Int64.Type, Date = date]
                                            ), 
                                            { "DayGap", Order.Ascending } 
                                        )
                                in
                                    Result[Date]{0},
                             Result = 
                                { 
                                    FWYearNumber,
                                    StartOfYear, 
                                    EndOfYear 
                                }
                            in
                                Result,
                        Check = if WeeklyType = "Last" then LastCalculation else NearestCalculations
                    in
                        Check
            ),
                type table [
                    FW YearNumber = Int64.Type,
                    FW StartOfYear = date,
                    FW EndOfYear = date
                ]
        ),
    WeeksInP1 = 
        if QuarterWeekType = "445"
        then 4
        else
            if QuarterWeekType = "454"
            then 4
            else 
                if QuarterWeekType = "544"
                then 5
                else "QuarterWeekType only supports 445, 454, and 544",
    WeeksInP2 = 
        if QuarterWeekType = "445"
        then 4
        else
            if QuarterWeekType = "454"
            then 5
            else 
                if QuarterWeekType = "544"
                then 4
                else "QuarterWeekType only supports 445, 454, and 544", 
    WeeksInP3 = 
        if QuarterWeekType = "445"
        then 5
        else
            if QuarterWeekType = "454"
            then 4
            else 
                if QuarterWeekType = "544"
                then 4
                else "QuarterWeekType only supports 445, 454, and 544", 
    FirstSundayReference = 
        #date ( 1900, 12, 30 ),
    FirstWeekReference = Date.AddDays ( FirstSundayReference, FirstDayOfWeek ),
    CustomFiscalRawDays = 
        Table.AddColumn ( 
            WeeklyFiscalPeriods, 
            "Date",
            each 
            Table.FromColumns ( 
                { 
                    List.Transform ( 
                        { 
                            Number.From ( [FW StartOfYear] )..Number.From ( [FW EndOfYear] ) 
                        }, 
                        each Date.From ( _ ) 
                    ) 
                }, 
                type table [Date = date] 
            ), 
            type table [Date = date] 
        ),
    ExpandedDate = 
        Table.ExpandTableColumn ( CustomFiscalRawDays, "Date", {"Date"}, {"Date"} ),
    FiscalWeeksBase = 
        Table.AddColumn ( 
            ExpandedDate,
            "NewCols",
            (CurrentRow)=>
                let
                    CalDate = CurrentRow[Date],
                    FwFirstDayOfYear = CurrentRow[FW StartOfYear],
                    FwDayOfYear = 
                        Number.From ( CalDate ) - Number.From ( FwFirstDayOfYear ) + 1,
                    CalYear = 
                        Date.Year ( CalDate ),
                    CalMonthNumber = Date.Month ( CalDate ),
                    CalDay = Date.Day ( CalDate ),
                    FwDayOfYearNumber = Number.From ( CalDate ) - Number.From ( CurrentRow[FW StartOfYear] ) + 1,
                    FwWeekNumber = 
                        Number.RoundAwayFromZero ( FwDayOfYearNumber / 7, 0 ),
                    FwPeriodNumber = 
                        if FwWeekNumber > 52 then 14 else Number.RoundUp ( FwWeekNumber / 4, 0 ),
                    FwYearNumber = CurrentRow[FW YearNumber],
                    FwQuarterNumber = 
                        if FwWeekNumber > 52 then 4 else Number.RoundUp ( FwWeekNumber / 13, 0 ),
                    FwWeekInQuarterNumber = 
                        if FwWeekNumber > 52 then 14 else FwWeekNumber - 13 * ( FwQuarterNumber - 1 ),
                    FwMonthNumber = 
                        (FwQuarterNumber - 1 ) * 3
                            + ( 
                                if FwWeekInQuarterNumber <= WeeksInP1 
                                then 1 
                                else 
                                    if FwWeekInQuarterNumber <= ( WeeksInP1 + WeeksInP2 )
                                    then 2
                                    else 3
                            ),
                    WeekDayNumber = Date.DayOfWeek ( CalDate, 0 ) + 1,
                    FirstDayOfWeek = Date.From ( Number.From ( CalDate ) - WeekDayNumber ),
                    LastDayOfWeek = Date.AddDays ( FirstDayOfWeek, 6 ),
                    IsWorkingDay = List.Contains ( WorkingDays, Date.DayOfWeek ( CalDate, WeekDayCalculationType ) ),
                    Result = 
                        Table.FromRecords ( 
                            { 
                                [ 
                                    DateKey = CalYear * 10000 + CalMonthNumber * 100 + CalDay,
                                    FW Year = FwYearNumber,
                                    FW QuarterNumber = FwQuarterNumber,
                                    FW Quarter = "FQ" & Text.From ( FwQuarterNumber ),
                                    FW YearQuarterNumber = FwYearNumber * 4 - 1 + FwQuarterNumber,
                                    FW Quarter Year = "FQ" & Text.From ( FwQuarterNumber ) & "-" & Text.From ( FwYearNumber ),
                                    FW MonthNumber = FwMonthNumber,
                                    FW YearMonthNumber = FwYearNumber * 12 - 1 + FwMonthNumber,
                                    FW WeekNumber = FwWeekNumber,
                                    FW Week = "FW" & Text.PadStart ( Text.From ( FwWeekNumber ), 2, "0" ),
                                    FW PeriodNumber = FwPeriodNumber,
                                    FW Period = "P" & Text.PadStart ( Text.From ( FwPeriodNumber ), 2, "0" ),
                                    FW YearWeekNumber = Number.IntegerDivide ( ( Number.From ( CalDate ) - Number.From ( FirstWeekReference ) ), 7 ) + 1,
                                    FW Week Year =  "FW" & Text.PadStart ( Text.From ( FwWeekNumber ), 2, "0" ) & "-" & Text.From ( FwYearNumber ),
                                    FW StartOfWeek =  FirstDayOfWeek,
                                    FW EndOfWeek = LastDayOfWeek,
                                    WeekDayNumber = WeekDayNumber,
                                    Week Day = Date.ToText ( CalDate, "ddd" ),
                                    FW DayOfYearNumber = FwDayOfYear,
                                    IsWorkingDay = IsWorkingDay,
                                    Sequential Day Number = Number.From ( CalDate ),
                                    Day Type = 
                                        if List.Contains ( WorkingDays, Date.DayOfWeek ( CalDate, WeekDayCalculationType ) ) 
                                        then WorkingDayType 
                                        else NonWorkingDayType
                                ] 
                            } 
                        )
                    in Result,

                type table [
                    DateKey = Int64.Type,
                    FW Year = Int64.Type,
                    FW QuarterNumber = Int64.Type,
                    FW Quarter = text,
                    FW YearQuarterNumber = Int64.Type,
                    FW Quarter Year = text,
                    FW MonthNumber = Int64.Type,
                    FW YearMonthNumber = Int64.Type,
                    FW WeekNumber = Int64.Type,
                    FW Week = text,
                    FW PeriodNumber = Int64.Type,
                    FW Period = text,
                    FW YearWeekNumber = Int64.Type,
                    FW Week Year =  text,
                    FW StartOfWeek =  date,
                    FW EndOfWeek = date,
                    WeekDayNumber = Int64.Type,
                    Week Day = text,
                    FW DayOfYearNumber = Int64.Type,
                    IsWorkingDay = logical,
                    Sequential Day Number = Int64.Type,
                    Day Type = text
                ]
        ),
    ColumnsToExpand = {
        "DateKey", 
        "FW Year", 
        "FW QuarterNumber", 
        "FW Quarter", 
        "FW YearQuarterNumber", 
        "FW Quarter Year", 
        "FW MonthNumber", 
        "FW YearMonthNumber", 
        "FW WeekNumber", 
        "FW Week", 
        "FW PeriodNumber", 
        "FW Period", 
        "FW YearWeekNumber", 
        "FW Week Year", 
        "FW StartOfWeek", 
        "FW EndOfWeek", 
        "WeekDayNumber", 
        "Week Day", 
        "FW DayOfYearNumber", 
        "IsWorkingDay", 
        "Sequential Day Number", 
        "Day Type" 
    },
    ExpandedNewCols = Table.ExpandTableColumn ( FiscalWeeksBase, "NewCols", ColumnsToExpand, ColumnsToExpand ),
    MonthDetails = 
        Table.Group (
            ExpandedNewCols, 
            {"FW YearMonthNumber"}, 
            {
                {"FW StartOfMonth", each List.Min([Date]), type nullable date}, 
                {"FW EndOfMonth", each List.Max([Date]), type nullable date}, 
                {"FW MonthDays", each Number.From ( List.Max ( [Date] ) ) - Number.From ( List.Min ( [Date] ) ) + 1, Int64.Type }, 
                {"FW Month", each "FM " & Date.ToText ( Date.AddDays ( List.Min([Date]), 14 ), "MMM" ), type text}, 
                {"FW Month Year", each "FM " & Date.ToText ( Date.AddDays ( List.Min([Date]), 14 ), "MMM yyyy" ), type text } 
            }
        ),
    QuarterDetails = 
        Table.Group ( 
            ExpandedNewCols, 
            {"FW YearQuarterNumber"}, 
            {
                {"FW StartOfQuarter", each List.Min([Date]), type nullable date}, 
                {"FW EndOfQuarter", each List.Max([Date]), type nullable date}, 
                {"FW QuraterDays", each Number.From ( List.Max ( [Date] ) ) - Number.From ( List.Min ( [Date] ) ) + 1, Int64.Type }
            }
        ),
    YearDetails = 
        Table.Group ( 
            ExpandedNewCols, 
            {"FW YearNumber"}, 
            {
                {"FW StartOfYear", each List.Min([Date]), type nullable date}, 
                {"FW EndOfYear", each List.Max([Date]), type nullable date}, 
                {"FW YearDays", each Number.From ( List.Max ( [Date] ) ) - Number.From ( List.Min ( [Date] ) ) + 1, Int64.Type }
            }
        ),
    MergedMonthDetails = 
        Table.NestedJoin ( 
            ExpandedNewCols, 
            {"FW YearMonthNumber"}, 
            MonthDetails, 
            {"FW YearMonthNumber"}, 
            "MonthDetails", 
            JoinKind.Inner
        ),
    ExpandedMonthDetails = 
        Table.ExpandTableColumn (
            MergedMonthDetails, 
            "MonthDetails", 
            {"FW StartOfMonth", "FW EndOfMonth", "FW MonthDays", "FW Month", "FW Month Year"}, 
            {"FW StartOfMonth", "FW EndOfMonth", "FW MonthDays", "FW Month", "FW Month Year"}
        ),
    MergedQuarterDetails = 
        Table.NestedJoin ( 
            ExpandedMonthDetails, 
            {"FW YearQuarterNumber"}, 
            QuarterDetails, 
            {"FW YearQuarterNumber"}, 
            "QuarterDetails", 
            JoinKind.Inner
        ),
    ExpandedQuarterDetails = 
        Table.ExpandTableColumn ( 
            MergedQuarterDetails, 
            "QuarterDetails", 
            {"FW StartOfQuarter", "FW EndOfQuarter", "FW QuraterDays"}, 
            {"FW StartOfQuarter", "FW EndOfQuarter", "FW QuraterDays"}
        ),
    MergedYearDetails = 
        Table.NestedJoin ( 
            ExpandedQuarterDetails, 
            {"FW YearNumber"}, 
            YearDetails, 
            {"FW YearNumber"}, 
            "YearDetails", 
            JoinKind.Inner
        ),
    ExpandedYearDetails = 
        Table.ExpandTableColumn ( 
            MergedYearDetails, 
            "YearDetails", 
            {"FW YearDays"}, 
            {"FW YearDays"}
        ),
    MoreNewCols =
        Table.AddColumn ( 
            ExpandedYearDetails,
            "NewCols",
            (CurrentRow)=>
            let
                DayOfMonthNumber = Number.From ( CurrentRow[Date] ) - Number.From ( CurrentRow[FW StartOfMonth] ) + 1,
                DayofQuarterNumber = Number.From ( CurrentRow[Date] ) - Number.From ( CurrentRow[FW StartOfQuarter] ) + 1,
                Result = 
                    Table.FromRows ( 
                        { { DayOfMonthNumber,  DayofQuarterNumber } },
                        type table [
                            FW DayOfMonthNumber = Int64.Type, 
                            FW DayOfQuarterNumber = Int64.Type 
                        ]
                    )
            in
                Result,
                type table [
                    FW DayOfMonthNumber = Int64.Type, 
                    FW DayOfQuarterNumber = Int64.Type
                ]

        ),
    ExpandedNewCols2 = 
        Table.Buffer ( 
            Table.ExpandTableColumn (
                MoreNewCols, 
                "NewCols", 
                {"FW DayOfMonthNumber", "FW DayOfQuarterNumber"}, 
                {"FW DayOfMonthNumber", "FW DayOfQuarterNumber"}
            )
        ),
    PreviousTimeCols = 
        Table.AddColumn ( 
            ExpandedNewCols2,
            "NewCols",
            (CurrentRow)=>
            let
                CalDate = CurrentRow[Date],
                FwYearMonthNumber = CurrentRow[FW YearMonthNumber],
                FwYearQuarterNumber = CurrentRow[FW YearQuarterNumber],
                FWYearNumber = CurrentRow[FW YearNumber],
                FwDayOfMonthNumber = CurrentRow[FW DayOfMonthNumber],
                FwDayOfQuarterNumber = CurrentRow[FW DayOfQuarterNumber],
                FwDayOfYearNumber = CurrentRow[FW DayOfYearNumber],
                FwMonthDays = Number.From ( CurrentRow[FW EndOfMonth] ) - Number.From ( CurrentRow[FW StartOfMonth] ) + 1,
                FwQuarterDays = Number.From ( CurrentRow[FW EndOfQuarter] ) - Number.From ( CurrentRow[FW StartOfQuarter] ) + 1,
                FwYearDays = Number.From ( CurrentRow[FW EndOfYear] ) - Number.From ( CurrentRow[FW StartOfYear] ) + 1,
                FwDatePreviousWeek = Date.AddDays ( CalDate, 7 ),
                FwDatePreviousMonth = 
                    List.Max ( 
                        Table.SelectRows ( 
                            ExpandedNewCols2, 
                            each [FW YearMonthNumber] = FwYearMonthNumber - 1 
                                and (
                                    [FW DayOfMonthNumber] <= FwDayOfMonthNumber 
                                        or [FW DayOfMonthNumber] = FwMonthDays
                                )
                        )[Date]
                    ),
                FwDatePreviousQuarter = 
                    List.Max ( 
                        Table.SelectRows ( 
                            ExpandedNewCols2, 
                            each [FW YearQuarterNumber] = FwYearQuarterNumber - 1
                                and (
                                    [FW DayOfQuarterNumber] <= FwDayOfQuarterNumber 
                                        or [FW DayOfQuarterNumber] = FwQuarterDays
                                )
                        )[Date]
                    ),
                        
                FwDatePreviousYear = 
                    List.Max ( 
                        Table.SelectRows ( 
                            ExpandedNewCols2, 
                            each [FW YearNumber] = FWYearNumber - 1
                                and (
                                    [FW DayOfYearNumber] <= FwDayOfYearNumber 
                                        or [FW DayOfYearNumber] = FwYearDays
                                )
                        )[Date]
                    ),
            Result =
                Table.FromRows ( 
                    { { FwDatePreviousWeek, FwDatePreviousMonth, FwDatePreviousQuarter, FwDatePreviousYear} },
                    type table [ 
                        FW DatePreviousWeek = date, 
                        FW DatePreviousMonth = date, 
                        FW DatePreviousQuarter = date, 
                        FW DatePreviousYear = date
                    ]
                )
            in
                Result,
            type table [ 
                FW DatePreviousWeek = date, 
                FW DatePreviousMonth = date, 
                FW DatePreviousQuarter = date,
                FW DatePreviousYear = date
            ]
        ),
    ExpandedNewCols3 = 
        Table.ExpandTableColumn (
            PreviousTimeCols, 
            "NewCols", 
            {"FW DatePreviousWeek", "FW DatePreviousMonth", "FW DatePreviousQuarter", "FW DatePreviousYear"}, 
            {"FW DatePreviousWeek", "FW DatePreviousMonth", "FW DatePreviousQuarter", "FW DatePreviousYear"}
        ),
    CompleteCalendar = 
        Table.SelectRows ( 
            ExpandedNewCols3, 
            each
            ( [FW YearNumber] >= FirstYear
            and [FW YearNumber] <= LastYear ) 
        ),
    ColumnsToKeep = { 
        "Date", 
        "Sequential Day Number", 
        "FW YearNumber", 
        "FW Year", 
        "FW QuarterNumber", 
        "FW Quarter", 
        "FW YearQuarterNumber", 
        "FW Quarter Year", 
        "FW MonthNumber", 
        "FW Month",  
        "FW YearMonthNumber", 
        "FW Month Year", 
        "FW WeekNumber",
        "FW Week", 
        "FW YearWeekNumber", 
        "FW Week Year", 
        "WeekDayNumber", 
        "Week Day", 
        "FW DayOfMonthNumber", 
        "FW DayOfQuarterNumber", 
        "FW DayOfYearNumber", 
        "IsWorkingDay",
        "Day Type"
    },
    Result = Table.SelectColumns ( CompleteCalendar, ColumnsToKeep, MissingField.Ignore ),
    NewColumnName = {
        "Date",
        "Sequential Day Number",
        "Fiscal Year Number",
        "Fiscal Year",
        "Fiscal Quarter Number",
        "Fiscal Quarter",
        "Fiscal Year Quarter Number",
        "Fiscal Year Quarter",
        "Fiscal Month Number",
        "Fiscal Month",
        "Fiscal Year Month Number",
        "Fiscal Year Month",
        "Fiscal Week Number",
        "Fiscal Week",
        "Fiscal Year Week Number",
        "Fiscal Year Week",
        "Day of Week Number",
        "Day of Week",
        "Day of Fiscal Month Number",
        "Day of Fiscal Quarter Number",
        "Day of Fiscal Year Number",
        "Working Day",
        "Day Type"
    },
    RenameCols = Table.RenameColumns ( Result, List.Zip ( { Table.ColumnNames ( Result ), NewColumnName } ), MissingField.Ignore )
in
    RenameCols
