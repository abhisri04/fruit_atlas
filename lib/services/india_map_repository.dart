import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../models/india_location_registry.dart';

class IndiaMapRegion {
  final String stateId;
  final Path path;
  IndiaMapRegion(this.stateId, this.path);
}

class IndiaMapRepository {
  // ISO codes belong to the source only; all application state uses registry IDs.
  static const sourceIds = <String, String>{
    'AN': 'andaman_nicobar',
    'AP': 'andhra_pradesh',
    'AR': 'arunachal_pradesh',
    'AS': 'assam',
    'BR': 'bihar',
    'CH': 'chandigarh',
    'CT': 'chhattisgarh',
    'DH': 'dadra_nagar_haveli_daman_diu',
    'DL': 'delhi',
    'GA': 'goa',
    'GJ': 'gujarat',
    'HR': 'haryana',
    'HP': 'himachal_pradesh',
    'JK': 'jammu_kashmir',
    'JH': 'jharkhand',
    'KA': 'karnataka',
    'KL': 'kerala',
    'LA': 'ladakh',
    'LD': 'lakshadweep',
    'MP': 'madhya_pradesh',
    'MH': 'maharashtra',
    'MN': 'manipur',
    'ML': 'meghalaya',
    'MZ': 'mizoram',
    'NL': 'nagaland',
    'OD': 'odisha',
    'PY': 'puducherry',
    'PB': 'punjab',
    'RJ': 'rajasthan',
    'SK': 'sikkim',
    'TN': 'tamil_nadu',
    'TG': 'telangana',
    'TR': 'tripura',
    'UP': 'uttar_pradesh',
    'UT': 'uttarakhand',
    'WB': 'west_bengal',
  };
  static Future<List<IndiaMapRegion>>? _regions;
  static Future<List<IndiaMapRegion>> load() => _regions ??= _load();
  static Future<List<IndiaMapRegion>> _load() async {
    try {
      return parse(
        jsonDecode(
          await rootBundle.loadString(
            'assets/data/india_passport_boundaries.json',
          ),
        ) as Map<String, dynamic>,
      );
    } catch (_) {
      _regions = null;
      rethrow;
    }
  }

  static List<IndiaMapRegion> parse(Map<String, dynamic> data) {
    final regions = <IndiaMapRegion>[];
    for (final feature in data['features'] as List) {
      final code = (feature['properties']['code'] as String).replaceFirst(
        'IN-',
        '',
      );
      final id = sourceIds[code];
      if (id == null) throw FormatException('Unknown map code: $code');
      final geometry = feature['geometry'];
      final coordinates = geometry['coordinates'] as List;
      final polygons = geometry['type'] == 'Polygon'
          ? [coordinates]
          : coordinates;
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final polygon in polygons) {
        for (final ring in polygon as List) {
          final points = (ring as List)
              .map(
                (p) => Offset(
                  ((p[0] as num).toDouble() - 67) * 0.9,
                  38 - (p[1] as num).toDouble(),
                ),
              )
              .toList();
          if (points.length >= 3) path.addPolygon(points, true);
        }
      }
      regions.add(IndiaMapRegion(id, path));
    }
    final ids = regions.map((r) => r.stateId).toSet();
    if (regions.length != 36 ||
        ids.length != 36 ||
        !ids.containsAll(IndiaLocationRegistry.allLocationIds)) {
      throw const FormatException('Map must match all 36 canonical locations');
    }
    return regions;
  }
}
