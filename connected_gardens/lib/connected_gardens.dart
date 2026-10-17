import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:vrlizate_world/vrlizate_world.dart';

import 'glb_writer.dart';

/// All author-owned content lives here, outside the VRlizate application.
abstract final class ConnectedGardens {
  static const id = 'community.connected_gardens';
  static const aliases = ['garden', 'observatory'];
  static const revision = '1.0.0-beta.1';

  static Map<String, Object?> worldSource(
    String alias, {
    String license = 'MIT',
  }) {
    if (!aliases.contains(alias)) throw ArgumentError.value(alias, 'alias');
    final garden = alias == 'garden';
    final models = <String, Uint8List>{
      'floor': _floor(garden),
      'pavilion': garden ? _pergola() : _observatory(),
      'planter': garden ? _planter() : _beacon(),
      'monument': garden ? _fountain() : _orrery(),
    };
    final entities = <Map<String, Object?>>[];
    void place(
      String name,
      String prototype,
      double x,
      double z, {
      double yaw = 0,
    }) {
      entities.add({
        'id': '$alias.$name',
        'prototypeId': '$id.$alias.$prototype',
        'x': x,
        'y': 0.0,
        'z': z,
        'yawRadians': yaw,
        'scale': 1.0,
      });
    }

    for (final x in [-6.0, 6.0]) {
      for (final z in [-6.0, 6.0]) {
        place('floor.$x.$z', 'floor', x, z);
      }
    }
    place('pavilion', 'pavilion', -6, -3);
    place('monument', 'monument', 5, -3);
    for (var i = 0; i < 4; i++) {
      place(
        'planter.$i',
        'planter',
        i.isEven ? -8.5 : 8.5,
        i < 2 ? 6.0 : -8.0,
        yaw: i * math.pi / 2,
      );
    }
    final regions = <Map<String, Object?>>[];
    for (var z = -1; z <= 0; z++) {
      for (var x = -1; x <= 0; x++) {
        regions.add({
          'x': x,
          'z': z,
          'entities': [
            for (final entity in entities)
              if (((entity['x'] as double) / 12).floor() == x &&
                  ((entity['z'] as double) / 12).floor() == z)
                {
                  ...entity,
                  'x': (entity['x'] as double) - x * 12,
                  'z': (entity['z'] as double) - z * 12,
                },
          ],
        });
      }
    }
    return {
      'schemaVersion': 1,
      'id': '$id.$alias',
      'title': garden ? 'Jardín de mosaicos' : 'Observatorio del crepúsculo',
      'revision': revision,
      'license': license,
      'gridId': '$alias-grid-12m',
      'cellSizeMeters': 12,
      'origin': {'type': 'local'},
      'prototypes': [for (final key in models.keys) '$id.$alias.$key'],
      'regions': regions,
      'resources': [
        for (final entry in models.entries)
          {
            'id': 'model.${entry.key}',
            'type': 'model.glb',
            'data': base64.encode(entry.value),
          },
        {
          'id': 'texture.mosaic',
          'type': 'texture.rgba8',
          'width': 64,
          'height': 64,
          'data': base64.encode(_mosaic(garden)),
        },
      ],
      'prototypeBindings': [
        for (final key in models.keys)
          {
            'prototypeId': '$id.$alias.$key',
            'model': 'model.$key',
            if (key == 'floor') 'baseColorTexture': 'texture.mosaic',
          },
      ],
    };
  }

  static Map<String, Object?> manifest(Map<String, Uint8List> worlds) => {
    'formatVersion': 1,
    'id': id,
    'title': 'Jardines conectados',
    'description':
        'Un jardín de mosaicos y un observatorio originales, unidos por portales.',
    'runtime': 'vrlizate.worlds.v1',
    'entrypoint': 'garden',
    'capabilities': ['worlds.local'],
    'revision': revision,
    'worlds': [
      for (final alias in aliases)
        {
          'alias': alias,
          'id': '$id.$alias',
          'file': 'world_$alias.vrlw',
          'sha256': crypto.sha256
              .convert(worlds['world_$alias.vrlw']!)
              .toString(),
          'indexSha256': _index(worlds['world_$alias.vrlw']!).indexSha256,
          'spawn': [0.0, 1.6, 7.0],
          'yaw': 0.0,
        },
    ],
    'portals': [
      {
        'id': 'garden.to_observatory',
        'from': 'garden',
        'to': 'observatory',
        'position': [0.0, 1.6, -9.0],
        'arrival': [0.0, 1.6, 7.0],
        'yaw': 0.0,
        'label': 'Observatorio del crepúsculo',
      },
      {
        'id': 'observatory.to_garden',
        'from': 'observatory',
        'to': 'garden',
        'position': [0.0, 1.6, -9.0],
        'arrival': [0.0, 1.6, 7.0],
        'yaw': 0.0,
        'label': 'Jardín de mosaicos',
      },
    ],
  };

  static VrlwBundleIndex _index(Uint8List bytes) {
    final header = VrlwBundleCodec.parseHeader(bytes.sublist(0, 16));
    return VrlwBundleCodec.parseIndex(
      header,
      bytes.sublist(16, header.payloadOffset),
    );
  }

  static Uint8List _floor(bool garden) {
    final model = StaticGlb();
    model.box('mosaic_floor', [1, 1, 1], 0, -.08, 0, 12, .16, 12, uvScale: 3);
    return model.encode();
  }

  static Uint8List _pergola() {
    final m = StaticGlb();
    const wood = [.40, .23, .12], foliage = [.19, .42, .13];
    for (final x in [-2.3, 2.3]) {
      for (final z in [-1.8, 1.8]) {
        m.box('cedar', wood, x, 1.55, z, .22, 3.1, .22);
      }
    }
    for (final x in [-2.3, 2.3]) {
      m.box('cedar', wood, x, 3.13, 0, .28, .25, 4.5);
    }
    for (var i = 0; i < 8; i++) {
      m.box('cedar', wood, 0, 3.30, -2.1 + i * .6, 5.4, .16, .15);
      if (i.isEven)
        m.box(
          'climbing_leaves',
          foliage,
          -.2,
          3.42,
          -2.1 + i * .6,
          3.3,
          .12,
          .32,
        );
    }
    m.box('cedar', wood, 0, .53, -1.55, 3.5, .16, .65);
    m.box('cedar', wood, 0, .95, -1.86, 3.5, .70, .12);
    for (final x in [-1.35, 1.35]) {
      m.box('cedar', wood, x, .23, -1.55, .14, .46, .55);
    }
    return m.encode();
  }

  static Uint8List _planter() {
    final m = StaticGlb();
    m.cylinder('terracotta', [.60, .24, .12], 0, .33, 0, .65, .83, .66);
    m.cylinder('soil', [.12, .08, .04], 0, .67, 0, .72, .72, .035);
    for (var i = 0; i < 6; i++) {
      final x = math.cos(i * math.pi / 3) * .43;
      final z = math.sin(i * math.pi / 3) * .43;
      m.box('stems', [.16, .33, .08], x, 1.05, z, .07, .75, .07);
      m.cylinder(
        'sage',
        [.28, .50, .18],
        x,
        1.10,
        z,
        .24,
        .05,
        .45,
        segments: 6,
      );
      m.cylinder(
        'flowers',
        [.89, .67, .26],
        x,
        1.47,
        z,
        .13,
        .04,
        .12,
        segments: 6,
      );
    }
    return m.encode();
  }

  static Uint8List _fountain() {
    final m = StaticGlb();
    m.cylinder(
      'limestone',
      [.80, .76, .61],
      0,
      .14,
      0,
      1.70,
      1.70,
      .28,
      segments: 20,
    );
    m.cylinder(
      'water',
      [.13, .48, .57],
      0,
      .29,
      0,
      1.42,
      1.42,
      .03,
      segments: 20,
    );
    m.cylinder('limestone', [.80, .76, .61], 0, .72, 0, .34, .25, .90);
    m.cylinder(
      'limestone',
      [.80, .76, .61],
      0,
      1.20,
      0,
      .83,
      .98,
      .16,
      segments: 16,
    );
    m.cylinder(
      'water',
      [.13, .48, .57],
      0,
      1.29,
      0,
      .83,
      .83,
      .02,
      segments: 16,
    );
    m.cylinder('limestone', [.80, .76, .61], 0, 1.58, 0, .15, .05, .6);
    return m.encode();
  }

  static Uint8List _observatory() {
    final m = StaticGlb();
    const metal = [.20, .30, .40], copper = [.66, .38, .18];
    m.cylinder(
      'platform',
      [.40, .47, .54],
      0,
      .10,
      0,
      2.8,
      2.8,
      .20,
      segments: 8,
    );
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      // The two eastern bays remain open toward the central path.
      if (i != 0)
        m.box(
          'navy_frame',
          metal,
          math.cos(a) * 2.5,
          1.65,
          math.sin(a) * 2.5,
          .16,
          3.1,
          .16,
        );
    }
    m.cylinder('roof_rim', copper, 0, 3.25, 0, 2.85, 2.85, .18, segments: 8);
    m.cylinder('navy_frame', metal, 0, 3.63, 0, 2.85, .45, .62, segments: 8);
    m.cylinder('antenna', copper, 0, 4.08, 0, .11, .05, .30);
    m.cylinder('instrument', [.23, .56, .65], 0, 1.02, 0, .22, .18, 1.55);
    m.box('instrument', [.23, .56, .65], 0, 1.88, 0, .60, .23, 1.70);
    m.box('lens', [.09, .16, .27], 0, 1.88, -.90, .48, .18, .12);
    return m.encode();
  }

  static Uint8List _beacon() {
    final m = StaticGlb();
    m.cylinder(
      'foundation',
      [.36, .42, .48],
      0,
      .15,
      0,
      .63,
      .63,
      .30,
      segments: 8,
    );
    m.cylinder('mast', [.20, .29, .39], 0, 1.03, 0, .16, .12, 1.48);
    m.cylinder(
      'signal',
      [.20, .73, .82],
      0,
      1.89,
      0,
      .32,
      .32,
      .28,
      segments: 8,
    );
    m.cylinder('cap', [.73, .41, .18], 0, 2.10, 0, .43, .04, .20, segments: 8);
    return m.encode();
  }

  static Uint8List _orrery() {
    final m = StaticGlb();
    m.cylinder(
      'platform',
      [.38, .45, .54],
      0,
      .19,
      0,
      1.65,
      1.65,
      .38,
      segments: 16,
    );
    m.cylinder('mast', [.30, .36, .43], 0, 1.13, 0, .19, .12, 1.6);
    const gold = [.80, .57, .20];
    m.cylinder('sun', gold, 0, 2.10, 0, .50, .22, .65, segments: 10);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      m.box(
        'orbit',
        [.27, .67, .78],
        math.cos(a) * 1.4,
        1.73,
        math.sin(a) * 1.4,
        .22,
        .10,
        .22,
      );
    }
    m.box('orbit', [.27, .67, .78], 0, 1.73, 0, 2.8, .10, .10);
    m.box('orbit', [.27, .67, .78], 0, 1.73, 0, .10, .10, 2.8);
    m.cylinder(
      'planet',
      [.72, .34, .20],
      1.4,
      1.94,
      0,
      .26,
      .08,
      .42,
      segments: 8,
    );
    return m.encode();
  }

  static Uint8List _mosaic(bool garden) {
    final bytes = Uint8List(64 * 64 * 4);
    final colors = garden
        ? const [
            [219, 207, 161],
            [153, 175, 143],
            [171, 117, 82],
            [235, 218, 176],
          ]
        : const [
            [43, 72, 99],
            [69, 114, 132],
            [149, 116, 67],
            [111, 143, 161],
          ];
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        final tile = ((x ~/ 8) + (y ~/ 8) * 3) % colors.length;
        final grout = x % 8 == 0 || y % 8 == 0;
        final inset = x % 8 == 1 || y % 8 == 1;
        final color = colors[tile];
        final at = (y * 64 + x) * 4;
        for (var c = 0; c < 3; c++) {
          bytes[at + c] = grout
              ? (garden ? 76 : 22)
              : (color[c] + (inset ? 10 : 0)).clamp(0, 255);
        }
        bytes[at + 3] = 255;
      }
    }
    return bytes;
  }
}
