# =========================================================
# Script to set up 3 PSOs.
# Jason Yoder, MCT
# Twitter: JasonYoder_MCT
# FaceBook: MCTExpert
# Blog: www.MCTExpert.blogspt.com
# Created for PowerShell class in Columbus, Oh
# June 22, 2012
# =========================================================

# Import the Active Directory Module
Import-Module ActiveDirectory

# Get the users credientials
#$Cred = Get-Credential -Credential "Contoso\Administrator"

# Create the first Fine Grain Password Policy for Group 1.

New-ADFineGrainedPasswordPolicy -Name "Group1PSO" `
 -Precedence 10 `
 -ComplexityEnabled $True `
 -Description "PSO for Group 1" `
 -DisplayName "Group1PSO" `
 -LockoutDuration "0.12:00:00" `
 -LockoutObservationWindow "0.00:15:00" `
 -LockoutThreshold 3 `
 -MaxPasswordAge "10.00:00:00" `
 -MinPasswordAge "1.00:00:00" `
 -MinPasswordLength 8 `
 -PasswordHistoryCount 10 `
 -ReversibleEncryptionEnabled $False

# Create the first Fine Grain Password Policy for Group 2

New-ADFineGrainedPasswordPolicy -Name "Group2PSO" `
 -Precedence 10 `
 -ComplexityEnabled $True `
 -Description "PSO for Group 2" `
 -DisplayName "Group1PSO" `
 -LockoutDuration "0.12:00:00" `
 -LockoutObservationWindow "0.00:15:00" `
 -LockoutThreshold 3 `
 -MaxPasswordAge "15.00:00:00" `
 -MinPasswordAge "1.00:00:00" `
 -MinPasswordLength 8 `
 -PasswordHistoryCount 10 `
 -ReversibleEncryptionEnabled $False
   
 # Create the first Fine Grain Password Policy for Group 2

New-ADFineGrainedPasswordPolicy -Name "Group3PSO" `
 -Precedence 10 `
 -ComplexityEnabled $True `
 -Description "PSO for Group 3" `
 -DisplayName "Group1PSO" `
 -LockoutDuration "0.12:00:00" `
 -LockoutObservationWindow "0.00:15:00" `
 -LockoutThreshold 3 `
 -MaxPasswordAge "20.00:00:00" `
 -MinPasswordAge "1.00:00:00" `
 -MinPasswordLength 8 `
 -PasswordHistoryCount 10 `
 -ReversibleEncryptionEnabled $False 
 
