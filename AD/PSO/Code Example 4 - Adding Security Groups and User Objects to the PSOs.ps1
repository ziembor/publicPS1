# =========================================================
# Script to assign users and groups to PSOs.
# Jason Yoder, MCT
# Twitter: JasonYoder_MCT
# FaceBook: MCTExpert
# Blog: www.MCTExpert.blogspt.com
# Created for PowerShell class in Columbus, Oh
# June 22, 2012
# =========================================================
# Import the Active Directory Module
Import-Module ActiveDirectory

# Add Groups to the PSO
Add-ADFineGrainedPasswordPolicySubject -Identity Group1PSO `
    -Subjects Group1  
Add-ADFineGrainedPasswordPolicySubject -Identity Group2PSO `
    -Subjects Group2  
Add-ADFineGrainedPasswordPolicySubject -Identity Group3PSO `
    -Subjects Group3  

# Add individual users to groups to take into account user 
# objects that are added to PSOs as opposed to being added 
# as part of a security group.

# Add uses to a higher Precedence PSO
Get-ADUser -Filter `
    'Name -like "User*23" -or Name -like "User*32"' |
Add-ADFineGrainedPasswordPolicySubject -Identity Group1PSO
    
# Add Users to a Lower precedence PSO
Get-ADUser -Filter `
'Name -like "User*21" -or Name -like "User*12"' |
Add-ADFineGrainedPasswordPolicySubject -Identity Group3PSO
