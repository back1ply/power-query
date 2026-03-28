let
    // Text.RegexReplace function to replace content matching a regex pattern with specified text
    Text.RegexReplace = (
        text as text,             // Original text
        pattern as text,          // Regex pattern (e.g., "[0-9]{3}-")
        replacement as text,      // Replacement text
        optional occurrence as number,     // Which occurrence to replace (0 = all, default)
        optional caseSensitivity as number   // Case sensitivity (0 = case-sensitive, default)
    ) =>
    let
        // Handle default parameters
        occurrenceValue = if occurrence = null then 0 else occurrence,
        caseSensitivityValue = if caseSensitivity = null then 0 else caseSensitivity,
        
        // Generate JavaScript regex with appropriate modifiers
        regexModifier = if caseSensitivityValue = 0 then "g" else "gi",
        regexExpression = "/" & pattern & "/" & regexModifier, 
        
        // Build JavaScript replacement logic
        javascriptCode = 
            "var regex = " & regexExpression & ";" & 
            "var str = '" & text & "';" &
            "var replacement = '" & replacement & "';" &
            "var occ = " & Text.From(occurrenceValue) & ";" &
            "
                var matches = [];
                var match;
                while ((match = regex.exec(str)) !== null) {
                    matches.push({
                        index: match.index,
                        length: match[0].length
                    });
                }
                if (occ === 0) {
                    // Replace all occurrences
                    document.write(str.replace(regex, replacement));
                } else {
                    // Calculate target position
                    var targetIndex;
                    if (occ > 0) {
                        targetIndex = occ - 1;
                    } else {
                        targetIndex = matches.length + occ;
                    }
                    if (targetIndex < 0 || targetIndex >= matches.length) {
                        document.write(str);
                    } else {
                        var target = matches[targetIndex];
                        var res = str.substring(0, target.index) + 
                                  replacement + 
                                  str.substring(target.index + target.length);
                        document.write(res);
                    }
                }
            ",
        // Execute JavaScript and get result
        htmlContent = "<script>" & javascriptCode & "</script>",
        resultText = Web.Page(htmlContent)[Data]{0}[Children]{0}[Children]{1}[Text]{0}
    in
        resultText
in
    Text.RegexReplace
