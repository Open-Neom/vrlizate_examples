import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Original, static GLB meshes; no renderer or application dependency.
final class StaticGlb {
  final _parts = <String, _Part>{};

  void box(
    String material,
    List<double> color,
    double x,
    double y,
    double z,
    double width,
    double height,
    double depth, {
    double uvScale = 1,
  }) {
    final a = x - width / 2, b = x + width / 2;
    final c = y - height / 2, d = y + height / 2;
    final e = z - depth / 2, f = z + depth / 2;
    final part = _parts.putIfAbsent(material, () => _Part(material, color));
    for (final face in [
      [
        [b, c, e],
        [b, d, e],
        [b, d, f],
        [b, c, f],
      ],
      [
        [a, c, f],
        [a, d, f],
        [a, d, e],
        [a, c, e],
      ],
      [
        [a, d, f],
        [b, d, f],
        [b, d, e],
        [a, d, e],
      ],
      [
        [a, c, e],
        [b, c, e],
        [b, c, f],
        [a, c, f],
      ],
      [
        [b, c, f],
        [b, d, f],
        [a, d, f],
        [a, c, f],
      ],
      [
        [a, c, e],
        [a, d, e],
        [b, d, e],
        [b, c, e],
      ],
    ]) {
      part.quad(face[0], face[1], face[2], face[3], uvScale);
    }
  }

  void cylinder(
    String material,
    List<double> color,
    double x,
    double y,
    double z,
    double bottomRadius,
    double topRadius,
    double height, {
    int segments = 12,
  }) {
    final part = _parts.putIfAbsent(material, () => _Part(material, color));
    final bottom = y - height / 2, top = y + height / 2;
    for (var i = 0; i < segments; i++) {
      final a = i * math.pi * 2 / segments;
      final b = (i + 1) * math.pi * 2 / segments;
      final p = [
        x + math.cos(a) * bottomRadius,
        bottom,
        z + math.sin(a) * bottomRadius,
      ];
      final q = [
        x + math.cos(b) * bottomRadius,
        bottom,
        z + math.sin(b) * bottomRadius,
      ];
      final r = [x + math.cos(b) * topRadius, top, z + math.sin(b) * topRadius];
      final s = [x + math.cos(a) * topRadius, top, z + math.sin(a) * topRadius];
      part.quad(q, p, s, r, 1);
      if (bottomRadius > 0) part.triangle([x, bottom, z], p, q);
      if (topRadius > 0) part.triangle([x, top, z], r, s);
    }
  }

  Uint8List encode() {
    final binary = BytesBuilder(copy: false);
    final views = <Map<String, Object>>[];
    final accessors = <Map<String, Object>>[];
    final meshes = <Map<String, Object>>[];
    final materials = <Map<String, Object>>[];
    final nodes = <Map<String, Object>>[];

    int add(
      List<num> values,
      int components,
      String type, {
      bool indices = false,
    }) {
      while (binary.length % 4 != 0) {
        binary.addByte(0);
      }
      final start = binary.length;
      final data = ByteData(values.length * (indices ? 2 : 4));
      for (var i = 0; i < values.length; i++) {
        if (indices) {
          data.setUint16(i * 2, values[i].toInt(), Endian.little);
        } else {
          data.setFloat32(i * 4, values[i].toDouble(), Endian.little);
        }
      }
      binary.add(data.buffer.asUint8List());
      views.add({
        'buffer': 0,
        'byteOffset': start,
        'byteLength': data.lengthInBytes,
      });
      accessors.add({
        'bufferView': views.length - 1,
        'componentType': indices ? 5123 : 5126,
        'count': values.length ~/ components,
        'type': type,
        if (!indices)
          'min': [
            for (var c = 0; c < components; c++)
              _extreme(values, components, c, true),
          ],
        if (!indices)
          'max': [
            for (var c = 0; c < components; c++)
              _extreme(values, components, c, false),
          ],
      });
      return accessors.length - 1;
    }

    for (final part in _parts.values) {
      if (part.positions.length ~/ 3 > 65535)
        throw StateError('Mesh is too large.');
      final position = add(part.positions, 3, 'VEC3');
      final normal = add(part.normals, 3, 'VEC3');
      final uv = add(part.uvs, 2, 'VEC2');
      final indices = add(part.indices, 1, 'SCALAR', indices: true);
      materials.add({
        'name': part.name,
        'pbrMetallicRoughness': {
          'baseColorFactor': [...part.color, 1.0],
          'metallicFactor': 0.0,
          'roughnessFactor': 0.78,
        },
      });
      meshes.add({
        'name': part.name,
        'primitives': [
          {
            'attributes': {
              'POSITION': position,
              'NORMAL': normal,
              'TEXCOORD_0': uv,
            },
            'indices': indices,
            'material': materials.length - 1,
            'mode': 4,
          },
        ],
      });
      nodes.add({'name': part.name, 'mesh': meshes.length - 1});
    }
    final unpaddedLength = binary.length;
    while (binary.length % 4 != 0) {
      binary.addByte(0);
    }
    final json = utf8.encode(
      jsonEncode({
        'asset': {
          'version': '2.0',
          'generator': 'connected_gardens static Dart authoring',
        },
        'scene': 0,
        'scenes': [
          {'nodes': List<int>.generate(nodes.length, (i) => i)},
        ],
        'nodes': nodes,
        'meshes': meshes,
        'materials': materials,
        'buffers': [
          {'byteLength': unpaddedLength},
        ],
        'bufferViews': views,
        'accessors': accessors,
      }),
    );
    final paddedJson = [
      ...json,
      ...List<int>.filled((4 - json.length % 4) % 4, 32),
    ];
    final bin = binary.takeBytes();
    final result = Uint8List(12 + 8 + paddedJson.length + 8 + bin.length);
    final header = ByteData.sublistView(result);
    header
      ..setUint32(0, 0x46546c67, Endian.little)
      ..setUint32(4, 2, Endian.little)
      ..setUint32(8, result.length, Endian.little)
      ..setUint32(12, paddedJson.length, Endian.little)
      ..setUint32(16, 0x4e4f534a, Endian.little)
      ..setUint32(20 + paddedJson.length, bin.length, Endian.little)
      ..setUint32(24 + paddedJson.length, 0x004e4942, Endian.little);
    result.setRange(20, 20 + paddedJson.length, paddedJson);
    result.setRange(28 + paddedJson.length, result.length, bin);
    return result;
  }
}

double _extreme(List<num> values, int stride, int channel, bool minimum) {
  var result = values[channel].toDouble();
  for (var i = channel + stride; i < values.length; i += stride) {
    result = minimum
        ? math.min(result, values[i].toDouble())
        : math.max(result, values[i].toDouble());
  }
  return result;
}

final class _Part {
  _Part(this.name, this.color);
  final String name;
  final List<double> color;
  final positions = <double>[], normals = <double>[], uvs = <double>[];
  final indices = <int>[];

  void quad(
    List<double> a,
    List<double> b,
    List<double> c,
    List<double> d,
    double uvScale,
  ) {
    triangle(
      a,
      b,
      c,
      uv: [
        [0, 0],
        [0, uvScale],
        [uvScale, uvScale],
      ],
    );
    triangle(
      a,
      c,
      d,
      uv: [
        [0, 0],
        [uvScale, uvScale],
        [uvScale, 0],
      ],
    );
  }

  void triangle(
    List<double> a,
    List<double> b,
    List<double> c, {
    List<List<double>>? uv,
  }) {
    final ab = [for (var i = 0; i < 3; i++) b[i] - a[i]];
    final ac = [for (var i = 0; i < 3; i++) c[i] - a[i]];
    final n = [
      ab[1] * ac[2] - ab[2] * ac[1],
      ab[2] * ac[0] - ab[0] * ac[2],
      ab[0] * ac[1] - ab[1] * ac[0],
    ];
    final length = math.sqrt(n.fold<double>(0, (sum, v) => sum + v * v));
    if (length < 1e-10) return;
    final first = positions.length ~/ 3;
    for (var i = 0; i < 3; i++) {
      positions.addAll([a, b, c][i]);
      normals.addAll(n.map((v) => v / length));
      uvs.addAll(
        (uv ??
            const [
              [0.5, 0.5],
              [0.0, 0.0],
              [1.0, 1.0],
            ])[i],
      );
      indices.add(first + i);
    }
  }
}
