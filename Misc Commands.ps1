#########################
#		Exchange		#
#########################

#Search all mailboxes on Exchange server for particular emails, send results to Discovery Seach Mailbox.
Get-Mailbox -Server  "EXCHANGE" | Search-Mailbox -SearchQuery 'from:sender@domain.com.au' -targetmailbox "Discovery Search Mailbox" -targetfolder "Inbox" -logonly -loglevel full
Get-Mailbox -Server  "EXCHANGE" | Search-Mailbox -SearchQuery 'from:sender@domain.com.au' -deletecontent

#Hide all disabled users from GAL
Get-Mailbox -OrganizationalUnit "Disabled Users" | Set-Mailbox -HiddenFromAddressListsEnabled $true

#########################
#		SharePoint		#
#########################

#Set SharePoint site to 'Open Documents in Client Application by Default'
Get-SPSite -WebApplication http://sharepoint/ -limit ALL | foreach{ Enable-SPFeature 8A4B8DE2-6FD8-41e9-923C-C7C3C00F8295 -url $_.URL }

#Remove 'Maintenance Mode' (Read Only) from SharePoint Site
$SPURL = new-object Microsoft.SharePoint.Administration.SPSiteAdministration('http://sharepoint/')
$SPURL.ClearMaintenanceMode()