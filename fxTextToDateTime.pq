// transform text "2024-10-15 19-00-24" to datetime "15-Oct-24 7:00:24 PM"
(tbl as table, columnName as text) as table =>
let
    // Step 1: Replace the first dash in the time portion with a colon (at position 14)
    ReplaceFirstDash = Table.TransformColumns(
        tbl,
        {
            {columnName, each Text.ReplaceRange(_, 13, 1, ":"), type text}
        }
    ),

    // Step 2: Replace the second dash in the time portion with a colon (at position 16)
    ReplaceSecondDash = Table.TransformColumns(
        ReplaceFirstDash,
        {
            {columnName, each Text.ReplaceRange(_, 16, 1, ":"), type text}
        }
    ),

    // Step 3: Convert the final result to DateTime
    FinalConversion = Table.TransformColumns(
        ReplaceSecondDash,
        {
            {columnName, each DateTime.FromText(_), type datetime}
        }
    )
in
    FinalConversion
