let
    // Implementation of Text.RegexTest function to check if a string matches a given regex pattern
    Text.RegexTest = (text as text, pattern as text, optional caseSensitivity as number) =>
    let
        // Set default caseSensitive to 0 (case-insensitive) if not provided
        caseSensitivityValue = if caseSensitivity = null then 0 else caseSensitivity,
        
        // Set regex modifier based on case sensitivity setting (0 = case-sensitive, otherwise case-insensitive)
        regexModifier = if caseSensitivityValue = 0 then "" else "i",
        
        // Construct the JavaScript regex expression
        regexExpression = "/" & pattern & "/" & regexModifier,
        
        // Create HTML with embedded JavaScript to evaluate the regex pattern
        htmlContent = 
            "<script>" &
            "var matches = """ & text & """.match(" & regexExpression & ");" &
            "document.write(matches ? 'true' : 'false');" &
            "</script>",
        
        // Execute the JavaScript using Web.Page and extract the result
        resultText = Web.Page(htmlContent)[Data]{0}[Children]{0}[Children]{1}[Text]{0},
        
        // Convert string result to a logical value
        resultValue = if resultText = "true" then true else false
    in
        resultValue
in
    Text.RegexTest
