/*
Created by: Reid Havens
Co-Founder - Analytic Endeavors
www.analyticendeavors.com
reid.havens@analyticendeavors.com
*/

(CalendarStartDate as date, CalendarEndDate as date, FiscalYearEndDate as date) =>
let
    TodayDate    = Date.From(DateTime.FixedLocalNow()),
    TodayYear    = Date.Year(TodayDate),
    TodayMonth   = Date.Month(TodayDate),
    TodayQuarter = Number.RoundUp(TodayMonth / 3),

    ListDates = List.Dates(CalendarStartDate,
                           Number.From(CalendarEndDate - CalendarStartDate) + 1,
                           #duration(1,0,0,0)),
    
    #"Converted to Table" = Table.FromList(ListDates, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns"    = Table.RenameColumns(#"Converted to Table",{{"Column1", "Date"}}),
    #"Changed to Date"    = Table.TransformColumnTypes(#"Renamed Columns",{{"Date", type date}}),

    // ============================================
    // YEAR COLUMNS
    // ============================================
    
    // Year: Gregorian year number (e.g., 2025)
    #"Added Year" = Table.AddColumn(#"Changed to Date", "Year", each Date.Year([Date]), Int64.Type),

    // Year Short: last two digits of year (e.g., '25')
    #"Added Year Short" = Table.AddColumn(#"Added Year", "Year Short", 
        each Text.End(Text.From(Date.Year([Date]), "en-US"), 2), type text),

    // ============================================
    // QUARTER COLUMNS (Calendar)
    // ============================================
    
    // Start of Quarter: first day of the quarter (date key for quarter grain)
    #"Added Start of Quarter" = Table.AddColumn(#"Added Year Short", "Start of Quarter", 
        each Date.StartOfQuarter([Date]), type date),

    // Quarter Num: 1–4 quarter index
    #"Added Quarter Num" = Table.AddColumn(#"Added Start of Quarter", "Quarter Num", 
        each Date.QuarterOfYear([Date]), Int64.Type),

    // Quarter: label "Q#" (e.g., Q2)
    #"Added Quarter" = Table.AddColumn(#"Added Quarter Num", "Quarter", 
        each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),

    // Quarter Year: label "Q# 'YY" (e.g., Q2 '25)
    #"Added Quarter Year" = Table.AddColumn(#"Added Quarter", "Quarter Year", 
        each "Q" & Text.From(Date.QuarterOfYear([Date])) & " '" & Text.End(Text.From(Date.Year([Date])), 2), type text),

    // ============================================
    // MONTH COLUMNS (Calendar)
    // ============================================
    
    // Month Year: first day of the month (date key for month grain, format in model as "MMM YYYY")
    #"Added Month Year" = Table.AddColumn(#"Added Quarter Year", "Month Year", 
        each Date.StartOfMonth([Date]), type date),

    // Month Num: 1–12 month index
    #"Added Month Num" = Table.AddColumn(#"Added Month Year", "Month Num", 
        each Date.Month([Date]), Int64.Type),

    // Month: full month name (e.g., March)
    #"Added Month" = Table.AddColumn(#"Added Month Num", "Month", 
        each Date.MonthName([Date]), type text),

    // Month Short: 3-letter month (e.g., Mar)
    #"Added Month Short" = Table.AddColumn(#"Added Month", "Month Short", 
        each Text.Start(Date.MonthName([Date]), 3), type text),
    // Month of Quarter Num: 1–3 position within quarter
    #"Added Month of Quarter Num" = Table.AddColumn(#"Added Month Short", "Month of Quarter Num", each let q = Date.QuarterOfYear([Date]), m = Date.Month([Date]) in m - ((q - 1) * 3), Int64.Type),
    // Position of the month within its quarter (1-3)
    #"Added Month of Quarter" = Table.AddColumn(#"Added Month of Quarter Num", "Month of Quarter", each "QM" & Text.From(let q = Date.QuarterOfYear([Date]), m = Date.Month([Date]) in m - ((q - 1) * 3)), type text),

    // ============================================
    // WEEK COLUMNS (Calendar - ISO)
    // ============================================
    
    // Week Start: Monday of the current ISO week (primary key for week grain)
    #"Added Week Start" = Table.AddColumn(#"Added Month of Quarter", "Week Start", 
        each Date.StartOfWeek([Date], Day.Monday), type date),

    // ISO Year: the ISO week's year (dates near New Year may belong to prev/next ISO year)
    #"Added ISO Year" = Table.AddColumn(#"Added Week Start", "ISO Year",
        each Date.Year(Date.AddDays(Date.StartOfWeek([Date], Day.Monday), 3)), Int64.Type),

    // ISO Week Num: 1–52/53 number of the ISO week
    #"Added ISO Week Num" = Table.AddColumn(#"Added ISO Year", "ISO Week Num",
        each let
            ws = Date.StartOfWeek([Date], Day.Monday),
            isoYear = Date.Year(Date.AddDays(ws, 3)),
            isoYearStart = Date.StartOfWeek(#date(isoYear, 1, 4), Day.Monday)
        in Number.IntegerDivide(Duration.Days(ws - isoYearStart), 7) + 1
    , Int64.Type),

    // Week of Year: label "W##" for ISO Week Num (e.g., W10)
    #"Added Week" = Table.AddColumn(#"Added ISO Week Num", "Week",
        each "W" & Text.PadStart(Text.From(
                let
                    ws = Date.StartOfWeek([Date], Day.Monday),
                    isoYear = Date.Year(Date.AddDays(ws, 3)),
                    isoYearStart = Date.StartOfWeek(#date(isoYear, 1, 4), Day.Monday)
                in Number.IntegerDivide(Duration.Days(ws - isoYearStart), 7) + 1
            ), 2, "0"), type text),

    // Week: label "W## 'YY" combining ISO week and ISO year (e.g., W01 '25)
    #"Added Week Year" = Table.AddColumn(#"Added Week", "Week Year",
        each let
            ws = Date.StartOfWeek([Date], Day.Monday),
            isoYear = Date.Year(Date.AddDays(ws, 3)),
            isoYearStart = Date.StartOfWeek(#date(isoYear, 1, 4), Day.Monday),
            w = Number.IntegerDivide(Duration.Days(ws - isoYearStart), 7) + 1
        in "W" & Text.PadStart(Text.From(w), 2, "0") & " '" & Text.End(Text.From(isoYear), 2)
    , type text),

    // Week of Month Num: 1–6 Monday-aligned weeks within the month
    #"Added Week of Month Num" = Table.AddColumn(#"Added Week Year", "Week of Month Num",
        each let
            ws = Date.StartOfWeek([Date], Day.Monday),
            monthStartAligned = Date.StartOfWeek(Date.StartOfMonth([Date]), Day.Monday)
        in Number.IntegerDivide(Duration.Days(ws - monthStartAligned), 7) + 1
    , Int64.Type),

    // Week of Month: label "MW#" (e.g., MW3)
    #"Added Week of Month" = Table.AddColumn(#"Added Week of Month Num", "Week of Month", 
        each "MW" & Text.From(
            let
                ws = Date.StartOfWeek([Date], Day.Monday),
                monthStartAligned = Date.StartOfWeek(Date.StartOfMonth([Date]), Day.Monday)
            in Number.IntegerDivide(Duration.Days(ws - monthStartAligned), 7) + 1
        ), type text),

    // Week of Quarter Num: 1–13 Monday-aligned weeks from quarter start
    #"Added Week of Quarter Num" = Table.AddColumn(#"Added Week of Month", "Week of Quarter Num",
        each let
            ws = Date.StartOfWeek([Date], Day.Monday),
            qStart = Date.StartOfQuarter([Date]),
            qStartAligned = Date.StartOfWeek(qStart, Day.Monday)
        in Number.IntegerDivide(Duration.Days(ws - qStartAligned), 7) + 1
    , Int64.Type),

    // Week of Quarter: label "QW#" (e.g., QW7)
    #"Added Week of Quarter" = Table.AddColumn(#"Added Week of Quarter Num", "Week of Quarter",
        each "QW" & Text.From(
            let
                ws = Date.StartOfWeek([Date], Day.Monday),
                qStart = Date.StartOfQuarter([Date]),
                qStartAligned = Date.StartOfWeek(qStart, Day.Monday)
            in Number.IntegerDivide(Duration.Days(ws - qStartAligned), 7) + 1
        ), type text),

    // ============================================
    // DAY COLUMNS (Calendar)
    // ============================================
    
    // Day: day number within month (1–31)
    #"Added Day of Month" = Table.AddColumn(#"Added Week of Quarter", "Day of Month", 
        each Date.Day([Date]), Int64.Type),

    // Day of Week: weekday name (e.g., Wednesday)
    #"Added Day of Week" = Table.AddColumn(#"Added Day of Month", "Day of Week", 
        each Date.DayOfWeekName([Date]), type text),

    // Day of Week Short: 3-letter weekday (e.g., Wed)
    #"Added Day of Week Short" = Table.AddColumn(#"Added Day of Week", "Day of Week Short", 
        each Text.Start(Date.DayOfWeekName([Date]), 3), type text),

    // Day of Week Num: index of weekday (Sunday=0, Monday=1, etc.)
    #"Added Day of Week Num" = Table.AddColumn(#"Added Day of Week Short", "Day of Week Num", 
        each Date.DayOfWeek([Date], Day.Sunday), Int64.Type),

    // Day of Quarter: 1–92 within the quarter
    #"Added Day of Quarter" = Table.AddColumn(#"Added Day of Week Num", "Day of Quarter",
        each Duration.Days([Date] - Date.StartOfQuarter([Date])) + 1, Int64.Type),

    // Day of Year: 1–365/366 within the year
    #"Added Day of Year" = Table.AddColumn(#"Added Day of Quarter", "Day of Year", 
        each Date.DayOfYear([Date]), Int64.Type),
    // Days since the start of the ISO year (ISO year starts on Monday of week 1)
    #"Added ISO Day of Year" = Table.AddColumn(#"Added Day of Year", "ISO Day of Year", each let isoYear = Date.Year(Date.AddDays(Date.StartOfWeek([Date], Day.Monday), 3)), isoYearStart = Date.StartOfWeek(#date(isoYear, 1, 4), Day.Monday) in Duration.Days([Date] - isoYearStart) + 1, Int64.Type),

    // Weekend Flag: TRUE for Saturday/Sunday
    #"Added Weekend Flag" = Table.AddColumn(#"Added ISO Day of Year", "Weekend Flag", 
        each Logical.From(if Date.DayOfWeek([Date]) = 6 or Date.DayOfWeek([Date]) = 0 then 1 else 0), type logical),

    // ============================================
    // FISCAL YEAR COLUMNS
    // ============================================
    
    // Fiscal Year Num: fiscal year as number (e.g., 2025)
    #"Added Fiscal Year Num" = Table.AddColumn(#"Added Weekend Flag", "Fiscal Year Num",
        each let 
            y = Date.Year([Date]), 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate)
        in if m > em then y + 1 else y, Int64.Type),

    // Fiscal Year: label "FYyy" (e.g., FY25)
    #"Added Fiscal Year" = Table.AddColumn(#"Added Fiscal Year Num", "Fiscal Year",
        each let 
            y = Date.Year([Date]), 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate),
            fy = if m > em then y + 1 else y
        in "FY" & Text.End(Text.From(fy), 2), type text),

    // ============================================
    // FISCAL QUARTER COLUMNS
    // ============================================
    
    // Fiscal Quarter Num: 1–4 based on fiscal month position
    #"Added Fiscal Quarter Num" = Table.AddColumn(#"Added Fiscal Year", "Fiscal Quarter Num",
        each let 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate),
            adj = if m > em then m - em else m + (12 - em)
        in Number.RoundUp(adj / 3, 0), Int64.Type),

    // Fiscal Quarter: label "FQ#" (e.g., FQ3)
    #"Added Fiscal Quarter" = Table.AddColumn(#"Added Fiscal Quarter Num", "Fiscal Quarter",
        each let 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate),
            adj = if m > em then m - em else m + (12 - em)
        in "FQ" & Text.From(Number.RoundUp(adj / 3, 0)), type text),

    // Fiscal Quarter Year: label "Q# FYyy" (e.g., Q3 FY25)
    #"Added Fiscal Quarter Year" = Table.AddColumn(#"Added Fiscal Quarter", "Fiscal Quarter Year",
        each let 
            y = Date.Year([Date]), 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate),
            q = Number.RoundUp((if m > em then m - em else m + (12 - em)) / 3, 0),
            fy = if m > em then y + 1 else y
        in "Q" & Text.From(q) & " FY" & Text.End(Text.From(fy), 2), type text),

    // ============================================
    // FISCAL MONTH COLUMNS
    // ============================================
    
    // Fiscal Month Num: 1–12 relative to fiscal year (FY starts month after FY End)
    #"Added Fiscal Month Num" = Table.AddColumn(#"Added Fiscal Quarter Year", "Fiscal Month Num",
        each let 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate)
        in if m > em then m - em else m + (12 - em), Int64.Type),

    // Fiscal Month: full Gregorian month name (e.g., March)
    #"Added Fiscal Month" = Table.AddColumn(#"Added Fiscal Month Num", "Fiscal Month",
        each Date.MonthName([Date]), type text),

    // Fiscal Month Short: 3-letter Gregorian month (e.g., Mar)
    #"Added Fiscal Month Short" = Table.AddColumn(#"Added Fiscal Month", "Fiscal Month Short",
        each Text.Start(Date.MonthName([Date]), 3), type text),
    // Month position within the quarter (1-3)
    #"Added Fiscal Month of Quarter Num" = Table.AddColumn(#"Added Fiscal Month Short", "Fiscal Month of Quarter Num", each let fq = Number.RoundUp((if Date.Month([Date]) > Date.Month(FiscalYearEndDate) then Date.Month([Date]) - Date.Month(FiscalYearEndDate) else Date.Month([Date]) + (12 - Date.Month(FiscalYearEndDate))) / 3, 0), fm = if Date.Month([Date]) > Date.Month(FiscalYearEndDate) then Date.Month([Date]) - Date.Month(FiscalYearEndDate) else Date.Month([Date]) + (12 - Date.Month(FiscalYearEndDate)) in fm - ((fq - 1) * 3), Int64.Type),
    // Month position within the quarter as label (QM1-QM3)
    #"Added Fiscal Month of Quarter" = Table.AddColumn(#"Added Fiscal Month of Quarter Num", "Fiscal Month of Quarter", each "FQM" & Text.From(let fq = Number.RoundUp((if Date.Month([Date]) > Date.Month(FiscalYearEndDate) then Date.Month([Date]) - Date.Month(FiscalYearEndDate) else Date.Month([Date]) + (12 - Date.Month(FiscalYearEndDate))) / 3, 0), fm = if Date.Month([Date]) > Date.Month(FiscalYearEndDate) then Date.Month([Date]) - Date.Month(FiscalYearEndDate) else Date.Month([Date]) + (12 - Date.Month(FiscalYearEndDate)) in fm - ((fq - 1) * 3)), type text),

    // ============================================
    // FISCAL WEEK COLUMNS
    // ============================================
    
    // Fiscal Week Num: 1–52/53 Monday-aligned weeks since fiscal year start
    #"Added Fiscal Week Num" = Table.AddColumn(#"Added Fiscal Month of Quarter", "Fiscal Week Num",
        each let
            em = Date.Month(FiscalYearEndDate),
            y  = Date.Year([Date]),
            m  = Date.Month([Date]),
            fyStartBase = if m > em then #date(y, em, 1) else #date(y - 1, em, 1),
            fyStart = Date.StartOfWeek(Date.AddMonths(fyStartBase, 1), Day.Monday),
            ws = Date.StartOfWeek([Date], Day.Monday)
        in Number.IntegerDivide(Duration.Days(ws - fyStart), 7) + 1
    , Int64.Type),

    // Fiscal Week: label "FW##" (e.g., FW32)
    #"Added Fiscal Week" = Table.AddColumn(#"Added Fiscal Week Num", "Fiscal Week",
        each "FW" & Text.PadStart(Text.From(
            let
                em = Date.Month(FiscalYearEndDate),
                y  = Date.Year([Date]),
                m  = Date.Month([Date]),
                fyStartBase = if m > em then #date(y, em, 1) else #date(y - 1, em, 1),
                fyStart = Date.StartOfWeek(Date.AddMonths(fyStartBase, 1), Day.Monday),
                ws = Date.StartOfWeek([Date], Day.Monday)
            in Number.IntegerDivide(Duration.Days(ws - fyStart), 7) + 1
        ), 2, "0"), type text),

    // Fiscal Week of Quarter Num: 1–13 Monday-aligned weeks since fiscal quarter start
    #"Added Fiscal Week of Quarter Num" = Table.AddColumn(#"Added Fiscal Week", "Fiscal Week of Quarter Num",
        each let
            em = Date.Month(FiscalYearEndDate),
            y  = Date.Year([Date]),
            m  = Date.Month([Date]),
            fyStartBase = if m > em then #date(y, em, 1) else #date(y - 1, em, 1),
            fyStart = Date.AddMonths(fyStartBase, 1),
            monthsFromStart = if m > em then m - em else m + (12 - em),
            qIndex = Number.IntegerDivide(monthsFromStart - 1, 3),
            fqStart = Date.StartOfWeek(Date.AddMonths(fyStart, qIndex * 3), Day.Monday),
            ws = Date.StartOfWeek([Date], Day.Monday)
        in Number.IntegerDivide(Duration.Days(ws - fqStart), 7) + 1
    , Int64.Type),

    // Fiscal Week of Quarter: label "FQW#" (e.g., FQW6)
    #"Added Fiscal Week of Quarter" = Table.AddColumn(#"Added Fiscal Week of Quarter Num", "Fiscal Week of Quarter",
        each "FQW" & Text.From(
            let
                em = Date.Month(FiscalYearEndDate),
                y  = Date.Year([Date]),
                m  = Date.Month([Date]),
                fyStartBase = if m > em then #date(y, em, 1) else #date(y - 1, em, 1),
                fyStart = Date.AddMonths(fyStartBase, 1),
                monthsFromStart = if m > em then m - em else m + (12 - em),
                qIndex = Number.IntegerDivide(monthsFromStart - 1, 3),
                fqStart = Date.StartOfWeek(Date.AddMonths(fyStart, qIndex * 3), Day.Monday),
                ws = Date.StartOfWeek([Date], Day.Monday)
            in Number.IntegerDivide(Duration.Days(ws - fqStart), 7) + 1
        ), type text),

    // ============================================
    // FISCAL DAY COLUMNS
    // ============================================
    
    // Fiscal Day of Quarter: 1–92 since fiscal quarter start
    #"Added Fiscal Day of Quarter" = Table.AddColumn(#"Added Fiscal Week of Quarter", "Fiscal Day of Quarter",
        each let
            em = Date.Month(FiscalYearEndDate),
            y  = Date.Year([Date]),
            m  = Date.Month([Date]),
            fyStartBase = if m > em then #date(y, em, 1) else #date(y - 1, em, 1),
            fyStart = Date.AddMonths(fyStartBase, 1),
            monthsFromStart = if m > em then m - em else m + (12 - em),
            qIndex = Number.IntegerDivide(monthsFromStart - 1, 3),
            fqStart = Date.AddMonths(fyStart, qIndex * 3)
        in Duration.Days([Date] - fqStart) + 1
    , Int64.Type),

    // Fiscal Day of Year: 1–365/366 since fiscal year start
    #"Added Fiscal Day of Year" = Table.AddColumn(#"Added Fiscal Day of Quarter", "Fiscal Day of Year",
        each let
            em = Date.Month(FiscalYearEndDate),
            y  = Date.Year([Date]),
            m  = Date.Month([Date]),
            fyStartBase = if m > em then #date(y, em, 1) else #date(y - 1, em, 1),
            fyStart = Date.AddMonths(fyStartBase, 1)
        in Duration.Days([Date] - fyStart) + 1
    , Int64.Type),

    // ============================================
    // OFFSET COLUMNS - CALENDAR (Relative to Today)
    // ============================================
    
    // Day Offset: days from Today (0=today, negative=past, positive=future)
    #"Added Day Offset" = Table.AddColumn(#"Added Fiscal Day of Year", "Day Offset", 
        each Number.From((TodayDate - [Date])) * -1, Int64.Type),

    // Week Offset: ISO weeks from Today's week (Monday aligned)
    #"Added Week Offset" = Table.AddColumn(#"Added Day Offset", "Week Offset", 
        each Number.IntegerDivide(Duration.Days(Date.StartOfWeek([Date], Day.Monday) - Date.StartOfWeek(TodayDate, Day.Monday)), 7), Int64.Type),

    // Month Offset: months from Today's month
    #"Added Month Offset" = Table.AddColumn(#"Added Week Offset", "Month Offset",
        each (Date.Year([Date]) - TodayYear) * 12 + Date.Month([Date]) - TodayMonth, Int64.Type),

    // Quarter Offset: quarters from Today's quarter
    #"Added Quarter Offset" = Table.AddColumn(#"Added Month Offset", "Quarter Offset",
        each (Date.Year([Date]) - TodayYear) * 4 + Number.RoundUp(Date.Month([Date]) / 3) - TodayQuarter, Int64.Type),

    // Year Offset: years from Today's year
    #"Added Year Offset" = Table.AddColumn(#"Added Quarter Offset", "Year Offset",
        each (TodayYear - Date.Year([Date])) * -1, Int64.Type),
    // Fiscal Day Offset: days from Today (same as calendar day offset)
    #"Added Fiscal Day Offset" = Table.AddColumn(#"Added Year Offset", "Fiscal Day Offset", 
        each Number.From((TodayDate - [Date])) * -1, Int64.Type),
    // Fiscal Week Offset: fiscal weeks from Today's week (Monday aligned, same as calendar)
    #"Added Fiscal Week Offset" = Table.AddColumn(#"Added Fiscal Day Offset", "Fiscal Week Offset", 
        each Number.IntegerDivide(Duration.Days(Date.StartOfWeek([Date], Day.Monday) - Date.StartOfWeek(TodayDate, Day.Monday)), 7), Int64.Type),
    // Fiscal Month Offset: fiscal months from Today's fiscal month
    #"Added Fiscal Month Offset" = Table.AddColumn(#"Added Fiscal Week Offset", "Fiscal Month Offset",
        each let
            m = Date.Month([Date]),
            em = Date.Month(FiscalYearEndDate),
            fyRow = if m > em then Date.Year([Date]) + 1 else Date.Year([Date]),
            fmRow = if m > em then m - em else m + (12 - em),
            fyToday = if TodayMonth > em then TodayYear + 1 else TodayYear,
            fmToday = if TodayMonth > em then TodayMonth - em else TodayMonth + (12 - em)
        in (fyRow - fyToday) * 12 + (fmRow - fmToday), Int64.Type),
    // Fiscal Quarter Offset: fiscal quarters from Today's fiscal quarter
    #"Added Fiscal Quarter Offset" = Table.AddColumn(#"Added Fiscal Month Offset", "Fiscal Quarter Offset",
        each let
            m = Date.Month([Date]),
            em = Date.Month(FiscalYearEndDate),
            fyRow = if m > em then Date.Year([Date]) + 1 else Date.Year([Date]),
            fqRow = Number.RoundUp((if m > em then m - em else m + (12 - em)) / 3, 0),
            fyToday = if TodayMonth > em then TodayYear + 1 else TodayYear,
            fqToday = Number.RoundUp((if TodayMonth > em then TodayMonth - em else TodayMonth + (12 - em)) / 3, 0)
        in (fyRow - fyToday) * 4 + (fqRow - fqToday), Int64.Type),

    // ============================================
    // OFFSET COLUMNS - FISCAL (Relative to Today)
    // ============================================

    // Fiscal Year Offset: fiscal years from Today's fiscal year
    #"Added Fiscal Year Offset" = Table.AddColumn(#"Added Fiscal Quarter Offset", "Fiscal Year Offset",
        each let 
            m = Date.Month([Date]), 
            em = Date.Month(FiscalYearEndDate),
            fyRow = if m > em then Date.Year([Date]) + 1 else Date.Year([Date]),
            fyToday = if TodayMonth > em then TodayYear + 1 else TodayYear
        in fyRow - fyToday, Int64.Type)
in
    #"Added Fiscal Year Offset"
