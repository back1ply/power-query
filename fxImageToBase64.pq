// ImageToBase64
let
    // Definining the function ImageToBase64 with parameters for the image binary content and file extension
    ImageToBase64 = (ImageBinaryContent as binary, FileExtension as text) as text =>
let
    // Removing the first character from the file extension to remove a leading dot
    FileExtensionTrimmed = Text.RemoveRange(FileExtension, 0, 1),

    // Convert the file extension to lowercase for consistency
    FileExtensionLowercased = Text.Lower(FileExtensionTrimmed),

    // Construct the MIME type string using the file extension
    // This indicates the type of the image (e.g., png, jpg) as part of the Base64 encoded string
    MimeType = "data:image/" & FileExtensionLowercased & ";base64, ",
    
    // Convert the binary image content to a Base64 encoded text string
    // The MIME type string is prepended to indicate the format of the image data
    Base64 = MimeType & Binary.ToText(ImageBinaryContent, BinaryEncoding.Base64)
in
    Base64 // Return the complete Base64 encoded string
in
    ImageToBase64

// Folder Images to Base64
let
    Source = Folder.Files("\\Mac\Home\Movies\Video - Storing images as base64 inside Power BI model\Power BI Project Files\Images"),
    #"Filtered Rows" = Table.SelectRows(Source, each ([Extension] <> ".db" and [Extension] <> ".DS_Store")),
    #"Invoked Custom Function" = Table.AddColumn(#"Filtered Rows", "Base64", each ImageToBase64([Content], [Extension])),
    #"Changed Type" = Table.TransformColumnTypes(#"Invoked Custom Function",{{"Base64", type text}})
in
    #"Changed Type"
