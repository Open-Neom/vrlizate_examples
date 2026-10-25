# Ejemplos independientes de VRlizate SDK

Cuatro proyectos de autoría Dart que producen contenido para los runtimes
integrados en VRlizate. Las fuentes de cada experiencia quedan fuera del hub;
el SDK aporta el formato, sus validadores y los servicios del anfitrión.

| Proyecto | Experiencia | Resultado | Runtime requerido |
| --- | --- | --- | --- |
| [Jardines del Alba](sunny_gardens/README.md) | Plataformas original, 64 × 14 casillas, tema jardín. | `build/sunny_gardens.vrlz` | `vrlizate.retro2d.v1` |
| [Bastión Neón](neon_bastion/README.md) | Plataformas y disparos originales, exploración y arena final. | `build/neon_bastion.vrlz` | `vrlizate.retro2d.v1` |
| [openNES Snake](open_nes_snake/README.md) | ROM redistribuible de Sebastian Dine, cinco niveles; código fuente y avisos incluidos en el proyecto. | `build/open_nes_snake.vrlz` | `vrlizate.nes.v1` |
| [Jardines conectados](connected_gardens/README.md) | Jardín y observatorio originales, modelos estáticos, textura y portales entre lugares. | `dist/connected_gardens.vrlz` y dos `dist/world_*.vrlw` | `vrlizate.worlds.v1` |

La [biblioteca de generadores `codebase_vrlw`](../../codebase_vrlw/README.md)
amplía la autoría de lugares mediante un contrato Dart común. Sus
[proyectos de mundos](../../codebase_vrlw/projects/catalog.json) y
[contrato público](../../codebase_vrlw/docs/sdk_contract.md) complementan estos
ejemplos; los repositorios de estudio de
[`codebase_vr`](../../codebase_vr/README.md) son referencias, no dependencias
automáticamente incorporadas a una experiencia.

## Disposición local y reproducción

Las dependencias `path` se resuelven con esta estructura:

```text
/Users/serzen/
  codebase/
    neom_modules/vr/       # SDK
    vrlizate_examples/     # esta colección
    VRlizate_app/          # anfitrión
  codebase_vrlw/           # generadores y biblioteca de lugares
  codebase_vr/             # referencias de motores y técnicas
```

Cada ejemplo apunta al SDK con `../../neom_modules/vr/…`. Al descargarlo en
otra disposición, ajustar esas rutas o usar las revisiones publicadas del SDK
compatibles con el proyecto. No copiar `.dart_tool` entre ubicaciones.

Desde el directorio de uno de los tres ejemplos de juego:

```sh
flutter pub get
dart --packages=.dart_tool/package_config.json tool/build.dart
```

Para Jardines conectados:

```sh
cd connected_gardens
flutter pub get
dart --packages=.dart_tool/package_config.json tool/build.dart --write
dart --packages=.dart_tool/package_config.json tool/build.dart --check
```

Flutter resuelve las dependencias actuales del SDK; el exportador ejecuta Dart
durante la autoría. Los generadores decodifican y validan su salida antes de
escribirla. En Jardines conectados, `--check` además reconstruye en memoria y
compara los artefactos byte por byte. Estos comandos documentan la reproducción;
la revisión de rutas del 25 de octubre de 2026 no ejecutó compilaciones ni
pruebas en dispositivos.

## Qué contienen las extensiones

- `.vrlz` selecciona un runtime explícito y contiene metadatos y contenido
  validado. En estos juegos retro incluye `manifest.json` y `level.json`; en
  NES, `manifest.json` y `game.nes`; en mundos, el manifiesto y los lugares
  `.vrlw` declarados. El perfil determina el contenido permitido.
- `.vrlw` es un contenedor binario de datos espaciales indexados, con regiones,
  prototipos, recursos y comprobaciones de integridad. Permite decodificar las
  regiones necesarias mediante el lector/caché del SDK. Un `.vrlw` incluido en
  el `.vrlz` actual se descarga junto con ese paquete; no convierte por sí solo
  la descarga del ZIP en streaming por regiones.
- El Dart de estos proyectos **no se distribuye como código ejecutable nuevo**
  dentro del paquete. Una aplicación Flutter arbitraria necesita adaptarse a
  uno de los runtimes soportados o incorporarse al anfitrión al compilarlo.

La plataforma valida formato, capacidades, hashes y presupuestos; el anfitrión
proporciona renderizado, controles, pausa y navegación. El permiso de un paquete
no activa por sí mismo servicios nativos de cámara, micrófono o red. La calidad
visual y los FPS deben comprobarse en el runtime y dispositivo elegidos.

Los detalles del formato están en
[autoría de mundos del SDK](../neom_modules/vr/docs/creator_worlds_beta.md) y
[VRLW](../neom_modules/vr/vrlizate_world/doc/vrlw_format.md). Cada proyecto
conserva su licencia y la procedencia de los recursos que distribuye.
