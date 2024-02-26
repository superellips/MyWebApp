#!/bin/bash

app_name=MyWebApp
rg_name=$app_name-RG
rg_location=swedencentral
vm_name=$app_name-VM
vm_size=Standard_B1s
vm_image=Ubuntu2204
admin_username=azureuser
cloud_init=cloud-init.sh
port=5000

az group create \
    --name $rg_name \
    --location $rg_location

az vm create \
    --resource-group $rg_name \
    --name $vm_name \
    --size $vm_size \
    --image $vm_image \
    --admin-username $admin_username \
    --generate-ssh-keys \
    --custom-data @$cloud_init

az vm open-port \
    --resource-group $rg_name \
    --name $vm_name \
    --port $port

public_ip=$(
    az vm show \
    --resource-group $rg_name \
    --name $vm_name \
    --show-details \
    --query "publicIps" \
    -o tsv)

scp -o StrictHostKeyChecking=no -r \
./bin/Release/net8.0/publish \
$admin_username@$public_ip:/tmp

ssh $admin_username@$public_ip \
"sudo systemctl stop $app_name.service && \
sudo mv /tmp/publish /opt/$app_name && \
sudo chown -R www-data:www-data /opt/$app_name && \
sudo systemctl start $app_name.service"

echo "$app_name should be running at http://$public_ip:$port"
