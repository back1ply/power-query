// fxPathItemReverse
// --------------------------- Function ------------------------------
let
  fxPathItemReverse = (
    Path as text, 
    Position as number, 
    optional ErrorHandling as nullable text
  ) as nullable text =>
    let
      // Split the path by delimiter "|" into a list
      PathList = Text.Split(Path, "|"),
      // Adjust the position to count from the end
      AdjustedPosition = List.Count(PathList) - Position,
      // Retrieve the item at the adjusted position
      Item = if AdjustedPosition >= 0 and AdjustedPosition < List.Count(PathList)
             then PathList{AdjustedPosition}
             else if ErrorHandling = "Error" then error "Position out of range"
             else null
    in
      Item,

  // --------------------------- Documentation segment ------------------------------
  documentation = [
    Documentation.Name = "fxPathItemReverse",
    Documentation.Description = "This function returns the item at a specific position in a hierarchical path, but counting from the end, similar to the DAX PATHITEMREVERSE function.",
    Documentation.Source = "Custom Function",
    Documentation.Version = "1.0",
    Documentation.Author = "",
    Documentation.Examples =
    {
      [
        Description = "Get the last item from the path '1|4'",
        Code = "fxPathItemReverse(""1|4"", 1)",
        Result = "4"
      ]
    }
  ]
// --------------------------- Output ----------------------------------------------
in
  Value.ReplaceType(
    fxPathItemReverse,
    Value.ReplaceMetadata(
      Value.Type(fxPathItemReverse),
      documentation
    )
  )
  // ------------------------------------------------------------------------------------
