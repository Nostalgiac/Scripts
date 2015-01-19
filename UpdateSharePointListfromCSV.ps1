##########################################################
#		Updates a SharePoint list from a CSV File#
#		Version: 1.0				 #
#		Created: 19/01/2015			 #
#		Creator: Nostalgiac			 #
#							 #
#	Updates the SharePoint column 'Primary Program'
	based on the 'company column in the CSV File. It will
	only update if
	
#########################################################

$host.Runspace.ThreadOptions = "ReuseThread"

#Add SharePoint Module
Add-PsSnapIn Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 

#Connect to the SharePoint List 
$spServer="http://sharepoint"
$spAppList="/Lists/Phonebook/" 
$spWeb = Get-SPWeb $spServer 
$spData = $spWeb.GetList($spAppList)

#Get Data from Inventory CSV File
$csvFile="C:\Scripts\AD-Export.csv"
If (Test-Path $csvFile){
	"Loading $csvFile ..." 
	$tblData = Import-CSV $csvFile 
	} else { 
	"$csvFile does not exist." 
	exit
}

#Loop through the CSV and update the SharePoint List
"Updating SharePoint List..."
foreach ($row in $tblData){
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