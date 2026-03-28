let
    /*
     * Azure DeepSeek API Connector for Power Query
     * ---------------------------------------
     * A function to interact with Azure DeepSeek's Large Language Model API.
     */
    fnDeepSeekChat = (
        // Required parameters
        systemContent as text,  // System instructions for AI behavior
        userContent as text,    // User's actual query or prompt
        
        // Optional parameters
        optional model as text,        // Model name to use
        optional maxTokens as number,  // Controls maximum response length
        optional temperature as number // Controls randomness (0-1), lower = more deterministic

    ) as any =>
    let
        // Azure API Configuration, replace with your own endpoint
        baseUrl = "https://<YOUR OWN URL>.services.ai.azure.com/models/chat/completions",
        apiVersion = "2024-05-01-preview",
        apiUrl = baseUrl & "?api-version=" & apiVersion,
        // API key should be defined externally as AzureDeepSeekAPIKey
        apiKey = "<YOUR OWN API KEY>",
        
        // Default settings
        DefaultModel = "DeepSeek-V3",
        DefaultMaxTokens = 300,      // Default token limit
        DefaultTemperature = 0.7,    // Balanced between creativity and determinism

        // Set final parameter values
        finalModel = if model <> null then model else DefaultModel,
        finalMaxTokens = if maxTokens <> null then maxTokens else DefaultMaxTokens,
        finalTemperature = if temperature <> null then temperature else DefaultTemperature,
        
        // Configure request headers - Azure uses api-key
        headers = [
            #"Content-Type" = "application/json",
            #"api-key" = apiKey
        ],
        
        // Build request body
        requestBody = Json.FromValue([
            model = finalModel,
            messages = {
                [role = "system", content = systemContent],
                [role = "user", content = userContent]
            },
            max_tokens = finalMaxTokens,
            temperature = finalTemperature,
            stream = false
        ]),
        
        // Execute API request with error handling
        // Adding 500ms delay to avoid potential rate limiting
        response = Function.InvokeAfter(
            () => try Web.Contents(apiUrl, [
                Headers = headers, 
                Content = requestBody,
                // Manual handling of error status codes for better diagnostics
                ManualStatusHandling = {400, 401, 403, 404, 429, 500}
            ]) otherwise null,
            #duration(0, 0, 0, 0.5)
        ),
        
        // Parse JSON response
        json = if response is null then null else try Json.Document(response) otherwise null,
        
        // Extract response text with error handling
        result = 
            if json <> null and Record.HasFields(json, "choices") and List.Count(json[choices]) > 0 then
                try json[choices]{0}[message][content] otherwise "Error: Invalid response format"
            else
                "Error: No valid response"
    in
        result
in
    fnDeepSeekChat
