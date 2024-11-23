let
    #"SET 445 Start Month" = 7,
    #"SET Day of Week Start" = Day.Monday,
    #"SET Starting Year" = 2012,
    #"SET Years Forward to Include" = 2,
    #"CREATE List of Years" = { 
    #"SET Starting Year" 
	.. 
	( Date.Year(DateTime.FixedLocalNow() ) + #"SET Years Forward to Include" ) 
  },
    #"CONVERT to table" = Table.FromList(#"CREATE List of Years", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"SET TYPE to number" = Table.TransformColumnTypes(#"CONVERT to table",{{"Column1", Int64.Type}}),
    #"RENAME col Year" = Table.RenameColumns(#"SET TYPE to number",{{"Column1", "Year"}}),
    #"ADD fy Start Date" = Table.AddColumn(#"RENAME col Year", "FyStart", each #date( [Year], #"SET 445 Start Month", 1 )),
    #"ADD 445 Start Date" = Table.AddColumn(#"ADD fy Start Date", "445.Start", each Date.StartOfWeek( [FyStart], Day.Monday )),
    #"KEEP ONLY 445 Start Date" = Table.SelectColumns(#"ADD 445 Start Date",{"445.Start"}),
    #"ADD previous year end" = Table.AddColumn(#"KEEP ONLY 445 Start Date", "445.PyEnd", each [445.Start] - Duration.From(1)),
    #"ADD this row num" = Table.AddIndexColumn(#"ADD previous year end", "ThisRow", 1, 1),
    #"ADD previous row num" = Table.AddIndexColumn(#"ADD this row num", "PrevRow", 0, 1),
    #"SELFJOIN w previous row" = Table.NestedJoin(#"ADD previous row num",{"ThisRow"},#"ADD previous row num",{"PrevRow"},"NewColumn",JoinKind.Inner),
    #"KEEP ONLY 445 start and join" = Table.SelectColumns(#"SELFJOIN w previous row",{"445.Start", "NewColumn"}),
    #"EXPAND 445.pyend" = Table.ExpandTableColumn(#"KEEP ONLY 445 start and join", "NewColumn", {"445.PyEnd"}, {"445.PyEnd"}),
    #"RENAME to 445.End" = Table.RenameColumns(#"EXPAND 445.pyend",{{"445.PyEnd", "445.End"}}),
    #"ADD 445 Year" = Table.AddColumn(#"RENAME to 445.End", "445.Year", each Date.Year([445.End]), type number),
    #"ADD Days in Year" = Table.AddColumn(#"ADD 445 Year", "DaysInYear", each Number.From( [445.End] - [445.Start] ) + 1),
    #"ADD Day of 445" = Table.AddColumn(#"ADD Days in Year", "DayOf445", each {1 .. [DaysInYear] }),
    #"EXPAND Day of 445" = Table.ExpandListColumn(#"ADD Day of 445", "DayOf445"),
    #"SET TYPE dayof445 to number" = Table.TransformColumnTypes(#"EXPAND Day of 445",{{"DayOf445", Int64.Type}}),
    #"ADD Date" = Table.AddColumn(#"SET TYPE dayof445 to number", "Date", each [445.Start] + Duration.From( [DayOf445] - 1 )),
    #"KEEP ONLY Date DayOf445 Year" = Table.SelectColumns(#"ADD Date",{"Date", "DayOf445", "445.Year"}),
    #"--Create Template--" = #"KEEP ONLY Date DayOf445 Year",

    #"GET Periods" = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45WMlGK1YGRpkhs4kXMlGJjAQ==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [WeeksInPeriod = _t]),
    #"SET col type to number" = Table.TransformColumnTypes(#"GET Periods",{{"WeeksInPeriod", Int64.Type}}),
    #"ADD Period number" = Table.AddIndexColumn(#"SET col type to number", "Period", 1, 1),
    #"ADD Quarter" = Table.AddColumn(#"ADD Period number", "Qtr", each Number.RoundUp( [Period]/3 )),
    #"REORDER cols" = Table.ReorderColumns(#"ADD Quarter",{"Period", "Qtr", "WeeksInPeriod"}),
    #"ADD WeekOfPeriod" = Table.AddColumn(#"REORDER cols", "WeekOfPeriod", each { 1 .. [WeeksInPeriod] }),
    #"EXPAND WeekOfPeriod row=week" = Table.ExpandListColumn(#"ADD WeekOfPeriod", "WeekOfPeriod"),
    #"ADD WeekOf445" = Table.AddIndexColumn(#"EXPAND WeekOfPeriod row=week", "WeekOf445", 1, 1),
    #"ADD DayOfWeek" = Table.AddColumn(#"ADD WeekOf445", "DayOfWeek", each { 1 .. 7 }),
    #"EXPAND DayOfWeek row=day" = Table.ExpandListColumn(#"ADD DayOfWeek", "DayOfWeek"),
    #"ADD DayOf445" = Table.AddIndexColumn(#"EXPAND DayOfWeek row=day", "DayOf445", 1, 1),
    #"ADD PeriodLabel" = Table.AddColumn(#"ADD DayOf445", "PeriodLabel", each "P-"&Text.PadStart(Text.From( [Period] ), 2, "0") ),
    #"ADD Quarter Label" = Table.AddColumn(#"ADD PeriodLabel", "QuarterLabel", each "Q-" & Text.From([Qtr]), type text),
    #"SET col types" = Table.TransformColumnTypes(#"ADD Quarter Label",{{"PeriodLabel", type text}, {"Qtr", type number}, {"WeekOfPeriod", type number}, {"DayOfWeek", type number}}),
    #"REORDER columns" = Table.ReorderColumns(#"SET col types",{"DayOf445", "Period", "PeriodLabel", "Qtr", "QuarterLabel", "WeeksInPeriod", "WeekOfPeriod", "WeekOf445", "DayOfWeek"}),
    TEMPLATE = #"REORDER columns",

    #"LEFTJOIN w Template" = Table.NestedJoin(#"KEEP ONLY Date DayOf445 Year",{"DayOf445"},TEMPLATE,{"DayOf445"},"445",JoinKind.LeftOuter),
    #"EXPAND 445" = Table.ExpandTableColumn(#"LEFTJOIN w Template", "445", {"Period", "PeriodLabel", "Qtr", "QuarterLabel", "WeeksInPeriod", "WeekOfPeriod", "WeekOf445", "DayOfWeek"}, {"445.Period", "445.PeriodLabel", "445.Qtr", "445.QuarterLabel", "445.WeeksInPeriod", "445.WeekOfPeriod", "445.WeekOf445", "445.DayOfWeek"})
in
    #"EXPAND 445"