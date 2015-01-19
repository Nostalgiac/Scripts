#########################################################
#		Updates a SharePoint list from a CSV File#
#		Version: 1.0				#
#		Created: 19/01/2015			#
#		Creator: Nostalgiac			#
#########################################################

#Add SharePoint Module if not already loaded
if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null ) 
{ 
   Add-PsSnapin Microsoft.SharePoint.PowerShell 
} 
$host.Runspace.ThreadOptions = "ReuseThread"

#Connect to the SharePoint List 
$SPServer="http://sharepoint"
$SPAppList="/Lists/Phonebook/" 
$spWeb = Get-SPWeb $SPServer 
$spData = $spWeb.GetList($SPAppList)

#Get Data from Inventory CSV File
$InvFile="C:\Scripts\AD-Export.csv"
$FileExists = (Test-Path $InvFile -PathType Leaf) 
if ($FileExists) {
	"Loading $InvFile ..." 
	$tblData = Import-CSV $InvFile 
	} else { 
	"$InvFile not found! Abort!" 
	exit
}

#Loop through the CSV and upload them to SharePoint
#Only updates existing fields in SharePoint List
"Updating SharePoint List"
foreach ($row in $tblData) 
{
	$accountName = $row."givenName".ToString() + " "  + $row."sn".ToString()
	$item = $spData.Items.Add()
	$item = $spData.Items | where {($_['Employee'].substring(5) -like $accountName) -or ($_['Titlex'] -like $accountName)}
	$item["Primary Program"] = $row."company".ToString()
	$item.Update() 
}

"---------------" 
"Upload Complete"
"---------------" 
$spWeb.Dispose()