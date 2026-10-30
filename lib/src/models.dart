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
  const MeetingGroup({required this.name, required this.size, this.id});
  final String name;
  final int size;
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
    this.lat,
    this.lng,
  });

  final String id;
  final String name;
  final int score;
  final List<String> reasons;
  final List<String> warnings;
  final List<String> travel;
  final String category;
  final String? url;
  final double? lat;
  final double? lng;

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
    List<String> reasonItems(Object? value) => strings(
      value,
    ).expand(_splitReasonText).where((item) => item.isNotEmpty).toList();
    final matched = reasonItems(json['matched']);
    final reason = reasonItems([
      if (json['reason'] != null) json['reason'].toString(),
    ]);
    final travelSummary = json['travel_summary'];
    final travelReasons = <String>[];
    if (travelSummary is Map) {
      final average = travelSummary['average_minutes'];
      final maximum = travelSummary['maximum_minutes'];
      if (average is num) {
        travelReasons.add('평균 이동시간은 ${_minutes(average)}이에요.');
      }
      if (maximum is num) {
        travelReasons.add('가장 먼 참여자도 ${_minutes(maximum)} 안에 도착해요.');
      }
    }
    final reasons = <String>{...matched, ...reason, ...travelReasons}.toList();
    return PlaceRecommendation(
      id: place['id']?.toString() ?? json['place_id']?.toString() ?? '',
      name: place['name']?.toString() ?? '추천 장소',
      category:
          place['category']?.toString() ??
          place['road_address']?.toString() ??
          place['address']?.toString() ??
          '추천 장소',
      score: ((json['score'] as num?) ?? 0).round(),
      reasons: reasons.isEmpty
          ? const ['그룹의 이동 편의와 선호 조건을 종합해 추천했어요.']
          : reasons.take(4).toList(),
      warnings: strings(json['warnings']),
      travel: travel,
      url: place['url']?.toString() ?? place['map_url']?.toString(),
      lat: (place['lat'] as num?)?.toDouble(),
      lng: (place['lng'] as num?)?.toDouble(),
    );
  }

  static List<String> _splitReasonText(String text) {
    final normalized = text.replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return const [];
    final parts = <String>[];
    var start = 0;
    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      final isLineBreak = char == '\n' || char == '•';
      final isSentenceEnd =
          (char == '.' || char == '!' || char == '?') &&
          (i + 1 == normalized.length || normalized[i + 1].trim().isEmpty);
      if (!isLineBreak && !isSentenceEnd) continue;
      final end = isSentenceEnd ? i + 1 : i;
      final part = normalized.substring(start, end).trim();
      if (part.isNotEmpty) parts.add(part);
      start = i + 1;
    }
    final tail = normalized.substring(start).trim();
    if (tail.isNotEmpty) parts.add(tail);
    return parts;
  }

  static String _minutes(num value) {
    final number = value.toDouble();
    final text = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
    return '$text분';
  }
}

List<String> displayRecommendationReasons(
  PlaceRecommendation recommendation,
  Iterable<String> preferences,
) {
  bool isTravel(String value) {
    final text = value.replaceAll(' ', '');
    return [
      '이동시간',
      '이동거리',
      '도착',
      '참여자',
      '가까운',
      '가까워',
      '직선거리',
    ].any(text.contains);
  }

  bool isTechnical(String value) {
    final text = value.replaceAll(' ', '');
    return [
      '2순위대비',
      '기여분',
      '총점차이',
      '반올림전',
      '추천정책으로계산',
      '그룹의이동편의와선호조건을종합',
    ].any(text.contains);
  }

  String? firstValue(Iterable<String> values) {
    for (final value in values) {
      return value;
    }
    return null;
  }

  final supplied = recommendation.reasons
      .map((reason) => reason.trim())
      .where((reason) => reason.isNotEmpty)
      .toList();
  final nonTravel = supplied
      .where((reason) => !isTravel(reason) && !isTechnical(reason))
      .toList();
  final travel = supplied.where(isTravel).toList();
  final preference = firstValue(
    preferences
        .map((value) => value.trim())
        .where(
          (value) =>
              value.isNotEmpty && !isTravel(value) && !isTechnical(value),
        ),
  );
  final categories = recommendation.category
      .split('>')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  final category = categories.isEmpty ? null : categories.last;

  final result = <String>[
    if (nonTravel.isNotEmpty)
      nonTravel.first
    else if (preference != null)
      '$preference 조건을 고려한 장소예요.'
    else
      '${category ?? '모임'} 유형으로 모임 목적에 잘 맞는 장소예요.',
    if (travel.isNotEmpty)
      travel.first
    else if (nonTravel.length > 1)
      nonTravel[1]
    else
      '그룹의 전체 조건을 종합해 선정했어요.',
  ];
  return result.toSet().take(2).toList();
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
