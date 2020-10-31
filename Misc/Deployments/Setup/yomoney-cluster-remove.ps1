param([Parameter(Mandatory=$false)] [string] $resourceGroup = "yomoney-poc-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "yomoney-poc-cluster",        
        [Parameter(Mandatory=$false)] [string] $acrName = "yomoneyacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "yomoney-poc-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "yomoney-poc-vnet",
        [Parameter(Mandatory=$false)] [string] $applicationGatewayName = "yomoney-poc-appgw",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "70cfb383-cd5e-4a3e-b6d7-8281d36bff9d")

$aksSPIdName = $clusterName + "-sp-id"
$publicIpAddressName = "$applicationGatewayName-pip"
$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

Remove-AzApplicationGateway -Name $applicationGatewayName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup -Force

Remove-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup -Force

Remove-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPIdName
    if ($spAppId)
    {

        Remove-AzADServicePrincipal `
        -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

Write-Host "Remove Successfully Done!"