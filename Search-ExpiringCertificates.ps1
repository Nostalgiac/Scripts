#This will search all servers for certificates that are expiring in the next (31) days and then email you the report.
#Requires "Remote Managemenet Users" access to those servers.

#Set working directory like a noob.
cd "D:\Scripts\ExpiringCertificates"

#Delete previous report
Remove-Item .\Certs.csv -Confirm:$false

#Script setup
$count = 0
$i = 0
$j = 0
$EmailObject = @()

#Get all PRODUCTION servers
$servers = Get-ADComputer -Filter "OperatingSystem -like 'Windows Server*'" -SearchBase "OU=Servers,DC=contoso,DC=local"

#Foreach server, check the local cert store for certificates expiring in the next 31 days.
$servers | foreach {
    $progress = ($count++/$servers.count) * 100
    Write-Progress -Activity "Checking $_" -Status "$progress % completed" -PercentComplete $progress;
    
    if(Test-Connection -ComputerName $_.DNSHostName -Count 2 -Quiet){
        $Invoke = Invoke-Command -ComputerName $_.DNSHostName {dir 'Cert:\LocalMachine\my' -Recurse | ? { $_.NotAfter -lt (Get-Date).AddDays(31) -and $_.NotAfter -gt (Get-Date) } | Select-Object -Property FriendlyName, Thumbprint, SerialNumber, Subject, NotBefore, NotAfter}
        $j++
        if($Invoke){
            $EmailObject += $Invoke
            $i++
        }
    }
}

#"Checked $j servers. $i servers have certificates expiring."
#"Results"
#$EmailObject | ft -auto| Out-String

#Export results to a csv file, then email it out.
$EmailObject | Export-Csv -NoTypeInformation Certs.csv
Send-MailMessage -SmtpServer mailrelay.abn.group -From "server@contoso.local" -To "dl@contoso.local" -Subject "$i certifcates are expiring." -Body "Checked $j servers. $i servers have certificates expiring. (Attached)." -Attachments .\Certs.csv
