#!/bin/bash

API="https://pokeapi.co/api/v2/pokemon"

fail() {
	printf 'Error: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<EOF >&2
Uso: $0 <pokemon1> <pokemon2>

Elige cada pokemon por su nombre o por su numero:
  Ejemplo: $0 8 29            (por numero)
  Ejemplo: $0 pikachu 25      (mixto)
  Ejemplo: $0 charizard blastoise (por nombre)

El script consulta la PokeAPI, obtiene el ataque fisico y el ataque
especial de cada pokemon, y declara ganador al de mayor dano total.
EOF
	exit 1
}

# ----- controles previos -----
if [ $# -ne 2 ]; then
	usage
fi

command -v curl >/dev/null 2>&1 || fail "se necesita 'curl' para hacer las peticiones. Instalalo con: brew install curl"
command -v jq >/dev/null 2>&1 || fail "se necesita 'jq' para procesar el JSON. Instalalo con: brew install jq"

# ----- descarga la informacion de un pokemon -----
# deja la ruta del archivo JSON en $POKE_FILE, o sale con un mensaje claro
get_pokemon() {
	local ref="$1" tmp err slug code curlexit cause
	POKE_FILE=""
	tmp="$(mktemp)" || fail "no se pudo crear un archivo temporal"
	err="$(mktemp)" || fail "no se pudo crear un archivo temporal"

	slug="$(printf '%s\n' "$ref" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
	code="$(curl -sS --max-time 20 -o "$tmp" -w '%{http_code}' "$API/$slug" 2>"$err")"
	curlexit=$?

	if [ "$code" = "000" ]; then
		cause="$(tr -d '\n' <"$err")"
		rm -f "$tmp" "$err"
		printf 'No se pudo conectar con la PokeAPI (curl error %s).\n' "$curlexit" >&2
		printf '  Causa: %s\n' "${cause:-respuesta vacia de curl}" >&2
		printf '  -> Revisa tu conexion a internet y vuelve a intentar.\n' >&2
		exit 1
	fi

	if [ "$code" = "404" ]; then
		rm -f "$tmp" "$err"
		printf "El pokemon '%s' no existe en la PokeAPI.\n" "$ref" >&2
		printf '  -> Verifica el nombre (ej: pikachu, nidoran-f) o el numero (1-1025).\n' >&2
		exit 1
	fi

	if [ "$code" != "200" ]; then
		rm -f "$tmp" "$err"
		printf 'La PokeAPI respondio con un error inesperado (HTTP %s).\n' "$code" >&2
		printf '  Causa: %s\n' "$(tr -d '\n' <"$err")" >&2
		printf '  -> Intenta de nuevo en unos segundos.\n' >&2
		exit 1
	fi
	rm -f "$err"

	if ! jq -e . "$tmp" >/dev/null 2>&1; then
		rm -f "$tmp"
		printf 'La PokeAPI respondio con un JSON invalido para %s.\n' "$ref" >&2
		printf '  -> Intenta de nuevo en unos segundos.\n' >&2
		exit 1
	fi

	POKE_FILE="$tmp"
}

# ----- extrae nombre y stats de dano de un archivo json -----
get_stats() {
	local file="$1"
	echo "$(jq -r '.name' "$file") $(jq -r '.stats[] | select(.stat.name=="attack") | .base_stat' "$file") $(jq -r '.stats[] | select(.stat.name=="special-attack") | .base_stat' "$file")"
}

# ----- flujo principal -----
get_pokemon "$1"
f1="$POKE_FILE"
get_pokemon "$2"
f2="$POKE_FILE"

read -r n1 d1 c1 <<<"$(get_stats "$f1")"
read -r n2 d2 c2 <<<"$(get_stats "$f2")"

if ! printf '%s\n' "$d1" "$c1" "$d2" "$c2" | grep -qE '^[0-9]+$'; then
	rm -f "$f1" "$f2"
	fail "no se pudieron leer las estadisticas de dano de '$n1' o '$n2'"
fi
rm -f "$f1" "$f2"

t1=$((d1 + c1))
t2=$((d2 + c2))

printf '\n=== Combate: %s vs %s ===\n' "$n1" "$n2"
printf '%-12s -> ataque: %d | ataque especial: %d | dano total: %d\n' "$n1" "$d1" "$c1" "$t1"
printf '%-12s -> ataque: %d | ataque especial: %d | dano total: %d\n' "$n2" "$d2" "$c2" "$t2"

if [ "$t1" -gt "$t2" ]; then
	printf 'GANADOR: %s\n' "$n1"
elif [ "$t2" -gt "$t1" ]; then
	printf 'GANADOR: %s\n' "$n2"
else
	printf 'EMPATE: ambos pokemones tienen el mismo dano total.\n'
fi