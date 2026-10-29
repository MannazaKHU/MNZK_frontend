import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
    MeetingStep.code: '코드 공유',
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

/// 프론트엔드 체험용 상태. 실제 API 연동 지점은 createGroup, joinGroup, submit.
/// 모든 데이터는 메모리에만 보관하며 다른 기기와 동기화하지 않는다.
class MeetingController extends ChangeNotifier {
  MeetingController({DateTime? today})
    : viewMonth = DateTime(
        (today ?? DateTime.now()).year,
        (today ?? DateTime.now()).month,
      );

  MeetingStep? step;
  ScheduleDraft draft = ScheduleDraft();
  MeetingGroup? group;
  List<Member> members = [];
  DateTime viewMonth;
  int groupSize = 4;
  String groupName = '';
  String? error;
  bool showChoices = false;
  bool showCodeInput = false;
  bool isJoiner = false;
  final List<Timer> _timers = [];

  List<MeetingStep> get flow => MeetingStep.values
      .where((s) => !isJoiner || s.index >= MeetingStep.name.index)
      .toList();
  int get position => step == null ? 0 : flow.indexOf(step!);
  int get completedCount => members.where((m) => m.submitted).length;
  MeetingResult get result => MeetingResult(members);

  void home() {
    _cancelTimers();
    step = null;
    showChoices = false;
    showCodeInput = false;
    error = null;
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
    isJoiner = false;
    groupName = '';
    go(MeetingStep.create);
  }

  void changeSize(int delta) {
    groupSize = (groupSize + delta).clamp(2, 12);
    notifyListeners();
  }

  void createGroup() {
    if (groupName.trim().isEmpty) {
      error = '그룹 이름을 적어주세요.';
      notifyListeners();
      return;
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    group = MeetingGroup(name: groupName.trim(), size: groupSize, code: code);
    go(MeetingStep.code);
  }

  void joinGroup(String input) {
    final code = input.trim().toUpperCase();
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

  void next() {
    if (step == MeetingStep.name && draft.name.trim().isEmpty) {
      error = '이름을 적어주세요.';
      notifyListeners();
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
    draft.toggleDate(date);
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

  void submit() {
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
      _timers.add(
        Timer(Duration(milliseconds: 700 + i * 450), () {
          _fillExample(members[index], index);
          notifyListeners();
          if (completedCount == group!.size) {
            _timers.add(
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
    _cancelTimers();
    go(MeetingStep.date);
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
