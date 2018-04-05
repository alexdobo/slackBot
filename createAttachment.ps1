param(
    # A plain-text summary of the attachment
    [Parameter(Mandatory=$False)]
    [string]$Fallback,   

    # 'good', 'warning', 'danger', or and hex code e.g. '#439FE0'
    [Parameter(Mandatory=$False)]
    [String]
    $Color,

    # This is optional text that appears above the message attachment block.
    [Parameter(Mandatory=$False)]
    [String]
    $Pretext,

    # Larger, bold text near the top of a message attachment.
    [Parameter(Mandatory=$True)]
    [String]
    $Title,

    # Makes the Title a hyperlink
    [Parameter(Mandatory=$False)]
    [String]
    $TitleLink,

    # Array that's a table thing (needs to be an array)
    [Parameter(Mandatory=$False)]
    $Fields,

    # The main body of the attachment
    [Parameter(Mandatory=$True)]
    [string]$Text,

    # A valid URL to an image file that will be displayed inside a message attachment. We currently support the following formats: GIF, JPEG, PNG, and BMP.
    [Parameter(Mandatory=$False)]
    [string]
    $ImageURL
)

$result = @(@{
    fallback = $Fallback
    color = $Color
    pretext = $Pretext
    title = $Title
    title_link = $TitleLink
    text = $Text
    image_url = $ImageURL
    fields = $Fields
})
$result