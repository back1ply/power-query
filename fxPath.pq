// --------------------------- Function ------------------------------															  
let
  // --------------------------- Function segment -----------------------------------																				 
  fxPath = (
    PathTable as table, 
    EntityKeyColumn as text, 
    ParentEntityKeyColumn as text, 
    KeyToCalculate as number
  ) as text =>
    let
      // Helper function to recursively get the path
      GetPath = (currentKey as number, currentPath as list) as list =>
        let
          currentRow = Table.First(Table.SelectRows(PathTable, each Record.Field(_, EntityKeyColumn) = currentKey), null),
          parentKey = if currentRow = null then null else Record.Field(currentRow, ParentEntityKeyColumn),
          newPath = List.Combine({currentPath, {Text.From(currentKey)}})
        in
          if parentKey = null or parentKey = currentKey then
            newPath
          else
            @GetPath(parentKey, newPath),

      // Start path construction from the key to calculate
      PathList = GetPath(KeyToCalculate, {}),
      
      // Combine the list into a pipe-delimited string
      finalPath = Text.Combine(List.Reverse(PathList), "|")
    in
      finalPath,

  // --------------------------- Documentation segment ------------------------------																					 
  documentation = [
    Documentation.Name = "fxPath",
    Documentation.Description = "This function calculates the hierarchical path for a given entity within a parent-child structure, similar to the DAX PATH function.",
    Documentation.Source = "Custom Function",
    Documentation.Version = "1.1",
    Documentation.Author = "",
    Documentation.Examples =
    {
      [
        Description = "Calculate the path for entity with EntityKey = 4",
        Code = "fxPath(EntityTable, ""EntityKey"", ""ParentEntityKey"", [EntityKey] )",
        Result = "1|4"
      ]
    }
  ]
// --------------------------- Output --------------------------------------------																			  
in
  Value.ReplaceType(
    fxPath,
    Value.ReplaceMetadata(
      Value.Type(fxPath),
      documentation
    )
  )
  // ------------------------------------------------------------------------------------
