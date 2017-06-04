<#
.SYNOPSIS
Start or stop the specfied ARM VMs in parallel using background jobs

.DESCRIPTION
Start or stop the specfied ARM VMs in parallel using background jobs

.PARAMETER Subscription
The Azure subscription

.PARAMETER Credential
Credential used to authenticate via Add-AzureRmAccount - needed for authentication - can not be a live id

.PARAMETER ResourceGroupName
Resource group name

.PARAMETER VMNames
Array of vm names

.PARAMETER Action
Start or Stop
#>

param(
	[string][Parameter(Mandatory=$true)]$Subscription,
	[PSCredential][Parameter(Mandatory=$true)]$Credential,
	[string][Parameter(Mandatory=$true)]$ResourceGroupName,
	[array][Parameter(Mandatory=$true)]$VMNames,
	[ValidateSet('Start','Stop')]
	[string] [Parameter(Mandatory=$true)]$Action
)


workflow StartStop-AzureRMVMsWorkflow {
	Param($credential, $subscription, $vmNames, $resourceGroupName, $action)

	foreach -parallel ($VMName in $VMNames)
	{		
		Add-AzureRMAccount -Credential $Credential
		Select-AzureRmSubscription -SubscriptionName $subscription
		if($action -eq 'Stop')
		{
			Write-Output "Stopping VM $vmName"
			Stop-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName -Force		
		}

		if($action -eq 'Start')
		{
			Write-Output "Starting VM $vmName"
			Start-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName 
		}
	}
}

StartStop-AzureRMVMsWorkflow -vmNames $VMNames -resourceGroupName $ResourceGroupName -action $Action -credential $Credential -subscription $Subscription




