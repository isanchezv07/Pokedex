#!/bin/bash

API="https://pokeapi.co/api/v2/pokemon"

if [ $# -eq 0 ]; then
  echo "ERROR: No se proporciono ningun argumento."
  echo "Por que paso: El script necesita el numero o nombre del pokemon para buscar."
  echo "Uso correcto: ./search.sh <numero_o_nombre>"
  echo "Ejemplo: ./search.sh 468"
  exit 1
fi

ARG="$1"

if ! [[ "$ARG" =~ ^[0-9]+$ ]] && ! [[ "$ARG" =~ ^[a-zA-Z-]+$ ]]; then
  echo "ERROR: El argumento '$ARG' no es valido."
  echo "Por que paso: Solo se aceptan numeros (ej. 468) o nombres (ej. ditto)."
  exit 1
fi

RESPONSE=$(curl -s -w "\n%{http_code}" "$API/$ARG")
HTTP_CODE=$(printf "%s" "$RESPONSE" | tail -n 1)
BODY=$(printf "%s" "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 000 ]; then
  echo "ERROR: No se pudo conectar con la API de Pokemon."
  echo "Por que paso: Revisa tu conexion a internet o que el servidor no este caido."
  exit 1
fi

if [ "$HTTP_CODE" -eq 404 ]; then
  echo "ERROR: No se encontro el pokemon '$ARG'."
  echo "Por que paso: No existe un pokemon con ese numero o nombre en la Pokedex."
  exit 1
fi

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "ERROR: La API respondio con un codigo inesperado: $HTTP_CODE"
  echo "Por que paso: Hubo un problema con la peticion (error del servidor, rate limit, etc)."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: La herramienta 'jq' no esta instalada."
  echo "Por que paso: El script necesita jq para procesar el JSON. Instalala con: brew install jq"
  exit 1
fi

ID=$(echo "$BODY" | jq -r '.id')
NAME=$(echo "$BODY" | jq -r '.name')
BASE_EXPERIENCE=$(echo "$BODY" | jq -r '.base_experience')
HEIGHT=$(echo "$BODY" | jq -r '.height')
IS_DEFAULT=$(echo "$BODY" | jq -r '.is_default')
ORDER=$(echo "$BODY" | jq -r '.order')
WEIGHT=$(echo "$BODY" | jq -r '.weight')

echo "id:$ID"
echo "name:\"$NAME\""
echo "base_experience:$BASE_EXPERIENCE"
echo "height:$HEIGHT"
echo "is_default:$IS_DEFAULT"
echo "order:$ORDER"
echo "weight:$WEIGHT"