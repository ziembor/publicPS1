function Get-ExchangeMTLastMailByRecipient {[CmdletBinding()]
param([string]$username='r4nsg76')
#region initVariables 
$ScriptVersion='2020-04-24T1211B'
Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010
#. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
#Connect-ExchangeServer -auto
$ExcludeHealthData = $true 
$ExcludePFData = $true
$ExcludeJournalData = $true 
#endregion initVariables

#region DynamicFilters
#Section taken from E:\bau\MT_GenerateMessageProfile\Generate-MessageProfile.ps1
#https://techcommunity.microsoft.com/t5/exchange-team-blog/generating-user-message-profiles-for-use-with-the-exchange/ba-p/610916
  # Set the initial message filter to include only messages that come from the Information Store.
  $MessageFilter = '($_.Source -eq "STOREDRIVER")'
  # If the ExcludeHealthData switch was used, add HealthMailbox exclusions to the Message and Mailbox filters.
  If ($ExcludeHealthData) {
    $MessageFilter += ' -and ($_.Recipients -notlike "HealthMailbox*") -and ($_.Recipients -notlike "extest_*")'
      }
  # If the ExcludeJournalData switch was used, filter out all messages that end the MessageID with the text "@jounal.report.generator>",
  #   as those are always journal messages.
  If ($ExcludeJournalData) {
    $MessageFilter += ' -and ($_.MessageID -notlike "*journal.report.generator>")'
  }
  # If the ExcludePFData switch was used, add the PF messages subject line exclusions to the message filter.
  If ($ExcludePFData) {
    $MessageFilter += ' -and ($_.MessageSubject -ne "Folder Content") -and ($_.MessageSubject -notlike "*Backfill Response")'
    # NOTE: The following PF message subject lines are no included because users could possibly use them in day to day messages:
    #   "Backfill Request", "Status", and "Hierarchy".
  } 
  Write-verbose  -Message ("The MessageFilter is:`n{0}" -f $MessageFilter)
#endregion DynamicFilters

#region UserMetadata 
  Set-ADServerSettings -ViewEntireForest:1
  $servername = (Get-Recipient -Identity $username ).ServerName
  $SamAccountName  = (Get-Recipient -Identity $username ).SamAccountName
  $PrimarySMTPAddress = (Get-Recipient -Identity $username ).PrimarySMTPAddress | Select-Object -ExpandProperty Address
  if($serverName){$serverList = Get-DatabaseAvailabilityGroup | Where-Object {$_.Servers -imatch $servername } | Select-Object -ExpandProperty  servers | Select-Object -ExpandProperty name} else {$serverList = Get-DatabaseAvailabilityGroup EU* | Select-Object -ExpandProperty  servers | Select-Object -ExpandProperty name}
#EndRegion   UserMetadata
Write-Verbose -Message ('before foreach {0}' -f $serverList -join '|')
#$SumSentMsgs = @()
$SumReceivedMsgs = @()
if($primarySMTPAddress) {
  foreach ($DaysAgo in (0..30)){
    $StartOnDate   = '{0:yyyy-MM-dd 00:00:00}' -f (get-date ).AddDays(-$DaysAgo)
    $EndBeforeDate = '{0:yyyy-MM-dd 00:00:00}' -f (get-date ).AddDays(-$DaysAgo + 1)
    if(-not ($SumReceivedMsgs.Count -ge 1)) {
      foreach ($ExchangeServerFQDN in $serverList){
        Write-verbose  -message ('inside foreach {0} {1} {2}' -f $ExchangeServerFQDN,$startOnDate,$EndBeforeDate)
        # First retrieve the messages that were sent by a mailbox ("Received" by the Transport service from a mailbox via the
        #   STOREDRIVER).
        #$SentMsgs = Get-MessageTrackingLog -Server $ExchangeServerFQDN -sender $PrimarySMTPAddress -ResultSize:Unlimited -Start $StartOnDate -End $EndBeforeDate  -EventID Receive -ErrorAction 0 | Where-Object ([ScriptBlock]::Create($MessageFilter)) | Select-Object   -Property @{n='Recipients' ;e={$_.Recipients -join ','}},Sender,TotalBytes, timestamp
        #$SumSentMsgs += $SentMsgs
        # Next retrieve the messages that were received by a mailbox ("Delivered" by the Transport service to a
        #   mailbox via the STOREDRIVER).
        $ReceivedMsgs = Get-MessageTrackingLog -Server $ExchangeServerFQDN -recipients $PrimarySMTPAddress -ResultSize:Unlimited -Start $StartOnDate -End $EndBeforeDate -EventID Deliver -ErrorAction 0 | Where-Object ([ScriptBlock]::Create($MessageFilter)) | Select-Object   -Property @{n='Recipients' ;e={$_.Recipients -join ','}},Sender,TotalBytes, timestamp
        $SumReceivedMsgs += $ReceivedMsgs
        }#EndForEachSevers 
    } Else {Write-verbose  -Message ('Skipped {0}' -f $StartOnDate)} #EndIfVariableIsFilled
  }#EndForEachDays 
  [datetime]$newest = $SumReceivedMsgs | Sort-Object timestamp -Descending | Select-Object -First 1 -ExpandProperty timestamp 
  if(-not $newest) {[datetime]$newest = get-date -Date '1970-01-01' ; $LastMailByDaysAgo = 9999} else {[int]$LastMailByDaysAgo  = ((get-date) - $newest ).TotalDays}
  $GMEMTLastMailByRecipient = [PSCustomObject]@{
    SamAccountName = $SamAccountName
    PrimarySMTPAddress= $PrimarySMTPAddress
    LastMailByDaysAgo =  $LastMailByDaysAgo
    newest = $newest
  }
 } #EndIfPrimarySMTPAddress
 else {
  $GMEMTLastMailByRecipient = [PSCustomObject]@{
    SamAccountName = $username
    PrimarySMTPAddress= 'not existing object' 
    LastMailByDaysAgo =  '9998'
    newest = (get-date -Date 1970-01-01)
  }
 } #EndElse 
return $GMEMTLastMailByRecipient
} #EndFunction 
