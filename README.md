# Isac branch 
#### made by: Gemini

Script en bash que consulta la [PokeAPI](https://pokeapi.co/) y devuelve los datos basicos de un pokemon en formato de texto plano.

## Que es

`search.sh` es una herramienta de linea de comandos que, dado el numero o nombre de un pokemon, hace una peticion HTTP a la PokeAPI y muestra los siguientes campos:

- `id`
- `name`
- `base_experience`
- `height`
- `is_default`
- `order`
- `weight`

## Requisitos

- `curl` (incluido en macOS y la mayoria de distribuciones Linux)
- `jq` — se instala con `brew install jq` (macOS) o `apt install jq` (Debian/Ubuntu)

## Como funciona

1. El script recibe un argumento: el numero (ej. `468`) o el nombre (ej. `ditto`) del pokemon.
2. Construye la URL de la PokeAPI (`https://pokeapi.co/api/v2/pokemon/<argumento>`).
3. Hace la peticion con `curl` y captura tanto el cuerpo de la respuesta como el codigo HTTP.
4. Valida la respuesta:
   - Codigo `200` → procesa el JSON con `jq` y muestra los campos.
   - Codigo `404` → el pokemon no existe.
   - Codigo `000` → no hay conexion con la API.
   - Cualquier otro codigo → error inesperado del servidor.
5. Imprime los datos en el formato `clave:valor`.

## Uso

```bash
./search.sh 468
```

### Salida de ejemplo

```
id:468
name:"togekiss"
base_experience:245
height:15
is_default:true
order:270
weight:380
```

## Manejadores de errores

| Caso                          | Mensaje                                                       |
| ----------------------------- | ------------------------------------------------------------- |
| Sin argumento                 | Muestra el error y el uso correcto del script                 |
| Argumento invalido            | Explica que solo acepta numeros o nombres                     |
| Sin conexion (HTTP 000)       | Indica que hay un problema de red o el servidor esta caido    |
| Pokemon inexistente (HTTP 404)| Indica que no existe en la Pokedex                            |
| Error inesperado (otro codigo)| Muestra el codigo HTTP y su posible causa (rate limit, etc.)  |
| `jq` no instalado             | Muestra los comandos para instalarlo                          |