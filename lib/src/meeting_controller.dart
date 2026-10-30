import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'session_storage.dart';

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
    if (_pendingMeetingId != null) unawaited(_restoreSession());
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
  bool isJoiner = false;
  bool isHost = false;
  bool isBusy = false;
  String? serverStatus;
  int revision = 1;
  String? confirmedPlaceId;
  String? meetingId;
  String? memberId;
  String? accessToken;
  String? inviteCode;
  String? _pendingMeetingId;
  String? _pendingInviteCode;
  Map<String, dynamic>? _remoteMeeting;
  Timer? _pollTimer;
  bool _polling = false;
  bool restoringSession = false;
  final List<Timer> _mockTimers = [];

  bool get backendEnabled => api.enabled;
  int get maxGroupSize => backendEnabled ? 10 : 12;
  Set<String> get allowedDateKeys => {
    for (final value
        in (_remoteMeeting?['candidate_dates'] as List? ?? const []))
      value.toString(),
  };
  String get dateSelectionMode =>
      _remoteMeeting?['date_selection_mode']?.toString() ?? 'fixed';
  bool canSelectDate(DateTime date) {
    final value = dateOnly(date);
    if (backendEnabled && value.isBefore(_today)) return false;
    if (!backendEnabled || dateSelectionMode == 'free') return true;
    return allowedDateKeys.contains(dateKey(value));
  }

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
      return '';
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
    group = const MeetingGroup(name: '초대받은 그룹', size: 0);
    step = MeetingStep.name;
  }

  Future<void> _restoreSession() async {
    final id = _pendingMeetingId;
    if (id == null) return;
    final saved = readMeetingSession(id);
    if (saved == null || saved['access_token']?.toString().isEmpty != false) {
      return;
    }
    restoringSession = true;
    notifyListeners();
    try {
      meetingId = id;
      memberId = saved['member_id']?.toString();
      accessToken = saved['access_token']?.toString();
      inviteCode = saved['invite_code']?.toString() ?? _pendingInviteCode;
      isHost = saved['is_host'] == true;
      isJoiner = !isHost;
      _restoreDraft(saved['draft']);
      final meeting = await api.getMeeting(
        meetingId: meetingId!,
        accessToken: accessToken!,
      );
      _applyMeeting(meeting);
      final me = (meeting['members'] as List? ?? const [])
          .whereType<Map>()
          .where((member) => member['id']?.toString() == memberId);
      final submitted = me.isNotEmpty && me.first['submitted_at'] != null;
      if (serverStatus == 'recommended' || serverStatus == 'finalized') {
        go(MeetingStep.result);
      } else if (submitted || saved['step'] == MeetingStep.wait.name) {
        go(MeetingStep.wait);
        _startPolling();
      } else {
        final savedStep = MeetingStep.values.where(
          (value) => value.name == saved['step']?.toString(),
        );
        final target = savedStep.isEmpty ? MeetingStep.date : savedStep.first;
        go(
          target.index >= MeetingStep.date.index &&
                  target.index <= MeetingStep.review.index
              ? target
              : MeetingStep.date,
        );
      }
    } on ApiException {
      deleteMeetingSession(id);
      meetingId = null;
      memberId = null;
      accessToken = null;
      isHost = false;
      isJoiner = true;
      step = MeetingStep.name;
    } finally {
      restoringSession = false;
      notifyListeners();
    }
  }

  void _restoreDraft(Object? value) {
    if (value is! Map) return;
    final restored = ScheduleDraft();
    restored.name = value['name']?.toString() ?? '';
    restored.place = value['place']?.toString() ?? '';
    restored.good = value['good']?.toString() ?? '';
    restored.bad = value['bad']?.toString() ?? '';
    final dates = value['dates'];
    if (dates is List) {
      for (final raw in dates) {
        final date = DateTime.tryParse(raw.toString());
        if (date != null) restored.dates.add(dateOnly(date));
      }
    }
    final slots = value['slots'];
    if (slots is Map) {
      for (final entry in slots.entries) {
        final values = entry.value;
        if (values is List) {
          restored.slots[entry.key.toString()] = values
              .whereType<num>()
              .map((value) => value.toInt())
              .toSet();
        }
      }
    }
    draft = restored;
  }

  void saveProgress() {
    final id = meetingId;
    if (id == null || memberId == null || accessToken == null) return;
    writeMeetingSession(id, {
      'member_id': memberId,
      'access_token': accessToken,
      'invite_code': inviteCode ?? _pendingInviteCode,
      'is_host': isHost,
      'step': step?.name,
      'draft': draft.toJson(),
    });
  }

  void home() {
    _cancelTimers();
    step = null;
    showChoices = false;
    error = null;
    isBusy = false;
    notifyListeners();
  }

  void choose() {
    home();
    showChoices = true;
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
    isHost = false;
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
      group = MeetingGroup(name: groupName.trim(), size: groupSize);
      go(MeetingStep.code);
      return;
    }
    if (hostName.trim().isEmpty) {
      error = '방장 이름을 적어주세요.';
      notifyListeners();
      return;
    }
    await _run(() async {
      final response = await api.createMeeting({
        'title': groupName.trim(),
        'host_name': hostName.trim(),
        'expected_member_count': groupSize,
      });
      _applySession(response, host: true);
      draft.name = hostName.trim();
      go(MeetingStep.code);
    });
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
    saveProgress();
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
    if (step == MeetingStep.place && draft.place.trim().isEmpty) {
      error = '출발지를 적어주세요.';
      notifyListeners();
      return;
    }
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
    final normalized = dateOnly(date);
    if (!draft.dates.contains(normalized) && draft.dates.length >= 14) {
      error = '날짜는 최대 14개까지 선택할 수 있어요.';
      notifyListeners();
      return;
    }
    draft.toggleDate(normalized);
    error = null;
    saveProgress();
    notifyListeners();
  }

  void setSlots(Map<String, Set<int>> slots) {
    draft.slots
      ..clear()
      ..addAll(slots);
    saveProgress();
    notifyListeners();
  }

  void clearSlots() {
    draft.slots.clear();
    saveProgress();
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
    isHost = host;
    if (host) inviteCode = meeting['invite_code']?.toString();
    _applyMeeting(meeting);
    saveProgress();
  }

  void _applyMeeting(Map<String, dynamic> meeting) {
    _remoteMeeting = meeting;
    serverStatus = meeting['status']?.toString();
    revision = (meeting['revision'] as num?)?.toInt() ?? revision;
    final confirmedPlace = meeting['confirmed_place'];
    confirmedPlaceId = confirmedPlace is Map
        ? confirmedPlace['id']?.toString()
        : null;
    final expected =
        (meeting['expected_member_count'] as num?)?.toInt() ?? groupSize;
    groupSize = expected;
    group = MeetingGroup(
      id: meeting['id']?.toString(),
      name: meeting['title']?.toString() ?? groupName,
      size: expected,
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

  Future<void> retryRecommendation() async {
    if (meetingId == null || accessToken == null) return;
    await _run(() async {
      final meeting = await api.retryRecommendation(
        meetingId: meetingId!,
        accessToken: accessToken!,
      );
      _applyMeeting(meeting);
      _routeForStatus();
    });
  }

  Future<void> confirmPlace(String placeId) async {
    if (!isHost ||
        meetingId == null ||
        accessToken == null ||
        placeId.isEmpty) {
      return;
    }
    await _run(() async {
      final meeting = await api.confirmPlace(
        meetingId: meetingId!,
        accessToken: accessToken!,
        placeId: placeId,
        revision: revision,
      );
      _applyMeeting(meeting);
      go(MeetingStep.result);
    });
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
    } catch (exception, stackTrace) {
      debugPrint('MeetFlow request failed: $exception');
      debugPrintStack(stackTrace: stackTrace);
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
