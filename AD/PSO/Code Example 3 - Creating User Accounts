# =========================================================
# Script to create 500 User accounts
# Jason Yoder, MCT
# Twitter: JasonYoder_MCT
# FaceBook: MCTExpert
# Blog: www.MCTExpert.blogspt.com
# Created for PowerShell class in Columbus, Oh
# June 22, 2012
# =========================================================
Import-Module ActiveDirectory

$Count = 0

For ($x = $Count;$X -lt 500;$X++)
{
   # Create the User Name
   $UserName = "User$x"
    
   # Create the User Object in Active Directory, give it a
   # password and Enable it.
    New-ADUser -Name$UserName -SamAccountName $UserName `
        -AccountPassword (ConvertTo-SecureString `
       -AsPlainText "Pa$$Word1" -Force)`
        -Enabled$True `
        -DisplayName "$UserName"
   

   # Assign the users into Groups.
   # Group assignment is based on whether or not the user
   # name contains a 1, 2, or 3.  The use may be assigned
   # into up to 3 groups, or none at all.  This is by
   # design to simulate multiple Fine Grain Password
   # Policies being applied to the User object.
   If ($UserName -Like "*1*")
    {
        Add-ADGroupMember -Identity Group1$UserName
    }
    
       If ($UserName -Like "*2*")
    {
        Add-ADGroupMember -Identity Group2$UserName
    }
    
       If ($UserName -Like "*3*")
    {
        Add-ADGroupMember -Identity Group3$UserName
    }

}
