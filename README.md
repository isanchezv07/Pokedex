# PokeDex - Combate de Pokemon

Script en **Bash** que enfrenta a 2 pokemon usando la [PokeAPI](https://pokeapi.co/). Consulta las estadisticas de cada uno y declara ganador al que tenga el mayor daño total.

## Que es

`fight.sh` es una herramienta de linea de comandos que:
1. Recibe 2 pokemon (por **nombre** o por **numero**).
2. Consulta su informacion en la PokeAPI.
3. Obtiene sus estadisticas de daño: **ataque** (fisico) y **ataque especial**.
4. Suma ambas para calcular el **daño total** de cada uno.
5. Declara **GANADOR** al de mayor daño total (o **EMPATE** si son iguales).

## Requisitos

- `curl` - para hacer las peticiones HTTP a la API.
- `jq` - para procesar las respuestas JSON.

En macOS se instalan con Homebrew:

```bash
brew install curl jq
```

## Uso

Asegurate de que el script tenga permisos de ejecucion (la primera vez):

```bash
chmod +x fight.sh
```

Ejecutalo pasando 2 pokemon. Cada uno puede ir por su numero o por su nombre:

```bash
./fight.sh 8 29
./fight.sh pikachu 25
./fight.sh charizard blastoise
```

### Ejemplos

| Comando                  | Resultado                                   |
| ------------------------ | ------------------------------------------- |
| `./fight.sh 8 29`        | GANADOR: wartortle                          |
| `./fight.sh charizard blastoise` | GANADOR: charizard                  |

Salida de ejemplo:

```
=== Combate: wartortle vs nidoran-f ===
wartortle    -> ataque: 63 | ataque especial: 65 | dano total: 128
nidoran-f    -> ataque: 47 | ataque especial: 40 | dano total: 87
GANADOR: wartortle
```

## Como funciona

1. **Controles previos**: valida que se pasen exactamente 2 argumentos y que existan `curl` y `jq`.
2. **Descarga**: para cada pokemon arma la URL `https://pokeapi.co/api/v2/pokemon/<id|nombre>` y guarda la respuesta en un archivo temporal.
3. **Validacion**: revisa el codigo HTTP de la respuesta. Si hay un error, muestra que paso y por que, con sugerencia para resolverlo.
4. **Extraccion**: con `jq` lee el `name`, el stat `attack` y el stat `special-attack` del JSON.
5. **Calculo y resultado**: suma los dos stats de cada pokemon, compara los totales e imprime el ganador.

## Manejo de errores

El script detecta y explica cada situacion:

| Situacion                          | Mensaje / accion                                                      |
| ---------------------------------- | --------------------------------------------------------------------- |
| Faltan argumentos                  | Muestra el uso con ejemplos                                           |
| No esta `curl` o `jq`              | Indica el comando para instalarlos                                    |
| Pokemon no existe (HTTP 404)       | Avisa que el nombre o numero es invalido                              |
| Sin conexion (error de red)        | Muestra la causa real de `curl` y sugiere revisar internet            |
| Error HTTP inesperado (5xx, etc.)  | Muestra el codigo de respuesta y sugiere reintentar                   |
| JSON invalido o stats no legibles  | Avisa del problema y aborta                                           |

En todos los casos de error el script termina con codigo de salida `1` y un mensaje claro en `stderr`.