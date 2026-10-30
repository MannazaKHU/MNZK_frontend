import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mannajaku/src/api_client.dart';

void main() {
  test('생성 요청을 백엔드 계약에 맞게 전송한다', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'meeting': {'id': 'meeting-1'},
          'member_id': 'member-1',
          'access_token': 'token-1',
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = MeetFlowApi(
      baseUrl: 'https://api.example.com/',
      client: client,
    );
    final response = await api.createMeeting({
      'title': '우리 모임',
      'host_name': '승주',
      'expected_member_count': 4,
    });

    expect(captured.url.toString(), 'https://api.example.com/api/meetings');
    expect(captured.method, 'POST');
    expect(jsonDecode(captured.body)['host_name'], '승주');
    expect(response['access_token'], 'token-1');
  });

  test('인증 요청에 Bearer 토큰을 넣고 서버 오류 메시지를 전달한다', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer secret-token');
      return http.Response(
        jsonEncode({
          'detail': {'code': 'INVALID_TOKEN', 'message': '토큰이 올바르지 않아요.'},
        }),
        401,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = MeetFlowApi(baseUrl: 'https://api.example.com', client: client);

    await expectLater(
      api.getMeeting(meetingId: 'meeting-1', accessToken: 'secret-token'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'INVALID_TOKEN')
            .having((error) => error.message, 'message', '토큰이 올바르지 않아요.'),
      ),
    );
  });
}
