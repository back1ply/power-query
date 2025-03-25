//=====================================================================
// Function: fxLookupListPosition
//
// Purpose: 
//   Searches for a lookup value in a specified key column of a lookup table
//   and returns the corresponding value from another column using list indexing.
//   If the lookup fails (for example, if the value is not found), the function 
//   returns a default value (by default, null).
//
// Syntax:
//   fxLookupListPosition(
//       lookupTable as table, 
//       keyCol as text, 
//       valueCol as text, 
//       lookupValue as any, 
//       optional defaultValue as any
//   ) as any
//
// Parameters:
//   lookupTable   - A table that contains the lookup data.
//   keyCol        - The name of the column to search for the lookup value.
//   valueCol      - The name of the column from which to return the value.
//   lookupValue   - The value to search for in the key column.
//   defaultValue  - (Optional) The value to return if the lookup fails; 
//                   defaults to null.
// 
// Returns:
//   The value from the specified value column corresponding to the lookup value,
//   or the default value ("-- no match --" unless overridden) if not found.
//
// Example Usage:
//   fxLookupListPosition(ZDEL_ORD_DELV_DATAW, "Sales Doc.", "Curr.", [#"Ref. Doc."])
//=====================================================================
 (lookupTable as table, keyCol as text, valueCol as text, lookupValue as any, optional defaultValue as any) as any =>
    let
        // Set default value if none is provided.
        defValue = if defaultValue = null then null else defaultValue,
        // Use try/otherwise to catch errors when the lookup fails.
        result = try Table.Column(lookupTable, valueCol)
                    { List.PositionOf(Table.Column(lookupTable, keyCol), lookupValue) } 
                 otherwise defValue
    in
        result
