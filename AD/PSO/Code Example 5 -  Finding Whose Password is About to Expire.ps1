Function Get-MaxPwdAge
{
    # Get the Domain information
    $Domain = Get-ADDomain

    # Get the domain root
    $DNSRoot = $Domain.DNSRoot

    # Get the Domain Distinguished Name.
    $DistinguishedName = $Domain.DistinguishedName

    # Connect to Active Directory
    $Connection = "LDAP://"+$DistinguishedName
    $AD = [ADSI]$Connection

    # Extract the Maximum Password Age from AD and convert it to days.
    $MaxPwdAge = -($AD.ConvertLargeIntegerToInt64($AD.MaxPwdAge.Value))/(600000000 * 1440)

    Write-Output $MaxPwdAge
}


<#
.SYNOPSIS
Confirms if a module is available.

.DESCRIPTION
Confirms if the provided parameter is available on
the local client.
         
.PARAMETER ModuleName
The name of the module who?s presence is being checked.
                   
.EXAMPLE
Confirm-Module ActiveDirectory

Checks to see if the ActiveDirectory module is
present on the local machine
Returns True is present and False if not.

.OUTPUTS
Boolean

.Link
Get-Module
#>

Function Confirm-Module
{
    Param ($ModuleName = $(Throw "You need to provide a module name."))
    # Place the name of the module from Get-Module into
    # the variable $Data
    $Data = (Get-Module -ListAvailable -Name $ModuleName).name

    # If the contents of $Data is equal to the variable
    # $ModuleName, the module is present, return 
    # True.  If not, return $False.
    If ($Data -eq $ModuleName){Return $True}
    Else {Return $False}    
}


Function Get-PasswordDayDiff
{
param (
$Date1

)
    $Date2 = Get-Date
    if ($Date2 -gt $Date1)
    {
       $DDiff = $Date2 - $Date1
    }
    Else
    {
       $DDiff = $Date1 - $Date2
    }
    Write-Output $DDiff
    


}

<#
.SYNOPSIS
Displays a list of users whos accounts are within a number of days
of requiring a reset.

.DESCRIPTION
This cmdlet can be used to help determine which user objects within
Active Directory are within a specified number of days from requiring
a new password.

.PARAMETER NumOfDays
This is the number of days that the user wants to see if any account
passwords will expire.

.PARAMETER All
Shows all the properties from this cmdlet

.PARAMETER ShowDaysSinceChange
Shows the number of days since the user changed their password.

.PARAMETER ShowDaysTillChange
Shows the number of days until the users password will need
to be reset

.PARAMETER ShowLastPasswordReset
Shows the date and time of the last password reset for the
user object.

.PARAMETER ShowMaxAge
Shows the maximum passowrd age allowed for a user object.

.PARAMETER ShowPrecedence
Shows the Precedence level of the Fine Grain Password Policy
that is being enforced on the user account.  A value of 9999
if used internally by this cmdlet to denote the Default Domain
Policy is being used to set the maximum password age.

.EXAMPLE
PS C:\> Get-PasswordExpirations 10  | FT -AutoSize

UserName             WithinRange
--------             -----------
User1                       True
User10                      True
User11                      True
User14                      True
User15                      True
User16                      True

Description
-----------
Displays a list of all user accoutns whose passwords will be expiring withing 10 days.

.EXAMPLE
PS C:\> Get-PasswordExpirations 10  -AllUsers | Select-Object -First 100 | FT -AutoSize

UserName             WithinRange
--------             -----------
User0                      False
User1                       True
User3                      False
User4                      False
User5                      False
User6                      False
User7                      False
User8                      False
User9                      False
User10                      True

Description
-----------
Displays the first 10 users objects that include both those that will have
passwords expiring withing 10 days and those that do not.

.EXAMPLE
PS C:\> Get-PasswordExpirations 10  -AllUsers -ShowDaysTillChange | 
Where-Object {$_.DaysTillchange -le 16} | 
FT -AutoSize

UserName             DaysTillChange WithinRange
--------             -------------- -----------
User1                            10        True
User10                           10        True
User11                           10        True
User14                           10        True
User15                           10        True
User16                           10        True
User17                           10        True
User18                           10        True
User19                           10        True
User20                           15       False
User22                           15       False


Description
-----------
Shows a list of all users and the number of days until the 
password expires. The WithRange property is looking for 
accounts that will exprie in the next 10 days.
#>

Function Get-PasswordExpirations
{
# =========================================================
# Script to create 3 global security groups
# Jason Yoder, MCT
# Twitter: JasonYoder_MCT
# FaceBook: MCTExpert
# Blog: www.MCTExpert.blogspt.com
# Created for PowerShell class in Columbus, Oh
# June 22, 2012
# =========================================================
param (
    [CmdletBinding()]
    
    [parameter(Mandatory=$true)][int]$NumOfDays,
    [switch]$All,
    [switch]$AllUsers,
    [switch]$ShowMaxAge,
    [switch]$ShowPrecedence,
    [switch]$ShowLastPasswordReset,
    [switch]$ShowDaysSinceChange,
    [switch]$ShowDaysTillChange
    )
    
    # Test to see if the ActiveDirectory module is
    # available on this client.
    # Exit the script if it is not.
    If ((Confirm-Module ActiveDirectory) -eq $False)
    {
        Write-Host "ActiveDiretory Module Not Present" `
         -ForegroundColor Red -BackgroundColor Black
        BREAK
    }

    # Load the cmdlets needed from the Active Directory 
    # module Present for backword compatability with 
    # PowerShell V2.
    Import-Module ActiveDirectory -Cmdlet Get-ADUser, `
        Get-ADFineGrainedPasswordPolicy
    
    # Get the Maximum Password Age from Active Directory.
    # Note: This calls a supporting function.
    $MaxPwdAge = Get-MaxPwdAge

    # Extract the PSO information that will be needed.
    $PSOInfo = Get-ADFineGrainedPasswordPolicy -Filter * |
        Select-Object -Property Name, AppliesTo, `
        MaxPasswordAge, Precedence
    
    # Extract the user information from Active Directory
    $UserInfo = Get-ADUser -Filter * -Properties DisplayName, `
        DistinguishedName, MemberOf, PasswordLastSet
 
 
    <#
    Rules for determining the current password policy
    1. If the user is not assigned to a PSO, then use the 
        Default Domain Policy.
    2. If user is part of a Security Group that is assied 
        a PSO, use that PSO.
        2a. If the user is assigned to multiple POSs, use 
        the higher precedence PSO.
    3. If the user object is specifically assigned to a 
        PSO, override anny Group PSO.
        3a. If the user object is assigned to multipl PSOs, 
        use the higher precedence PSO.
    #>  
    
    # Create a dynamic array to hold the custom object to 
    # be sent to the pipeline.
    $PasswordObj = @()
    
    # Loop through the user objects.
    ForEach ($User in $UserInfo)
    {
    
        # Test to see if the Password has ever been set.
        # If not, ignor this account.
        
        If ($User.PasswordLastSet -NE $null)
        {
        
            # Set the starting precedence number.  
            # This is used to determine which PSO to use.
            $PrecedenceNumber = 9999
            
            # Flag to denote that a PSO has a User object 
            # specified in it. This will override and 
            # Group set PSO.
            $UserSetPSO = $False
            
            # PSOFound flag is used to seperate the users 
            # who have a PSO applied to them and those 
            # that do not.
            $PSOFound = $False
            $PSOMaxPwdAge = $MaxPwdAge
            
            
        
            # Loop through each PSO
            ForEach ($PSO in $PSOInfo)
            {
                # Create the object to store the data.
                $Obj = New-Object PSObject
                
                # Get the Membership information of the 
                # user.
                $MemberOf = $User.MemberOf
                
                # Get the AppliesTo information for the 
                # current PSO
                $AppliesTo = $PSO.AppliesTo
            
                # Loop through the MemberOf information
                ForEach ($Member in $MemberOf)
                {
                   
                    # Loop through the AppliesTo 
                    # information
                    ForEach ($Applies in $AppliesTo)
                    {
                       
                        # Compare the Groups of the user 
                        # and PSO only if the User object 
                        # has not previously found in
                        # a PSO AppliesTo property.
                        If (($Member -eq $Applies) -and ($PSOInfo.Precedence -lt $PrecedenceNumber) -and ($UserSetPSO -eq $False))
                        { 
                            $PrecedenceNumber = $PSO.Precedence
                            $PSOFound = $True
                            $PSOMaxPwdAge = ($PSO.MaxPasswordAge).days                        }
                        
                        # Compare the User Object to the 
                        # PSO AppliesTo property.  If they match,
                        # Set the $UserSetPSO flag to true.  
                        # Then reset the $PrecedenceNumber number
                        # and apply the new Presedence number to 
                        # the current User.
                        
                        If ($User.DistinguishedName -eq $Applies)
                        {
                            $UserSetPS = $True
                            $PrecedenceNumber = 9999
                            If ($PSOInfo.Precedence -lt $PrecedenceNumber)
                            {                       
                                $PrecedenceNumber = $PSO.Precedence
                                $PSOFound = $True
                                $PSOMaxPwdAge = ($PSO.MaxPasswordAge).days
                            }
                        
                        }

                    }
                }
            
            } # End: ForEach ($PSO in $PSOInfo)
            
            # Create the object for each instance.
            $Obj = New-Object PSObject
            
            # Add the user name to the Object.
            $Obj | Add-Member -MemberType NoteProperty -Name UserName -Value $User.DisplayName
            
            # Add the number of days since the password has been changed to the object.
            $DDiff = (Get-PasswordDayDiff $User.PasswordLastSet).Days
            If ($ShowDaysSinceChange -or $all)
            {
                
                $Obj | Add-Member -MemberType NoteProperty -Name DaysSinceChange -Value $DDiff
            }
          
            # Determine if the password reset is within the parameter specified
            # by the user.
            
            If (($PrecedenceNumber -eq 9999) -and ($DDiff -lt $MaxPwdAge))
            {
                $DaysTillChange = ($MaxPwdAge - $DDiff)
                If ($ShowDaysTillChange -or $all)
                {
                    $Obj | Add-Member -MemberType NoteProperty -Name DaysTillChange -Value $DaysTillChange
                }
            }
            Else
            {
                $DaysTillChange = ($PSOMaxPwdAge - $DDiff)
                If ($ShowDaysTillChange -or $all)
                {
                    $Obj | Add-Member -MemberType NoteProperty -Name DaysTillChange -Value $DaysTillChange
                }
            }
            
            
            # Set to True if the password is within the range specified by the user.
            If ($DaysTillChange -le $NumOfDays)
            {
                $Obj | Add-Member -MemberType NoteProperty -Name WithinRange -Value $True 
            }
            Else
            {
                $Obj | Add-Member -MemberType NoteProperty -Name WithinRange -Value $False 
            }
            
            
            # Display the maximum number of days that a users password can be used.
            # before needing to be reset.
            If ($ShowMaxAge -or $all)
            { 
                $Obj | Add-Member -MemberType NoteProperty -Name MaxPwdAge -Value $PSOMaxPwdAge 
            }

            # Add the precedence value of the PSO. Note: a vaule of 9999 is the 
            # default domain policy.
            If ($ShowPrecedence -or $all)
            {             
                $Obj | Add-Member -MemberType NoteProperty -Name PrecedenceNum -Value $PrecedenceNumber
            }
            
            # Add the date of the last password reset.
            If ($ShowLastPasswordReset -or $all)
            {            
                $Obj | Add-Member -MemberType NoteProperty -Name PWDLastSet -Value $User.PasswordLastSet
            }
            
            # Commit the instance object to the output if the account is within the range.
            # Also write the data for users outside the range is the -AllUsers
            # switch is $True.
            If ($DaysTillChange -le $NumOfDays)
            {
                $PasswordObj += $Obj
            }
            ElseIf (($DaysTillChange -gt $NumOfDays) -and $AllUsers)
            {
                $PasswordObj += $Obj
            }
        } # End: If ($User.PasswordLastSet -NE $null)
    } # End: ForEach ($User in $UserInfo)
    
    #Write the data to the pipeline.
    Write-Output $PasswordObj
}
