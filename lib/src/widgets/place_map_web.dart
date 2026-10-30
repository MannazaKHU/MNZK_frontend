// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class PlatformPlaceMap extends StatefulWidget {
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
  State<PlatformPlaceMap> createState() => _PlatformPlaceMapState();
}

class _PlatformPlaceMapState extends State<PlatformPlaceMap> {
  static int _nextViewId = 0;

  late final String _viewType = 'place-map-${_nextViewId++}';
  bool _registered = false;

  bool get _canRender => widget.latitude != null && widget.longitude != null;

  @override
  void initState() {
    super.initState();
    if (_canRender) _registerView();
  }

  void _registerView() {
    if (_registered) return;
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final lat = widget.latitude!;
      final lng = widget.longitude!;
      final bbox = [lng - .006, lat - .004, lng + .006, lat + .004].join(',');
      return html.IFrameElement()
        ..src =
            'https://www.openstreetmap.org/export/embed.html?'
            'bbox=${Uri.encodeQueryComponent(bbox)}&layer=mapnik&marker=$lat%2C$lng'
        ..title = '${widget.label} 지도'
        ..setAttribute('loading', 'lazy')
        ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade')
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#eef8e9';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender) return widget.fallback;
    return HtmlElementView(viewType: _viewType);
  }
}
