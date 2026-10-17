import 'dart:typed_data';

import 'package:vrlizate_apps/vrlizate_apps.dart';

/// Authored independently of the VRlizate hub; the SDK owns the package format.
///
/// Dart exports the game content and its manifest. The game itself is the
/// original NES program, which runs in a compatible host's NES runtime.
abstract final class OpenNesSnake {
  static const id = 'org.vrlizate.homebrew.open-nes-snake';
  static const title = 'openNES Snake';
  static const description =
      'Snake de Sebastian Dine · cinco niveles · '
      'cruceta y Start · partida local reanudable';
  static const upstreamCommit = '66cc333b9df91c2b27965083c48dd0e6e48cb044';
  static const sourceUrl =
      'https://github.com/sebastiandine/openNES-Snake/tree/$upstreamCommit';
  static const romSha256 =
      '71792a9b4e4db52fb60df4633400301fac8f244f802b88d336b58e079c75acc7';

  static Uint8List build({
    required Uint8List romBytes,
    required String licenseText,
  }) => VrlzPackage.encodeNes(
    romBytes: romBytes,
    id: id,
    title: title,
    description: description,
    license: licenseText,
    sourceUrl: sourceUrl,
  );
}
