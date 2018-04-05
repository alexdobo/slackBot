$null = @( #define initial variables
    $token = get-content ".\variables\token.txt" #not making that mistake again...
    $tolerance = 5
    $alertsChannel = get-content ".\variables\alertsChannel.txt"
    $monitorList = New-Object System.Collections.ArrayList
    import-csv ".\monitorList.csv" -Header "Name" | ForEach-Object{$monitorList.add($_.Name)}
    $siteList = New-Object System.Collections.ArrayList
    import-csv ".\recordingData.csv" | Group-Object Site | ForEach-Object{$siteList.add($_.Name)}
    $psBotWebHook = get-content ".\variables\psBotWebHook.txt"
    $alexChannel = get-content ".\variables\alexChannel.txt"
)

function Send-SlackMsg{
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
    .\sendMsg.ps1 -Text $Text -Channel $Channel -Attachments $Attachments
}

function Create-Attachment {
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
        [string]$Text   
    )
    .\createAttachment.ps1 -Fallback $Fallback -Color $Color -Pretext $Pretext -Title $Title -TitleLink $TitleLink -Fields $Fields -Text $Text
}

function Create-Field {
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
    .\createFields.ps1 -Title $Title -Value $Value -Short $Short
}


$RTMSession = Invoke-RestMethod -Uri https://slack.com/api/rtm.start -Body @{token=$Token}
"I am $($RTMSession.self.name)"

Try{
    Do{
        $WS = New-Object System.Net.WebSockets.ClientWebSocket #web socket                                      
        $CT = New-Object System.Threading.CancellationToken #cancellation token
        
        #start webstocket connection
        $Conn = $WS.ConnectAsync($RTMSession.URL, $CT)                                                  
        
        #wait until connection is made
        While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }
        
        #creates an array to store received files
        $size = 1024
        $Array = [byte[]] @(,0) * $Size
        $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$Array)

        while ($ws.State -eq "Open"){
            $RTM = ""

            Do {
                $Conn = $WS.ReceiveAsync($recv, $CT)
                while (!$Conn.IsCompleted){ Sleep -Milliseconds 100 }
                $recv.Array[0..($Conn.Result.Count -1)] | ForEach-Object { $RTM = $RTM + [char]$_ }

            } Until ($conn.result.count -lt $size)

            if ($RTM){
                try{
                    $RTM = ($RTM | convertfrom-json)
                }catch{
                    #send-SlackMsg -body "ps Bot is going down! `n $($_.Exception.Message)"-Attachments "[]" -Channel $alexChannel
                    Break
                }finally{
                    #get-date
                }

                switch ($RTM){
                    {($_.type -eq "message") -and (!$_.reply_to)}{
                        if (($_.text.StartsWith("!")) -or ($_.text -match "<@$($RTMSession.self.id)>") -or $_.channel.StartsWith("D")) { 
                            "$(get-date) - Sent to me - $($_.text)"
                            $message = $_.text.Trim("!")
                            $response = .\respondToMessage.ps1 -Message $message -Channel $rtm.channel
                            if ($response){
                                Send-SlackMsg -Text $response.message -Channel $response.channel -Attachments $response.attachment
                            }
                        }else{
                            "$(get-date) - Not sent to me - $_"
                            #msg not sent to me
                        }
                    }
                    {$_.type -eq "reconnect_url"} {$RTMSession.URL = $RTM.url }
                    {$_.type -eq "error"}{
                        if ($sent -eq $false){
                            $body = @{
                                username="ps-bot"
                                text="ps-bot is going down!"
                            } | ConvertTo-Json
                            Invoke-RestMethod -Method Post -Uri $psBotWebHook -Body $body
                            send-SlackMsg -Text "ps-bot is going down right now!!" -Channel $alexChannel
                            $sent = $true
                        }
                        "$(get-date) - Error - $_"
                        $RTMSession = Invoke-RestMethod -Uri https://slack.com/api/rtm.start -Body @{token=$Token}
                    
                    }
                    {$_.type -eq "goodbye"}{
                        $body = @{
                            username="ps-bot"
                            text="ps-bot just got type goodbye"
                        } | ConvertTo-Json
                        Invoke-RestMethod -Method Post -Uri $psBotWebHook -Body $body
                        $RTMSession = Invoke-RestMethod -Uri https://slack.com/api/rtm.start -Body @{token=$Token}
                    }
                    default {"$(get-date) - No action for $($rtm.type)"}
                }


            }

        }
    }until (!$Conn)
}finally{
    if ($WS){
        $WS.Dispose()
        $body = @{
            username="ps-bot"
            text="ps-bot is going down"
        } | ConvertTo-Json
        Invoke-RestMethod -Method Post -Uri $psBotWebHook -Body $body
    }

}
