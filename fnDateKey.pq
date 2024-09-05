// Short function to generate Date Key from Date
(Date as date) as number =>
    Date.Year(Date) * 10000 + Date.Month(Date) * 100 + Date.Day(Date)
