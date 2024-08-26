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
      GetPath = (currentKey as number) as text =>
        let
          currentRow = Table.SelectRows(
            PathTable, 
            each Record.Field(_, EntityKeyColumn) = currentKey
          ), 
          parentKey = 
            if Table.IsEmpty(currentRow) then
              null
            else
              Record.Field(currentRow{0}, ParentEntityKeyColumn), 
          parentPath = 
            if parentKey <> null and parentKey <> currentKey then
              @GetPath(parentKey)
            else
              "", 
          path = 
            if parentPath <> "" then
              parentPath & "|" & Text.From(currentKey)
            else
              Text.From(currentKey)
        in
          path, 
      // Get the path for the specific key
      lastStep
        = GetPath(
        KeyToCalculate
      )                                                                                             
    in
      lastStep,                                                                                    
  // --------------------------- Documentation segment ------------------------------
  documentation = [
    Documentation.Name = "fxPath",                                                                  
    Documentation.Description
      = "This function calculates the hierarchical path for a given entity within a parent-child structure. 
            It recursively traverses the hierarchy to build a pipe-delimited path string, similar to the DAX PATH function.",
    Documentation.Source = "Custom Function",                                                      
    Documentation.Version = "1.0",                                                                  
    Documentation.Author = "",                                                                     
    Documentation.Examples
      =                                                                                            
    {
      [
        Description = "Calculate the path for entity with EntityKey = 4",                           
        Code = "fxPath(EntityTable, ""EntityKey"", ""ParentEntityKey"", [EntityKey])",                  
        Result
          = "1|4"                                                                                  
      ]
    }
  ]
// --------------------------- Output --------------------------------------------
in
  Value.ReplaceType(
    // Replace type of the value
    fxPath,                                                                                         // Function caller
    Value.ReplaceMetadata(
      // Replace metadata of the function
      Value.Type(fxPath),                                                                           // Return output type of function
      documentation                                                                                 // Documentation assignment
    )
  )
  // ------------------------------------------------------------------------------------
