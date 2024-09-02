// Page-based API URL
"https://reqres.in/api/users" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// Query Users
let
    // Function to fetch a single page of data
    GetPage = (PageNumber as number) as table =>
    let
        Source = Json.Document(Web.Contents(#"Page-based API URL", [Query=[#"page"=Text.From(PageNumber)]])),

        // Store away data from API response
        Data = Source[data],
        // Convert the list of records into a table
        ConvertedToTable = Table.FromList(Data, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
    in
        ConvertedToTable,

    // Fetch the first page to determine how many total pages there are
    FirstPage = GetPage(1),

    // Fetch total pages count from the API response
    TotalPages = Json.Document(Web.Contents(#"Page-based API URL"))[total_pages],

    // Generate a list of page numbers to iterate over
    PageList = List.Numbers(1, TotalPages),

    // Fetch all pages and query data for each page
    AllPages = List.Transform(PageList, each GetPage(_)),

    // Combine all pages into single table
    CombinedPages = Table.Combine(AllPages)
in
    CombinedPages

// Users
let
    Source = #"Query Users",
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"id", "email", "first_name", "last_name", "avatar"}, {"id", "email", "first_name", "last_name", "avatar"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Column1",{{"id", Int64.Type}, {"email", type text}, {"first_name", type text}, {"last_name", type text}, {"avatar", type text}})
in
    #"Changed Type"
