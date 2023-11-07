#This is to run Commvault Stubs restore jobs sequentially, based on a csv file with the qoperation commands to run. Also requires the appropriate restore config xml file on the commvault server.
#Example CSV
SmtpAddress,IsCompleted,Scripttorun
spaterso@abn.group - {463BBD29XB776X442CXA43EX014A5727DB7E},,"qoperation execute -af ""C:\CommvaultScripts\file2_restore.xml"" -destPath ""PST:F:\restores\PST_Export\user@contoso.local - {463BBD29XB776X442CXA43EX014A5727DB7E}\RESTORE.PST"" -pstFilePath ""E:\restores\PST_Export\user@contoso.local - {463BBD29XB776X442CXA43EX014A5727DB7E}\RESTORE.PST"" -sourceItem ""\MB\{463BBD29XB776X442CXA43EX014A5727DB7E}"""

#Setup
#File 1
#$pattern = '\\PST_EXPORT\\([^\\]+)'
#File 2
$pattern = '\\PST_EXPORT\\([^\\]+) - '

$outfile = "C:\Scripts\File2-Results.csv"

#Uncomment to create CSV if this is the first run.
#$header = "JobID,EmailAddress,JobStatus,JobReason"
#$header | Out-File -FilePath $outfile

#Login to Commvault
qlogin -sso

$csv = Import-CSV -Path 'C:\Scripts\File2-Restores.csv'

foreach($line in $csv){
    #Start the job
    $runCommand = Invoke-Expression $line.Scripttorun

    #Convert to XML
    $runCommandXML = [xml]$runCommand

    #Get the Job ID returned.
    $jobId = $runCommandXML.TMMsg_CreateTaskResp.jobIds.val

    do {
        #Every 30 seconds
        Start-Sleep -Seconds 30
        #Get Job details as xml
        $getJobDetailsXML = qlist job -j $jobId -format xml
        #Parse xml into PSObject
        $getJobDetails = [xml]$getJobDetailsXML
        #$getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs
        "Running job $($getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs.jobId)..."
        #While the complete percentage is not finished
        } while ($getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs.completePercentage -ne "100")

    #Save Results
    #Grab email from original query
    $matches = $line.Scripttorun | Select-String -Pattern $pattern
    $emailAddress = $matches | ForEach-Object { $_.Matches[0].Groups[1].Value }

    if($getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs.failureReasons.EventMsg){
    $failureReason = $getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs.failureReasons.EventMsg
    } else {
    $failureReason = ""
    }

    #Import existing results file
    $csvfile = Import-csv $outfile


    #Create object with data
    $newData = [PSCustomObject]@{
        EmailAddress = $emailAddress
        JobID = $getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs.jobId
        JobStatus = $getJobDetails.GalaxyUtilities_QGetJobsRespMsg.jobs.jobStatus
        JobReason = $failureReason
    }

    $newData | Export-csv -path $outfile -Append -NoTypeInformation


    $StubsDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID = 'F:'" -ComputerName RESTORELOCATION |
        Select-Object -Property DeviceID, VolumeName, @{Label='FreeSpace (Gb)'; expression={($_.FreeSpace/1GB).ToString('F2')}},
        @{Label='Total (Gb)'; expression={($_.Size/1GB).ToString('F2')}},
        @{label='FreePercent'; expression={[Math]::Round(($_.freespace / $_.size) * 100, 2)}}

    "$($StubsDrive.DeviceID) on RESTORELOCATION has $($StubsDrive.'FreeSpace (Gb)')GB remaining ($($StubsDrive.FreePercent)%)"

    if($StubsDrive.FreePercent -lt '1.5'){
    "Drive is near full, exiting script..."
    Send-MailMessage -SmtpServer mail.contoso.local -From "COMMVAULT@contoso.local" -To "admin@contoso.local" -Subject "RESTORELOCATION drive almost full" -Body "RESTORELOCATION Drive almost full."
    break
    }

}


Send-MailMessage -SmtpServer mail.contoso.local -From "COMMVAULT@contoso.local" -To "admin@contoso.local" -Subject "Restore batch finished" -Body "Finished current batch of restores."
