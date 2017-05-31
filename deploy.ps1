<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>
[CmdletBinding(DefaultParametersetName="subName")] 
param(
    [Parameter(ParameterSetName="subId")]
    [string]
    $subscriptionId,

    [Parameter(ParameterSetName="subName")]
    [string]
    $subscriptionName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [string]
    $resourceGroupLocation,


    [string]
    $deploymentName = "Deployment-$(get-date  -f yyyyMMdd-HHss)",

    [ValidateScript({Test-Path -PathType leaf $_})]
    [string]
    $templateFilePath,

    [ValidateScript({$_ -eq $null -or (Test-Path -PathType leaf $_)})]
    [string]
    $parametersFilePath
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
Try {
  Get-AzureRmContext | Out-Null
  Write-Host "Already logged...";
} Catch {
  if ($_ -like "*Login-AzureRmAccount to login*") {
    Write-Host "Logging in...";
    Login-AzureRmAccount
  }
}


if ($PsCmdlet.ParameterSetName -eq "subId") {
    # select subscription
    Write-Host "Selecting subscription '$subscriptionId'";
    Select-AzureRmSubscription -SubscriptionID $subscriptionId;
} elseif (-not [string]::IsNullOrEmpty($subscriptionName)) {
    Write-Host "Selecting subscription '$subscriptionName'";
    Select-AzureRmSubscription -SubscriptionName $subscriptionName;
} else {
    $c = Get-AzureRmContext
    Write-Host "Using subscription '$($c.Subscription.SubscriptionName) ($($c.Subscription.SubscriptionId))'";
}


# Register RPs
$resourceProviders = @("microsoft.compute", "microsoft.network");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if (!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else {
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";
if ($parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath -Verbose
}
else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $templateFilePath -Verbose
}