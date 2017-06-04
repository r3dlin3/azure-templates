<#
.SYNOPSIS
Start or stop the specfied ARM VMs in parallel using background jobs

.DESCRIPTION
Start or stop the specfied ARM VMs in parallel using background jobs

.PARAMETER Subscription
The Azure subscription

.PARAMETER ProfilePath
Path to azure profile - needed for authentication

.PARAMETER ResourceGroupName
Resource group name

.PARAMETER VMNames
Array of vm names

.PARAMETER Action
Start or Stop

.PARAMETER Timeout
In seconds
#>

param(
	[string][Parameter(Mandatory=$true)]$Subscription,
	[string][Parameter(Mandatory=$true)]$ProfilePath,
	[string][Parameter(Mandatory=$true)]$ResourceGroupName,
	[array][Parameter(Mandatory=$true)]$VMNames,
	[ValidateSet('Start','Stop')]
	[string] [Parameter(Mandatory=$true)]$Action,
	[int]$Timeout = 300
)

$script = {
    Param($profilePath, $vmName, $resourceGroupName, $action, $subscription)
    Select-AzureRmProfile -Path $profilePath
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

$jobIds = @()
$VMNames | % {
	$job =  Start-Job -Name "$Action $_" $script -ArgumentList $ProfilePath, $_, $ResourceGroupName, $Action, $Subscription
	Write-Output "$Action vm $_ being performed in background job $($job.Name) ID $($job.Id)"
	$jobIds += $job.Id
}

$sleepTime = 30
$timeElapsed = 0
$running = $true

while($running -and $timeElapsed -le $Timeout)
{
	$running = $false
	$jobs = Get-Job | ?  { $jobIds.Contains($_.Id) }
	$jobs
	Write-Output ""
	$jobs | % {
		if($_.State -eq 'Running')
		{
			$running = $true
		}
	}
	Start-Sleep -Seconds $sleepTime
	$timeElapsed += $sleepTime
}