let
    easternDate = (EasterYear as number) as date =>
        let
            FirstDig = Number.RoundDown(EasterYear / 100),
            Remain19 = Number.Mod(EasterYear, 19),
            Temp1 = Number.Mod(Number.RoundDown((FirstDig - 15) / 2) + 202 - 11 * Remain19, 30),
            tA = Temp1 + 21 + (if (Temp1 = 29) or ((Temp1 = 28) and (Remain19 > 10)) then -1 else 0),
            tB = Number.Mod(tA - 19, 7),
            tCpre = Number.Mod(40 - FirstDig, 4),
            tC = tCpre + (if tCpre = 3 then 1 else 0) + (if tCpre > 1 then 1 else 0),
            Temp2 = Number.Mod(EasterYear, 100),
            tD = Number.Mod(Temp2 + Number.RoundDown(Temp2 / 4), 7),
            tE = Number.Mod(20 - tB - tC - tD, 7) + 1,
            d = tA + tE,
            EasterDay = if d > 31 then d - 31 else d,
            EasterMonth = if d > 31 then 4 else 3,
            Result = #date(EasterYear, EasterMonth, EasterDay)
        in
            Result,
    output = (start_date as date, end_date as date, list_of_holidays as list) as table =>
        let
            tb = #table(
                type table [
                    Date = date,
                    Day = Int64.Type,
                    Month = Int64.Type,
                    MonthName = text,
                    Year = Int64.Type,
                    Quarter = Int64.Type,
                    DayOfWeek = Int64.Type,
                    DayOfWeekName = text,
                    IsWeekend = logical,
                    IsEastern = logical,
                    Holidays = logical,
                    HolidayOrWeekend = logical,
                    EndDayOfMonth = Int64.Type,
                    isToday = logical,
                    isCurrentMonth = logical
                ],
                List.Transform(
                    List.Dates(start_date, Duration.Days(end_date-start_date), #duration(1, 0, 0, 0)),
                    each
                        let
                            dt = _,
                            day = Date.Day(dt),
                            month = Date.Month(dt),
                            monthName = Date.ToText(dt, "MMMM", "en-us"),
                            year = Date.Year(dt),
                            quarter = Date.QuarterOfYear(dt),
                            dayOfWeek = Date.DayOfWeek(dt, Day.Monday) + 1,
                            dayOfWeekName = Date.DayOfWeekName(dt, "en-us"),
                            isWeekend = if dayOfWeek > 5 then true else false,
                            isEastern = if easternDate(year) = dt then true else false,
                            holidays = if List.Contains(list_of_holidays, Date.ToText(dt, "dd.MM")) then true else false,
                            nonWorkingDay = if isWeekend or holidays or isEastern then true else false,
                            enddayofmonth = Date.Day(Date.EndOfMonth(dt)),
                            isToday = Date.IsInCurrentDay(dt),
                            isCurrentMonth = Date.IsInCurrentMonth(dt),
                            result = {
                                dt,
                                day,
                                month,
                                monthName,
                                year,
                                quarter,
                                dayOfWeek,
                                dayOfWeekName,
                                isWeekend,
                                isEastern,
                                holidays,
                                nonWorkingDay,
                                enddayofmonth,
                                isToday,
                                isCurrentMonth
                            }
                        in
                            result
                )
            )
        in
            tb,
    documentation = [
        Documentation.Name = " Create-dateKey_newVersion.pq ",
        Documentation.Description = " Funcion is creating DateKey table. ",
        Documentation.Source = " https://www.datameerkat.com . ",
        Documentation.Version = " 2.0 ",
        Documentation.Author = " Štěpán Rešl "
    ]
in
    Value.ReplaceType(output, Value.ReplaceMetadata(Value.Type(output), documentation))
