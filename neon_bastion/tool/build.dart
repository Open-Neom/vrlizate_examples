import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:vrlizate_apps/vrlizate_apps.dart';
import '../lib/neon_bastion.dart';

void main(List<String> arguments) {
  if (arguments.isNotEmpty) {
    stderr.writeln('Usage: dart tool/build.dart');
    exitCode = 64;
    return;
  }
  try {
    final root = File.fromUri(Platform.script).parent.parent;
    final tiled =
        jsonDecode(File('${root.path}/assets/level.tmj').readAsStringSync())
            as Map<String, dynamic>;
    final license = File('${root.path}/LICENSE').readAsStringSync();
    final bytes = NeonBastion.build(tiled: tiled, licenseText: license);
    final package = VrlzPackage.decode(bytes);
    if (package.kind != VrlzPackageKind.retro || package.id != NeonBastion.id) {
      throw StateError('SDK round-trip did not preserve the retro package.');
    }
    final output = File('${root.path}/build/neon_bastion.vrlz');
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(bytes, flush: true);
    stdout.writeln('Built ${output.path} (${bytes.length} bytes)');
    stdout.writeln('Package SHA-256: ${sha256.convert(bytes)}');
    stdout.writeln(
      'Runtime: ${package.retroBundle!.manifest.runtime} · level + metadata + license',
    );
  } on Object catch (error) {
    stderr.writeln('Cannot build Bastión Neón: $error');
    exitCode = 1;
  }
}
