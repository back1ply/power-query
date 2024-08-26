// fxPathContains
// --------------------------- Function ------------------------------
let
  fxPathContains = (
    Path as text, 
    Item as text
  ) as logical =>
    let
      // Split the path by delimiter "|" into a list
      PathList = Text.Split(Path, "|"),
      // Check if the item is in the list
      ContainsItem = List.Contains(PathList, Item)
    in
      ContainsItem,

  // --------------------------- Documentation segment ------------------------------
  documentation = [
    Documentation.Name = "fxPathContains",
    Documentation.Description = "This function checks if a specified item is present within a hierarchical path, similar to the DAX PATHCONTAINS function.",
    Documentation.Source = "Custom Function",
    Documentation.Version = "1.0",
    Documentation.Author = "",
    Documentation.Examples =
    {
      [
        Description = "Check if the path '1|4' contains the item '4'",
        Code = "fxPathContains(""1|4"", ""4"")",
        Result = "true"
      ]
    }
  ]
// --------------------------- Output ----------------------------------------------
in
  Value.ReplaceType(
    fxPathContains,
    Value.ReplaceMetadata(
      Value.Type(fxPathContains),
      documentation
    )
  )
  // ------------------------------------------------------------------------------------
