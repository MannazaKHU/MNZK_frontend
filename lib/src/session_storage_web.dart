// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

const _prefix = 'mannajaku.meeting-session.';

Map<String, dynamic>? readMeetingSession(String meetingId) {
  final raw = html.window.localStorage['$_prefix$meetingId'];
  if (raw == null || raw.isEmpty) return null;
  try {
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  } catch (_) {
    html.window.localStorage.remove('$_prefix$meetingId');
    return null;
  }
}

void writeMeetingSession(String meetingId, Map<String, dynamic> value) {
  html.window.localStorage['$_prefix$meetingId'] = jsonEncode(value);
}

void deleteMeetingSession(String meetingId) {
  html.window.localStorage.remove('$_prefix$meetingId');
}
