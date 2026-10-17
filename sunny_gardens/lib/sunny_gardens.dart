import 'dart:typed_data';
import 'package:vrlizate_apps/vrlizate_apps.dart';

/// Independent content definition. The platform supplies the common runtime.
abstract final class SunnyGardens {
  static const id = 'org.openneom.sunny_gardens';
  static const title = 'Jardines del Alba';

  static VrlzRetroLevel level(Map<String, Object?> tiled) =>
      VrlzTiledImporter.importLevel(
        tiled,
        name: title,
        theme: 'garden',
        mode: 'platformer',
      );

  static Uint8List build({
    required Map<String, Object?> tiled,
    required String licenseText,
  }) => VrlzPackage.encodeRetro(
    level: level(tiled),
    id: id,
    title: title,
    description:
        'Explora jardines suspendidos, recoge cristales y cruza sus puentes con saltos precisos.',
    license: licenseText,
  );
}
