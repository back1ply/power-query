let
    // Text.RegexExtract function to extract content matching a given regex pattern
    Text.RegexExtract = (
        text as text, 
        pattern as text, 
        optional returnMode as number,
        optional caseSensitivity as number
    ) =>
    let
        // Set default return mode (0 = first match only) if not provided
        returnModeValue = if returnMode is null then 0 else returnMode,
        
        // Set default case sensitivity (0 = case-sensitive) if not provided
        caseSensitivityValue = if caseSensitivity = null then 0 else caseSensitivity,
        
        // Set regex modifier based on case sensitivity (g = global, i = case-insensitive)
        regexModifier = if caseSensitivityValue = 1 then "g" else "gi",
        
        // Construct the JavaScript regex expression
        regexExpression = "/" & pattern & "/" & regexModifier,
        
        // Generate JavaScript logic based on return mode:
        // 0 = first match only
        // 1 = all matches as array
        // other = capturing groups
        javascriptLogic = if returnModeValue = 0 then 
            "var match = str.match(regex); var res = match ? match[0] : null;" 
        else if returnModeValue = 1 then 
            "var res = str.match(regex);"
        else 
            "var match = regex.exec(str); res = match ? match.slice(1) : null;",
        
        // Build HTML content with embedded JavaScript
        htmlContent = Text.Combine({
            "<script>",
            "var regex = ", regexExpression, ";",
            "var str = """, text, """;",
            javascriptLogic,
            "document.write(res)",
            "</script>"
        }),
        
        // Execute JavaScript via Web.Page and extract the result
        resultText = Web.Page(htmlContent)[Data]{0}[Children]{0}[Children]{1}[Text]{0}
    in
        // Return extracted text
        resultText
in
    Text.RegexExtract
