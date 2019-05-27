#Referenced by GPO 'Server Policy - Cleanup IIS Logs'

#Import IIS Module
Import-Module WebAdministration

#Set max days of log files
$maxDaystoKeep = -90

#Get list of IIS Websites
$Websites = Get-Website

if($Websites){
    ForEach($WebSite in $Websites){
        #Get log path for website        
        $LogPath = "$($Website.logFile.directory)\W3SVC$($website.id)".replace("%SystemDrive%",$env:SystemDrive)
      
        #Generate list of old logs
        $logsToDelete = Get-ChildItem $LogPath -Recurse -File *.log | Where LastWriteTime -lt ((Get-Date).AddDays($maxDaystoKeep)) 
    
        #Delete list of old logs
        if ($logsToDelete.Count -gt 0){ 
            ForEach ($log in $logsToDelete){ 
                Get-item $log.FullName | Remove-Item
            } 
        }
    } 
}else {
    #No websites found, check default dir anyway and clear out if needed.
    $logsToDelete = Get-ChildItem "C:\inetpub\logs\LogFiles\" -Recurse -File *.log | Where LastWriteTime -lt ((Get-Date).AddDays($maxDaystoKeep)) 
  
    if ($logsToDelete.Count -gt 0){ 
        ForEach ($log in $logsToDelete){ 
            Get-item $log.FullName | Remove-Item
        } 
    }

}
