let
  Source = Table.FromRecords(
    {
      [id = 1, plan_date = "2024-08-15"], 
      [id = 1, plan_date = "2024-03-10"], 
      [id = 1, plan_date = "2023-05-05"], 
      [id = 2, plan_date = "2025-02-24"], 
      [id = 2, plan_date = "2024-07-15"], 
      [id = 2, plan_date = "2024-03-15"]
    }
  ), 
  ChangedType = Table.TransformColumnTypes(Source, {{"plan_date", type date}}), 
  SortedRows = Table.Sort(ChangedType, {{"id", Order.Ascending}, {"plan_date", Order.Descending}}), 
  CurrentDate = DateTime.FixedLocalNow(), 
  CurrentYear = Date.Year(CurrentDate), 
  CurrentMonth = Date.Month(CurrentDate), 
  FinancialYearNumber = if CurrentMonth >= 4 then CurrentYear else CurrentYear - 1, 
  FinancialYearStart = #date(FinancialYearNumber, 4, 1), 
  FinancialYearEnd = #date(FinancialYearNumber + 1, 3, 31), 
  DateDiffInMonths = (date1 as date, date2 as date) as number => (Date.Year(date1) - Date.Year(date2)) * 12 + (Date.Month(date1) - Date.Month(date2)), 
  ComputeIS_LAST_SIX_MONTHS = (TablePerId) =>
    let
      IndexedTable = Table.AddIndexColumn(TablePerId, "Index", 0, 1), 
      PreviousDates = Table.AddColumn(IndexedTable, "PreviousDate", each if [Index] = 0 then null else IndexedTable{[Index] - 1}[plan_date], type date), 
      DifferenceInMonths = Table.AddColumn(PreviousDates, "DiffInMonths", each if [PreviousDate] = null then null else DateDiffInMonths([plan_date], [PreviousDate]), Int64.Type), 
      IS_LAST_SIX_MONTHS = Table.AddColumn(DifferenceInMonths, "IS_LAST_SIX_MONTHS", each if [Index] = 0 then "YES" else if [DiffInMonths] >= - 6 then "YES" else "NO"), 
      RemoveColumns = Table.RemoveColumns(IS_LAST_SIX_MONTHS, {"Index", "PreviousDate", "DiffInMonths"})
    in
      RemoveColumns, 
  AddIS_LAST_SIX_MONTHS = Table.Group(SortedRows, {"id"}, {{"AllData", each ComputeIS_LAST_SIX_MONTHS(_), type table}}), 
  ExpandedTable = Table.ExpandTableColumn(AddIS_LAST_SIX_MONTHS, "AllData", {"plan_date", "IS_LAST_SIX_MONTHS"}), 
  AddIS_CURRENT_FINANCIAL_YEAR = Table.AddColumn(ExpandedTable, "IS_CURRENT_FINANCIAL_YEAR", each if [plan_date] >= FinancialYearStart and [plan_date] <= FinancialYearEnd then "YES" else "NO"), 
  AddIS_CURRENT_YEAR = Table.AddColumn(AddIS_CURRENT_FINANCIAL_YEAR, "IS_CURRENT_YEAR", each if Date.Year([plan_date]) = CurrentYear then "YES" else "NO"), 
  FinalTable = Table.SelectColumns(AddIS_CURRENT_YEAR, {"id", "plan_date", "IS_LAST_SIX_MONTHS", "IS_CURRENT_FINANCIAL_YEAR", "IS_CURRENT_YEAR"}), 
  FinalSortedTable = Table.Sort(FinalTable, {{"id", Order.Ascending}, {"plan_date", Order.Descending}})
in
  FinalSortedTable
