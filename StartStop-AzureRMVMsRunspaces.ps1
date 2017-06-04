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

.PARAMETER NumThreads
Defaults to 5
#>

param(
	[string][Parameter(Mandatory=$true)]$Subscription,
	[PSCredential][Parameter(Mandatory=$true)]$Credential,
	[string][Parameter(Mandatory=$true)]$ResourceGroupName,
	[array][Parameter(Mandatory=$true)]$VMNames,
	[ValidateSet('Start','Stop')]
	[string] [Parameter(Mandatory=$true)]$Action,
	[int]$NumThreads = 5
)

$script = {
    Param($credential, $vmName, $resourceGroupName, $action, $subscription)
    Add-AzureRmAccount -Credential $credential
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
 
# Create runspace pool consisting of $NumThreads runspaces
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $NumThreads, $Host)
$RunspacePool.Open()
 
$Jobs = @()
$VMNames | % {
    $Job = [powershell]::Create().AddScript($script)
	  $Job.AddParameter("credential", $Credential).AddParameter("vmName", $_).AddParameter("resourceGroupName", $ResourceGroupName).AddParameter("action", $Action).AddParameter("subscription", $Subscription)
    $Job.RunspacePool = $RunspacePool
    $Jobs += New-Object PSObject -Property @{
      RunNum = $_
      Job = $Job
      Result = $Job.BeginInvoke()
   }
}
 
ForEach ($Job in $Jobs)
{
    $Job.Job.EndInvoke($Job.Result)
}