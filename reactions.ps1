function Do-Reaction {
    param(
        # add or remove
        [Parameter(Mandatory=$True)]
        #[ValidatesSet('Add','Remove')]
        [string]
        $Action,   

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
    switch ($Action) {
        {$_ -eq "Add"} {
            $null = @(
                Start-Job -InitializationScript {import-module -name C:\Users\Administrator\Documents\Powershell\SlackBot\reactions.ps1} -ScriptBlock { param($1, $2, $3)
                    cd "C:\Users\Administrator\Documents\Powershell\SlackBot"
                    Add-Reaction -Channel $1 -Timestamp $2 -Emoji $3
                    "$1 , $2 , $3"
                } -arg $Channel,$Timestamp,$Emoji
            )
        }
        {$_ -eq "Remove"}{
            $null = @(
                Start-Job -InitializationScript {import-module -name C:\Users\Administrator\Documents\Powershell\SlackBot\reactions.ps1} -ScriptBlock { param($1, $2, $3)
                    cd "C:\Users\Administrator\Documents\Powershell\SlackBot"
                    Remove-Reaction -Channel $1 -Timestamp $2 -Emoji $3
                    "$1 , $2 , $3"
                } -arg $Channel,$Timestamp,$Emoji
            )
        }
        Default {
            return $False
        }
    }
}

function Add-Reaction {
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
    Write-Host "adding reaction $Channel , $Timestamp , $Emoji"
    $null = @(
        $token = get-content ".\variables\token.txt" #not making that mistake again...
    )

    $message = @{
        name = $Emoji
        channel = $Channel
        timestamp = $Timestamp
        token = $token
    }
    $json = $message | ConvertTo-Json -Depth 5

    $url = "https://slack.com/api/reactions.add"

    $contentType = "application/json; charset=utf-8"
    $headers = @{
        Authorization = "Bearer $token"
    }

    $r = Invoke-WebRequest -Method Post -Uri $url -body $json -ContentType $contentType -Headers $headers 
    while ($True){
        try{
            [IO.File]::OpenWrite("slack.log").close()
            $r | out-file -filepath "slack.log" -append
            break
        } catch {}
    }
    
}


Function Remove-Reaction {
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

    $url = "https://slack.com/api/reactions.remove"

    $contentType = "application/json; charset=utf-8"
    $headers = @{
        Authorization = "Bearer $token"
    }

    $r = Invoke-WebRequest -Method Post -Uri $url -body $json -ContentType $contentType -Headers $headers
    while ($True){
        try{
            [IO.File]::OpenWrite("slack.log").close()
            $r | out-file -filepath "slack.log" -append
            break
        } catch {}
    }
}