// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const _naverMapClientId = String.fromEnvironment(
  'NAVER_MAP_CLIENT_ID',
  defaultValue: '',
);

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
  static Future<void>? _sdkFuture;
  static final List<js.JsObject> _mapHandles = [];

  late final String _viewType = 'naver-place-map-${_nextViewId++}';
  bool _registered = false;

  bool get _canRender =>
      _naverMapClientId.trim().isNotEmpty &&
      widget.latitude != null &&
      widget.longitude != null;

  @override
  void initState() {
    super.initState();
    if (_canRender) _registerView();
  }

  void _registerView() {
    if (_registered) return;
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final element = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#eef8e9'
        ..setAttribute('aria-label', '${widget.label} 지도');
      unawaited(_renderMap(element));
      return element;
    });
  }

  Future<void> _renderMap(html.DivElement element) async {
    try {
      await (_sdkFuture ??= _loadSdk());
      await Future<void>.delayed(Duration.zero);
      final naver = js.context['naver'] as js.JsObject?;
      final maps = naver?['maps'] as js.JsObject?;
      if (maps == null) throw StateError('Naver Maps SDK is unavailable');

      final center = js.JsObject(maps['LatLng'], [
        widget.latitude,
        widget.longitude,
      ]);
      final map = js.JsObject(maps['Map'], [
        element,
        js.JsObject.jsify({'center': center, 'zoom': 16}),
      ]);
      final marker = js.JsObject(maps['Marker'], [
        js.JsObject.jsify({
          'position': center,
          'map': map,
          'title': widget.label,
        }),
      ]);
      _mapHandles.addAll([map, marker]);
    } catch (_) {
      element
        ..text = '지도를 불러오지 못했어요.'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.color = '#486454'
        ..style.fontFamily = 'sans-serif';
    }
  }

  static Future<void> _loadSdk() {
    if (js.context['naver'] != null) return Future<void>.value();
    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src =
          'https://oapi.map.naver.com/openapi/v3/maps.js?'
          'ncpKeyId=${Uri.encodeQueryComponent(_naverMapClientId.trim())}'
      ..async = true;
    script.onLoad.first.then((_) => completer.complete());
    script.onError.first.then(
      (_) => completer.completeError(StateError('Naver Maps SDK load failed')),
    );
    html.document.head?.append(script);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender) return widget.fallback;
    return HtmlElementView(viewType: _viewType);
  }
}
