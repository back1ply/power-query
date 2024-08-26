// fxPathLength
// --------------------------- Function ------------------------------
let
  fxPathLength = (Path as text) as number =>
    let
      // Split the path by delimiter "|" into a list
      PathList = Text.Split(Path, "|"),
      // Count the number of items in the list to determine the path length
      PathLength = List.Count(PathList)
    in
      PathLength,

  // --------------------------- Documentation segment ------------------------------
  documentation = [
    Documentation.Name = "fxPathLength",
    Documentation.Description = "This function calculates the length of a hierarchical path by counting the number of levels in the path.",
    Documentation.Source = "Custom Function",
    Documentation.Version = "1.0",
    Documentation.Author = "",
    Documentation.Examples =
    {
      [
        Description = "Calculate the path length for a given path '1|4'",
        Code = "fxPathLength(""1|4"")",
        Result = "2"
      ]
    }
  ]
// --------------------------- Output ----------------------------------------------
in
  Value.ReplaceType(
    fxPathLength,
    Value.ReplaceMetadata(
      Value.Type(fxPathLength),
      documentation
    )
  )
  // ------------------------------------------------------------------------------------
