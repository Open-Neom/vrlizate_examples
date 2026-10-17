# Jardines conectados

Proyecto independiente de autoría **Dart + VRlizate SDK**. Genera una experiencia
`.vrlz` con dos lugares `.vrlw` y conexiones declaradas entre ellos. El contenido
original está en este proyecto: no importa `VRlizate_app`, no usa sus prototipos
de OpenWorld y no necesita introducir su geometría en el código de la plataforma.

| Lugar | Contenido propio |
| --- | --- |
| Jardín de mosaicos | Piso de baldosas, pérgola con banco, maceteros y fuente estática. |
| Observatorio del crepúsculo | Piso azul, pabellón octagonal, instrumento de observación, balizas y escultura astronómica. |

Cada mundo comprende cuatro regiones de 12 m y diez entidades. Incluye cuatro
modelos GLB originales con posiciones, normales, UV y materiales, más una textura
RGBA8 de 64 × 64 aplicada al suelo. La fuente y la escultura son objetos estáticos;
no implementan agua simulada, astronomía o colisiones personalizadas.

## Generar y comprobar

Este ejemplo supone el SDK local junto al directorio `vrlizate_examples`, como
indican las dependencias `path` del `pubspec.yaml`. Si se descarga por separado,
ajustar esas rutas a la ubicación del SDK.

```sh
flutter pub get
dart --packages=.dart_tool/package_config.json tool/build.dart --write
dart --packages=.dart_tool/package_config.json tool/build.dart --check
```

Flutter resuelve las dependencias transitivas actuales del SDK; la autoría y el
empaquetador se ejecutan con Dart usando la configuración propia del proyecto.
Los overrides locales incluyen la cadena de módulos SDK requerida; no hace falta
que esas revisiones se hayan publicado en Pub. No se compila una aplicación Flutter
autónoma ni se incluye código Dart ejecutable en el contenedor.

Salidas:

- `dist/connected_gardens.vrlz`: paquete de experiencia completo.
- `dist/world_garden.vrlw` y `dist/world_observatory.vrlw`: lugares independientes,
  también incluidos en la experiencia.
- `sources/manifest.json`: manifiesto legible con portales y hashes.
- `sources/world_*.vrlw.json`: documentos de autoría generados, con recursos base64.

`--check` vuelve a construir todo en memoria, valida con el SDK y compara las
salidas byte por byte. No sobrescribe los archivos. Los JSON bajo `sources/` son
salidas del generador: para conservar una edición en sucesivas compilaciones,
modificar los archivos Dart de `lib/`.

## Verificar reanudación en otro proceso

El [verificador de sesión](tool/verify_session.dart) usa el lector y almacenamiento
de archivos del SDK sin inicializar Flutter ni una GPU. Ejecutar dos procesos
contra un directorio temporal nuevo:

```sh
save_dir=$(mktemp -d)
dart --packages=.dart_tool/package_config.json tool/verify_session.dart seed "$save_dir"
dart --packages=.dart_tool/package_config.json tool/verify_session.dart resume "$save_dir"
```

`seed` valida los recursos, viaja al observatorio y guarda una posición distinta.
`resume` recupera el mundo y la pose desde disco, cruza el portal de vuelta y
comprueba la posición previa del jardín. El estado no depende de una instancia
Dart retenida en memoria ni de archivos dentro del paquete. Este ensayo verifica
navegación/pose; no es una comprobación visual ni persiste cualquier estado de juego.

## Estructura para autores

[`lib/connected_gardens.dart`](lib/connected_gardens.dart) define los lugares,
materiales, textura, distribución de entidades, llegadas y portales.
[`lib/glb_writer.dart`](lib/glb_writer.dart) genera mallas originales a partir de
cajas y cilindros, agrupadas por material y con buffers embebidos.
[`tool/build.dart`](tool/build.dart) llama a los codificadores y validadores del
SDK, calcula hashes y escribe las salidas reproducibles.

Las coordenadas están en metros: +Y arriba, −Z al frente. El autor entrega
coordenadas locales de región, mientras las posiciones de inicio y portales
usan el marco del mundo. Los dos lugares empiezan en `(0, 1.6, 7)` y sus portales
están en `(0, 1.6, -9)`, con el acceso central despejado.

El runtime declarado es `vrlizate.worlds.v1`, capacidad `worlds.local`. Cada mundo
define su ID, revisión, archivo, SHA-256 e índice esperado. El host debe admitir
este perfil de la beta, validar los recursos y materializar las vinculaciones
modelo/textura. Cambiar una extensión no evita esas comprobaciones.

Las texturas se incluyen como recursos del `.vrlw`; no son referencias a archivos
ni a imágenes remotas dentro del GLB. No hay red, scripts, shaders arbitrarios,
plugins nativos, permisos de cámara/micrófono o binarios de terceros en el paquete.
El motor, los controles y el ciclo de vida siguen siendo responsabilidad del SDK
integrado en la plataforma. La carga de paquetes no certifica por sí sola los FPS
ni la calidad visual en un dispositivo.

## Licencia

Código, geometrías, texturas y distribuciones originales: [MIT](LICENSE).
El generador incluye el aviso completo de esta licencia en cada lugar.
Las dependencias del SDK conservan sus propias licencias. No se copiaron modelos,
texturas ni código de los repositorios de referencia de `codebase_vr`.
