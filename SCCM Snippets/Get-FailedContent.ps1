#Connect to SCCM
if (test-path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1") { import-module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" }
if (test-path "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1") { import-module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" }

$SiteCode = "xxx"
cd "$($SiteCode):"
$CMServerName = "SCCM-Site-Server.ad.domain"

$DistributionPoints = Get-CMDistributionPoint | select NetworkOSPath
$resultsArray = @()

foreach($dp in $DistributionPoints){
    $dp = $dp.NetworkOSPath -replace '[\\]'
    $SiteSystemServerName = $dp

    $query = Get-WmiObject –NameSpace Root\SMS\Site_$SiteCode –Class SMS_DistributionDPStatus -ComputerName $CMServerName –Filter "Name='$SiteSystemServerName'" | where{$_.MessageState -notlike "1"} |Select PackageId,MessageID, MessageState, LastUpdateDate
    $query | %{
                $pkgname = (Get-CMPackage -Id $_.PackageId |Select-Object Name).Name
                if(!($pkgname)){$pkgname = (Get-CMDriverPackage -Id $_.PackageId |Select-Object Name).Name}
	            if(!($pkgname)){$pkgname = (Get-CMBootImage -Id $_.PackageId |Select-Object Name).Name}
	            if(!($pkgname)){$pkgname = (Get-CMOperatingSystemImage -Id $_.PackageId |Select-Object Name).Name}
	            if(!($pkgname)){$pkgname = (Get-CMSoftwareUpdateDeploymentPackage -Id $_.PackageId |Select-Object Name).Name}
                if(!($pkgname)){$pkgname = "Application, name can't be found"}

                switch ($_.MessageState){
                        1{$Status = "Success"}
                        2{$Status = "In Progress"}
			            3{$Status = "Unknown"}
                        4{$Status = "Failed"}
                    }
                    switch ($_.MessageID){
                        2303{$Message = "Content was successfully refreshed"}
                        2323{$Message = "Failed to initialize NAL"}
                        2324{$Message = "Failed to access or create the content share"}
                        2330{$Message = "Content was distributed to distribution point"}
                        2354{$Message = "Failed to validate content status file"}
                        2357{$Message = "Content transfer manager was instructed to send content to Distribution Point"}
                        2360{$Message = "Status message 2360 unknown"}
                        2370{$Message = "Failed to install distribution point"}
                        2371{$Message = "Waiting for prestaged content"}
                        2372{$Message = "Waiting for content"}
                        2380{$Message = "Content evaluation has started"}
                        2381{$Message = "An evaluation task is running. Content was added to Queue"}
                        2382{$Message = "Content hash is invalid"}
                        2383{$Message = "Failed to validate content hash"}
                        2384{$Message = "Content hash has been successfully verified"}
                        2391{$Message = "Failed to connect to remote distribution point"}
                        2398{$Message = "Content Status not found"}
                        8203{$Message = "Failed to update package"}
                        8204{$Message = "Content is being distributed to the distribution Point"}
                        8211{$Message = "Failed to update package"}
                    }
        
            $resultsObject = [PSCustomObject]@{
                    'Name' = $pkgname
                    'PackageID' = $_.PackageID
                    'Distribution Point'= $SiteSystemServerName
                    'Status' = $Status
                    'Message' = $Message
                    'LastUpdated' = [System.Management.ManagementDateTimeconverter]::ToDateTime($_.LastUpdateDate)
            }
            $resultsArray += $resultsObject
    }
    
}
if(!$resultsArray){
Write-Host -ForegroundColor Green "Congratulations, no content has failed or is in progress!"
break
}

#Display results in a table.
#$resultsArray | Sort-Object PackageID | ft -AutoSize

#Pipe to Grid View and Selecting a row and pressing Ok will redistribute it.
$resultsArray | Sort-Object PackageID | Out-GridView -Title "Select package(s) to redistribute" -OutputMode Multiple |
                 ForEach-Object {
                    Get-WmiObject -Namespace root\sms\site_CIT -ComputerName $CMServerName -Query "SELECT * FROM SMS_DistributionPoint WHERE PackageID='$($_.PackageID)' and ServerNALPath like '%$($_.'Distribution Point')%'" |
                        ForEach-Object {
                            $_.RefreshNow = $true
                            $_.Put()

                            
                        }
                }
