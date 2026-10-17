import 'dart:io';

import 'package:vrlizate_apps/vrlizate_apps.dart';
import 'package:vrlizate_apps/vrlizate_apps_io.dart';

import '../lib/connected_gardens.dart';

/// Run seed and resume as separate Dart processes against the same temporary
/// directory. This proves file-backed navigation state without a Flutter/GPU.
Future<void> main(List<String> args) async {
  if (args.length != 2 || !['seed', 'resume'].contains(args.first)) {
    stderr.writeln(
      'Usage: dart tool/verify_session.dart seed|resume SAVE_DIRECTORY',
    );
    exitCode = 64;
    return;
  }
  try {
    final root = File.fromUri(Platform.script).parent.parent;
    final bytes = await File(
      '${root.path}/dist/connected_gardens.vrlz',
    ).readAsBytes();
    final package = VrlzPackage.decode(bytes);
    _require(
      package.kind == VrlzPackageKind.worlds &&
          package.id == ConnectedGardens.id,
      'Unexpected package/runtime.',
    );
    final bundle = package.worldBundle!;
    final store = VrlzWorldSaveStore(directoryPath: args[1]);
    final session = VrlzWorldSession(bundle);
    if (args.first == 'seed') {
      _require(
        await store.read(package.id) == null,
        'Use a new empty save directory for the seed process.',
      );
      for (final world in bundle.manifest.worlds) {
        final prepared = await bundle.openWorld(world.alias);
        try {
          _require(
            prepared.resources.length == 5,
            '${world.alias} is missing an authored resource.',
          );
          stdout.writeln(
            'Validated ${world.alias}: four GLB models and one RGBA8 texture',
          );
        } finally {
          await prepared.reader.close();
        }
      }
      _require(session.currentWorld == 'garden', 'Wrong entrypoint.');
      session.updatePose(_gardenPose);
      _require(
        session.enterPortal('garden.to_observatory'),
        'Cannot enter observatory.',
      );
      session.updatePose(_observatoryPose);
      await store.write(package.id, session.encodeSnapshot());
      stdout.writeln(
        'SEED OK pid=$pid: observatory pose saved; garden visit retained.',
      );
    } else {
      final data = await store.read(package.id);
      _require(data != null, 'No durable save found; run seed first.');
      _require(
        session.restoreSnapshot(data!),
        'Save rejected for this content revision.',
      );
      _require(
        session.currentWorld == 'observatory',
        'Current world was not restored.',
      );
      _samePose(session.pose, _observatoryPose);
      _samePose(session.visits['garden']!, _gardenPose);
      session.updatePose(const VrlzWorldPose(x: -1, y: 1.6, z: -7.5, yaw: .2));
      _require(
        session.enterPortal('observatory.to_garden'),
        'Cannot return to garden.',
      );
      _require(
        session.currentWorld == 'garden',
        'Return used the wrong world.',
      );
      _samePose(session.pose, _gardenPose);
      await store.write(package.id, session.encodeSnapshot());
      stdout.writeln(
        'RESUME OK pid=$pid: restored observatory after process restart, '
        'then returned to the saved garden pose.',
      );
    }
  } on Object catch (error) {
    stderr.writeln('Session verification failed: $error');
    exitCode = 1;
  }
}

const _gardenPose = VrlzWorldPose(x: 1.25, y: 1.6, z: -7.75, yaw: .35);
const _observatoryPose = VrlzWorldPose(x: -2.5, y: 1.6, z: 3.25, yaw: -.42);

void _samePose(VrlzWorldPose actual, VrlzWorldPose expected) {
  final a = [...actual.position, actual.yaw];
  final b = [...expected.position, expected.yaw];
  for (var i = 0; i < a.length; i++) {
    _require((a[i] - b[i]).abs() < 1e-9, 'Saved pose component $i differs.');
  }
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
