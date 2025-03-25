//=====================================================================
// Function: fxLookupListPosition
//
// Purpose: 
//   Searches for a lookup value in a specified key column of a lookup table
//   and returns the corresponding value from another column using list indexing.
//   If the lookup fails (for example, if the value is not found), the function 
//   returns null.
//   Optionally, the lookup table's key and value columns can be buffered to 
//   improve performance when the table is large or the function is called repeatedly.
//
// Syntax:
//   fxLookupListPosition(
//       lookupTable as table, 
//       keyCol as text, 
//       valueCol as text, 
//       lookupValue as any,
//       optional useBuffer as logical
//   ) as any
//
// Parameters:
//   lookupTable - A table that contains the lookup data.
//   keyCol      - The name of the column to search for the lookup value.
//   valueCol    - The name of the column from which to return the value.
//   lookupValue - The value to search for in the key column.
//   useBuffer   - (Optional) A logical flag indicating whether to buffer the column lists.
//                 Defaults to false if not provided.
//
// Returns:
//   The value from the specified value column corresponding to the lookup value,
//   or null if no match is found.
//=====================================================================
(
    lookupTable as table, 
    keyCol as text, 
    valueCol as text, 
    lookupValue as any,
    optional useBuffer as logical
) as any =>
    let
        // Always return null if no match is found.
        defValue = null,
        // Determine if buffering should be applied (default: false).
        useBufferValue = if useBuffer = null then false else useBuffer,
        // Extract key and value lists, buffering them if requested.
        keyList = if useBufferValue then List.Buffer(Table.Column(lookupTable, keyCol)) else Table.Column(lookupTable, keyCol),
        valueList = if useBufferValue then List.Buffer(Table.Column(lookupTable, valueCol)) else Table.Column(lookupTable, valueCol),
        // Use try/otherwise to perform the lookup via list indexing.
        result = try valueList{ List.PositionOf(keyList, lookupValue) } otherwise defValue
    in
        result
