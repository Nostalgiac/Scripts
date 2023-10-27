#Can be used after Search-DCEvents.ps1 to filter the messages to a digestable list. (eg. if searching for logon events and you want a summarised view of the source IPs).

$pattern = 'Source Network Address:\s+(\d+\.\d+\.\d+\.\d+)'
#$match = [regex]::Match($eventArray[2].Message, $pattern)
$newArray = @()

$eventArrayNew = $eventArray
foreach($item in $eventArrayNew){
    $match = [regex]::Match($item.Message, $pattern)
    $sourceMatch = $match.Value
    
    $customObject = [PSCustomObject]@{
    Sources = $sourceMatch
    TimeCreated = $item.TimeCreated
    }
    
    $newArray += $customObject
}

#$newArray | Sort-Object -Property Sources | Get-Unique | Out-GridView
$newArray | Out-GridView
