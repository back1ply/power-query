// fxRegExpExtract
// https://regexr.com/ is a good resource
let
  fx = (txt as text, regex as text, delim as text) =>
    Web.Page("<script
            var x = '" & txt & "';
            var delim = '" & delim & "';
            var pattern = /" & regex & "/gi;
            var result = x.match(pattern).join(delim);
            document.write(result);
        </script>")[Data]{0}[Children]{0}[Children]{1}[Text]{0}
in
  fx
