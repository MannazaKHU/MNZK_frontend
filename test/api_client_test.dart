import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mannajaku/src/api_client.dart';
import 'package:mannajaku/src/meeting_controller.dart';

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

  test('그룹 생성은 자유 날짜 계약의 필수 세 필드만 전송한다', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      sent = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      return http.Response(
        jsonEncode({
          'meeting': {
            'id': 'meeting-free',
            'title': '강감자',
            'expected_member_count': 4,
            'date_selection_mode': 'free',
            'candidate_dates': ['2026-11-01'],
            'time_range': {'start': '06:00', 'end': '24:00'},
            'slot_minutes': 30,
            'status': 'waiting',
            'revision': 1,
            'invite_code': 'invite-token',
            'progress': {'submitted_member_count': 0},
            'members': [],
            'recommendations': [],
          },
          'member_id': 'host-1',
          'access_token': 'host-token',
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final controller = MeetingController(
      today: DateTime(2026, 10, 30),
      api: MeetFlowApi(baseUrl: 'https://api.example.com', client: client),
      initialUri: Uri.parse('https://front.example.com'),
    );
    addTearDown(controller.dispose);
    controller.startCreate();
    controller.groupName = '강감자';
    controller.hostName = '승주';

    await controller.createGroup();

    expect(sent, {
      'title': '강감자',
      'host_name': '승주',
      'expected_member_count': 4,
    });
    expect(controller.step, MeetingStep.code);
    expect(controller.dateSelectionMode, 'free');
    expect(controller.canSelectDate(DateTime(2027, 3, 1)), isTrue);
    expect(controller.canSelectDate(DateTime(2026, 10, 29)), isFalse);
  });
}
