#!/usr/bin/env bash
set -euo pipefail

API_URL="https://pokeapi.co/api/v2/pokemon"
MAX_POKEMON_ID=1025

random_id=$(( (RANDOM % MAX_POKEMON_ID) + 1 ))

response=$(curl --silent --fail-with-body \
    --connect-timeout 5 --max-time 15 \
    --write-out "\n%{http_code}" \
    "${API_URL}/${random_id}") && curl_status=0 || curl_status=$?

if [[ $curl_status -ne 0 ]]; then
    if [[ $curl_status -eq 22 ]]; then
        http_code=$(echo "$response" | tail -n1)
        if [[ "$http_code" == "404" ]]; then
            echo "El pokemon no se encontro"
            exit 0
        fi
        echo "Error: la API respondio con codigo HTTP ${http_code}" >&2
        exit 1
    fi
    echo "Error: no se pudo conectar con la API (curl exit code ${curl_status})" >&2
    exit 1
fi

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [[ "$http_code" != "200" ]]; then
    echo "Error: la API respondio con codigo HTTP ${http_code}" >&2
    exit 1
fi

id=$(echo "$body" | jq -r '.id')
name=$(echo "$body" | jq -r '.name')
height=$(echo "$body" | jq -r '.height')
weight=$(echo "$body" | jq -r '.weight')
base_experience=$(echo "$body" | jq -r '.base_experience')

echo "ID: ${id}"
echo "Name: ${name}"
echo "Height: ${height}"
echo "Weight: ${weight}"
echo "Base Experience: ${base_experience}"

echo "Types:"
echo "$body" | jq -r '.types[].type.name' | while read -r type; do
    echo "  - ${type}"
done

echo "Abilities:"
echo "$body" | jq -r '.abilities[].ability.name' | while read -r ability; do
    echo "  - ${ability}"
done

echo "Stats:"
echo "$body" | jq -r '.stats[] | "  - \(.stat.name): \(.base_stat)"'
