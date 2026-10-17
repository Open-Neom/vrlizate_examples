import 'dart:typed_data';
import 'package:vrlizate_apps/vrlizate_apps.dart';

/// Independent content definition. The platform supplies the common runtime.
abstract final class NeonBastion {
  static const id = 'org.openneom.neon_bastion';
  static const title = 'Bastión Neón';

  static VrlzRetroLevel level(Map<String, Object?> tiled) =>
      VrlzTiledImporter.importLevel(
        tiled,
        name: title,
        theme: 'neon',
        mode: 'blaster',
      );

  static Uint8List build({
    required Map<String, Object?> tiled,
    required String licenseText,
  }) => VrlzPackage.encodeRetro(
    level: level(tiled),
    id: id,
    title: title,
    description:
        'Avanza por una ciudad de luz, esquiva guardianes y derrota al centinela del bastión.',
    license: licenseText,
  );
}
