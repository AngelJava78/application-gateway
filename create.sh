#!/bin/bash

location="mexicocentral"
region="mx"
project="cf"
env="dev"
rgName="rg-$project-$env-$region"
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
az group create --location $location --name $rgName

# Crear VNet
az network vnet create   --location $location   --resource-group $rgName   --name $vnetName   --address-prefix $vnet_address

# Crear subredes
az network vnet subnet create   --resource-group $rgName   --vnet-name $vnetName   --name $frontSubnetName   --address-prefix $front_snet_address

az network vnet subnet create   --resource-group $rgName   --vnet-name $vnetName   --name $backSubnetName   --address-prefix $back_snet_address

# Crear NSG
az network nsg create   --resource-group $rgName   --name $nsgName   --location $location

# Reglas NSG
az network nsg rule create   --resource-group $rgName   --nsg-name $nsgName   --name Allow-SSH   --protocol Tcp   --direction Inbound   --priority 100   --source-address-prefixes '*'   --source-port-ranges '*'   --destination-address-prefixes '*'   --destination-port-ranges 22   --access Allow

az network nsg rule create   --resource-group $rgName   --nsg-name $nsgName   --name Allow-HTTP   --protocol Tcp   --direction Inbound   --priority 110   --source-address-prefixes '*'   --source-port-ranges '*'   --destination-address-prefixes '*'   --destination-port-ranges 80   --access Allow

az network nsg rule create   --resource-group $rgName   --nsg-name $nsgName   --name Allow-HTTPS   --protocol Tcp   --direction Inbound   --priority 120   --source-address-prefixes '*'   --source-port-ranges '*'   --destination-address-prefixes '*'   --destination-port-ranges 443   --access Allow

# Asociar NSG a la subred
az network vnet subnet update   --resource-group $rgName   --vnet-name $vnetName   --name $backSubnetName   --network-security-group $nsgName

# Crear VM
az vm create   --resource-group $rgName   --name $vmName   --image $image   --size $size   --admin-username $adminUser   --generate-ssh-keys   --location $location   --vnet-name $vnetName   --subnet $backSubnetName
