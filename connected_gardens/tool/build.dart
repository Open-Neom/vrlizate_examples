import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:vrlizate_apps/vrlizate_apps.dart';
import 'package:vrlizate_world/vrlizate_world.dart';

import '../lib/connected_gardens.dart';

/// Pure Dart authoring; package resolution can be supplied with --packages.
Future<void> main(List<String> args) async {
  if (args.length > 1 ||
      (args.isNotEmpty &&
          args.single != '--check' &&
          args.single != '--write')) {
    stderr.writeln('Usage: dart tool/build.dart [--write|--check]');
    exitCode = 64;
    return;
  }
  try {
    final check = args.contains('--check');
    final root = File.fromUri(Platform.script).parent.parent;
    final outputs = <String, List<int>>{};
    final worlds = <String, Uint8List>{};
    const json = JsonEncoder.withIndent('  ');
    final license = File(
      '${root.path}/LICENSE',
    ).readAsStringSync().trim().replaceAll(RegExp(r'\s+'), ' ');
    for (final alias in ConnectedGardens.aliases) {
      final source = ConnectedGardens.worldSource(alias, license: license);
      final bytes = VrlwBundleCodec.encode(source);
      worlds['world_$alias.vrlw'] = bytes;
      outputs['sources/world_$alias.vrlw.json'] = utf8.encode(
        '${json.convert(source)}\n',
      );
      outputs['dist/world_$alias.vrlw'] = bytes;
    }
    final manifest = ConnectedGardens.manifest(worlds);
    final bundle = VrlzWorldBundle.encode(manifest, worlds);
    final decoded = VrlzPackage.decode(bundle);
    if (decoded.kind != VrlzPackageKind.worlds ||
        decoded.id != ConnectedGardens.id) {
      throw StateError('SDK round-trip lost package identity or runtime.');
    }
    // Validation includes decompression, GLB structure and every region, not
    // only the front index. No renderer or GPU is initialized by this step.
    final checkedWorlds = VrlzWorldBundle.decode(bundle);
    for (final alias in ConnectedGardens.aliases) {
      final prepared = await checkedWorlds.openWorld(alias);
      try {
        final provider = VrlwRegionProvider(prepared.reader);
        var entities = 0;
        for (final chunk in prepared.reader.index.chunks) {
          final region = await provider.load(
            provider.grid.key(chunk.x, chunk.z),
            VrRegionCancellation(),
          );
          entities += region.value.length;
        }
        stdout.writeln(
          'Validated $alias: ${prepared.resources.length} resources, '
          '$entities entities across ${prepared.reader.index.chunks.length} regions',
        );
      } finally {
        await prepared.reader.close();
      }
    }
    outputs['sources/manifest.json'] = utf8.encode(
      '${json.convert(manifest)}\n',
    );
    outputs['dist/connected_gardens.vrlz'] = bundle;
    for (final entry in outputs.entries) {
      final file = File('${root.path}/${entry.key}');
      if (check) {
        final actual = file.readAsBytesSync();
        if (actual.length != entry.value.length ||
            Iterable<int>.generate(
              actual.length,
            ).any((i) => actual[i] != entry.value[i])) {
          throw StateError('${entry.key} differs: regenerate with --write.');
        }
      } else {
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(entry.value, flush: true);
      }
      stdout.writeln(
        '${check ? 'Verified' : 'Built'} ${entry.key} (${entry.value.length} bytes)',
      );
    }
    stdout.writeln('Package SHA-256: ${crypto.sha256.convert(bundle)}');
    stdout.writeln(
      'SDK validation: two worlds, original static models and textures, local portals.',
    );
  } on Object catch (error) {
    stderr.writeln('Connected gardens build failed: $error');
    exitCode = 1;
  }
}
