param(
    # The RTM Value
    [Parameter(Mandatory=$True)]
    [string]
    $Message,

    [Parameter(Mandatory=$True)]
    [string]
    $Channel
)
$null = @(
    $alertsChannel = get-content ".\variables\alertsChannel.txt"
)
. .\createStuff.ps1
. .\sendMsg.ps1
. .\whosOnline.ps1

function Console ($Message) {
    Write-Host "$(get-date) - $Message"  
}

$msg = ""
$attachment = @()
$return = $True
switch ($Message){
    {$_ -match ".*help.*"}{
        Console "Help"
        $msg = "*Help* file `n The following is a list of commands that are accepted. The key words are in bold. To call a command, the message must have the key words in it. `n `n"
        $msg += "*Evolve* aaaabbbbccccdddd `n"
        $msg += "Creates an Evolve license, and then sends it to the user. `n"
        $msg += " `n"
        $msg += "*Clarify* <channel limit> aaaaabbbbbcccccdddddeeeee `n"
        $msg += "Creates an Clarify license, and then sends it to the user. Channel limit is not required. `n"
        $msg += " `n"
        # $msg += "*List sites* `n"
        # $msg += "This will list all of the sites that have sent data to the me. `n"
        # $msg += " `n"
        # $msg += "*List monitor* or *List monitored sites* `n"
        # $msg += "This will list all of the sites that are being monitored `n"
        # $msg += "If a site that is being monitored hasn't sent me data within the last 25 hours, I will send a message to the <#C7MJWNARK|alerts> channel `n"
        # $msg += " `n"
        # $msg += "*Start monitor* ing 'Site 1' `n "
        # $msg += "This will add 'Site 1' to the monitor list `n"
        # $msg += "Do not include the quotation marks `n"
        # $msg += " `n"
        # $msg += "*Stop monitor* ing 'Site 1' `n"
        # $msg += "This will remove 'Site 1' to the monitor list `n"
        # $msg += "Do not include the quotation marks `n"
        # $msg += " `n"
        # $msg += "Tell me about 'Site 1' `n"
        # $msg += "Sends you the last set of information on record about the site `n"
        # $msg += " `n"
        # $msg += "*Set tolerance* 4 `n"
        # $msg += "This will set the recording alerts tolerance to 4 `n"
        # $msg += " `n"
        $msg += "Tell me a *joke* `n"
        $msg += "This will tell you a Chuck Norris joke `n"
        $msg += " `n"
        $msg += "Give me an *excuse* `n"
        $msg += "This will give you a randmon excuse `n"
        $msg += " `n"
        $msg += "Send me a *photo* of a *dog* `n"
        $msg += "This will send you a dog photo `n"
        $msg += " `n"
        $msg += "Tell me the *time* `n"
        $msg += "This will tell you the time `n"
        $msg += " `n"
        $msg += "*Help* `n"
        $msg += "This will send you this message `n"
    }

    {$_ -match "evolve"}{
        Console "Creating Evolve license"
        #get just the key
        $triggers = $_.split()
        switch ($triggers) {
            {$triggers.length -eq 5} { #evolve aaaa bbbb cccc dddd 
                $key = "$($triggers[1])-$($triggers[2])-$($triggers[3])-$($triggers[4])"
            }
            {$triggers.length -eq 2}{ #evolve aaaabbbbccccdddd
                $key = $triggers[1]
            }
            Default {
                $msg = "Something went wrong! I couldn't understand the key you gave me"
                Console $_
                Console $_.length
                Console $triggers
                Console $triggers.length
            }
        }

        try{
            .\evolveLicenseSlackBot.exe $key $Channel
            #msg sent in python
            $msg = $false
            $attachment = $false
            $done = $True
        }catch {
            $msg = "Something went wrong!"
        }
    }
    {$_ -match "clarify"}{
        Console "Creating Clarify License"
        $triggers = $_.split()
        switch ($triggers) {
            {$triggers.length -eq 7} { #channel limit and key w/ spaces
                $channelLimit = $triggers[1]
                $key = "$($triggers[2])-$($triggers[3])-$($triggers[4])-$($triggers[5])-$($triggers[6])"
            }
            {$triggers.length -eq 6}{ #just key w/ spaces
                $channelLimit = "10"
                $key = "$($triggers[1])-$($triggers[2])-$($triggers[3])-$($triggers[4])-$($triggers[5])"
            }
            {$triggers.length -eq 3}{
                $channelLimit = $triggers[1]
                $key = $triggers[2]
            }
            {$triggers.length -eq 2}{
                $channelLimit = "10"
                $key = $triggers[1]
            }
            Default {
                $msg = "Something went wrong!  I couldn't understand the key you gave me"
                Console $_.length
                Console $_
                Console $triggers
            }
        }
        try{
            Console "Running py file"
            Console "$key $channelLimit $Channel"
            $r = (.\clarifyLicenseSlackBot.exe $key $channelLimit $Channel)
            Console $r
            #msg sent in python
            $msg = $false
            $attachment = $false
            $done = $True
        }catch {
            $msg = "Something went wrong!"
        }

    }

    {$_ -match ".*joke.*"}{
        Console "Getting a joke"
        $msg = ((Invoke-RestMethod -Method Get -Uri "http://api.icndb.com/jokes/random").value).joke
    }

    {$_ -match ".*excuse.*"}{
        Console "Getting an excuse"
        $msg = (Invoke-WebRequest http://pages.cs.wisc.edu/~ballard/bofh/excuses -OutVariable excuses).content.split([Environment]::NewLine)[(get-random $excuses.content.split([Environment]::NewLine).count)]
    }

    {$_ -match ".*dog.*" -and $_ -match ".*photo.*" -and !($_ -match "Here is a photo of a dog:")}{
        Console "Getting an image of a dog"
        $image = (((Invoke-WebRequest -Method get -Uri "http://api.thedogapi.co.uk/v2/dog.php").content) | convertFrom-json).data.url
        $attachment += Create-Attachment -Fallback "Dog Photo" -ImageURL $image -Title "Dog photo" -Text "Dog photo"
        $msg = "Here is a photo of a dog:"
    }
    {$_ -match ".*time.*"}{
        Console "Getting the time"
        $time = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
        $msg = "The time is <!date^$time^{time} on {date}|$(Get-Date)>"
    }
    {$_ -match "who's online"}{
        Console "Getting who's online"
        $up = Invoke-Expression ".\whosOnline.ps1"
        $ipString = " "
        $hostNameString = " "
        $up | ForEach-Object {
            $ipString += $_.IPAddress.IPAddressToString
            $ipString += " `n "
            if ($_.HostName -eq $null){
                $hostnameString += "-"
            }else{
                $hostnameString += $_.HostName
            }
            $hostNameString += " `n "
        }
        $ipField = Create-Field -Title "IP Address" -Value $ipString -Short $True
        $hostNameField = Create-Field -Title "Host Name" -Value $hostNameString -Short $True
        $fields = @($ipField,$hostNameField)
        $msg += "These people are online"
        $attachment += Create-Attachment -Title "Who's online?" -Fields $fields -Text "The following people are online:"
    }
    {$_ -match "(.+),(.+),(\d+),(\d+),(\d+),(\d+),(\d\.\d+),(\d+),(\d+),(.+)"}{
        Console "Reading CollectCents pulse"
        #Site,Loc,Large,Small,Empty Recordings,Date (UNIX),Free Space,Last Col Date,Last Rec Date,BoardStatus
        #is a csv, do analysis
        $splitData = $_ -split ","
        $datum = @{
            "Site" = $splitdata[0];
            "Location" = $splitdata[1];
            "Large" = $splitdata[2];
            "Small" = $splitdata[3];
            "Empty" = $splitdata[4];
            "Date" = $splitdata[5];
            "FreeSpace" = $splitdata[6];
            "LastCol" = $splitdata[7];
            "LastRec" = $splitdata[8];
            "BoardStatus" = $splitdata[9];
        }
        $_ | Out-File ".\recordingData.csv" -Append
        
        $color = "good"
        $text = ""
        if ($datum.BoardStatus -ne "NA"){
            $msg = "For the site $($datum.Site): "
            $color = "danger"
            $text += "Something's up with board $($datum.BoardStatus) `n"
        }
        if ($datum.lastRec -lt ([int][double]::Parse((Get-Date ((get-date).AddHours(-2)).ToUniversalTime() -UFormat %s)))) { #something about last rec file being older than 2 hours
            $msg = "For the site $($datum.Site): "
            $color = "danger"
            $text += "The .rec file hasn't been written to in over two hours! `n"
        }
        if ($datum.lastCol -lt ([int][double]::Parse((Get-Date ((get-date).AddHours(-2)).ToUniversalTime() -UFormat %s)))){ #something about last col file being older than 2 hours
            $msg = "For the site $($datum.Site): "
            $color = "danger"
            $text += "The .col file hasn't been written to in over two hours! `n"
        }

        if ($color -eq "danger"){
            $fields = @()
            $fields += Create-Field -Title "Last recorded write to .col file" -Value "<!date^$($datum.LastCol)^{time} on {date}|you need to update slack>" -Short $True
            $fields += Create-Field -Title "Last recorded write to .rec file" -Value "<!date^$($datum.LastRec)^{time} on {date}|you need to update slack>" -Short $True
            $fields += Create-Field -Title "Large recordings" -Value $datum.Large -Short $True
            $fields += Create-Field -Title "Small recordings" -Value $datum.Small -Short $True
            $fields += Create-Field -Title "0KB recordings" -Value $datum.Empty -Short $True
            $fields += Create-Field -Title "Free space" -Value ([double]($datum.FreeSpace)).ToString("P") -Short $True
            $attachment += Create-Attachment -Fallback "Alert for location '$($datum.location)" -Color $color -Title $datum.location -Text $text -Fields $fields
            $Channel = $alertsChannel
        }else{
            $done = $True
        }
        

    }
    default { 
        Console "No response"
        $msg = $false
        $attachment = $false
    }
}
if ($done){
    $return = "Done"
}elseif (!$return){
    Console "Return False"
    $return = $False
}elseif (!$msg -and !$attachment){
    Console "No msg or att"
    $return = $false
}else{
    $return = @{
        message = $msg
        attachment = $attachment
        channel = $Channel
    }
}

$return