#!/bin/bash

# Variables de configuración
location="mexicocentral"
region="mx"
project="cf"
env="dev"
rgName="rg-$project-$env-$region"
echo "🔧 Para usar esta variable en tu sesión actual, ejecuta:"
echo "export rgName=$rgName"
vnetName="vnet-$project-$env-$region"
frontSubnetName="snet-front-$project-$env-$region"
backSubnetName="snet-back-$project-$env-$region"
vnet_address="10.10.0.0/16"
front_snet_address="10.10.1.0/24"
back_snet_address="10.10.2.0/24"
nsgName="nsg-$project-$env-$region"
vmName="vm-$project-$env-$region-01"
adminUser="angeladmin"
image="Canonical:ubuntu-24_04-lts:server:latest"
size="Standard_D2s_v3"

# Validar y crear grupo de recursos
if az group exists --name $rgName | grep true; then
  echo "✅ Grupo de recursos $rgName ya existe."
else
  echo "⚙️ Creando grupo de recursos: $rgName..."
  az group create --location $location --name $rgName
fi

# Validar y crear VNet
if az network vnet show --resource-group $rgName --name $vnetName &>/dev/null; then
  echo "✅ VNet $vnetName ya existe."
else
  echo "⚙️ Creando VNet: $vnetName..."
  az network vnet create --location $location --resource-group $rgName --name $vnetName --address-prefix $vnet_address
fi

# Validar y crear subred frontal
if az network vnet subnet show --resource-group $rgName --vnet-name $vnetName --name $frontSubnetName &>/dev/null; then
  echo "✅ Subred frontal $frontSubnetName ya existe."
else
  echo "⚙️ Creando subred frontal: $frontSubnetName..."
  az network vnet subnet create --resource-group $rgName --vnet-name $vnetName --name $frontSubnetName --address-prefix $front_snet_address
fi

# Validar y crear subred trasera
if az network vnet subnet show --resource-group $rgName --vnet-name $vnetName --name $backSubnetName &>/dev/null; then
  echo "✅ Subred trasera $backSubnetName ya existe."
else
  echo "⚙️ Creando subred trasera: $backSubnetName..."
  az network vnet subnet create --resource-group $rgName --vnet-name $vnetName --name $backSubnetName --address-prefix $back_snet_address
fi

# Validar y crear NSG
if az network nsg show --resource-group $rgName --name $nsgName &>/dev/null; then
  echo "✅ NSG $nsgName ya existe."
else
  echo "⚙️ Creando NSG: $nsgName..."
  az network nsg create --resource-group $rgName --name $nsgName --location $location
fi

# Crear reglas de NSG (no se validan individualmente)
az network nsg rule create --resource-group $rgName --nsg-name $nsgName --name Allow-SSH --protocol Tcp --direction Inbound --priority 100 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow
az network nsg rule create --resource-group $rgName --nsg-name $nsgName --name Allow-HTTP --protocol Tcp --direction Inbound --priority 110 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow
az network nsg rule create --resource-group $rgName --nsg-name $nsgName --name Allow-HTTPS --protocol Tcp --direction Inbound --priority 120 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 443 --access Allow

# Asociar NSG a subred trasera
az network vnet subnet update --resource-group $rgName --vnet-name $vnetName --name $backSubnetName --network-security-group $nsgName

# Validar y crear VM
if az vm show --resource-group $rgName --name $vmName &>/dev/null; then
  echo "✅ VM $vmName ya existe."
else
  echo "⚙️ Creando VM: $vmName..."
  az vm create --resource-group $rgName --name $vmName --image $image --size $size --admin-username $adminUser --generate-ssh-keys --location $location --vnet-name $vnetName --subnet $backSubnetName
fi

# Obtener IP pública
publicIp=$(az vm show --resource-group $rgName --name $vmName --show-details --query publicIps --output tsv)
publicIpName=$(az network public-ip list --resource-group $rgName --query "[?ipAddress=='$publicIp'].name" --output tsv)

# Esperar 30 segundos
sleep 30

# Instalar Apache
ssh -o StrictHostKeyChecking=no $adminUser@$publicIp << 'EOF'
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl enable apache2
  sudo systemctl start apache2
EOF

# Subir index.html
scp -o StrictHostKeyChecking=no ./index.html $adminUser@$publicIp:/tmp/index.html

# Reemplazar index.html
ssh $adminUser@$publicIp << 'EOF'
  sudo mv /tmp/index.html /var/www/html/index.html
  sudo chown www-data:www-data /var/www/html/index.html
  sudo chmod 644 /var/www/html/index.html
EOF

# Verificar Apache
ssh $adminUser@$publicIp << 'EOF'
  sudo systemctl status apache2 | grep Active
  curl -I http://localhost | grep "HTTP"
  curl -s http://localhost | head -n 10
EOF

echo "✅ Verificación de Apache completada."
sleep 15

# Asignar DNS
az network public-ip update --resource-group $rgName --name $publicIpName --dns-name $vmName

echo "🌐 Accede a la página principal de Apache en:"
echo "👉 http://$vmName.$location.cloudapp.azure.com"
