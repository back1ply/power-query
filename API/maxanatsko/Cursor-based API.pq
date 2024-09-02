// Cursor-based API URL
"https://rickandmortyapi.com/api/character" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// Query Data (Using Next URL)
let
    // Function to fetch data from the API until there are no more pages
    FetchData = (initialUrl as text) as list =>
        let
            // Initialize the state with the first URL and an empty list for data
            State = [NextUrl = initialUrl, Accumulated = {}],
            
            // Define a function to process the current state
            ProcessPage = (state) as record =>
                let
                    // Fetch the data from the current URL
                    CurrentSource = Json.Document(Web.Contents(state[NextUrl])),
                    // Extract the 'results' part of the data
                    Data = CurrentSource[results],
                    // Combine the data from this page with the accumulated data
                    NewAccumulated = state[Accumulated] & Data,
                    // Try to get the 'next' URL, if any
                    NextUrl = try CurrentSource[info][next] otherwise null,
                    // Return the new state
                    NewState = [NextUrl = NextUrl, Accumulated = NewAccumulated]
                in
                    NewState,

            // Loop to fetch all pages
            ResultState = List.Generate(
                () => State,
                (state) => state[NextUrl] <> null,
                (state) => ProcessPage(state)
            ),
            
            // Extract the accumulated data from the last state
            FinalData = List.Last(ResultState)[Accumulated]
        in
            FinalData
in
    // Invoke the function to start fetching data
    FetchData(#"Cursor-based API URL")

// Rick & Morty Characters
let
    Source = #"Query Data (Using Next URL)",
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"id", "name", "status", "species", "type", "gender", "origin", "location", "image", "episode", "url", "created"}, {"id", "name", "status", "species", "type", "gender", "origin", "location", "image", "episode", "url", "created"}),
    #"Expanded location" = Table.ExpandRecordColumn(#"Expanded Column1", "location", {"name"}, {"location.name"}),
    #"Expanded origin" = Table.ExpandRecordColumn(#"Expanded location", "origin", {"name"}, {"origin.name"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded origin",{"episode"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"id", Int64.Type}, {"name", type text}, {"status", type text}, {"species", type text}, {"type", type text}, {"gender", type text}, {"origin.name", type text}, {"location.name", type text}, {"image", type text}, {"url", type text}, {"created", type datetime}})
in
    #"Changed Type"
