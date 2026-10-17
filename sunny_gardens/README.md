# Jardines del Alba

Proyecto independiente de autoría Dart que usa **VRlizate SDK** para generar
`sunny_gardens.vrlz`. Incluye un nivel original de 64 × 14 casillas, con modo
`platformer` y tema `garden`. No importa la aplicación VRlizate ni incluye ROM,
personajes, sprites, mapas o música de juegos comerciales.

```sh
flutter pub get
dart tool/build.dart
```

Salida: `build/sunny_gardens.vrlz`. El paquete incluye exactamente `manifest.json` y
`level.json`, con licencia MIT e integridad SHA-256. Es contenido portable:
VRlizate lo detecta, valida y ejecuta mediante el runtime `vrlizate.retro2d.v1`
integrado en la plataforma. No contiene un binario Flutter ni Dart descargable.
Flutter resuelve las dependencias transitivas del SDK; el exportador es Dart.

## Editar con Tiled

Abre `assets/level.tmj` con [Tiled](https://www.mapeditor.org/). El tileset está
embebido; `solid.svg` es solo la miniatura local del editor y no se empaqueta ni
se carga al importar. Pinta casillas sólidas en la capa `terrain` (GID 1); borra
para crear espacio vacío (GID 0). En `entities`, usa objetos de **punto** con
clase/tipo `spawn`, `exit`, `gem`, `enemy`, `boss`, `checkpoint` o `spike`.

Ajusta cada punto a una intersección de la cuadrícula: `(columna × 16, fila × 16)`.
Las filas van de arriba abajo; el punto nombra la casilla y los pies del actor
quedan en `y = alto - 1 - fila`. No uses plantillas externas, TSX externos,
grupos, GIDs volteados, compresión, scripts, desplazamientos de capas o puntos
superpuestos. Mantén exactamente un inicio y una salida sobre suelo sólido.
El SDK rechaza datos fuera del contrato y límites excedidos.

## Diseño y controles

- Cruceta o joystick izquierdo: avanzar.
- A: salto; mantener para mayor altura y soltar para recortarlo.
- X: disparo en el modo blaster.
- Y: pausa/reanudación; al completar el nivel permite reiniciar.
- L: alternar cercanía de la vista; B: guardar y volver a Home.
- K en el mapa: checkpoint; G: salida. Las gemas son objetivos opcionales.
- El anfitrión aporta pausa, retorno a Home, visualización estereoscópica y
  persistencia de partida; esos servicios no se duplican en este proyecto.

Los fosos tienen tres casillas como máximo y la ruta principal usa escalones
asequibles. No se exige recoger todas las gemas. El bastión tiene una arena
final con un centinela; los jardines priorizan saltos y exploración.

## Licencia

Todo el código y contenido original de este proyecto usa [MIT](LICENSE).
La licencia del proyecto no sustituye las licencias de las dependencias del SDK.
