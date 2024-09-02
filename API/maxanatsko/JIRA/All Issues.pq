// JIRA Instance URL
"https://maxanatsko-dev.atlassian.net" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// Query Issues
let 
    // Store the base URL for the JIRA instance.
    jira_instance_url = #"JIRA Instance URL",

    // Store the project identifier for the JIRA query.
    jira_projects = #"Jira Project",

    // Specify additional fields to expand in the JIRA query result.
    jira_expand = "renderedFields",

    // Maximum possible results per page, actual numbers depends on the JIRA server configuration. DO NOT change manually.
    jira_maxResults = 1000,

    // Construct the base URL for the JIRA API call.
    BaseUrl = jira_instance_url & "/rest/api/latest/search?jql=project%20in%20(" & jira_projects & 
              ")&expand=" & jira_expand & "&maxResults=" & Text.From(jira_maxResults),

    // Function to get the maximum number of results per page from the JSON response.
    GetResultsPerPage = () =>
        let 
            // Use the base URL to make the API call.
            Url = BaseUrl,

            // Retrieve the JSON response from the API call.
            Json = GetJson(Url),

            // Extract the 'maxResults' value from the JSON response.
            ResultsPerPage = Json[#"maxResults"]
        in  
            ResultsPerPage,

    // Initialize ResultsPerPage by invoking the GetResultsPerPage function.
    ResultsPerPage = GetResultsPerPage(),
 
    // Function to get a JSON document from a given URL.
    GetJson = (Url) =>
        let 
            // Retrieve the raw data from the web service at the specified URL.
            RawData = Web.Contents(Url),

            // Parse the raw data into a JSON document.
            Json = Json.Document(RawData)
        in  
            Json,
 
    // Function to get the total count of JIRA IDs.
    GetJiraIDCount = () =>
        let 
            // Make a specific API call to get the count of JIRA IDs with 'maxResults' set to 0.
            Url = BaseUrl,

            // Retrieve and parse the JSON response from the API call.
            Json = GetJson(Url),

            // Extract the 'total' count of JIRA IDs from the JSON response.
            Count = Json[#"total"]
        in  
            Count,
 
    // Function to retrieve a page of results given an index.
    GetPage = (Index) =>
        let 
            // Calculate the 'startAt' parameter for pagination based on the index and results per page.
            Skip = "&startAt=" & Text.From(Index * ResultsPerPage),

            // Specify the number of results per page for pagination.
            Top = "&maxResults=" & Text.From(ResultsPerPage),

            // Construct the final URL for the API call including pagination parameters.
            Url = BaseUrl & Skip & Top,

            // Retrieve and parse the JSON response from the API call.
            Json = GetJson(Url),

            // Extract the list of issues from the JSON response.
            Value = Json[#"issues"]
        in  
            Value,
 
    // Compute the total number of JIRA IDs and determine the number of pages.
    JiraIDCount = List.Max({ ResultsPerPage, GetJiraIDCount() }),
    PageCount = Number.RoundUp(JiraIDCount / ResultsPerPage),

    // Generate a list of page indices based on the total number of pages.
    PageIndices = { 0 .. PageCount - 1 },

    // Transform the list of page indices into a list of pages containing JIRA IDs.
    Pages = List.Transform(PageIndices, each GetPage(_)),

    // Combine the pages into a single list of JIRA IDs.
    JiraID = List.Union(Pages),

    // Convert the list of JIRA IDs into a table format.
    Table = Table.FromList(JiraID, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
in
    // Output the final table of JIRA IDs.
    Table

// Jira Project
"PBD" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// All Issues
let
    Source = #"Query Issues",
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"expand", "id", "self", "key", "renderedFields", "fields"}, {"expand", "id", "self", "key", "renderedFields", "fields"}),
    #"Expanded renderedFields" = Table.ExpandRecordColumn(#"Expanded Column1", "renderedFields", {"statuscategorychangedate", "issuetype", "timespent", "customfield_10030", "customfield_10031", "project", "customfield_10032", "customfield_10033", "fixVersions", "customfield_10034", "aggregatetimespent", "resolution", "customfield_10027", "customfield_10028", "customfield_10029", "resolutiondate", "workratio", "lastViewed", "watches", "created", "customfield_10020", "customfield_10021", "customfield_10022", "customfield_10023", "priority", "customfield_10024", "customfield_10025", "customfield_10026", "labels", "customfield_10016", "customfield_10017", "customfield_10018", "customfield_10019", "aggregatetimeoriginalestimate", "timeestimate", "versions", "issuelinks", "assignee", "updated", "status", "components", "timeoriginalestimate", "description", "customfield_10010", "customfield_10014", "customfield_10015", "customfield_10005", "customfield_10006", "security", "customfield_10007", "customfield_10008", "aggregatetimeestimate", "customfield_10009", "summary", "creator", "subtasks", "reporter", "aggregateprogress", "customfield_10001", "customfield_10002", "customfield_10003", "customfield_10004", "customfield_10038", "customfield_10039", "environment", "duedate", "progress", "votes"}, {"statuscategorychangedate", "issuetype", "timespent", "customfield_10030", "customfield_10031", "project", "customfield_10032", "customfield_10033", "fixVersions", "customfield_10034", "aggregatetimespent", "resolution", "customfield_10027", "customfield_10028", "customfield_10029", "resolutiondate", "workratio", "lastViewed", "watches", "created", "customfield_10020", "customfield_10021", "customfield_10022", "customfield_10023", "priority", "customfield_10024", "customfield_10025", "customfield_10026", "labels", "customfield_10016", "customfield_10017", "customfield_10018", "customfield_10019", "aggregatetimeoriginalestimate", "timeestimate", "versions", "issuelinks", "assignee", "updated", "status", "components", "timeoriginalestimate", "description", "customfield_10010", "customfield_10014", "customfield_10015", "customfield_10005", "customfield_10006", "security", "customfield_10007", "customfield_10008", "aggregatetimeestimate", "customfield_10009", "summary", "creator", "subtasks", "reporter", "aggregateprogress", "customfield_10001", "customfield_10002", "customfield_10003", "customfield_10004", "customfield_10038", "customfield_10039", "environment", "duedate", "progress", "votes"})
in
    #"Expanded renderedFields"
