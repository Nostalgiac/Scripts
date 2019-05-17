#Disconnect Local User Sessions where AD password has expired

#Update the LDAP SearchRoot for your domain
#Update the $maxAge for your password maximum age

$i = 1

#Get session info from computer
$session = (quser | Where-Object { $_ -match 'Disc' }) -split ' +'

#Loop over number of sessions
while($i -le $session.count){
    $username = $session[$i]
    $sessionId = $session[$i+1]

    #Search AD for username
    $Searcher = New-Object DirectoryServices.DirectorySearcher
    $Searcher.Filter = "(&(objectCategory=person)(anr=$($username)))"
    $Searcher.SearchRoot = 'LDAP://DC=domain,DC=local'
    $results = $Searcher.FindOne()

    #If result found in AD, check if the accounts password would have expired
    if($?){
        $expand = $results | select -ExpandProperty Properties

        #Check if the password is older than 90 days.
        $pwdLastSet = [datetime]::FromFileTime($($expand.pwdlastset))
        $maxAge = New-TimeSpan -Days 91
        $pwdExpiry = $pwdLastSet + $maxAge

        #If the password has expired, log the session off
        if($pwdExpiry -lt (Get-Date)){
            logoff $sessionId
        }
    }

    #Increment array to next user
    $i = $i + 8
}



