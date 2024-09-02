// JIRA Instance URL
"https://maxanatsko-dev.atlassian.net" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// Query Worklogs
let 

    //Initial configuration
    jira_instance_url = #"JIRA Instance URL",
    jira_projects = #"Jira Project",
    jira_expand = "renderedFields",
    jira_maxResults = 1000, //maximum possible, actual maxResults per page depends on server configuration
    BaseUrl = jira_instance_url & "/rest/api/latest/search?jql=project%20in%20(" & jira_projects & ")&fields=worklog&maxResults=" & Text.From(jira_maxResults),

    GetResultsPerPage = () =>
        let Url   = BaseUrl,
            Json  = GetJson(Url),
            ResultsPerPage = Json[#"maxResults"]
        in  ResultsPerPage,

    ResultsPerPage = GetResultsPerPage(),
 
    GetJson = (Url) =>
        let 
            RawData = Web.Contents(Url),
            Json    = Json.Document(RawData)
        in  Json,
 
    GetJiraIDCount = () =>
        let Url   = BaseUrl & "&maxResults=0",
            Json  = GetJson(Url),
            Count = Json[#"total"]
        in  Count,
 
    GetPage = (Index) =>
        let Skip  = "&startAt=" & Text.From(Index * ResultsPerPage),
            Top   = "&maxResults=" & Text.From(ResultsPerPage),
            Url   = BaseUrl & Skip & Top,
            Json  = GetJson(Url),
            Value = Json[#"issues"]
        in  Value,
 
    JiraIDCount = List.Max({ ResultsPerPage, GetJiraIDCount() }),
    PageCount   = Number.RoundUp(JiraIDCount / ResultsPerPage),
    PageIndices = { 0 .. PageCount - 1 },
    Pages       = List.Transform(PageIndices, each GetPage(_)),
    JiraID      = List.Union(Pages),
    Table       = Table.FromList(JiraID, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
in
    Table

// Jira Project
"PBD" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

// All Worklogs
let
    Source = #"Query Worklogs",
    #"Expanded Column1" = Table.ExpandRecordColumn(Source, "Column1", {"key", "fields"}, {"key", "fields"}),
    #"Expanded fields" = Table.ExpandRecordColumn(#"Expanded Column1", "fields", {"worklog"}, {"worklog"}),
    #"Expanded worklog" = Table.ExpandRecordColumn(#"Expanded fields", "worklog", {"worklogs"}, {"worklogs"}),
    #"Expanded worklogs" = Table.ExpandListColumn(#"Expanded worklog", "worklogs"),
    #"Expanded worklogs1" = Table.ExpandRecordColumn(#"Expanded worklogs", "worklogs", {"author", "created", "timeSpentSeconds"}, {"author", "created", "timeSpentSeconds"}),
    #"Expanded author" = Table.ExpandRecordColumn(#"Expanded worklogs1", "author", {"emailAddress"}, {"emailAddress"})
in
    #"Expanded author"
