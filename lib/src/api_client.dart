import 'dart:convert';

import 'package:http/http.dart' as http;

const configuredApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class MeetFlowApi {
  MeetFlowApi({String baseUrl = configuredApiBaseUrl, http.Client? client})
    : baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  bool get enabled => baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> body) =>
      _request('POST', '/api/meetings', body: body);

  Future<Map<String, dynamic>> joinMeeting({
    required String meetingId,
    required String name,
    required String inviteCode,
  }) => _request(
    'POST',
    '/api/meetings/$meetingId/members',
    body: {'name': name, 'invite_code': inviteCode},
  );

  Future<Map<String, dynamic>> getMeeting({
    required String meetingId,
    required String accessToken,
  }) => _request('GET', '/api/meetings/$meetingId', accessToken: accessToken);

  Future<Map<String, dynamic>> submit({
    required String meetingId,
    required String accessToken,
    required Map<String, dynamic> body,
  }) => _request(
    'PUT',
    '/api/meetings/$meetingId/members/me/submission',
    accessToken: accessToken,
    body: body,
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
  }) async {
    if (!enabled) {
      throw const ApiException('백엔드 주소가 설정되지 않았어요.');
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null) headers['Authorization'] = 'Bearer $accessToken';
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri, headers: headers),
        'POST' => await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const {}),
        ),
        'PUT' => await _client.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const {}),
        ),
        _ => throw ApiException('지원하지 않는 요청 방식이에요: $method'),
      };
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('서버에 연결하지 못했어요. API 주소와 CORS 설정을 확인해주세요.');
    }

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        final value = jsonDecode(utf8.decode(response.bodyBytes));
        if (value is Map<String, dynamic>) decoded = value;
      } catch (_) {
        throw ApiException('서버 응답을 읽지 못했어요.', statusCode: response.statusCode);
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded['detail'];
      if (detail is Map) {
        throw ApiException(
          detail['message']?.toString() ?? '요청을 처리하지 못했어요.',
          code: detail['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
      throw ApiException(
        '요청을 처리하지 못했어요. (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  void close() => _client.close();
}
