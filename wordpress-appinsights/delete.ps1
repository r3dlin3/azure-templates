param (
    [Parameter(Mandatory=$true)]
    [string]$rgName,

    [switch]$force
)

Get-AzureRmResource -ResourceGroupName $rgName -ResourceType "Microsoft.Web/sites"  | Remove-AzureRmResource -force:$force
#Get-AzureRmResource -ResourceGroupName $rgName -ResourceType "Microsoft.DBforMySQL/servers"  | Remove-AzureRmResource -force:$force
Find-AzureRmResource -ResourceGroupName $rgName | Remove-AzureRmResource -force:$force
Write-Host "Remaining resources:"
Find-AzureRmResource -ResourceGroupName $rgName | Format-Table Name,ResourceType
