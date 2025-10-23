#!/bin/bash

# Variables
location="mexicocentral"
region="mx"
project="cf"
env="dev"
rgName="rg-$project-$env-$region"
pipAg="pip-ag-$project-$env-$region"
agName="ag-$project-$env-$region"
vnetName="vnet-$project-$env-$region"
frontSubnetName="snet-front-$project-$env-$region"
vmPrivateIp="10.10.2.4"  # IP privada de la VM en la subred trasera

# Crear IP pública
az network public-ip create \
  --resource-group $rgName \
  --name $pipAg \
  --location $location \
  --sku Standard \
  --allocation-method Static

# Crear Application Gateway base
az network application-gateway create \
  --name $agName \
  --location $location \
  --resource-group $rgName \
  --vnet-name $vnetName \
  --subnet $frontSubnetName \
  --capacity 2 \
  --sku Standard_v2 \
  --public-ip-address $pipAg

# Crear backend pool con IP privada de la VM
az network application-gateway address-pool create \
  --gateway-name $agName \
  --resource-group $rgName \
  --name backendPool \
  --servers $vmPrivateIp

# Crear configuración HTTP
az network application-gateway http-settings create \
  --gateway-name $agName \
  --resource-group $rgName \
  --name httpSetting \
  --port 80 \
  --protocol Http \
  --cookie-based-affinity Disabled

# Crear listener
az network application-gateway frontend-port list \
  --gateway-name $agName \
  --resource-group $rgName --query "[0].id" -o tsv

frontendIpId=$(az network application-gateway frontend-ip list \
  --gateway-name $agName \
  --resource-group $rgName \
  --query "[0].id" -o tsv)

az network application-gateway listener create \
  --gateway-name $agName \
  --resource-group $rgName \
  --name listener \
  --frontend-ip $frontendIpId \
  --frontend-port 80 \
  --protocol Http

# Crear regla de enrutamiento
az network application-gateway rule create \
  --gateway-name $agName \
  --resource-group $rgName \
  --name rule \
  --address-pool backendPool \
  --http-listener listener \
  --rule-type Basic \
  --http-settings httpSetting

# Obtener IP pública del Application Gateway
agIp=$(az network public-ip show \
  --resource-group $rgName \
  --name $pipAg \
  --query ipAddress \
  --output tsv)

echo "🌐 Accede a Apache a través del Application Gateway en:"
echo "👉 http://$agIp"