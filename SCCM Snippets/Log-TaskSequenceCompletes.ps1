#Connect to SCCM
if (test-path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1") { import-module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" }
if (test-path "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1") { import-module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" }
$SiteCode = "xxx"
cd "$($SiteCode):"
$CMServerName = "SCCM-Site-Server.ad.domain"
  
#Set Parameters
$logfile = "C:\Scripts\TSComplete.log"
$recordIDArray = @()
$date = (get-date).AddDays(-1)

#Get Status Messages for Successful task sequences
#$messages = Get-CMSiteStatusMessage -MessageId 11171 -StartDateTime $date | select Time,MachineName,RecordID -Unique | sort Time
$messages = Get-CMSiteStatusMessage -MessageId 11171 -StartDateTime $date | select @{n='Time';e={$_.Time.AddHours(8)}},MachineName,RecordID -Unique | sort Time
$csvOutput = $messages | ConvertTo-Csv -NoTypeInformation | Select -Skip 1

#Import existing log file
$csv = Import-Csv -Path $logfile -Header Time,MachineName,RecordID

#For each message in SCCM, check if exists, else add.
foreach($line in $csvOutput){
    $lineFormat = $line -replace "`"", ""
    $lineFormat = $lineFormat.Split("{,}")
    $recordID = $lineFormat[2]

    if($csv.RecordId -match $recordID){
        #"$recordID already exists in log"
    } else {
        #"Does not exist in log, add $recordID"
        $line | Out-File -FilePath $logfile -Append -Encoding utf8
        #[IO.File]::WriteAllLines($logfile, $line)

    }

}
