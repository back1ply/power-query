// Query written by Ken Puls, FCPA, FCMA, MS MVP (Excel) (www.excelguru.ca)
// Injected into this workbook via Monkey Tools at the model designer's request
// For more information, Or to purchase a copy of this add-in, visit https://monkeytools.ca
//
// Function to the return the week number based on ISO8601 standards
// based on https://en.wikipedia.org/wiki/ISO_week_date

// This function can return one of two outputs:
//    the ISO week number as a whole number (i.e. 1, 34, 52, etc...)
//    a "precise" week in the formatt yyyy-Www-d (2006-W52-7 for Sun 31 Dec 2006)

// The function takes two inputs:
//    the date for which you wish to return the ISO week number
//    an optional input of 'true' to return the 'precise' week

//  Examples ( when function saved under the name fnGetISOWeek )
//		fnGetISOWeek(#date(2006,12,31))		-->  52
//		fnGetISOWeek(#date(2006,12,31), true)	-->  2006-W52-7
//		fnGetISOWeek(#date(2007,12,31))		-->  1
//		fnGetISOWeek(#date(2007,12,31), true)	-->  2008-01-1

(
	GivenDate as date,
	optional PreciseDateFormat as nullable logical
) as any =>
let
	getWeek =
		(
			dt as date
		) =>
		let
			getWeek =
				Number.RoundDown(
					(
						Date.DayOfYear(dt) - (
							1 + Date.DayOfWeek(
								dt,
								Day.Monday
							)
						) + 10
					) / 7
				)
		in
			getWeek,

	dow =
		Date.DayOfWeek(
			GivenDate,
			Day.Monday
		) + 1,

	w =
		getWeek(GivenDate),

	y =
		Date.Year(GivenDate),

	woyPY =
		getWeek(
			#date(
				y - 1,
				12,
				28
			)
		),

	woyCY =
		getWeek(
			#date(
				y,
				12,
				28
			)
		),

	woy =
		if
			PreciseDateFormat=null or PreciseDateFormat=false
		then
			(
				if
					w < 1
				then
					woyPY
				else
					if
						w > woyCY
					then
						1
					else
						w
			)
		else
			(
				if
					w < 1
				then
					Text.From(
						y - 1
					) & "-W" & Text.From(woyPY) & "-" & Text.From(dow)
				else
					if
						w=1
					then
						Text.From(y) & "-W01-" & Text.From(dow)
					else
						if
							w > woyCY
						then
							Text.From(
								y + 1
							) & "-W01-" & Text.From(dow)
						else
							Text.From(y) & "-W" & Text.End(
								"0" & Text.From(w),
								2
							) & "-" & Text.From(dow)
			)
in
	woy
