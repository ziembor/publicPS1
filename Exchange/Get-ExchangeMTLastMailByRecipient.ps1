function Get-ExchangeMTLastMailByRecipient {
[CmdletBinding()]
  param([string[]]$recipient='username',[int]$howmanydaysago=30 )
  #region initVariables 
  $ScriptVersion='2020-09-09T1211B'
  $GMEMTLastMailByRecipient = @()
  #try {Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010 -EA 0
  #. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
  #Connect-ExchangeServer -auto
  #} catch {write-warning 'failed Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010'}
  #endRegion initVariables
  #region UserMetadata 
  Set-ADServerSettings -ViewEntireForest:1
  $ritemn= 0 
  foreach ($recipientItem in $recipient) {
  $ritemn++
  $Error.Clear()
  Write-Warning ('{0} {1}/{2} {3}' -f $recipientItem,$ritemn,($recipient).Count,(get-date -Format s))
  $recipientObj = Get-Recipient -Identity $recipientItem -EA 0 
  $servername = $recipientObj.ServerName
  $SamAccountName  = $recipientObj.SamAccountName
  $PrimarySMTPAddress = $recipientObj.PrimarySMTPAddress | Select-Object -ExpandProperty Address
  $serverList=@()
  if($serverName){$serverList = Get-DatabaseAvailabilityGroup | Where-Object {$_.Servers -imatch $servername } | Select-Object -ExpandProperty  servers | Select-Object -ExpandProperty name | Sort-Object}
   else {$serverList = Get-DatabaseAvailabilityGroup EU* | Select-Object -ExpandProperty  servers | Select-Object -ExpandProperty name | Sort-Object}
  #EndRegion   UserMetadata
  Write-Verbose -Message ('before interting dates  {0}' -f ($serverList -join ', '))
  #$SumSentMsgs = @()
  $SumReceivedMsgs = @()
  
  if($primarySMTPAddress) {
    foreach ($DaysAgo in (0..$howmanydaysago)){
      $StartOnDate   = '{0:yyyy-MM-dd 00:00:00}' -f (get-date ).AddDays(-$DaysAgo)
      $EndBeforeDate = '{0:yyyy-MM-dd 00:00:00}' -f (get-date ).AddDays(-$DaysAgo + 1)
      if(-not ($SumReceivedMsgs.Count -ge 1)) {
      foreach ($ExchangeServerFQDN in $serverList){
          if($recipientObj.RecipientType -imatch 'Mailbox') {
            # Next retrieve the messages that were received by a mailbox ("Delivered" by the Transport service to a mailbox via the STOREDRIVER).
          $ReceivedMsgs = Get-MessageTrackingLog -Server $ExchangeServerFQDN -recipients $PrimarySMTPAddress -ResultSize:Unlimited -Start $StartOnDate -End $EndBeforeDate -EventID Deliver -ErrorAction 0 | Where-Object {$_.Source -eq "STOREDRIVER"}| Select-Object   -Property @{n='Recipients' ;e={$_.Recipients -join ','}},Sender,TotalBytes, timestamp } 
          else { 
          $ReceivedMsgs = Get-MessageTrackingLog -Server $ExchangeServerFQDN -recipients $PrimarySMTPAddress -ResultSize:Unlimited -Start $StartOnDate -End $EndBeforeDate -EventID RECEIVE -ErrorAction 0 | Where-Object {$_.Source -eq 'SMTP'}| Select-Object   -Property @{n='Recipients' ;e={$_.Recipients -join ','}},Sender,TotalBytes, timestamp }
          $SumReceivedMsgs += $ReceivedMsgs
          Write-verbose  -message ('inside foreach {0} {1} {2} {5} count {3}/{4} {6}' -f $ExchangeServerFQDN,$startOnDate,$EndBeforeDate,$ReceivedMsgs.Count,$SumReceivedMsgs.Count,$PrimarySMTPAddress,(get-Date -format s))
          Remove-Variable ReceivedMsgs -Force
        }#EndForEachSevers 
      } Else {Write-verbose  -Message ('Skipped {0}' -f $StartOnDate)} #EndIfVariableIsFilled
    }#EndForEachDays 
    if(-not $SumReceivedMsgs) {[datetime]$newest = get-date -Date '1970-01-01' ; $LastMailByDaysAgo = 9999} else {
    [datetime]$newest = $SumReceivedMsgs | Sort-Object timestamp -Descending | Select-Object -First 1 -ExpandProperty timestamp 
    [int]$LastMailByDaysAgo  = ((get-date) - $newest ).TotalDays}
        Write-Verbose $newest 
      if($Error[0]){  $errorCode = $Error[0].Exception.ToString()} else {$errorCode=''}
    $GMEMTLastMailByRecipientItem = [PSCustomObject]@{
      SamAccountName = $SamAccountName
      PrimarySMTPAddress= $PrimarySMTPAddress
      LastMailByDaysAgo =  $LastMailByDaysAgo
      newest = $newest
      errorCode = $errorCode 
    }
  } #EndIfPrimarySMTPAddress
  else {
  if($Error[0]){  $errorCode = $Error[0].Exception.ToString()} else {$errorCode=''}
    $GMEMTLastMailByRecipientItem = [PSCustomObject]@{
      SamAccountName = 'not existing object'
      PrimarySMTPAddress=  $recipientItem
      LastMailByDaysAgo =  '9998'
      newest = (get-date -Date 1970-02-01)
      errorCode = $errorCode 
    }
  } #EndElse 
  $GMEMTLastMailByRecipient += $GMEMTLastMailByRecipientItem
  $localpath = $null 
  $localpath = '{2}\GMEMTLastMailByRecipientItem-{0}-{1:0000}-{3}.csv' -f (get-date -format s).Replace(':',''),(get-random),$env:temp,$PrimarySMTPAddress
  $GMEMTLastMailByRecipientItem | Export-Csv -NoTypeInformation -Path $localpath -Append -Verbose
  $r = Import-Csv $localpath | ft -a -Wrap | out-string 
  Write-Verbose $r 
  }#EndForeAch $recipientItem
  if($GMEMTLastMailByRecipient) {$GMEMTLastMailByRecipient | Export-Csv -NoTypeInformation -Path ('GMEMTLastMailByRecipient-{0}-{1:0000}.csv' -f (get-date -format s).Replace(':',''),(get-random)) -Append -Verbose} else {Write-Warning 'that never should happen $GMEMTLastMailByRecipient  is empty'}
  $Error.Clear()
  return $GMEMTLastMailByRecipient
} #EndFunction 
