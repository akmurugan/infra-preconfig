param([Parameter(Mandatory=$false)] [string] $resourceGroup = "yomoney-poc-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "yomoney-poc-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "yomoneyacr",                        
        [Parameter(Mandatory=$false)] [string] $acrSPIdName,
        [Parameter(Mandatory=$false)] [string] $acrSPSecretName,
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "yomoney-poc-kv",
        [Parameter(Mandatory=$false)] [string] $applicationGatewayName,
        [Parameter(Mandatory=$false)] [string] $apimName = "yomoney-poc-apim",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "yomoney-poc-vnet",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "yomoney-poc-appgw-subnet",
        [Parameter(Mandatory=$false)] [string] $dockerSecretName = "yomoney-poc-secret",
        [Parameter(Mandatory=$false)] [string] $helmReleaseName = "yomoney-poc-internal-ingress",
        [Parameter(Mandatory=$false)] [string] $ingressNSName = "yomoney-poc-internal-ingress-ns",
        [Parameter(Mandatory=$false)] [string] $ilbFileName = "internal-ingress",
        [Parameter(Mandatory=$false)] [string] $ilbIPAddress = "173.0.0.157",
        [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "yomoney-appgw-deploy",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/Lulu_Workshop/YoMoney-POC-Repos/Deployments")

$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"

$acrInfo = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
if (!$acrInfo)
{

    Write-Host "Error creating Service Principal"
    return;

}

Write-Host $acrInfo.Id

$acrUserName = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPIdName
if (!$acrUserName)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$acrPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPSecretName
if (!$acrPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$dockerServer = $acrInfo.LoginServer
$dockerUserName = $acrUserName.SecretValueText
$dockerPassword = $acrPassword.SecretValueText

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Create ACR secret
$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUserName --docker-password=$dockerPassword"
Invoke-Expression -Command $dockerSecretCommand

# Docker Login command
$dockerLoginCommand = "docker login $dockerServer --username $dockerUserName --password $dockerPassword"
Invoke-Expression -Command $dockerLoginCommand

# Configure ILB file
$ipReplaceCommand = "sed -e 's|<ILB_IP>|$ilbIPAddress|' $yamlFilePath/Common/$ilbFileName > $yamlFilePath/Common/tmp.$ilbFileName"
Invoke-Expression -Command $ipReplaceCommand

# Remove temp ILB file
$removeTempFileCommand = "mv $yamlFilePath/Common/tmp.$ilbFileName $yamlFilePath/Common/$ilbFileName"
Invoke-Expression -Command $removeTempFileCommand

# Create namespace for nginx
$nginxNSCommand = "kubectl create namespace $ingressNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxILBCommand = "helm install $helmReleaseName stable/nginx-ingress --namespace $ingressNSName -f $yamlFilePath/Common/$ilbFileName --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"
Invoke-Expression -Command $nginxILBCommand

# Install AppGW
$apimPrivateIPAddress = ""
$apim = Get-AzApiManagement -ResourceGroupName $resourceGroup -Name $apimName
if ($apim)
{
    $apimPrivateIPAddress = $apim.PrivateIPAddresses[0]
}

$networkNames = "-applicationGatewayName $applicationGatewayName -vnetName $aksVNetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName -backendIPAddress $apimPrivateIPAddress $networkNames"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "Post-Config Successfully Done!"
