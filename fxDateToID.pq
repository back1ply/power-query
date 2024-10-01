(inputDate as nullable date) as nullable number =>
    if inputDate = null then null else
        let
            dateID = Number.FromText(Date.ToText(inputDate, "yyyyMMdd"))
        in
            dateID
