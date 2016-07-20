#######################################################
#   Shadow RDS Sessions                               #    
#   Version: 1.00                                     #
#   Created: 20/07/2016                               #
#   Last Updated: 20/07/2016                          #
#   Creator: Nostalgiac                               #
#                                                     #
#   Required:                                         #
#   Replace 'DomainController' and 'ConnectionBroker' #
#   with the appropriate Server Names.                #
#######################################################

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$credentials = Get-Credential -UserName "$(whoami).admin" -Message "Enter your admin account details"
$result = invoke-command -computer "DomainController" -scriptblock {Get-RDUserSession -ConnectionBroker "ConnectionBroker" | Select-Object -Property Username,HostServer,UnifiedSessionID} -Credential $credentials
$users = $result.UserName

#Set popup box settings
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(40,20)  
$Form.Text = "Shadow RDS Session"
$Form.AutoSize = $True
$Form.AutoSizeMode = "GrowOnly"
$Form.StartPosition = "CenterScreen"

#Function to run mstsc.exe with required parameters
function remoteConnect {
    $selectedUser = $ListBox.SelectedItem.ToString()
    $newResult = $result | where {$_.UserName -like $selectedUser}
    Start-Process mstsc -Credential $credentials -ArgumentList "/shadow: $($newResult.UnifiedSessionId) /control /v: $($newResult.HostServer) /noConsentPrompt"
}

#Create Listbox
$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Size(5,5) 
$ListBox.Size = New-Object System.Drawing.Size(180,20) 
$ListBox.Height = 200 
$Form.Controls.Add($ListBox) 

#Add users to listbox
foreach ($user in $users) {
    $ListBox.Items.Add("$user")
}

#Create Connect button
$Button = New-Object System.Windows.Forms.Button 
$Button.Location = New-Object System.Drawing.Size(210,60) 
$Button.Size = New-Object System.Drawing.Size(110,80) 
$Button.Text = "Connect" 
$Button.Add_Click({remoteConnect}) 
$Form.Controls.Add($Button) 


$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()
