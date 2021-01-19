#!/bin/bash
set -euo pipefail

curr_user="$(id -u -n)"
echo "User=${curr_user}"
echo "Home=$HOME"
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi

azure_resource_group="b-g-deploy"
azure_tm_profile_name="b-g-test"
azure_tm_blue_endpoint="blue-endpoint-1"
azure_tm_green_endpoint="green-endpoint-1"
azure_tm_endpoint_type="azureEndpoints"

tm_show_blue_endpoint() {
  echo "Showing the current assigned weightage for the TM's Blue endpoint..."

  blue_weightage=$(az network traffic-manager endpoint show \
    --resource-group "${azure_resource_group}" \
    --profile-name "${azure_tm_profile_name}" \
    --name "${azure_tm_blue_endpoint}" \
    --type "${azure_tm_endpoint_type}" \
    --query 'weight' -o tsv)

  echo "Current assigned weightage for the TM's Blue endpoint : ${blue_weightage}"
}

tm_show_green_endpoint() {
  echo "Showing the current assigned weightage for the TM's Green endpoint..."

  green_weightage=$(az network traffic-manager endpoint show \
    --resource-group "${azure_resource_group}" \
    --profile-name "${azure_tm_profile_name}" \
    --name "${azure_tm_green_endpoint}" \
    --type "${azure_tm_endpoint_type}" \
    --query 'weight' -o tsv)

  echo "Current assigned weightage for the TM's Green endpoint : ${green_weightage}"
}

tm_run_update() {
  local blue_weight="${1}"
  local green_weight="${2}"

  update_blue_weightage=$(az network traffic-manager endpoint update \
    --resource-group "${azure_resource_group}" \
    --profile-name "${azure_tm_profile_name}" \
    --name "${azure_tm_blue_endpoint}" \
    --weight "${blue_weight}" \
    --type "${azure_tm_endpoint_type}" \
    --query 'weight' -o tsv)

  update_green_weightage=$(az network traffic-manager endpoint update \
    --resource-group "${azure_resource_group}" \
    --profile-name "${azure_tm_profile_name}" \
    --name "${azure_tm_green_endpoint}" \
    --weight "${green_weight}" \
    --type "${azure_tm_endpoint_type}" \
    --query 'weight' -o tsv)
}


tm_update_weightage() {
  if [[ "${blue_weightage}" -eq 1000 && "${green_weightage}" -eq 1 ]]; then
    echo "Updating the weightage of both TM's Blue & Green endpoints..."

    tm_run_update 1 1000

    echo "Updated weightage of TM's Blue endpoint : ${update_blue_weightage} & Green endpoint : ${update_green_weightage}"
  elif [[ "${blue_weightage}" -eq 1 && "${green_weightage}" -eq 1000 ]]; then
    echo "Updating the weightage of both TM's Blue & Green endpoints..."

    tm_run_update 1000 1

    echo "Updated weightage of TM's Blue endpoint : ${update_blue_weightage} & Green endpoint : ${update_green_weightage}"
  else
    echo "Wrong inputs for the TM's Blue and Green endpoints, exiting..."
    exit 1
  fi
}

main() {
  tm_show_blue_endpoint
  tm_show_green_endpoint
  tm_update_weightage
}

main
