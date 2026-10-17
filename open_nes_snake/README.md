# openNES Snake para VRlizate

Proyecto de autoría **Dart independiente del hub VRlizate** que utiliza `vrlizate_apps`, parte del VRlizate SDK, para generar una aplicación de contenido NES. El archivo resultante contiene el juego, su identidad, licencia completa, procedencia y comprobación de integridad. No depende de `vrlizate_app` ni referencia una demo compilada por su nombre.

El juego es **openNES Snake 1.0.9**, de Sebastian Dine: cinco niveles, dirección con cruceta y Start para comenzar, pausar y reintentar. Se incluye la ROM oficial sin modificar, con permiso de redistribución bajo zlib. El archivo `assets/LICENSE.txt` conserva también los avisos de las bibliotecas del juego.

## Compilar el paquete

Este checkout espera el SDK en `../../neom_modules/vr/vrlizate_apps`, según `pubspec.yaml`. Actualmente ese paquete del SDK declara Flutter como dependencia, por lo que se resuelven las dependencias con Flutter. La exportación posterior utiliza Dart y no inicializa Flutter ni una GPU:

```sh
flutter pub get
dart --packages=.dart_tool/package_config.json tool/build.dart
```

El resultado es `build/open_nes_snake.vrlz`. La definición pública está en `lib/open_nes_snake.dart`; `tool/build.dart` lee los assets locales, verifica la ROM original y usa el codificador del SDK. La propia API decodifica y valida el archivo antes de escribirlo.

El formato es **`vrlizate.nes.v1`**, distinto de `vrlizate.builtin.v1`: el ZIP contiene `manifest.json` y `game.nes`. El manifiesto conserva la licencia y fuente. El `.vrlz` puede distribuirse de forma independiente y cargarse en un anfitrión compatible que ya tenga el runtime NES. El índice para hosting se genera con `vrlizate_apps/tool/index_vrlz.dart`; publicar requiere subir tanto el paquete como su índice.

## Probar en el anfitrión VR

En una instalación Android compatible de VRlizate, añade el archivo compilado al directorio mostrado por **Mis .vrlz** y actualiza la biblioteca. También puede importarse desde una URL HTTPS mediante el flujo existente. Al abrirlo, el anfitrión valida el paquete y ejecuta su ROM en la sala NES. El guardado depende del host y se asocia al juego y al núcleo.

Este proyecto no incluye un widget Flutter de emulación propio ni duplica el runtime. La vista de prueba es la sala del anfitrión, accesible por el mismo mecanismo de importación que utilizará un creador. La ejecución y la persistencia deben probarse allí, además de comprobar el paquete.

## Qué se compila y qué se ejecuta

Dart define y exporta este paquete; **no se carga código Dart nuevo desde el `.vrlz`**. La lógica del juego es el programa NES original, ejecutado por un runtime explícito del SDK/anfitrión. El hecho de tener autoría Dart no convierte una aplicación Flutter arbitraria en un módulo ejecutable descargable. Este ejemplo demuestra distribución independiente de juego y metadatos dentro de un runtime compatible.

La fuente original, gráficos, sonido y scripts de compilación de la ROM están íntegros en `upstream/openNES-Snake-1.0.9-source.tar.gz`. Su commit es `66cc333b9df91c2b27965083c48dd0e6e48cb044`; el autor publica el [código](https://github.com/sebastiandine/openNES-Snake/tree/66cc333b9df91c2b27965083c48dd0e6e48cb044), la [licencia](https://github.com/sebastiandine/openNES-Snake/blob/66cc333b9df91c2b27965083c48dd0e6e48cb044/LICENSE) y la [ROM v1.0.9](https://github.com/sebastiandine/openNES-Snake/releases/tag/v1.0.9).

SHA-256 de la ROM: `71792a9b4e4db52fb60df4633400301fac8f244f802b88d336b58e079c75acc7`.

No contiene BIOS ni juegos comerciales. El ejemplo no garantiza que el anfitrión admita todos los mappers o cartuchos NES.
