// ft_sales
let
    Source = #date(2025,1,1),
    #"Converted to Table" = #table(1, {{Source}}),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "fk_date"}})
in
    #"Renamed Columns"

// Query1
let
    // ============================================================
    // PARAMETERS (edit here)
    // ============================================================
    // ➜ Adjust the source to determine the date range (min and max)
    MinDate = List.Min(ft_sales[fk_date]),
    MaxDate = List.Max(ft_sales[fk_date]),

    // ➜ Month in which the Fiscal Year starts (1=Jan ... 12=Dec). Example: 7 = July
    FiscalStartMonth = 7,

    // ➜ Start of the week (use Day.Monday for ISO/US/BR standards)
    StartOfWeek = Day.Monday,

    // ➜ Activate 4-4-5 calendar fields (retail)
    Use445 = true,

    // ➜ “Padding” years before/after the actual date range
    PadYearsBefore = 1,
    PadYearsAfter  = 1,

    // ============================================================
    // HELPER FUNCTIONS (do not edit)
    // ============================================================
    FiscalYearStart = (d as date) as date =>
        let
            baseYear = if Date.Month(d) < FiscalStartMonth then Date.Year(d) - 1 else Date.Year(d),
            start    = #date(baseYear, FiscalStartMonth, 1),
            aligned  = Date.StartOfWeek(start, Day.Monday)
        in aligned,

    ISOKey = (y as number, w as number) as number => y * 100 + w,

    Map445 = (wk as number) as number =>
        if wk <= 4 then 1 else
        if wk <= 8 then 2 else
        if wk <= 13 then 3 else
        if wk <= 17 then 4 else
        if wk <= 21 then 5 else
        if wk <= 26 then 6 else
        if wk <= 30 then 7 else
        if wk <= 34 then 8 else
        if wk <= 39 then 9 else
        if wk <= 43 then 10 else
        if wk <= 47 then 11 else
        if wk <= 52 then 12 else 12,

    // ============================================================
    // DATE RANGE
    // ============================================================
    PaddedStart = Date.StartOfYear(Date.AddYears(MinDate, -PadYearsBefore)),
    PaddedEnd   = Date.EndOfYear(Date.AddYears(MaxDate, PadYearsAfter)),
    DaysCount   = Duration.Days(PaddedEnd - PaddedStart) + 1,
    ListDates   = List.Buffer(List.Dates(PaddedStart, DaysCount, #duration(1,0,0,0))),
    Base        = Table.FromList(ListDates, Splitter.SplitByNothing(), {"date"}, null, ExtraValues.Error),
    BaseTyped   = Table.TransformColumnTypes(Base, {{"date", type date}}),

    // ============================================================
    // GREGORIAN (CIVIL) CALENDAR
    // ============================================================
    Add_year              = Table.AddColumn(BaseTyped, "year", each Date.Year([date]), Int64.Type),
    Add_month_num         = Table.AddColumn(Add_year, "month_num", each Date.Month([date]), Int64.Type),
    Add_month_name        = Table.AddColumn(Add_month_num, "month_name", each Text.Proper(Date.MonthName([date])), type text),
    Add_month_abbr        = Table.AddColumn(Add_month_name, "month", each Text.Proper(Text.Start(Date.MonthName([date]), 3)), type text),
    Add_year_month_int    = Table.AddColumn(Add_month_abbr, "year_month_int", each [year]*100 + [month_num], Int64.Type),
    Add_year_month_txt    = Table.AddColumn(Add_year_month_int, "year_month_txt", each Text.From([year]) & "-" & Text.PadStart(Text.From([month_num]),2,"0"), type text),
    Add_month_year        = Table.AddColumn(Add_year_month_txt, "month_year", each [month] & "-" & Text.End(Text.From([year]), 2), type text),
    Add_start_of_month    = Table.AddColumn(Add_month_year, "start_of_month", each Date.StartOfMonth([date]), type date),
    Add_quarter_num       = Table.AddColumn(Add_start_of_month, "quarter_num", each Date.QuarterOfYear([date]), Int64.Type),
    Add_quarter_abbr      = Table.AddColumn(Add_quarter_num, "quarter_abbr", each "Q" & Text.From([quarter_num]), type text),
    Add_year_quarter_int  = Table.AddColumn(Add_quarter_abbr, "year_quarter_int", each [year]*10 + [quarter_num], Int64.Type),
    Add_year_quarter_txt  = Table.AddColumn(Add_year_quarter_int, "year_quarter_txt", each Text.From([year]) & "-Q" & Text.From([quarter_num]), type text),
    Add_bimester_num      = Table.AddColumn(Add_year_quarter_txt, "bimester_num", each Number.RoundUp([month_num]/2), Int64.Type),
    Add_bimester          = Table.AddColumn(Add_bimester_num, "bimester", each Text.From([bimester_num]) & "º Bim", type text),

    // --- HALF-YEAR (replaces old "semester") ---
    Add_half_year_num     = Table.AddColumn(Add_bimester, "half_year_num", each Number.RoundUp([month_num]/6), Int64.Type),
    Add_half_year         = Table.AddColumn(Add_half_year_num, "half_year", each "H" & Text.From([half_year_num]), type text),
    Add_year_half_int     = Table.AddColumn(Add_half_year, "year_half_int", each [year]*10 + [half_year_num], Int64.Type),
    Add_year_half_txt     = Table.AddColumn(Add_year_half_int, "year_half_txt", each Text.From([year]) & "-" & [half_year], type text),

    Add_week_of_month     = Table.AddColumn(Add_year_half_txt, "week_of_month", each Date.WeekOfMonth([date], StartOfWeek), Int64.Type),
    Add_day_of_week_num   = Table.AddColumn(Add_week_of_month, "day_of_week_num", each Date.DayOfWeek([date], StartOfWeek), Int64.Type),
    Add_day_name          = Table.AddColumn(Add_day_of_week_num, "day_name", each Date.DayOfWeekName([date]), type text),
    Add_is_past           = Table.AddColumn(Add_day_name, "is_past", each [date] <= MaxDate, type logical),
    Add_is_current_year   = Table.AddColumn(Add_is_past, "is_current_year", each Date.IsInCurrentYear([date]), type logical),
    Add_is_current_month  = Table.AddColumn(Add_is_current_year, "is_current_month", each Date.IsInCurrentMonth([date]), type logical),
    Add_year_label        = Table.AddColumn(Add_is_current_month, "year_label", each if [is_current_year] then "Current Year" else Text.From([year]), type text),
    Add_month_label       = Table.AddColumn(Add_year_label, "month_label", each if [is_current_year] and [is_current_month] then "Current Month" else [month_name], type text),

    // ============================================================
    // ISO WEEK
    // ============================================================
    Add_ISO_week          = Table.AddColumn(Add_month_label, "ISO_week", each Date.WeekOfYear([date], Day.Monday), Int64.Type),
    Add_start_of_week     = Table.AddColumn(Add_ISO_week, "start_of_week", each Date.StartOfWeek([date], Day.Monday), type date),
    Add_ISO_year          = Table.AddColumn(Add_start_of_week, "ISO_year", each
                            let y=Date.Year([date]), m=Date.Month([date]), w=[ISO_week]
                            in if m=1 and w>=52 then y-1 else if m=12 and w=1 then y+1 else y, Int64.Type),
    Add_ISO_year_week     = Table.AddColumn(Add_ISO_year, "ISO_year_week", each Text.From([ISO_year]) & "-W" & Text.PadStart(Text.From([ISO_week]),2,"0"), type text),
    Add_ISO_order         = Table.AddColumn(Add_ISO_year_week, "ISO_year_week_order", each ISOKey([ISO_year],[ISO_week]), Int64.Type),

    // ============================================================
    // FISCAL CALENDAR
    // ============================================================
    Add_fiscal_year       = Table.AddColumn(Add_ISO_order, "fiscal_year", each let m=[month_num] in if m < FiscalStartMonth then [year]-1 else [year], Int64.Type),
    Add_fiscal_month_num  = Table.AddColumn(Add_fiscal_year, "fiscal_month_num", each let m=[month_num] in if m >= FiscalStartMonth then m - FiscalStartMonth + 1 else m + (12 - FiscalStartMonth + 1), Int64.Type),
    Add_fiscal_month      = Table.AddColumn(Add_fiscal_month_num, "fiscal_month", each Text.PadStart(Text.From([fiscal_month_num]),2,"0") & " - " & [month_name], type text),
    Add_fiscal_quarter_num= Table.AddColumn(Add_fiscal_month, "fiscal_quarter_num", each Number.RoundUp([fiscal_month_num]/3), Int64.Type),
    Add_fiscal_quarter    = Table.AddColumn(Add_fiscal_quarter_num, "fiscal_quarter", each "Q" & Text.From([fiscal_quarter_num]), type text),

    // --- Fiscal Half-Year ---
    Add_fiscal_half_year_num = Table.AddColumn(Add_fiscal_quarter, "fiscal_half_year_num", each Number.RoundUp([fiscal_month_num]/6), Int64.Type),
    Add_fiscal_half_year     = Table.AddColumn(Add_fiscal_half_year_num, "fiscal_half_year", each "H" & Text.From([fiscal_half_year_num]), type text),
    Add_fiscal_year_month    = Table.AddColumn(Add_fiscal_half_year, "fiscal_year_month", each [fiscal_year]*100 + [fiscal_month_num], Int64.Type),
    Add_fiscal_year_month_txt= Table.AddColumn(Add_fiscal_year_month, "fiscal_year_month_txt", each Text.From([fiscal_year]) & "-" & Text.PadStart(Text.From([fiscal_month_num]),2,"0"), type text),
    Add_fiscal_year_quarter_int = Table.AddColumn(Add_fiscal_year_month_txt, "fiscal_year_quarter_int", each [fiscal_year]*10 + [fiscal_quarter_num], Int64.Type),
    Add_fiscal_year_quarter_txt = Table.AddColumn(Add_fiscal_year_quarter_int, "fiscal_year_quarter_txt", each Text.From([fiscal_year]) & "-Q" & Text.From([fiscal_quarter_num]), type text),
    Add_fiscal_year_half_int    = Table.AddColumn(Add_fiscal_year_quarter_txt, "fiscal_year_half_int", each [fiscal_year]*10 + [fiscal_half_year_num], Int64.Type),
    Add_fiscal_year_half_txt    = Table.AddColumn(Add_fiscal_year_half_int, "fiscal_year_half_txt", each Text.From([fiscal_year]) & "-" & [fiscal_half_year], type text),

    // ============================================================
    // 4-4-5 CALENDAR (optional)
    // ============================================================
    Add_fy_week_start    = Table.AddColumn(Add_fiscal_year_half_txt, "fiscal_year_start_week", each FiscalYearStart([date]), type date),
    Add_fiscal_week_num  = Table.AddColumn(Add_fy_week_start, "fiscal_week_num", each 1 + Number.IntegerDivide(Duration.Days([date] - [fiscal_year_start_week]), 7), Int64.Type),
    Add_445_month_num    = if Use445 then Table.AddColumn(Add_fiscal_week_num, "month_445_num", each Map445([fiscal_week_num]), Int64.Type) else Add_fiscal_week_num,
    Add_445_month        = if Use445 then Table.AddColumn(Add_445_month_num, "month_445", each Text.PadStart(Text.From([month_445_num]),2,"0") & " (4-4-5)", type text) else Add_445_month_num,
    Add_445_quarter_num  = if Use445 then Table.AddColumn(Add_445_month, "quarter_445_num", each Number.RoundUp([month_445_num]/3), Int64.Type) else Add_445_month,
    Add_445_quarter      = if Use445 then Table.AddColumn(Add_445_quarter_num, "quarter_445", each "Q" & Text.From([quarter_445_num]), type text) else Add_445_quarter_num,

    // ============================================================
    // FINAL DATA TYPES
    // ============================================================
    Typed =
        Table.TransformColumnTypes(
            Add_445_quarter,
            {
                {"date", type date},
                {"year", Int64.Type}, {"month_num", Int64.Type}, {"month_name", type text}, {"month", type text},
                {"year_month_int", Int64.Type}, {"year_month_txt", type text}, {"month_year", type text}, {"start_of_month", type date},
                {"quarter_num", Int64.Type}, {"quarter_abbr", type text},
                {"year_quarter_int", Int64.Type}, {"year_quarter_txt", type text},
                {"bimester_num", Int64.Type}, {"bimester", type text},
                {"half_year_num", Int64.Type}, {"half_year", type text},
                {"year_half_int", Int64.Type}, {"year_half_txt", type text},
                {"week_of_month", Int64.Type}, {"day_of_week_num", Int64.Type}, {"day_name", type text},
                {"is_past", type logical}, {"is_current_year", type logical}, {"is_current_month", type logical},
                {"year_label", type text}, {"month_label", type text},
                {"ISO_week", Int64.Type}, {"start_of_week", type date},
                {"ISO_year", Int64.Type}, {"ISO_year_week", type text}, {"ISO_year_week_order", Int64.Type},
                {"fiscal_year", Int64.Type}, {"fiscal_month_num", Int64.Type}, {"fiscal_month", type text},
                {"fiscal_quarter_num", Int64.Type}, {"fiscal_quarter", type text},
                {"fiscal_half_year_num", Int64.Type}, {"fiscal_half_year", type text},
                {"fiscal_year_month", Int64.Type}, {"fiscal_year_month_txt", type text},
                {"fiscal_year_quarter_int", Int64.Type}, {"fiscal_year_quarter_txt", type text},
                {"fiscal_year_half_int", Int64.Type}, {"fiscal_year_half_txt", type text},
                {"fiscal_year_start_week", type date}, {"fiscal_week_num", Int64.Type},
                {"month_445_num", Int64.Type}, {"month_445", type text},
                {"quarter_445_num", Int64.Type}, {"quarter_445", type text}
            }
        ),

    Result = Table.Sort(Typed, {{"date", Order.Ascending}})
in
    Result
