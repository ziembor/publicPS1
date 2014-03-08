################################################################################################################################################################
# Script accepts 3 parameters from the command line
#
# Office365Username - Mandatory - Administrator login ID for the tenant we are querying
# Office365Password - Mandatory - Administrator login password for the tenant we are querying
#
#
# To run the script
#
# .\Get-SharedMailboxSizes.ps1 -Office365Username admin@xxxxxx.onmicrosoft.com -Office365Password Password123 
#
# Author: 				Alan Byrne
# Version: 				1.0
# Last Modified Date: 	19/12/2012
# Last Modified By: 	Alan Byrne
################################################################################################################################################################

#Accept input parameters
Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Office365Username,
	[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Office365Password
)

#Constant Variables
$OutputFile = "SharedMailboxSizes.csv"   #The CSV Output file that is created, change for your purposes


#Main
Function Main {

	#Remove all existing Powershell sessions
	Get-PSSession | Remove-PSSession
	
	#Call ConnectTo-ExchangeOnline function with correct credentials
	ConnectTo-ExchangeOnline -Office365AdminUsername $Office365Username -Office365AdminPassword $Office365Password			
	
	#Prepare Output file with headers
	Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,NumberOfItems,MailboxSize,IssueWarningQuota,ProhibitSendQuota,ProhibitSendReceiveQuota" -Encoding UTF8
	
	#gather all shared/room/resource mailboxes from Office 365
	$objMailboxes = get-mailbox -ResultSize Unlimited -filter {RecipientTypeDetails -eq "SharedMailbox" -or RecipientTypeDetails -eq "RoomMailbox"} | select UserPrincipalName,IssueWarningQuota,ProhibitSendQuota,ProhibitSendReceiveQuota
	
	#Iterate through all users	
	Foreach ($objMailbox in $objMailboxes)
	{	
		#Connect to the users mailbox
		$objMailboxStats = get-mailboxstatistics -Identity $($objMailbox.UserPrincipalName) | Select ItemCount,TotalItemSize
		
		#Prepare UserPrincipalName variable
		$strUserPrincipalName = $objMailbox.UserPrincipalName
		
		#Get the size and item count
		$ItemSizeString = $objMailboxStats.TotalItemSize.ToString()
		$strMailboxSize = "{0:N2}" -f ($ItemSizeString.SubString(($ItemSizeString.IndexOf("(") + 1),($itemSizeString.IndexOf(" bytes") - ($ItemSizeString.IndexOf("(") + 1))).Replace(",","")/1024/1024)

		$strItemCount = $objMailboxStats.ItemCount
		
		#Get the quotas
		$ItemSizeString = $objMailbox.IssueWarningQuota.ToString()		
		$strMailboxIssueWarningQuota = "{0:N2}" -f ($ItemSizeString.SubString(($ItemSizeString.IndexOf("(") + 1),($itemSizeString.IndexOf(" bytes") - ($ItemSizeString.IndexOf("(") + 1))).Replace(",","")/1024/1024)
		$ItemSizeString = $objMailbox.ProhibitSendQuota.ToString()
		$strMailboxProhibitSendQuota = "{0:N2}" -f ($ItemSizeString.SubString(($ItemSizeString.IndexOf("(") + 1),($itemSizeString.IndexOf(" bytes") - ($ItemSizeString.IndexOf("(") + 1))).Replace(",","")/1024/1024)
		$ItemSizeString = $objMailbox.ProhibitSendReceiveQuota.ToString()
		$strMailboxProhibitSendReceiveQuota = "{0:N2}" -f ($ItemSizeString.SubString(($ItemSizeString.IndexOf("(") + 1),($itemSizeString.IndexOf(" bytes") - ($ItemSizeString.IndexOf("(") + 1))).Replace(",","")/1024/1024)
	
		#Output result to screen for debuging (Uncomment to use)
		#write-host "$strUserPrincipalName : $strLastLogonTime"
		
		#Prepare the user details in CSV format for writing to file
		$strMailboxDetails = ('"'+$strUserPrincipalName+'","'+$strItemCount+'","'+$strMailboxSize+'","'+$strMailboxIssueWarningQuota+'","'+$strMailboxProhibitSendQuota+'","'+$strMailboxProhibitSendReceiveQuota+'"')
		
		#Append the data to file
		Out-File -FilePath $OutputFile -InputObject $strMailboxDetails -Encoding UTF8 -append
	}
	
	#Clean up session
	Get-PSSession | Remove-PSSession
}

###############################################################################
#
# Function ConnectTo-ExchangeOnline
#
# PURPOSE
#    Connects to Exchange Online Remote PowerShell using the tenant credentials
#
# INPUT
#    Tenant Admin username and password.
#
# RETURN
#    None.
#
###############################################################################
function ConnectTo-ExchangeOnline
{   
	Param( 
		[Parameter(
		Mandatory=$true,
		Position=0)]
		[String]$Office365AdminUsername,
		[Parameter(
		Mandatory=$true,
		Position=1)]
		[String]$Office365AdminPassword

    )
		
	#Encrypt password for transmission to Office365
	$SecureOffice365Password = ConvertTo-SecureString -AsPlainText $Office365AdminPassword -Force    
	
	#Build credentials object
	$Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365AdminUsername, $SecureOffice365Password
	
	#Create remote Powershell session
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic –AllowRedirection    	

	#Import the session
    Import-PSSession $Session -AllowClobber | Out-Null
}


# Start script
. Main