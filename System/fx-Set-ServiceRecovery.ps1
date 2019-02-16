function Set-ServiceRecovery{
  [CmdletBinding()]
  param
  (
    [string] [alias('serviceDisplayName','Name')][Parameter(Mandatory,HelpMessage='Select service name - it will be used also by regex')] $Service,
    [string] [alias('CN','MachineName','Server')]$ComputerName=$env:COMPUTERNAME,
    [string] $action1 = 'restart',
    [int] $time1 =  30000, # in miliseconds
    [string] $action2 = 'restart',
    [int] $time2 =  30000, # in miliseconds
    [string] $actionLast = '',
    [int] $timeLast = 230000, # in miliseconds
    [int] $resetCounter = 86400 # in seconds - 86400 - one day 
  )
  $serverPath = '\\' + $ComputerName
  $services = Get-CimInstance -ClassName 'Win32_Service' -ComputerName $ComputerName | Where-Object {$_.DisplayName -imatch $Service -or $_.Name -imatch $Service}
  $actions = $action1+'/'+$time1+'/'+$action2+'/'+$time2+'/'+$actionLast+'/'+$timeLast
  foreach ($serviceIns in $services){
    # https://technet.microsoft.com/en-us/library/cc742019.aspx
    $command = '{4}\system32\sc.exe {0} failure {1} actions= {2} reset= {3}' -f $serverPath, $serviceIns.Name, $actions, $resetCounter,$env:windir
    write-verbose -Message $command 
    $result = Invoke-Expression -Command $command 
    Write-Verbose -Message $result 
  }
  <#
      .SYNOPSIS

      .DESCRIPTION
    Add a more complete description of what the function does.

    .PARAMETER Service
    Describe parameter -Service.

    .PARAMETER ComputerName
    Describe parameter -ComputerName.

    .PARAMETER action1
    Describe parameter -action1.

    .PARAMETER time1
    Describe parameter -time1.

    .PARAMETER action2
    Describe parameter -action2.

    .PARAMETER time2
    Describe parameter -time2.

    .PARAMETER actionLast
    Describe parameter -actionLast.

    .PARAMETER timeLast
    Describe parameter -timeLast.

    .PARAMETER resetCounter
    Describe parameter -resetCounter.

    .EXAMPLE
  [PS] E:\>. .\fx-set-ServiceRecovery.ps1 ; foreach ($m in (Get-ExchangeServer *servrs*| select -ExpandProperty name | sort )) { Set-ServiceRecovery -Service 'MSExchangePop3|MSExchangeImap4' -ComputerName
$M -Verbose}
VERBOSE: Perform operation 'Enumerate CimInstances' with following parameters, ''namespaceName' = root\cimv2,'className' = Win32_Service'.
VERBOSE: Operation 'Enumerate CimInstances' complete.
VERBOSE: C:\Windows\system32\sc.exe \\bservers12 failure MSExchangeImap4 actions= restart/30000/restart/30000//230000 reset= 86400
VERBOSE: [SC] ChangeServiceConfig2 SUCCESS
VERBOSE: C:\Windows\system32\sc.exe \\bservers12 failure MSExchangeIMAP4BE actions= restart/30000/restart/30000//230000 reset= 86400
VERBOSE: [SC] ChangeServiceConfig2 SUCCESS
VERBOSE: C:\Windows\system32\sc.exe \\bservers12 failure MSExchangePop3 actions= restart/30000/restart/30000//230000 reset= 86400
    
    .LINK
    https://evotec.xyz/set-service-recovery-options-powershell/ 

    
  #>




}
