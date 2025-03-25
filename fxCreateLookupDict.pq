//=====================================================================
// Function: CreateLookupDict
//
// Purpose: 
//   Creates a lookup dictionary (record) from a given table by mapping 
//   values in a key column to values in a value column. This function 
//   first reduces the table to only the necessary columns, removes duplicates 
//   based on the key, and optionally buffers the reduced table to improve performance.
//
// Syntax:
//   CreateLookupDict(source as table, keyCol as text, valueCol as text, optional useBuffer as logical) as record
//
// Parameters:
//   source      - A table that contains the data for the lookup.
//   keyCol      - A text value representing the name of the column to be used as keys.
//   valueCol    - A text value representing the name of the column to be used as values.
//   useBuffer   - (Optional) A logical value. If true, the function buffers the slimmed-down table.
//                 Default is false if omitted.
//
// Returns:
//   A record (dictionary) where each key is taken from the 'keyCol' and its 
//   corresponding value is from the 'valueCol' of the processed table.
//
// Example Usage:
//   // Without buffering (default):
//   SalesDocToCurrDict = CreateLookupDict(ZDEL_ORD_DELV_DATAW, "Sales Doc.", "Curr.")
//
//   // With buffering enabled:
//   SalesDocToCurrDict = CreateLookupDict(ZDEL_ORD_DELV_DATAW, "Sales Doc.", "Curr.", true)
//
// Remarks:
//   - The function uses Table.SelectColumns to limit the columns, and Table.Distinct 
//     to ensure unique keys (similar to Excel’s first-match behavior in VLOOKUP).
//   - Buffering (when enabled) is applied after slimming the table, reducing memory usage 
//     by storing only the necessary subset of data.
//=====================================================================

(source as table, keyCol as text, valueCol as text, optional useBuffer as logical) as record =>
    let
        useBufferValue = if (useBuffer = null) then false else useBuffer,
        SlimTablePreBuffer = Table.Distinct(Table.SelectColumns(source, {keyCol, valueCol}), {keyCol}),
        SlimTable = if useBufferValue then Table.Buffer(SlimTablePreBuffer) else SlimTablePreBuffer
    in
        Record.FromList(Table.Column(SlimTable, valueCol), Table.Column(SlimTable, keyCol))
