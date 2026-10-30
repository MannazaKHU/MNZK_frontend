final Map<String, Map<String, dynamic>> _sessions = {};

Map<String, dynamic>? readMeetingSession(String meetingId) {
  final value = _sessions[meetingId];
  return value == null ? null : Map<String, dynamic>.from(value);
}

void writeMeetingSession(String meetingId, Map<String, dynamic> value) {
  _sessions[meetingId] = Map<String, dynamic>.from(value);
}

void deleteMeetingSession(String meetingId) => _sessions.remove(meetingId);
