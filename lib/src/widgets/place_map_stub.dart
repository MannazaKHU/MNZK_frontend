import 'package:flutter/material.dart';

class PlatformPlaceMap extends StatelessWidget {
  const PlatformPlaceMap({
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
  Widget build(BuildContext context) => fallback;
}
