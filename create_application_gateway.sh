#!/bin/bash
# Variables de configuración
location="mexicocentral"
region="mx"
project="cf"
env="dev"
rgName="rg-$project-$env-$region"
pipAg="pip-ag-$project-$env-$region"
agName="ag-$project-$env-$region"
vnetName="vnet-$project-$env-$region"
frontSubnetName="snet-front-$project-$env-$region"
backSubnetName="snet-back-$project-$env-$region"
vmName="vm-$project-$env-$region-01"
# Crear IP pública para el Application Gateway
az network public-ip create \
    --resource-group $rgName \
    --name $pipAg \
    --location $location \
    --sku Standard \
    --allocation-method Static

# Crear el Application Gateway
az network application-gateway create \
    --name $agName \
    --location $location \
    --resource-group $rgName \
    --vnet-name $vnetName \
    --subnet $frontSubnetName \
    --capacity 2 \
    --sku Standard_v2 \
    --http-settings-cookie-based-affinity Disabled \
    --frontend-port 80 \
    --http-settings-port 80 \
    --http-settings-protocol Http \
    --frontend-ip $pipAg \
    --backend-pool-name backendPool \
    --backend-pool-ip-address $vmName \
    --routing-rule-name rule \
    --listener-name listener \
    --http-settings-name httpSetting

# Mostrar IP pública del Application Gateway
agIp=$(az network public-ip show \
    --resource-group $rgName \
    --name $pipAg \
    --query ipAddress \
    --output tsv)

echo "🌐 Accede a Apache a través del Application Gateway en:"
echo "👉 http://$agIp"
