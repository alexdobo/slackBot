param(
    # Bold heading above the value text. It cannot contain markup
    [Parameter(Mandatory=$True)]
    [string]
    $Title,

    # The text value of the field. It may contain standard message markup and must be escaped as normal. May be multi-line.
    [Parameter(Mandatory=$True)]
    [string]
    $Value,

    # An optional flag indicating whether the value is short enough to be displayed side-by-side with other values.
    [Parameter(Mandatory=$False)]
    [bool]
    $Short = $True
)
$return = @{
    title = $Title; 
    value = $Value; 
    short = $Short;
}
$return