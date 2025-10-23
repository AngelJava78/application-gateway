#!/bin/bash

# Crear IP pública para el Application Gateway
az network public-ip create \
    --resource-group rg-cf-dev-mx \
    --name pip-ag-cf-dev-mx \
    --location mexicocentral \
    --sku Standard \
    --allocation-method Static

# Crear el Application Gateway
az network application-gateway create \
    --name ag-cf-dev-mx \
    --location mexicocentral \
    --resource-group rg-cf-dev-mx \
    --vnet-name vnet-cf-dev-mx \
    --subnet snet-front-cf-dev-mx \
    --capacity 2 \
    --sku Standard_v2 \
    --http-settings-cookie-based-affinity Disabled \
    --frontend-port 80 \
    --http-settings-port 80 \
    --http-settings-protocol Http \
    --frontend-ip pip-ag-cf-dev-mx \
    --backend-pool-name backendPool \
    --backend-pool-ip-address vm-cf-dev-mx-01 \
    --routing-rule-name rule \
    --listener-name listener \
    --http-settings-name httpSetting

# Mostrar IP pública del Application Gateway
agIp=$(az network public-ip show \
    --resource-group rg-cf-dev-mx \
    --name pip-ag-cf-dev-mx \
    --query ipAddress \
    --output tsv)

echo "🌐 Accede a Apache a través del Application Gateway en:"
echo "👉 http://$agIp"
