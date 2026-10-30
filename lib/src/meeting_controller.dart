import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';

enum MeetingStep {
  create,
  code,
  name,
  date,
  time,
  place,
  good,
  bad,
  review,
  wait,
  result,
}

extension MeetingStepLabel on MeetingStep {
  String get label => const {
    MeetingStep.create: '그룹 만들기',
    MeetingStep.code: '초대 링크 공유',
    MeetingStep.name: '이름',
    MeetingStep.date: '날짜 선택',
    MeetingStep.time: '시간 칠하기',
    MeetingStep.place: '출발지',
    MeetingStep.good: '원하는 약속',
    MeetingStep.bad: '피하고 싶은 약속',
    MeetingStep.review: '입력 확인',
    MeetingStep.wait: '그룹원 기다리기',
    MeetingStep.result: '결과',
  }[this]!;
}

class MeetingController extends ChangeNotifier {
  MeetingController({DateTime? today, MeetFlowApi? api, Uri? initialUri})
    : _today = dateOnly(today ?? DateTime.now()),
      api = api ?? MeetFlowApi(),
      viewMonth = DateTime(
        (today ?? DateTime.now()).year,
        (today ?? DateTime.now()).month,
      ) {
    _readInvitation(initialUri ?? Uri.base);
  }

  final DateTime _today;
  final MeetFlowApi api;
  MeetingStep? step;
  ScheduleDraft draft = ScheduleDraft();
  MeetingGroup? group;
  List<Member> members = [];
  List<PlaceRecommendation> recommendations = [];
  DateTime viewMonth;
  int groupSize = 4;
  String groupName = '';
  String hostName = '';
  String? error;
  bool showChoices = false;
  bool showCodeInput = false;
  bool isJoiner = false;
  bool isBusy = false;
  String? serverStatus;
  String? meetingId;
  String? memberId;
  String? accessToken;
  String? inviteCode;
  String? _pendingMeetingId;
  String? _pendingInviteCode;
  Map<String, dynamic>? _remoteMeeting;
  Timer? _pollTimer;
  bool _polling = false;
  final List<Timer> _mockTimers = [];

  bool get backendEnabled => api.enabled;
  int get maxGroupSize => backendEnabled ? 10 : 12;
  Set<String> get allowedDateKeys => {
    for (final value
        in (_remoteMeeting?['candidate_dates'] as List? ?? const []))
      value.toString(),
  };
  bool canSelectDate(DateTime date) =>
      !backendEnabled ||
      allowedDateKeys.isEmpty ||
      allowedDateKeys.contains(dateKey(date));
  List<MeetingStep> get flow => MeetingStep.values.where((s) {
    if (isJoiner) return s.index >= MeetingStep.name.index;
    return !(backendEnabled && s == MeetingStep.name);
  }).toList();
  int get position => step == null ? 0 : flow.indexOf(step!);
  int get completedCount {
    final progress = _remoteMeeting?['progress'];
    if (progress is Map && progress['submitted_member_count'] is num) {
      return (progress['submitted_member_count'] as num).toInt();
    }
    return members.where((m) => m.submitted).length;
  }

  MeetingResult get result => MeetingResult(members);
  String get invitationLink {
    if (!backendEnabled || meetingId == null || inviteCode == null) {
      return group?.code ?? '';
    }
    return Uri.base
        .replace(
          queryParameters: {'meeting': meetingId!, 'invite': inviteCode!},
          fragment: '',
        )
        .toString();
  }

  void _readInvitation(Uri uri) {
    if (!backendEnabled) return;
    final id = uri.queryParameters['meeting'];
    final invite = uri.queryParameters['invite'];
    if (id == null || id.isEmpty || invite == null || invite.isEmpty) return;
    _pendingMeetingId = id;
    _pendingInviteCode = invite;
    isJoiner = true;
    group = const MeetingGroup(name: '초대받은 그룹', size: 0, code: 'INVITE');
    step = MeetingStep.name;
  }

  void home() {
    _cancelTimers();
    step = null;
    showChoices = false;
    showCodeInput = false;
    error = null;
    isBusy = false;
    notifyListeners();
  }

  void choose() {
    home();
    showChoices = true;
    notifyListeners();
  }

  void toggleCodeInput() {
    showCodeInput = !showCodeInput;
    error = null;
    notifyListeners();
  }

  void startCreate() {
    _cancelTimers();
    draft = ScheduleDraft();
    group = null;
    members = [];
    recommendations = [];
    meetingId = null;
    memberId = null;
    accessToken = null;
    inviteCode = null;
    _remoteMeeting = null;
    isJoiner = false;
    groupName = '';
    hostName = '';
    go(MeetingStep.create);
  }

  void changeSize(int delta) {
    groupSize = (groupSize + delta).clamp(2, maxGroupSize);
    notifyListeners();
  }

  Future<void> createGroup() async {
    if (groupName.trim().isEmpty) {
      error = '그룹 이름을 적어주세요.';
      notifyListeners();
      return;
    }
    if (!backendEnabled) {
      const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final random = Random.secure();
      final code = List.generate(
        6,
        (_) => alphabet[random.nextInt(alphabet.length)],
      ).join();
      group = MeetingGroup(name: groupName.trim(), size: groupSize, code: code);
      go(MeetingStep.code);
      return;
    }
    if (hostName.trim().isEmpty) {
      error = '방장 이름을 적어주세요.';
      notifyListeners();
      return;
    }
    await _run(() async {
      final dates = List.generate(
        14,
        (i) => dateKey(_today.add(Duration(days: i))),
      );
      final response = await api.createMeeting({
        'title': groupName.trim(),
        'host_name': hostName.trim(),
        'expected_member_count': groupSize,
        'candidate_dates': dates,
        'time_range': {'start': '06:00', 'end': '23:59'},
        'slot_minutes': 30,
        'recommendation_options': {
          'count': 3,
          'radius_m': 1000,
          'extra_text': '',
        },
      });
      _applySession(response, host: true);
      draft.name = hostName.trim();
      go(MeetingStep.code);
    });
  }

  void joinGroup(String input) {
    final value = input.trim();
    if (!backendEnabled) {
      final code = value.toUpperCase();
      if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
        error = '그룹 코드는 영문과 숫자 6자리예요. 다시 확인해 주세요.';
        notifyListeners();
        return;
      }
      _cancelTimers();
      final existing = group;
      group = existing?.code == code
          ? existing
          : MeetingGroup(name: '예시 그룹', size: 4, code: code);
      draft = ScheduleDraft();
      members = [];
      isJoiner = true;
      go(MeetingStep.name);
      return;
    }
    final uri = Uri.tryParse(value);
    String? id = uri?.queryParameters['meeting'];
    String? invite = uri?.queryParameters['invite'];
    if ((id == null || invite == null) && value.contains('|')) {
      final parts = value.split('|');
      if (parts.length == 2) {
        id = parts[0];
        invite = parts[1];
      }
    }
    if (id == null || id.isEmpty || invite == null || invite.isEmpty) {
      error = '친구에게 받은 초대 링크를 그대로 붙여 넣어주세요.';
      notifyListeners();
      return;
    }
    _cancelTimers();
    _pendingMeetingId = id;
    _pendingInviteCode = invite;
    draft = ScheduleDraft();
    members = [];
    isJoiner = true;
    group = const MeetingGroup(name: '초대받은 그룹', size: 0, code: 'INVITE');
    go(MeetingStep.name);
  }

  Future<bool> _joinRemote() async {
    if (_pendingMeetingId == null || _pendingInviteCode == null) {
      error = '초대 링크 정보가 없어요.';
      notifyListeners();
      return false;
    }
    var joined = false;
    await _run(() async {
      final response = await api.joinMeeting(
        meetingId: _pendingMeetingId!,
        name: draft.name.trim(),
        inviteCode: _pendingInviteCode!,
      );
      _applySession(response, host: false);
      joined = true;
    });
    return joined;
  }

  void go(MeetingStep target) {
    step = target;
    error = null;
    notifyListeners();
  }

  void back() {
    if (position <= 0) {
      home();
    } else {
      go(flow[position - 1]);
    }
  }

  Future<void> next() async {
    if (step == MeetingStep.name && draft.name.trim().isEmpty) {
      error = '이름을 적어주세요.';
      notifyListeners();
      return;
    }
    if (step == MeetingStep.name &&
        backendEnabled &&
        accessToken == null &&
        !await _joinRemote()) {
      return;
    }
    if (step == MeetingStep.date && draft.dates.isEmpty) return;
    if (step == MeetingStep.time && !draft.hasTime) return;
    if (position < flow.length - 1) go(flow[position + 1]);
  }

  void moveMonth(int delta) {
    viewMonth = DateTime(viewMonth.year, viewMonth.month + delta);
    notifyListeners();
  }

  void toggleDate(DateTime date) {
    if (!canSelectDate(date)) {
      error = '이 그룹에서 선택할 수 있는 날짜가 아니에요.';
      notifyListeners();
      return;
    }
    draft.toggleDate(date);
    error = null;
    notifyListeners();
  }

  void setSlots(Map<String, Set<int>> slots) {
    draft.slots
      ..clear()
      ..addAll(slots);
    notifyListeners();
  }

  void clearSlots() {
    draft.slots.clear();
    notifyListeners();
  }

  Future<void> submit() async {
    if (!backendEnabled) {
      _submitDemo();
      return;
    }
    if (meetingId == null || accessToken == null) {
      error = '참여 정보가 없어요. 초대 링크에서 다시 시작해주세요.';
      notifyListeners();
      return;
    }
    await _run(() async {
      final availability = <String, List<String>>{};
      final valid = _validSlotLabels();
      for (final entry in draft.slots.entries) {
        final values = entry.value.map(slotLabel).where(valid.contains).toList()
          ..sort();
        if (values.isNotEmpty) {
          availability[entry.key] = values;
        }
      }
      if (availability.isEmpty) {
        throw const ApiException('서버에서 허용하는 시간대를 한 칸 이상 선택해주세요.');
      }
      final meeting = await api.submit(
        meetingId: meetingId!,
        accessToken: accessToken!,
        body: {
          'availability': availability,
          'start_location_text': draft.place.trim(),
          'desired_text': draft.good.trim(),
          'avoided_text': draft.bad.trim(),
        },
      );
      _applyMeeting(meeting);
      _routeForStatus();
    });
  }

  Set<String> _validSlotLabels() {
    final range = _remoteMeeting?['time_range'];
    final minutes = (_remoteMeeting?['slot_minutes'] as num?)?.toInt() ?? 30;
    if (range is! Map) {
      return {for (var s = firstSlot; s < lastSlot; s++) slotLabel(s)};
    }
    int parse(Object? value) {
      final parts = value.toString().split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final start = parse(range['start']);
    final end = parse(range['end']);
    return {
      for (var value = start; value + minutes <= end; value += minutes)
        '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}',
    };
  }

  void _applySession(Map<String, dynamic> response, {required bool host}) {
    final meeting = Map<String, dynamic>.from(response['meeting'] as Map);
    meetingId = meeting['id'].toString();
    memberId = response['member_id'].toString();
    accessToken = response['access_token'].toString();
    if (host) inviteCode = meeting['invite_code']?.toString();
    _applyMeeting(meeting);
  }

  String _displayCode(String? value) {
    final cleaned = (value ?? '')
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toUpperCase();
    return cleaned.length >= 6
        ? cleaned.substring(0, 6)
        : cleaned.padRight(6, 'X');
  }

  void _applyMeeting(Map<String, dynamic> meeting) {
    _remoteMeeting = meeting;
    serverStatus = meeting['status']?.toString();
    final expected =
        (meeting['expected_member_count'] as num?)?.toInt() ?? groupSize;
    groupSize = expected;
    group = MeetingGroup(
      id: meeting['id']?.toString(),
      name: meeting['title']?.toString() ?? groupName,
      size: expected,
      code: _displayCode(inviteCode ?? _pendingInviteCode),
    );
    final rawMembers = meeting['members'] as List? ?? const [];
    members = rawMembers.map((raw) {
      final data = Map<String, dynamic>.from(raw as Map);
      final member = Member(
        name: data['name']?.toString() ?? '참여자',
        isMe: data['id']?.toString() == memberId,
      )..submitted = data['submitted_at'] != null;
      final availability = data['availability'];
      if (availability is Map) {
        member.slots = availability.map((key, value) {
          final slots = <int>{};
          if (value is List) {
            for (final time in value) {
              final parts = time.toString().split(':');
              if (parts.length == 2) {
                slots.add(
                  int.parse(parts[0]) * 2 + (int.parse(parts[1]) >= 30 ? 1 : 0),
                );
              }
            }
          }
          return MapEntry(key.toString(), slots);
        });
      }
      final preference = data['preference'];
      if (preference is Map && preference['submission_input'] is Map) {
        final input = preference['submission_input'] as Map;
        member.place = input['start_location_text']?.toString() ?? '';
        member.good = input['desired_text']?.toString() ?? '';
        member.bad = input['avoided_text']?.toString() ?? '';
      }
      return member;
    }).toList();
    final rawRecommendations = meeting['recommendations'] as List? ?? const [];
    recommendations = rawRecommendations
        .whereType<Map>()
        .map(
          (item) =>
              PlaceRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  void _routeForStatus() {
    switch (serverStatus) {
      case 'recommended':
      case 'finalized':
        _pollTimer?.cancel();
        go(MeetingStep.result);
      case 'schedule_conflict':
        error = _processingMessage() ?? '전원이 가능한 공통 시간이 없어요.';
        step = MeetingStep.wait;
        notifyListeners();
      case 'failed':
        error = _processingMessage() ?? '추천 처리에 실패했어요.';
        step = MeetingStep.wait;
        notifyListeners();
      default:
        go(MeetingStep.wait);
        _startPolling();
    }
  }

  String? _processingMessage() {
    final value = _remoteMeeting?['processing_error'];
    return value is Map ? value['message']?.toString() : null;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_polling || meetingId == null || accessToken == null) return;
    _polling = true;
    try {
      final meeting = await api.getMeeting(
        meetingId: meetingId!,
        accessToken: accessToken!,
      );
      _applyMeeting(meeting);
      if (serverStatus == 'recommended' || serverStatus == 'finalized') {
        _pollTimer?.cancel();
        go(MeetingStep.result);
      } else {
        if (serverStatus == 'failed' || serverStatus == 'schedule_conflict') {
          error = _processingMessage();
          _pollTimer?.cancel();
        }
        notifyListeners();
      }
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    } finally {
      _polling = false;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isBusy) return;
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = '요청을 처리하는 중 문제가 생겼어요.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _submitDemo() {
    _cancelTimers();
    final me = Member(name: draft.name.trim(), isMe: true)
      ..submitted = true
      ..slots = draft.slots.map((k, v) => MapEntry(k, {...v}))
      ..place = draft.place.trim()
      ..good = draft.good.trim()
      ..bad = draft.bad.trim();
    const names = [
      '지윤',
      '민호',
      '수아',
      '도현',
      '하린',
      '서준',
      '예은',
      '지후',
      '유나',
      '건우',
      '소율',
    ];
    members = [
      me,
      for (var i = 0; i < group!.size - 1; i++)
        Member(name: names[i], isExample: true),
    ];
    go(MeetingStep.wait);
    for (var i = 1; i < members.length; i++) {
      final index = i;
      _mockTimers.add(
        Timer(Duration(milliseconds: 700 + i * 450), () {
          _fillExample(members[index], index);
          notifyListeners();
          if (completedCount == group!.size) {
            _mockTimers.add(
              Timer(const Duration(milliseconds: 1600), () {
                if (step == MeetingStep.wait) go(MeetingStep.result);
              }),
            );
          }
        }),
      );
    }
  }

  void _fillExample(Member member, int index) {
    const places = ['경희대 국제캠퍼스', '수원역', '영통역', '강남역'];
    const good = ['이동시간이 짧았으면 좋겠다', '조용한 카페', '역에서 가까운 곳', '디저트가 있는 곳'];
    const bad = ['시끄러운 곳', '웨이팅 긴 곳', '너무 늦은 시간', '비싼 곳'];
    member
      ..submitted = true
      ..place = places[(index - 1) % places.length]
      ..good = good[(index - 1) % good.length]
      ..bad = bad[(index - 1) % bad.length];
    for (final entry in draft.slots.entries) {
      final available = <int>{};
      for (final range in consecutiveRanges(entry.value)) {
        final start = max(firstSlot, range.start - index % 3);
        final end = min(lastSlot, range.end + (index + 1) % 3);
        for (var s = start; s < end; s++) {
          available.add(s);
        }
      }
      member.slots[entry.key] = available;
    }
  }

  void editMine() {
    _pollTimer?.cancel();
    go(MeetingStep.date);
  }

  void _cancelTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    for (final timer in _mockTimers) {
      timer.cancel();
    }
    _mockTimers.clear();
  }

  @override
  void dispose() {
    _cancelTimers();
    api.close();
    super.dispose();
  }
}
