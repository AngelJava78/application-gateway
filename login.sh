#!/bin/bash

# Cargar variables del archivo .env
source .env

# Login al tenant específico usando device code
az login --tenant $AZURE_TENANT_ID --use-device-code

# Seleccionar la suscripción
az account set --subscription $AZURE_SUBSCRIPTION_ID