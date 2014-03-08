function Out-Speech {[CmdletBinding()]
param([Parameter(Position=0, Mandatory=$false,ValueFromPipeline=$true)][alias("text")][string] $Message = 'Brak tekstu do czytania',
[Parameter(Position=1)][string][validateset('Male','Female')]  $Gender = 'Female',
[Parameter(Position=2)][string]  $lang    = (Get-UICulture).Name,
[Parameter(Position=3)][int]     $Rate = 0,
[Parameter(Position=4)][string]  $Voice,
[Parameter(Position=5)][int][ValidateRange(1,100)] $Volume = 100
        )
begin {
        try {   Add-Type -Assembly System.Speech -ErrorAction Stop }
        catch { Write-Error -Message "Error loading the required assemblies"}
    }
process {
$voices = @()
$allVoices = $object.GetInstalledVoices()| select -ExpandProperty VoiceInfo 
write-verbose "Lang: $lang Gender: $Gender Message: $Message"
# tu może zmienne do stringa.... 
$object = New-Object System.Speech.Synthesis.SpeechSynthesizer 
if($Voice -eq $null -or $Voice -eq "") {
$voices = $allVoices | where {$_.Culture -match $lang -and $_.Gender -eq $Gender} 
if(-not $voices.count -ge  1) {$voices = $allVoices | where {$_.Culture -match $lang} } }
else {$voices = $allVoices | where {$_.Name -match $Voice -or $_.Description -match $Voice -or $_.Id -match $Voice }}
if(-not $voices.count -ge  1) {$voices = $allVoices | where {$_.Name -eq "Microsoft David Desktop"}}
try { [string]$selectedvoice = ($voices | get-random).Name ;
Write-Verbose -Message "Selecting a voice name: $selectedvoice"
$object.SelectVoice($selectedvoice)
} catch {"No such voice"}
$object.Rate = $Rate 
$object.Volume = $Volume 
$object.Speak($Message)
}
end {
$sumState =  ($object).State 
$sumRate =  ($object).Rate 
$sumVolume =  ($object).Volume 
$sumVoiceName = ($object.Voice).Name
Write-Verbose -Message "Speech summary: $sumState $sumRate $sumVolume $sumVoiceName"
$object = $null}
}