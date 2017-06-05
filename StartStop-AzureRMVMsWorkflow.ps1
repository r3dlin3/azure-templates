<#
.SYNOPSIS
Start or stop the specfied ARM VMs in parallel using background jobs

.DESCRIPTION
Start or stop the specfied ARM VMs in parallel using background jobs

.PARAMETER Subscription
The Azure subscription

.PARAMETER ResourceGroupName
Resource group name

.PARAMETER VMNames
Array of vm names

.PARAMETER Action
Start or Stop

.PARAMETER Credential
Credential used to authenticate via Add-AzureRmAccount - needed for authentication - can not be a live id

#>
[CmdletBinding(DefaultParametersetName = "subName")] 
param(
    [Parameter(ParameterSetName = "subId")]
    [string]
    $subscriptionId,

    [Parameter(ParameterSetName = "subName")]
    [string]
    $subscriptionName,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [array]$VMNames,
    
    [ValidateSet('Start', 'Stop')]
    [Parameter(Mandatory = $true)]
    [string] $Action,

    [Parameter(Mandatory = $true)]
    [PSCredential]$Credential
)


workflow StartStopAzureRMVMsWorkflow {
    Param(
        $vmNames, 
        $resourceGroupName,
        [ValidateSet('Start', 'Stop')]
        [Parameter(Mandatory = $true)]
        $action, 
        [Parameter(Mandatory = $true)][PSCredential]$Credential,
        [Parameter(Mandatory = $true)][string]$Subscription
    )

    foreach -parallel ($VM in $VMNames) {
        Login-AzureRmAccount -Credential $Credential
        if (-not $resourceGroupName) {
            $VMResourceGroupName = $VM.resourceGroupName
            $vmName = $VM.Name
        } else {
            $VMResourceGroupName = $resourceGroupName
            $vmName = $VM
        }

        if ($action -eq 'Stop') {         
            Write-Output "Stopping VM $VMResourceGroupName/$vmName"
            Stop-AzureRmVM -ResourceGroupName $VMResourceGroupName -Name $vmName -Force
            Write-Output "VM $VMResourceGroupName/$vmName stopped"
            
        } elseif ($action -eq 'Start') {    
            Write-Output "Starting VM $VMResourceGroupName/$vmName"
            Start-AzureRmVM -ResourceGroupName $VMResourceGroupName -Name $vmName
            Write-Output "VM $VMResourceGroupName/$vmName started"
        }
    }
}

# sign in
Try {
    Get-AzureRmContext | Out-Null
    Write-Host "Already logged...";
} Catch {
    if ($_ -like "*Login-AzureRmAccount to login*") {
        Write-Host "Logging in...";
        Login-AzureRmAccount -Credential $Credential
    }
}

if ($PsCmdlet.ParameterSetName -eq "subId") {
    # select subscription
    Write-Host "Selecting subscription '$subscriptionId'";
    Select-AzureRmSubscription -SubscriptionID $subscriptionId;
}
elseif (-not [string]::IsNullOrEmpty($subscriptionName)) {
    Write-Host "Selecting subscription '$subscriptionName'";
    Select-AzureRmSubscription -SubscriptionName $subscriptionName;
}
else {
    $c = Get-AzureRmContext
    Write-Host "Using subscription '$($c.Subscription.SubscriptionName) ($($c.Subscription.SubscriptionId))'";
}

$subscriptionId = (Get-AzureRmContext).Subscription.SubscriptionId

if ($VMNames -eq $null -or $VMNames.Count -eq 0) {
    if ([string]::IsNullOrEmpty($ResourceGroupName)) {
        throw "VMNames and ResourceGroupName cannot be both null or empty"
    }
    $VMNames = Get-AzureRmVM -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty name
}

StartStopAzureRMVMsWorkflow -vmNames $VMNames -resourceGroupName $ResourceGroupName -action $Action -Subscription $subscriptionId -Credential $Credential




