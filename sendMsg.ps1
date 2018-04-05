param(
    # The main body of the message
    [Parameter(Position=0,Mandatory=$True)]
    [string]$Text,   

    # Channel the message is going to be sent to
    [Parameter(Position=1,Mandatory=$True)]
    [String]
    $Channel,

    # Any attachments
    [Parameter(Position=2,Mandatory=$False)]
    $Attachments 
)


$token = get-content ".\variables\token.txt" #not making that mistake again...


$message = @{
    id = "ps-bot"
    type = "message"
    text = $Text
    channel = $channel
    as_user = "false"
    username = "ps-bot"
    token = $token
    attachments = $Attachments
}
$json = $message | ConvertTo-Json -Depth 5

$url = "https://slack.com/api/chat.postMessage"

$contentType = "application/json; charset=utf-8"
$headers = @{
    Authorization = "Bearer $token"
}

Invoke-WebRequest -Method Post -Uri $url -body $json -ContentType $contentType -Headers $headers | out-file -filepath "slack.log" -append

