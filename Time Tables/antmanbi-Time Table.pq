let
    MinutesInDay = 24 * 60,
    SecondsInDay = MinutesInDay * 60,
    TimeList = Table.FromColumns (
        { List.Times ( #time ( 0, 0, 0 ), SecondsInDay, #duration ( 0, 0, 0, 1 ) ) },
        type table [ Time = time ]
    ),
    PeriodOfDay = Table.FromColumns (
        {
            { 0, 5, 9, 13, 17, 21 },
            { 4, 8, 12, 16, 20, 24 },
            { "Midnight", "Early Morning", "Morning", "Afternoon", "Evening", "Night" },
            { 1, 2, 3, 4, 5, 6 }
        },
        type table [
            Hour Min = Int64.Type,
            Hour Max = Int64.Type,
            Period of Day Name = text,
            Period of Day Name Sort = Int64.Type
        ]
    ),
    TwelveHourPeriod = Table.FromColumns (
        { { 0, 12 }, { 11, 23 }, { "Before Noon", "After Noon" }, { "0-11", "12-23" }, { 1, 2 } },
        type table [
            Hour Min = Int64.Type,
            Hour Max = Int64.Type,
            #"12 Hour Period Name" = text,
            #"12 Hour Bin" = text,
            #"12 Hour Bin Sort" = Int64.Type
        ]
    ),
    SixHourPeriod = Table.FromColumns (
        {
            { 0, 6, 12, 19 },
            { 5, 11, 18, 24 },
            { "Down Time", "Login", "Meetings", "Logout" },
            { "0-5", "6-11", "12-17", "18-23" },
            { 1, 2, 3, 4 }
        },
        type table [
            Hour Min = Int64.Type,
            Hour Max = Int64.Type,
            #"6 Hour Period Name" = text,
            #"6 Hour Bin" = text,
            #"6 Hour Bin Sort" = Int64.Type
        ]
    ),
    FourHourPeriod = Table.FromColumns (
        {
            { 0, 4, 8, 12, 16, 20 },
            { 3, 7, 11, 15, 19, 23 },
            { "Down Time", "Down Time", "Login", "Meetings", "Logout", "Logout" },
            { "0-3", "4-7", "8-11", "12-15", "16-19", "20-23" },
            { 1, 2, 3, 4, 5, 6 }
        },
        type table [
            Hour Min = Int64.Type,
            Hour Max = Int64.Type,
            #"4 Hour Period Name" = text,
            #"4 Hour Bin" = text,
            #"4 Hour Bin Sort" = Int64.Type
        ]
    ),
    ThreeHourPeriod = Table.FromColumns (
        {
            { 0, 3, 6, 9, 12, 15, 18, 21 },
            { 2, 5, 8, 11, 14, 17, 20, 23 },
            {
                "Down Time",
                "Refresh Time",
                "Machinery Start",
                "Login",
                "Maintenance",
                "Meetings",
                "Logout",
                "Cleaning"
            },
            { "0-3", "3-5", "6-8", "9-11", "12-14", "15-17", "18-20", "21-23" },
            { 1, 2, 3, 4, 5, 6, 7, 8 }
        },
        type table [
            Hour Min = Int64.Type,
            Hour Max = Int64.Type,
            #"3 Hour Period Name" = text,
            #"3 Hour Bin" = text,
            #"3 Hour Bin Sort" = Int64.Type
        ]
    ),
    TwoHourPeriod = Table.FromColumns (
        {
            { 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22 },
            { 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23 },
            {
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description"
            },
            {
                "0-1",
                "2-3",
                "4-5",
                "6-7",
                "8-9",
                "10-11",
                "12-13",
                "14-15",
                "16-17",
                "18-19",
                "20-21",
                "22-23"
            },
            { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
        },
        type table [
            Hour Min = Int64.Type,
            Hour Max = Int64.Type,
            #"2 Hour Period Name" = text,
            #"2 Hour Bin" = text,
            #"2 Hour Bin Sort" = Int64.Type
        ]
    ),
    ThirtyMinutePeriod = Table.FromColumns (
        { { 0, 30 }, { 29, 59 }, { "Description", "Description" }, { "0-29", "30-59" }, { 1, 2 } },
        type table [
            Minute Min = Int64.Type,
            Minute Max = Int64.Type,
            #"30 Minute Period Name" = text,
            #"30 Minute Bin" = text,
            #"30 Minute Bin Sort" = Int64.Type
        ]
    ),
    FifteenMinutePeriod = Table.FromColumns (
        {
            { 0, 15, 30, 45 },
            { 14, 29, 44, 59 },
            { "Description", "Description", "Description", "Description" },
            { "0-29", "30-59" },
            { 1, 2, 3, 4 }
        },
        type table [
            Minute Min = Int64.Type,
            Minute Max = Int64.Type,
            #"15 Minute Period Name" = text,
            #"15 Minute Bin" = text,
            #"15 Minute Bin Sort" = Int64.Type
        ]
    ),
    TenMinutePeriod = Table.FromColumns (
        {
            { 0, 10, 20, 30, 40, 50 },
            { 9, 19, 29, 39, 49, 59 },
            {
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description"
            },
            { "0-9", "10-19", "20-29", "30-39", "40-49", "50-59" },
            { 1, 2, 3, 4, 5, 6 }
        },
        type table [
            Minute Min = Int64.Type,
            Minute Max = Int64.Type,
            #"10 Minute Period Name" = text,
            #"10 Minute Bin" = text,
            #"10 Minute Bin Sort" = Int64.Type
        ]
    ),
    FiveMinutePeriod = Table.FromColumns (
        {
            { 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 },
            { 4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59 },
            {
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description",
                "Description"
            },
            {
                "0-4",
                "5-9",
                "10-14",
                "15-19",
                "20-24",
                "25-29",
                "30-34",
                "35-39",
                "40-44",
                "45-49",
                "50-54",
                "55-59"
            },
            { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
        },
        type table [
            Minute Min = Int64.Type,
            Minute Max = Int64.Type,
            #"5 Minute Period Name" = text,
            #"5 Minute Bin" = text,
            #"5 Minute Bin Sort" = Int64.Type
        ]
    ),
    NewCols = 
        Table.AddColumn ( 
            TimeList,
            "NewCols",
            (Row)=>
            let
                Time = Row[Time],
                Minute = Time.Minute ( Time ),
                Second = Time.Second ( Time ),
                Hour24 = Time.Hour ( Time ),
                Hour12 = Number.Mod ( Hour24, 12 ),
                TimeKey = Hour24 * 10000 
                            + Minute * ( if Second is null then 1 else 100 )
                            + ( if Second is null then 0 else Second  ),
                AmPm = if Hour24 < 12 then "AM" else "PM",
                Combine = { 
                    Hour24, 
                    Hour12, 
                    Text.From ( Hour12 ) & " " & 
                    AmPm, Second, 
                    Minute, 
                    TimeKey, 
                    AmPm 
                },
                Result = 
                    Table.FromRows ( 
                       { Combine },
                       type table [
                           Hour24 = Int64.Type,
                           Hour12 = Int64.Type,
                           #"Hour 12 Text" = text,
                           Second = Int64.Type,
                           Minute = Int64.Type,
                           TimeKey = Int64.Type,
                           AmPm = text
                       ]
                    )
            in
                Result,
                type table [
                    Hour24 = Int64.Type,
                    Hour12 = Int64.Type,
                    #"Hour 12 Text" = text,
                    Second = Int64.Type,
                    Minute = Int64.Type,
                    TimeKey = Int64.Type,
                    AmPm = text
                ]
        ),
    ExpandedNewCols = Table.ExpandTableColumn (
        NewCols, 
        "NewCols", 
        { "Hour24", "Hour12", "Hour 12 Text", "Second", "Minute", "TimeKey", "AmPm" }, 
        { "Hour24", "Hour12", "Hour 12 Text", "Second", "Minute", "TimeKey", "AmPm" }
    ), 
    AddedPeriodOfDay = Table.AddColumn (
        ExpandedNewCols, 
        "PeriodOfDay", 
        ( OuterHour ) =>
            Table.SelectRows (
                PeriodOfDay, 
                ( InnerHour ) =>
                    OuterHour[Hour24] >= InnerHour[Hour Min] 
                        and OuterHour[Hour24] <= InnerHour[Hour Max]
            ), 
        type table [ Period of Day Name = text, Period of Day Name Sort = Int64.Type ]
    ), 
    ExpandedPeriodOfDayName = Table.ExpandTableColumn (
        AddedPeriodOfDay, 
        "PeriodOfDay", 
        { "Period of Day Name", "Period of Day Name Sort" }, 
        { "Period of Day Name", "Period of Day Name Sort" }
    ), 
    AddedTwelveHourPeriod = Table.AddColumn (
        ExpandedPeriodOfDayName, 
        "TwelveHourPeriod", 
        ( OuterHour ) =>
            Table.SelectRows (
                TwelveHourPeriod, 
                ( InnerHour ) =>
                    OuterHour[Hour24] >= InnerHour[Hour Min] 
                        and OuterHour[Hour24] <= InnerHour[Hour Max]
            ), 
        type table [
            Hour Min = Int64.Type, 
            Hour Max = Int64.Type, 
            #"12 Hour Period Name" = text, 
            #"12 Hour Bin" = text, 
            #"12 Hour Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedTwelverHourPeriod = Table.ExpandTableColumn (
        AddedTwelveHourPeriod, 
        "TwelveHourPeriod", 
        { "12 Hour Period Name", "12 Hour Bin", "12 Hour Bin Sort" }, 
        { "12 Hour Period Name", "12 Hour Bin", "12 Hour Bin Sort" }
    ), 
    AddedSixHourPeriod = Table.AddColumn (
        ExpandedTwelverHourPeriod, 
        "SixHourPeriod", 
        ( OuterHour ) =>
            Table.SelectRows (
                SixHourPeriod, 
                ( InnerHour ) =>
                    OuterHour[Hour24] >= InnerHour[Hour Min] 
                        and OuterHour[Hour24] <= InnerHour[Hour Max]
            ), 
        type table [
            Hour Min = Int64.Type, 
            Hour Max = Int64.Type, 
            #"6 Hour Period Name" = text, 
            #"6 Hour Bin" = text, 
            #"6 Hour Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedSixHourPeriod = Table.ExpandTableColumn (
        AddedSixHourPeriod, 
        "SixHourPeriod", 
        { "6 Hour Period Name", "6 Hour Bin", "6 Hour Bin Sort" }, 
        { "6 Hour Period Name", "6 Hour Bin", "6 Hour Bin Sort" }
    ), 
    AddedFourHourPeriod = Table.AddColumn (
        ExpandedSixHourPeriod, 
        "FourHourPeriod", 
        ( OuterHour ) =>
            Table.SelectRows (
                FourHourPeriod, 
                ( InnerHour ) =>
                    OuterHour[Hour24] >= InnerHour[Hour Min] 
                        and OuterHour[Hour24] <= InnerHour[Hour Max]
            ), 
        type table [
            Hour Min = Int64.Type, 
            Hour Max = Int64.Type, 
            #"4 Hour Period Name" = text, 
            #"4 Hour Bin" = text, 
            #"4 Hour Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedFourHourPeriod = Table.ExpandTableColumn (
        AddedFourHourPeriod, 
        "FourHourPeriod", 
        { "4 Hour Period Name", "4 Hour Bin", "4 Hour Bin Sort" }, 
        { "4 Hour Period Name", "4 Hour Bin", "4 Hour Bin Sort" }
    ), 
    AddedTwoHourPeriod = Table.AddColumn (
        ExpandedFourHourPeriod, 
        "TwoHourPeriod", 
        ( OuterHour ) =>
            Table.SelectRows (
                TwoHourPeriod, 
                ( InnerHour ) =>
                    OuterHour[Hour24] >= InnerHour[Hour Min] 
                        and OuterHour[Hour24] <= InnerHour[Hour Max]
            ), 
        type table [
            Hour Min = Int64.Type, 
            Hour Max = Int64.Type, 
            #"2 Hour Period Name" = text, 
            #"2 Hour Bin" = text, 
            #"2 Hour Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedTwoHourPeriod = Table.ExpandTableColumn (
        AddedTwoHourPeriod, 
        "TwoHourPeriod", 
        { "2 Hour Period Name", "2 Hour Bin", "2 Hour Bin Sort" }, 
        { "2 Hour Period Name", "2 Hour Bin", "2 Hour Bin Sort" }
    ), 
    AdddedThirtyMinutePeriod = Table.AddColumn (
        ExpandedTwoHourPeriod, 
        "ThirtyMinutePeriod", 
        ( OuterMinute ) =>
            Table.SelectRows (
                ThirtyMinutePeriod, 
                ( InnerMinute ) =>
                    OuterMinute[Minute] >= InnerMinute[Minute Min] 
                        and OuterMinute[Minute] <= InnerMinute[Minute Max]
            ), 
        type table [
            Minute Min = Int64.Type, 
            Minute Max = Int64.Type, 
            #"30 Minute Period Name" = text, 
            #"30 Minute Bin" = text, 
            #"30 Minute Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedThirtyMinutePeriod = Table.ExpandTableColumn (
        AdddedThirtyMinutePeriod, 
        "ThirtyMinutePeriod", 
        { "30 Minute Period Name", "30 Minute Bin", "30 Minute Bin Sort" }, 
        { "30 Minute Period Name", "30 Minute Bin", "30 Minute Bin Sort" }
    ), 
    AddedTenMinutePeriod = Table.AddColumn (
        ExpandedThirtyMinutePeriod, 
        "TenMinutePeriod", 
        ( OuterMinute ) =>
            Table.SelectRows (
                TenMinutePeriod, 
                ( InnerMinute ) =>
                    OuterMinute[Minute] >= InnerMinute[Minute Min] 
                        and OuterMinute[Minute] <= InnerMinute[Minute Max]
            ), 
        type table [
            Minute Min = Int64.Type, 
            Minute Max = Int64.Type, 
            #"10 Minute Period Name" = text, 
            #"10 Minute Bin" = text, 
            #"10 Minute Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedTenMinutePeriod = Table.ExpandTableColumn (
        AddedTenMinutePeriod, 
        "TenMinutePeriod", 
        { "10 Minute Period Name", "10 Minute Bin", "10 Minute Bin Sort" }, 
        { "10 Minute Period Name", "10 Minute Bin", "10 Minute Bin Sort" }
    ), 
    AddedFiveMinutePeriod = Table.AddColumn (
        ExpandedTenMinutePeriod, 
        "FiveMinutePeriod", 
        ( OuterMinute ) =>
            Table.SelectRows (
                FiveMinutePeriod, 
                ( InnerMinute ) =>
                    OuterMinute[Minute] >= InnerMinute[Minute Min] 
                        and OuterMinute[Minute] <= InnerMinute[Minute Max]
            ), 
        type table [
            Minute Min = Int64.Type, 
            Minute Max = Int64.Type, 
            #"5 Minute Period Name" = text, 
            #"5 Minute Bin" = text, 
            #"5 Minute Bin Sort" = Int64.Type
        ]
    ), 
    ExpandedFiveMinutePeriod = Table.ExpandTableColumn (
        AddedFiveMinutePeriod, 
        "FiveMinutePeriod", 
        { "5 Minute Period Name", "5 Minute Bin", "5 Minute Bin Sort" }, 
        { "5 Minute Period Name", "5 Minute Bin", "5 Minute Bin Sort" }
    )
in
    ExpandedFiveMinutePeriod
