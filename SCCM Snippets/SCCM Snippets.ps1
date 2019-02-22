#Bulk change the limiting collection for a group/folder of collections.
#SMS00001 = All Systems.

$collections = Get-WmiObject -Namespace "root\SMS\Site_CIT" -Class SMS_Collection | where {($_.LimitToCollectionID -eq "SMS00001") -and ($_.ObjectPath -like "/Subfolder Name")}

foreach($coll in $collections){
 $coll.LimitToCollectionName = "New Limiting Collection Name"
 $coll.LimitToCollectionID = "New Limiting Collection ID"
 $coll.Put()
}



#Add User Group Resource (AD Security Group) as a Direct Membership Rule
$SiteCode = "XXX"
$collectionName = "User Collection Name"
$ADGroupName = "Domain\SecGrp"
$SCCMServer = "primary-server.domain.com"

$UserGroups = Get-WmiObject -Namespace "root\sms\site_$($SiteCode)" -Class 'SMS_R_UserGroup' -ComputerName $SCCMServer
$GroupToAdd = $UserGroups | Where Name -eq $ADGroupName

 Add-CMUserCollectionDirectMembershipRule -CollectionName $collectionName -ResourceId $GroupToAdd.ResourceId
