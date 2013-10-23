##########################################################################################
$AppName = "Get-ExchangeServerPlus.ps1"
$AppVer = "v1.3 [30 Oct 2007]"
#v1.0 9th May 2007
#v1.1 14th September 2007: Updated formatting & Exchange 2003 exclusion
#v1.1 3 October 2007: Updated to include AdminDisplayVersion
#v1.2 15 October 2007: Updated to not perform registry check on Provisioned Servers
#v1.3 30 October 2007: Updated with cluster information
#Written By Paul Flaherty
#blogs.flaphead.com
##########################################################################################

##########################################################################################
#Display script name and version
##########################################################################################
Write-host $AppName -NoNewLine -foregroundcolor Green
Write-Host ": " $AppVer -foregroundcolor Green
Write-host ""


##########################################################################################
#Get a list of Exchange Server in the Org excluding Edge servers
##########################################################################################
$MsxServers = Get-ExchangeServer | sort Name

##########################################################################################
#Loop each Exchange Server that is found
##########################################################################################
ForEach ($MsxServer in $MsxServers)
{

##########################################################################################
#Get Exchange server version
##########################################################################################
$MsxVersion = $MsxServer.ExchangeVersion
$tmpServerRole = $MsxServer.ServerRole

IF (-NOT $MsxServer.IsExchange2007OrLater) {$tmpServerRole = "Exchange 2003?"}

##########################################################################################
#Create "header" string for output
# Servername [Role] [Edition] Version Number
##########################################################################################

$txt1 = $MsxServer.Name + " [" + $tmpServerRole + "] [" + $MsxServer.Edition + "] " + $MsxVersion.ExchangeBuild.toString()
#write-host $txt1

Write-host $MsxServer.Name -foregroundcolor Red -nonewline
write-host " [" -nonewline
write-host $tmpServerRole -foregroundcolor Green -NonewLine
write-host "] [" -nonewline
write-host $MsxServer.Edition -foregroundcolor Green -NonewLine
write-host "] " -NonewLine
write-host $MsxVersion.ExchangeBuild.toString()
write-host "* " -NonewLine
write-host $MsxServer.AdminDisplayVersion


##########################################################################################
#Connect to the Server's remote registry and enumerate all subkeys listed under "Patches"
##########################################################################################
$Srv = $MsxServer.Name
$key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\461C2B4266EDEF444B864AD6D9E5B613\Patches\"
$type = [Microsoft.Win32.RegistryHive]::LocalMachine
$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
$regKey = $regKey.OpenSubKey($key)

$doRegCheck = $false
IF ($MsxServer.IsExchange2007OrLater) {$doRegCheck = $true}
IF ($tmpServerRole -eq "ProvisionedServer") {$doRegCheck = $False}
IF ($tmpServerRole -eq "Edge") {$doRegCheck = $False}

IF ($doRegCheck)
{
##########################################################################################
#Loop each of the Subkeys (Patches) and gather the Installed date and Displayname of the Exchange 2007 patch
##########################################################################################
ForEach($sub in $regKey.GetSubKeyNames())
{
Write-Host "- " -nonewline
$SUBkey = $key + $Sub
$SUBregKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
$SUBregKey = $SUBregKey.OpenSubKey($SUBkey)

ForEach($SubX in $SUBRegkey.GetValueNames())
{
##########################################################################################
# Display Installed date and Displayname of the Exchange 2007 patch
##########################################################################################
IF ($Subx -eq "Installed") {Write-Host $SUBRegkey.GetValue($SubX) -NoNewLine}
IF ($Subx -eq "DisplayName") {write-Host ": "$SUBRegkey.GetValue($SubX)}
}
}
}
{

}

IF ($MsxServer.IsMemberOfCluster -eq "Yes")
{
Write-Host "Clustered Server Nodes" -foregroundcolor Green
$ClusterNodes = Get-ClusteredMailboxServerStatus $MsxServer | select OperationalMachines
$ClusterNodes.OperationalMachines
}
write-host ""
}#For Loop
