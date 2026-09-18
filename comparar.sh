#!/usr/bin/env bash
set -euo pipefail

API_URL="https://pokeapi.co/api/v2/pokemon"

if [[ $# -lt 2 ]]; then
    echo "Uso: $0 <pokemon-1> <pokemon-2>" >&2
    exit 1
fi

pokemon1_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
pokemon2_name=$(echo "$2" | tr '[:upper:]' '[:lower:]')

obtener_pokemon() {
    local pokemon_name="$1"
    local response http_code body

    response=$(curl --silent --fail-with-body \
        --connect-timeout 5 --max-time 15 \
        --write-out "\n%{http_code}" \
        "${API_URL}/${pokemon_name}") && curl_status=0 || curl_status=$?

    if [[ $curl_status -ne 0 ]]; then
        if [[ $curl_status -eq 22 ]]; then
            http_code=$(echo "$response" | tail -n1)
            if [[ "$http_code" == "404" ]]; then
                echo "El pokemon '${pokemon_name}' no se encontro" >&2
                return 1
            fi
            echo "Error: la API respondio con codigo HTTP ${http_code}" >&2
            return 1
        fi
        echo "Error: no se pudo conectar con la API (curl exit code ${curl_status})" >&2
        return 1
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" != "200" ]]; then
        echo "Error: la API respondio con codigo HTTP ${http_code}" >&2
        return 1
    fi

    echo "$body"
}

pokemon1_data=$(obtener_pokemon "$pokemon1_name") || exit 1
pokemon2_data=$(obtener_pokemon "$pokemon2_name") || exit 1

name1=$(echo "$pokemon1_data" | jq -r '.name')
name2=$(echo "$pokemon2_data" | jq -r '.name')
height1=$(echo "$pokemon1_data" | jq -r '.height')
height2=$(echo "$pokemon2_data" | jq -r '.height')
weight1=$(echo "$pokemon1_data" | jq -r '.weight')
weight2=$(echo "$pokemon2_data" | jq -r '.weight')
exp1=$(echo "$pokemon1_data" | jq -r '.base_experience')
exp2=$(echo "$pokemon2_data" | jq -r '.base_experience')
types1=$(echo "$pokemon1_data" | jq -r '[.types[].type.name] | join(", ")')
types2=$(echo "$pokemon2_data" | jq -r '[.types[].type.name] | join(", ")')
abilities1=$(echo "$pokemon1_data" | jq -r '[.abilities[].ability.name] | join(", ")')
abilities2=$(echo "$pokemon2_data" | jq -r '[.abilities[].ability.name] | join(", ")')

printf "%-20s | %-20s | %-20s\n" "Caracteristica" "$name1" "$name2"
printf "%s\n" "----------------------------------------------------------------"
printf "%-20s | %-20s | %-20s\n" "Altura" "$height1" "$height2"
printf "%-20s | %-20s | %-20s\n" "Peso" "$weight1" "$weight2"
printf "%-20s | %-20s | %-20s\n" "Exp. base" "$exp1" "$exp2"
printf "%-20s | %-20s | %-20s\n" "Tipos" "$types1" "$types2"
printf "%-20s | %-20s | %-20s\n" "Habilidades" "$abilities1" "$abilities2"

stat_names=$(echo "$pokemon1_data" | jq -r '.stats[].stat.name')
while read -r stat; do
    val1=$(echo "$pokemon1_data" | jq -r --arg s "$stat" '.stats[] | select(.stat.name == $s) | .base_stat')
    val2=$(echo "$pokemon2_data" | jq -r --arg s "$stat" '.stats[] | select(.stat.name == $s) | .base_stat')
    printf "%-20s | %-20s | %-20s\n" "$stat" "$val1" "$val2"
done <<< "$stat_names"

total1=$(echo "$pokemon1_data" | jq -r '[.stats[].base_stat] | add')
total2=$(echo "$pokemon2_data" | jq -r '[.stats[].base_stat] | add')
printf "%-20s | %-20s | %-20s\n" "Total stats" "$total1" "$total2"

echo ""
if [[ "$total1" -gt "$total2" ]]; then
    echo "En stats totales, ${name1} es superior a ${name2} (${total1} vs ${total2})."
elif [[ "$total2" -gt "$total1" ]]; then
    echo "En stats totales, ${name2} es superior a ${name1} (${total2} vs ${total1})."
else
    echo "${name1} y ${name2} tienen el mismo total de stats (${total1})."
fi
