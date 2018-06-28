#Bulk change the limiting collection for a group/folder of collections.
#SMS00001 = All Systems.

$collections = Get-WmiObject -Namespace "root\SMS\Site_CIT" -Class SMS_Collection | where {($_.LimitToCollectionID -eq "SMS00001") -and ($_.ObjectPath -like "/Subfolder Name")}

foreach($coll in $collections){
 $coll.LimitToCollectionName = "New Limiting Collection Name)"
 $coll.LimitToCollectionID = "New Limiting Collection ID"
 $coll.Put()
}
