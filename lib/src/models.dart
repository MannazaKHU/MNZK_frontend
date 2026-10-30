import 'dart:math' as math;

const firstSlot = 12; // 06:00, 30분 단위
const lastSlot = 48; // 24:00 (exclusive)
const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
String dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String shortDate(DateTime date) => '${date.month}/${date.day}';
String dateLabel(DateTime date) =>
    '${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
String slotLabel(int slot) =>
    '${(slot ~/ 2).toString().padLeft(2, '0')}:${slot.isOdd ? '30' : '00'}';
String durationLabel(int slots) => slots.isEven
    ? '${slots ~/ 2}시간'
    : slots == 1
    ? '30분'
    : '${slots ~/ 2}시간 30분';

class SlotRange {
  const SlotRange(this.start, this.end);
  final int start;
  final int end;
  int get length => end - start;
  String get label => '${slotLabel(start)}–${slotLabel(end)}';
}

List<SlotRange> consecutiveRanges(Iterable<int> slots) {
  final sorted = slots.toSet().toList()..sort();
  final ranges = <SlotRange>[];
  for (final slot in sorted) {
    if (ranges.isNotEmpty && ranges.last.end == slot) {
      ranges[ranges.length - 1] = SlotRange(ranges.last.start, slot + 1);
    } else {
      ranges.add(SlotRange(slot, slot + 1));
    }
  }
  return ranges;
}

class ScheduleDraft {
  String name = '';
  final Set<DateTime> dates = {};
  final Map<String, Set<int>> slots = {};
  String place = '';
  String good = '';
  String bad = '';

  List<DateTime> get sortedDates => dates.toList()..sort();
  bool get hasTime => slots.values.any((s) => s.isNotEmpty);
  Set<int> slotsOn(DateTime date) => slots[dateKey(date)] ?? <int>{};
  String rangesOn(DateTime date) =>
      consecutiveRanges(slotsOn(date)).map((r) => r.label).join(', ');

  void toggleDate(DateTime date) {
    final key = dateOnly(date);
    if (!dates.add(key)) {
      dates.remove(key);
      slots.remove(dateKey(key));
    }
  }

  Map<String, Object> toJson() => {
    'name': name.trim(),
    'dates': sortedDates.map(dateKey).toList(),
    'slots': slots.map((key, value) => MapEntry(key, value.toList()..sort())),
    'place': place.trim(),
    'good': good.trim(),
    'bad': bad.trim(),
  };
}

class MeetingGroup {
  const MeetingGroup({
    required this.name,
    required this.size,
    required this.code,
    this.id,
  });
  final String name;
  final int size;
  final String code;
  final String? id;
}

class PlaceRecommendation {
  const PlaceRecommendation({
    required this.id,
    required this.name,
    required this.score,
    required this.reasons,
    required this.warnings,
    required this.travel,
    this.category = '추천 장소',
    this.url,
  });

  final String id;
  final String name;
  final int score;
  final List<String> reasons;
  final List<String> warnings;
  final List<String> travel;
  final String category;
  final String? url;

  factory PlaceRecommendation.fromJson(Map<String, dynamic> json) {
    final place = json['place'] is Map
        ? Map<String, dynamic>.from(json['place'] as Map)
        : <String, dynamic>{};
    List<String> strings(Object? value) => value is List
        ? value
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList()
        : const [];
    final travelText = strings(json['travel_text']);
    final travel = travelText.where((item) => item.trim().isNotEmpty).toList();
    return PlaceRecommendation(
      id: place['id']?.toString() ?? json['place_id']?.toString() ?? '',
      name: place['name']?.toString() ?? '추천 장소',
      category:
          place['category']?.toString() ??
          place['road_address']?.toString() ??
          place['address']?.toString() ??
          '추천 장소',
      score: ((json['score'] as num?) ?? 0).round(),
      reasons: strings(json['matched']).isNotEmpty
          ? strings(json['matched'])
          : [if (json['reason'] != null) json['reason'].toString()],
      warnings: strings(json['warnings']),
      travel: travel,
      url: place['url']?.toString() ?? place['map_url']?.toString(),
    );
  }
}

class Member {
  Member({required this.name, this.isMe = false, this.isExample = false});
  final String name;
  final bool isMe;
  final bool isExample;
  bool submitted = false;
  Map<String, Set<int>> slots = {};
  String place = '';
  String good = '';
  String bad = '';
}

class Candidate {
  const Candidate(this.date, this.range, this.count);
  final DateTime date;
  final SlotRange range;
  final int count;
}

/// 화면에는 인원 수만 전달하고, 이름과 개인 시간표의 관계는 표시하지 않는다.
class MeetingResult {
  MeetingResult(List<Member> members) {
    final submitted = members.where((m) => m.submitted).toList();
    for (final member in submitted) {
      for (final entry in member.slots.entries) {
        final column = counts.putIfAbsent(entry.key, () => {});
        for (final slot in entry.value) {
          column[slot] = (column[slot] ?? 0) + 1;
          maximum = math.max(maximum, column[slot]!);
        }
      }
    }
    dates = counts.keys.map(DateTime.parse).toList()..sort();
    if (maximum == 0) return;
    for (final date in dates) {
      final best = counts[dateKey(date)]!.entries
          .where((e) => e.value == maximum)
          .map((e) => e.key);
      candidates.addAll(
        consecutiveRanges(best).map((r) => Candidate(date, r, maximum)),
      );
    }
    candidates.sort((a, b) {
      final byLength = b.range.length.compareTo(a.range.length);
      if (byLength != 0) return byLength;
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.range.start.compareTo(b.range.start);
    });
  }

  final Map<String, Map<int, int>> counts = {};
  List<DateTime> dates = [];
  int maximum = 0;
  final List<Candidate> candidates = [];
  int countAt(DateTime date, int slot) => counts[dateKey(date)]?[slot] ?? 0;
}
