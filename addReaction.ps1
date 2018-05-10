param(
    # Name of the emoji
    [Parameter(Mandatory=$False)]
    [string]
    $Emoji = "hourglass_flowing_sand",   

    # Channel the message was in
    [Parameter(Mandatory=$True)]
    [String]
    $Channel,

    # Timestamp of the message
    [Parameter(Mandatory=$True)]
    [String]
    $Timestamp
)
$null = @(
    $token = get-content ".\variables\token.txt" #not making that mistake again...
)

$message = @{
    name = $emoji
    channel = $channel
    timestamp = $Timestamp
    token = $token
}
$json = $message | ConvertTo-Json -Depth 5

$url = "https://slack.com/api/reactions.add"

$contentType = "application/json; charset=utf-8"
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-WebRequest -Method Post -Uri $url -body $json -ContentType $contentType -Headers $headers | out-file -filepath "slack.log" -append
