// fxPathItem
// --------------------------- Function ------------------------------
let
  fxPathItem = (
    Path as text, 
    Position as number, 
    optional ErrorHandling as nullable text
  ) as nullable text =>
    let
      // Split the path by delimiter "|" into a list
      PathList = Text.Split(Path, "|"),
      // Adjust for 1-based indexing in Power Query (lists are 0-based)
      AdjustedPosition = Position - 1,
      // Retrieve the item at the specified position
      Item = if AdjustedPosition >= 0 and AdjustedPosition < List.Count(PathList)
             then PathList{AdjustedPosition}
             else if ErrorHandling = "Error" then error "Position out of range"
             else null
    in
      Item,

  // --------------------------- Documentation segment ------------------------------
  documentation = [
    Documentation.Name = "fxPathItem",
    Documentation.Description = "This function returns the item at a specific position in a hierarchical path, with position being 1-based, similar to the DAX PATHITEM function.",
    Documentation.Source = "Custom Function",
    Documentation.Version = "1.0",
    Documentation.Author = "",
    Documentation.Examples =
    {
      [
        Description = "Get the item at position 2 from the path '1|4'",
        Code = "fxPathItem(""1|4"", 2)",
        Result = "4"
      ]
    }
  ]
// --------------------------- Output ----------------------------------------------
in
  Value.ReplaceType(
    fxPathItem,
    Value.ReplaceMetadata(
      Value.Type(fxPathItem),
      documentation
    )
  )
  // ------------------------------------------------------------------------------------
