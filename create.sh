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
image="Canonical:0001-com-ubuntu-server-jammy:24_04-lts-gen2:latest"
size="Standard_D2s_v3"

# Crear grupo de recursos
echo "🔧 Creando grupo de recursos: $rgName en la región $location..."
az group create --location $location --name $rgName
echo "✅ Grupo de recursos $rgName creado exitosamente."

# Crear red virtual (VNet)
echo "🌐 Creando red virtual: $vnetName con rango $vnet_address..."
az network vnet create \
  --location $location \
  --resource-group $rgName \
  --name $vnetName \
  --address-prefix $vnet_address
echo "✅ Red virtual $vnetName creada."

# Crear subred frontal
echo "📡 Creando subred frontal: $frontSubnetName con rango $front_snet_address..."
az network vnet subnet create \
  --resource-group $rgName \
  --vnet-name $vnetName \
  --name $frontSubnetName \
  --address-prefix $front_snet_address
echo "✅ Subred frontal $frontSubnetName creada."

# Crear subred trasera
echo "🔒 Creando subred trasera: $backSubnetName con rango $back_snet_address..."
az network vnet subnet create \
  --resource-group $rgName \
  --vnet-name $vnetName \
  --name $backSubnetName \
  --address-prefix $back_snet_address
echo "✅ Subred trasera $backSubnetName creada."

# Crear grupo de seguridad de red (NSG)
echo "🛡️ Creando NSG: $nsgName..."
az network nsg create \
  --resource-group $rgName \
  --name $nsgName \
  --location $location
echo "✅ NSG $nsgName creado."

# Crear reglas de NSG
echo "📥 Agregando regla para permitir SSH (puerto 22)..."
az network nsg rule create \
  --resource-group $rgName \
  --nsg-name $nsgName \
  --name Allow-SSH \
  --protocol Tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow

echo "🌐 Agregando regla para permitir HTTP (puerto 80)..."
az network nsg rule create \
  --resource-group $rgName \
  --nsg-name $nsgName \
  --name Allow-HTTP \
  --protocol Tcp \
  --direction Inbound \
  --priority 110 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80 \
  --access Allow

echo "🔒 Agregando regla para permitir HTTPS (puerto 443)..."
az network nsg rule create \
  --resource-group $rgName \
  --nsg-name $nsgName \
  --name Allow-HTTPS \
  --protocol Tcp \
  --direction Inbound \
  --priority 120 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443 \
  --access Allow

# Asociar NSG a la subred trasera
echo "🔗 Asociando NSG $nsgName a la subred $backSubnetName..."
az network vnet subnet update \
  --resource-group $rgName \
  --vnet-name $vnetName \
  --name $backSubnetName \
  --network-security-group $nsgName
echo "✅ NSG asociado a la subred $backSubnetName."

# Crear máquina virtual
echo "💻 Creando máquina virtual: $vmName con imagen $image..."
az vm create \
  --resource-group $rgName \
  --name $vmName \
  --image $image \
  --size $size \
  --admin-username $adminUser \
  --generate-ssh-keys \
  --location $location \
  --vnet-name $vnetName \
  --subnet $backSubnetName
echo "✅ Máquina virtual $vmName creada exitosamente."

# Obtener la IP pública de la VM
echo "🌐 Obteniendo la IP pública de la máquina virtual $vmName..."
publicIp=$(az vm show \
  --resource-group $rgName \
  --name $vmName \
  --show-details \
  --query publicIps \
  --output tsv)
echo "✅ IP pública obtenida: $publicIp"

# Esperar unos segundos para asegurar que la VM esté lista
echo "⏳ Esperando 30 segundos para que la VM esté lista..."
sleep 30

# Conectarse a la VM e instalar Apache
echo "🔧 Conectándose a la VM y realizando instalación de Apache..."
ssh -o StrictHostKeyChecking=no $adminUser@$publicIp << 'EOF'
  echo "📦 Actualizando paquetes del sistema..."
  sudo apt update -y

  echo "🌐 Instalando Apache..."
  sudo apt install apache2 -y

  echo "🚀 Habilitando e iniciando el servicio Apache..."
  sudo systemctl enable apache2
  sudo systemctl start apache2

  echo "✅ Apache instalado y en ejecución."
EOF


# Subir archivo index.html a la VM
echo "📤 Subiendo archivo local index.html a la máquina virtual..."
scp -o StrictHostKeyChecking=no ./index.html $adminUser@$publicIp:/tmp/index.html
echo "✅ Archivo index.html subido a /tmp en la VM."

# Reemplazar el archivo index.html en Apache
echo "📝 Reemplazando el archivo index.html predeterminado de Apache..."
ssh $adminUser@$publicIp << 'EOF'
  echo "📁 Moviendo el nuevo index.html a /var/www/html/..."
  sudo mv /tmp/index.html /var/www/html/index.html
  sudo chown www-data:www-data /var/www/html/index.html
  sudo chmod 644 /var/www/html/index.html
  echo "✅ Archivo index.html actualizado correctamente."
EOF