// Offset-based API URL
"https://dummyjson.com/quotes" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// Query Quotes
let
    SourceURL = #"Offset-based API URL",
    // Make an initial call to get the total count of records
    InitialResponse = Json.Document(Web.Contents(SourceURL)),
    Total = InitialResponse[total],
    
    // Define the batch size (this API returns 30 records by default)
    BatchSize = 30,
    
    // Calculate the number of required API calls
    NumberOfCalls = Number.RoundUp(Total / BatchSize),
    
    // Generate a list of offsets based on the number of calls
    ListOfOffsets = List.Numbers(0, NumberOfCalls, BatchSize),
    
    // Define a function to fetch a page of data
    FetchPage = (Offset) => 
        let
            Response = Json.Document(Web.Contents(SourceURL, [Query=[#"skip"=Text.From(Offset)]])),
            Data = Response[quotes]
        in
            Data,
    
    // Fetch data for all offsets
    AllData = List.Transform(ListOfOffsets, each FetchPage(_)),

    // Combine the data from all pages into one list
    CombinedData = List.Combine(AllData),

    // Convert to table
    OutputTable = Table.FromList(CombinedData, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
in
    OutputTable

// Quotes
let
    Source = #"Query Quotes",
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"id", "quote", "author"}, {"id", "quote", "author"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Column1",{{"id", Int64.Type}, {"quote", type text}, {"author", type text}})
in
    #"Changed Type"
