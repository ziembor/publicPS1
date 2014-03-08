# In ECP or EMC create a new DG .
# The DH must be security enabled or a security group.
#
# Provide the followinf informations:
# DG display name - Technical Support
# DG alias - supportgroup
#---------------------------------------------------------------------------------
# Author:      Alexandru Dionisie
# Website:     www.tutorialeoffice.ro
# Script Name: Shared_Mailbox.ps1
#---------------------------------------------------------------------------------
#
#
# Create Shared Mailbox
#
# 1. Create mailbox and add alias
# Customer Support - display name for Shared Mailbox
# support - alias (must be unique)
New-Mailbox -Name "Customer Support" -Alias support -Shared
#
# 2. Give Full Access to security group (DG alias - supportgroup) to the shared mailbox
# Customer Support - display name
# supportgroup - DG alias
Add-MailboxPermission "Customer Support" -User supportgroup -AccessRights FullAccess
#
#
# Give SendAs permissions to DG members
#
# Customer Support - display name
# supportgroup - DG alias
Add-RecipientPermission "Customer Support" -Trustee supportgroup -AccessRights SendAs