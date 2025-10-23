#!/bin/bash

# Variables de configuración
location="mexicocentral"
region="mx"
project="cf"
env="dev"
rgName="rg-$project-$env-$region"
az group delete --name $rgName --no-wait --yes
