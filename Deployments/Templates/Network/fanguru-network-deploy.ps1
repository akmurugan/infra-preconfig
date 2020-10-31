param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$false)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $fanguruVNetName,
        [Parameter(Mandatory=$false)] [string] $fanguruVNetPrefix,
        [Parameter(Mandatory=$false)] [string] $fanguruSubNetPrefix,
        [Parameter(Mandatory=$true)] [string] $appgwSubnetName,
        [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix,
        [Parameter(Mandatory=$false)] [string] $apimSubnetName,
        [Parameter(Mandatory=$false)] [string] $apimSubnetPrefix)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-fanguruVNetName $fanguruVNetName -fanguruVNetPrefix $fanguruVNetPrefix `
-appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix `
-apimSubnetName $apimSubnetName -apimSubnetPrefix $apimSubnetPrefix

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-fanguruVNetName $fanguruVNetName -fanguruVNetPrefix $fanguruVNetPrefix `
-appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix `
-apimSubnetName $apimSubnetName -apimSubnetPrefix $apimSubnetPrefix