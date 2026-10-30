import 'package:flutter_test/flutter_test.dart';
import 'package:mannajaku/src/meeting_controller.dart';
import 'package:mannajaku/src/models.dart';

void main() {
  test('그룹 이름 검증과 인원 범위를 적용한다', () {
    final c = MeetingController();
    addTearDown(c.dispose);
    c.startCreate();
    c.createGroup();
    expect(c.error, isNotNull);
    expect(c.step, MeetingStep.create);
    c.changeSize(-20);
    expect(c.groupSize, 2);
    c.changeSize(20);
    expect(c.groupSize, 12);
    c.groupName = '우리 스터디';
    c.createGroup();
    expect(c.group!.name, '우리 스터디');
    expect(c.step, MeetingStep.code);
  });

  test('날짜·시간 없이 넘어가지 않고, 날짜 해제 시 해당 시간도 지운다', () {
    final c = MeetingController(today: DateTime(2026, 10, 29));
    addTearDown(c.dispose);
    c.go(MeetingStep.date);
    c.next();
    expect(c.step, MeetingStep.date);
    final date = DateTime(2026, 10, 30);
    c.toggleDate(date);
    c.next();
    expect(c.step, MeetingStep.time);
    c.next();
    expect(c.step, MeetingStep.time);
    c.setSlots({
      dateKey(date): {36, 37},
    });
    c.next();
    expect(c.step, MeetingStep.place);
    c.toggleDate(date);
    expect(c.draft.hasTime, isFalse);
    expect(c.draft.slots, isEmpty);
    c.moveMonth(3);
    expect(c.viewMonth, DateTime(2027, 1));
  });

  test('연속 구간과 자정 경계를 올바르게 표현한다', () {
    final ranges = consecutiveRanges([47, 38, 36, 37, 36]);
    expect(ranges.map((r) => r.label), ['18:00–19:30', '23:30–24:00']);
    expect(durationLabel(3), '1시간 30분');
    expect(durationLabel(1), '30분');
  });

  test('최대 인원 구간을 긴 순서와 날짜 순서로 추천하고 미제출은 제외한다', () {
    const d1 = '2026-10-30';
    const d2 = '2026-10-31';
    final a = Member(name: '가')
      ..submitted = true
      ..slots = {
        d1: {36, 37, 38, 42},
        d2: {30, 31},
      };
    final b = Member(name: '나')
      ..submitted = true
      ..slots = {
        d1: {36, 37, 38, 42},
        d2: {30, 31, 32},
      };
    final pending = Member(name: '대기')
      ..slots = {
        d1: {36, 37, 38},
      };
    final result = MeetingResult([a, b, pending]);
    expect(result.maximum, 2);
    expect(result.candidates.first.range.label, '18:00–19:30');
    expect(result.candidates[1].date, DateTime(2026, 10, 31));
    expect(result.candidates.last.range.label, '21:00–21:30');
    expect(result.countAt(DateTime(2026, 10, 31), 32), 1);
    expect(MeetingResult([]).candidates, isEmpty);
  });
}
