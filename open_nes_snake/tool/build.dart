import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:vrlizate_apps/vrlizate_apps.dart';

import '../lib/open_nes_snake.dart';

/// Produces a portable content package, never a host route descriptor.
void main(List<String> arguments) {
  if (arguments.isNotEmpty) {
    stderr.writeln('Usage: dart tool/build.dart');
    exitCode = 64;
    return;
  }
  try {
    final root = File.fromUri(Platform.script).parent.parent;
    final rom = File('${root.path}/assets/open_nes_snake.nes')
        .readAsBytesSync();
    if (sha256.convert(rom).toString() != OpenNesSnake.romSha256) {
      throw StateError('The ROM is not the pinned upstream release.');
    }
    final license = File('${root.path}/assets/LICENSE.txt').readAsStringSync();
    final bytes = OpenNesSnake.build(romBytes: rom, licenseText: license);
    final decoded = VrlzPackage.decode(bytes);
    if (decoded.kind != VrlzPackageKind.nes ||
        decoded.nesBundle?.manifest.romSha256 != OpenNesSnake.romSha256) {
      throw StateError('SDK round-trip did not preserve the NES package.');
    }
    final output = File('${root.path}/build/open_nes_snake.vrlz');
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(bytes, flush: true);
    stdout.writeln('Built ${output.path} (${bytes.length} bytes)');
    stdout.writeln('Package SHA-256: ${sha256.convert(bytes)}');
    stdout.writeln('Runtime: vrlizate.nes.v1 · ROM + manifest + license');
  } on Object catch (error) {
    stderr.writeln('Cannot build openNES Snake: $error');
    exitCode = 1;
  }
}
