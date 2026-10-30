import 'package:flutter/material.dart';

import 'place_map_stub.dart'
    if (dart.library.html) 'place_map_web.dart'
    as platform;

class PlaceMap extends StatelessWidget {
  const PlaceMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.fallback,
  });

  final double? latitude;
  final double? longitude;
  final String label;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => platform.PlatformPlaceMap(
    latitude: latitude,
    longitude: longitude,
    label: label,
    fallback: fallback,
  );
}
