
$null = @(
    $url = get-content ".\variables\whosOnlineURL.txt"
)
$ipAddresses = Get-DhcpServerv4lease -ScopeId 192.168.69.0 | Where-Object {$_.AddressState -eq "Active"}
$up = @()
$down = @()
$time = [int][double]::Parse((Get-Date -UFormat %s))
$ipAddresses | ForEach-Object{
    $Ping = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$($_.IPAddress.IPAddressToString)' AND Timeout=5000";
    if ($Ping.StatusCode -eq 0){
        $details = @{
            ipAddress = $_.IPAddress.IPAddressToString;
            hostName = $_.HostName
            MAC = $_.ClientId
            timeStamp = $time
        }
        $body = @{
            httpMethod = "PUT";
            body = $details
        }
        $null = Invoke-WebRequest -Uri $url -Method Put -Body ($body | ConvertTo-Json)
        $up += $_
    } else {
        $down += $_   

    }
}
$up