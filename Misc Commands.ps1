#########################
#		Active Directory		#
#########################


#Find users that have not set their password since $searchDate
$searchDate = "2021-11-07" #yyyy-MM-dd format  
$passwordsNotChangedSince = $([datetime]::parseexact($searchDate,'yyyy-MM-dd',$null)).ToFileTime() 
$users = Get-ADUser -filter { Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties pwdLastSet | where { $_.pwdLastSet -lt $passwordsNotChangedSince -and $_.pwdLastSet -ne 0 } | Select-Object name,sAmAccountName,@{Name="PasswordLastSet";Expression={[datetime]::FromFileTimeUTC($_.pwdLastSet)}} 

#LastLogonTimestamp conversion
Get-ADUser -Filter * -SearchBase "OU=Accounts,DC=constso,DC=local" -Properties lastLogonTimestamp | select samAccountName,Name,Enabled, @{N='LastLogonTimestamp'; E={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

#Find AD user based on partial phone number match
Get-ADUser -filter 'telephoneNumber -like "*0434*"' -Properties telephoneNumber | select Name,telephoneNumber

#Workstation OU Report one liner
Get-ADComputer -SearchBase "OU=Workstations,DC=contoso,DC=local" -Filter * -Properties lastLogonTimestamp,pwdLastSet,Description,OperatingSystem,OperatingSystemVersion,distinguishedName,canonicalName  |?{$_.DistinguishedName -notlike "*OU=Z - DaaS*"} | select Name,@{N='LastLogonTimestamp'; E={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}, @{N='pwdLastSet'; E={[DateTime]::FromFileTime($_.pwdLastSet)}},Description,OperatingSystem,OperatingSystemVersion,distinguishedName,canonicalName | export-csv C:\temp\Workstations.csv  

#Disable computers and move to OU
foreach($computer in $csv){
    Get-ADObject $computer.distinguishedName | Disable-ADAccount
    Get-ADObject $computer.distinguishedName | Move-ADObject -TargetPath "OU=Retired,DC=contoso,DC=local"
}

#Remove all group memberships from a set of users
$users = Get-ADuser -filter {samAccountName -like 'admin*'} -SearchBase "OU=Disabled Accounts,DC=contoso,DC=local" -Properties memberOf

foreach($user in $users){
    $groups = $user.Memberof
    foreach ($group in $groups) {
        Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false -WhatIf
        Write-Host "Removed user $user.Name from group $group."
    }
}



#########################
#		Exchange		#
#########################

#Search all mailboxes on Exchange server for particular emails, send results to Discovery Seach Mailbox.
Get-Mailbox -Server  "EXCHANGE" | Search-Mailbox -SearchQuery 'from:sender@domain.com.au' -targetmailbox "Discovery Search Mailbox" -targetfolder "Inbox" -logonly -loglevel full
Get-Mailbox -Server  "EXCHANGE" | Search-Mailbox -SearchQuery 'from:sender@domain.com.au' -deletecontent

#Hide all disabled users from GAL
Get-Mailbox -OrganizationalUnit "Disabled Users" | Set-Mailbox -HiddenFromAddressListsEnabled $true

#########################
#		Miscellaneous		#
#########################
#Find all folders with partial name match of two strings.
$rootDirectory = "\\SERVERNAME\d$\Data"
$matchingFolders = Get-ChildItem -Path $rootDirectory -Recurse -Directory | Where-Object { $_.Name -match 'covid19|cov' }
$matchingFolders | export-csv -NoTypeInformation Desktop\MatchingExport.csv


#Summarise Windows DNS log file
$logFile = "C:\temp\DNS-05-09-2023.log"
$ipAddresses = Get-Content $logFile | Select-String -Pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -AllMatches | ForEach-Object {$_.Matches.Value}
$ipCounts = $ipAddresses | Group-Object | Sort-Object Count -Descending
foreach ($ip in $ipCounts) {
    Write-Host $ip.Name "appeared" $ip.Count "times in the log file."
}


#Update VMTools based on group membership
Import-Module VMWare.PowerCLI
Connect-VIServer -Server vcentereaddress
$servers = Get-ADGroupMember -Identity "AD_Group_Update_1"
$needsUpgrade = 0
$upToDate = 0
foreach($server in $servers){
    #Check it needs upgrade
    $upgrade = Get-VM $server.Name | % { get-view $_.id } |Where-Object {$_.Guest.ToolsVersionStatus -like "guestToolsNeedUpgrade"}  |select name, @{Name=“ToolsVersion”; Expression={$_.config.tools.toolsversion}}, @{ Name=“ToolStatus”; Expression={$_.Guest.ToolsVersionStatus}}
    if($upgrade){
        #Uncomment to actually update.
        #Update-Tools -VM $server.Name -Verbose
        "Update tools on $($server.Name)"
        $needsUpgrade += 1
    } else {
        "$($server.Name) up to date already or not found."
        $upToDate += 1
    }
}
"Total count in group: $($servers.count)"
"Up to date: $($upToDate)"
"Needs upgrade: $($needsUpgrade)"

#Run a compliance search action a gazillion times
Connect-IPPSSession
$searchName = "Search name goes here"
$searchNamePurge = "$searchName" + "_Purge"
$action = {
    New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType HardDelete -Confirm:$false -Force
}
for ($i = 1; $i -le 400; $i++) {
    Write-Host "Executing iteration $i"
    do {
        Start-Sleep -Seconds 10
        $status = Get-ComplianceSearchAction | Where-Object { $_.Name -eq $searchNamePurge }
        Write-Host "Status: $($status.Status)"
    } while ($status.Status -ne "Completed")

    try {
        & $action
    }
    catch {
        Write-Host "An error occurred while executing the command. Exiting loop."
        break
    }
}

#Adds Tls1.2 to Windows
#https://stackoverflow.com/questions/28286086/default-securityprotocol-in-net-4-5
[Net.ServicePointManager]::SecurityProtocol = ([Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12)

#Send an email with SSL.
Send-MailMessage -from "sender@contoso.local" -To "recipient@contoso.local" -Subject "From Subject" -Body "Test Email" -UseSsl -SmtpServer email.contoso.local -Port 587 -Credential $creds




#########################
#		SharePoint		#
#########################

#Set SharePoint site to 'Open Documents in Client Application by Default'
Get-SPSite -WebApplication http://sharepoint/ -limit ALL | foreach{ Enable-SPFeature 8A4B8DE2-6FD8-41e9-923C-C7C3C00F8295 -url $_.URL }

#Remove 'Maintenance Mode' (Read Only) from SharePoint Site
$SPURL = new-object Microsoft.SharePoint.Administration.SPSiteAdministration('http://sharepoint/')
$SPURL.ClearMaintenanceMode()
