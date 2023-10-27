###Search for an event or string across all domain controller event logs.###
#This example searches for ID 4624 for the account 'accountnamehere'. The data matches anything in the description. ID filters to only those event id's.

# Get all domain controllers in the current domain
$domainControllers = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
$eventLog = $null
$eventArray = @()
$Yesterday = (Get-Date) - (New-TimeSpan -Day 31)

$filter = @{
    LogName = 'Security'
    ID = 4624
    StartTime = $Yesterday
    Data = 'accountnamehere'
}

    #Stopwatch
    $stopWatchTotal = New-Object -TypeName 'System.Diagnostics.Stopwatch'
    $stopWatchTotal.Start()

# Iterate through each domain controller
foreach ($dc in $domainControllers) {
    Write-Host "Searching event logs on $dc..."


    #Stopwatch
    $stopWatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
    $stopWatch.Start()


    # Connect to the remote event log
    $eventLog = Get-WinEvent -ComputerName $dc -FilterHashtable $filter -ErrorAction SilentlyContinue

    $stopWatch.Stop()


    if ($eventLog) {

    $eventArray += $eventLog
    Write-Host "Found $($eventLog.Count) authentication events on on $dc after $($stopwatch.Elapsed.Minutes)m:$($stopwatch.Elapsed.Seconds)s."
        } else {
            Write-Host "No authentication events found on $dc after $($stopwatch.Elapsed.Minutes)m:$($stopwatch.Elapsed.Seconds)s."
        }
}

"Found $($eventArray.count) authentication events across all dcs after $($stopwatchTotal.Elapsed.Minutes)m:$($stopwatch.Elapsed.Seconds)s."


