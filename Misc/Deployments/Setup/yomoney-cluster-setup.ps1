param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "yomoney-poc-rg",
        [Parameter(Mandatory=$false)] [string] $location = "southindia",
        [Parameter(Mandatory=$false)] [string] $clusterName = "yomoney-poc-cluster",        
        [Parameter(Mandatory=$false)] [string] $acrName = "yomoneyacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "yomoney-poc-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "yomoney-poc-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "yomoney-poc-subnet",
        [Parameter(Mandatory=$false)] [string] $version = "1.16.7",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 3,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = 3,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 60,
        [Parameter(Mandatory=$false)] [string] $maxPods = 50,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS3_v2",
        [Parameter(Mandatory=$false)] [string] $networkPlugin = "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "yomoneypool",        
        [Parameter(Mandatory=$false)] [string] $aadServerAppID = "f9af19cf-2f73-4010-9b66-4ffcf8d6359c",
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret = "TPid=@X:2QADBvvDR.u3j3DdAksUaMv5",
        [Parameter(Mandatory=$false)] [string] $aadClientAppID = "b003b1d7-3a0f-4101-84bb-3d9d7a24b845",
        [Parameter(Mandatory=$false)] [string] $aadTenantID = "208c13e1-251b-4077-b5b8-12077e135bcb")


$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$nodeResourceGroup = $clusterName + "-node-rg"

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
if (!$aksVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksVnet
if (!$aksSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    Write-Host "Creating..."

    az aks create --name $clusterName --resource-group $resourceGroup `
    --node-resource-group $nodeResourceGroup `
    --kubernetes-version $version --enable-addons $addons --location $location `
    --vnet-subnet-id $aksSubnet.Id --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID
    
}
elseif ($mode -eq "update")
{

    Write-Host "Updating..."
    
    # az aks nodepool update --cluster-name $clusterName --resource-group $resourceGroup `
    # --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount `
    # --name $nodePoolName

    az aks update-credentials --name $clusterName --resource-group $resourceGroup `
    --reset-aad `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID
    
    # f9af19cf-2f73-4010-9b66-4ffcf8d6359c
    # TPid=@X:2QADBvvDR.u3j3DdAksUaMv5
    # b003b1d7-3a0f-4101-84bb-3d9d7a24b845
    # 208c13e1-251b-4077-b5b8-12077e135bcb
    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $clusterName --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }

Write-Host "Cluster Successfully Done!"

