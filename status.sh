#!/bin/bash

# Replace $mig_id with your actual migration ID
mig_id="0a778fd3-e0bf-4d6f-9039-270b58b64cf0"

while true
do
    clear
    curl --location --request GET "http://localhost:5002/api/migration/GetMigrationStatus/$mig_id" \
         --header "Content-Type: application/json" | jq '.'
    sleep 3
done
