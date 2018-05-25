
#a lot of the code that runs the bot has been shamelessly stolen from https://github.com/markwragg/Powershell-SlackBot
cd "C:\Users\Administrator\Documents\Powershell\SlackBot"
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

. .\sendMsg.ps1
. .\reactions.ps1
. .\createStuff.ps1

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
                        if (($_.channel -eq $oldChannel) -and ($_.ts -eq $oldTS)){
                            "$(get-date) - I sent this - $($_.text)"
                        }elseif (($_.text.StartsWith("!")) -or ($_.text -match "<@$($RTMSession.self.id)>") -or $_.channel.StartsWith("D") ) { 
                            "$(get-date) - Sent to me - $($_.text)"
                            #send hourglass_flowing_sand reaction
                            #start-job -FilePath .\reactions.ps1 -ArgumentList 
                            Do-Reaction -Action "Add" -Channel $rtm.channel -Timestamp $rtm.ts -Emoji "hourglass_flowing_sand"
                            $message = $_.text.Trim("!")
                            $response = .\respondToMessage.ps1 -Message $message -Channel $rtm.channel
                            if ($response -eq "Done"){
                                Do-Reaction -Action "Remove" -Channel $rtm.channel -Timestamp $rtm.ts -Emoji "hourglass_flowing_sand"
                                Do-Reaction -Action "Add" -Channel $rtm.channel -Timestamp $rtm.ts -Emoji "heavy_check_mark"
                            }elseif ($response){
                                $oldChannel, $oldTS = Send-SlackMsg -Text $response.message -Channel $response.channel -Attachments $response.attachment
                                Do-Reaction -Action "Remove" -Channel $rtm.channel -Timestamp $rtm.ts -Emoji "hourglass_flowing_sand"
                                Do-Reaction -Action "Add" -Channel $rtm.channel -Timestamp $rtm.ts -Emoji "heavy_check_mark"
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
