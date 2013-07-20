# =========================================================
# Script to create 3 global security groups
# Jason Yoder, MCT
# Twitter: JasonYoder_MCT
# FaceBook: MCTExpert
# Blog: www.MCTExpert.blogspt.com
# Created for PowerShell class in Columbus, Oh
# June 22, 2012
# =========================================================

Import-Module activedirectory

New-ADGroup -Name "Group1" -SamAccountName Group1 `
 -GroupCategory Security -DisplayName "Group 1" `
 -GroupScope Global `
 -Path "CN=Users,DC=Contoso,DC=com" `
 -Description "Group 1 for Password Expiration Test"

New-ADGroup -Name "Group2" -SamAccountName Group2 `
 -GroupCategory Security -DisplayName "Group 2" `
 -GroupScope Global `
 -Path "CN=Users,DC=Contoso,DC=com" `
 -Description "Group 2 for Password Expiration Test" 
 
 New-ADGroup -Name "Group3" -SamAccountName Group3 `
 -GroupCategory Security -DisplayName "Group 3" `
 -GroupScope Global `
 -Path "CN=Users,DC=Contoso,DC=com" `
 -Description "Group 3 for Password Expiration Test"
