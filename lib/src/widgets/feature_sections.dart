import 'package:flutter/material.dart';

import '../home_sections.dart';
import '../meeting_controller.dart';
import '../theme.dart';
import 'common.dart';

class FeatureSections extends StatelessWidget {
  const FeatureSections({
    super.key,
    required this.controller,
    required this.sectionKeys,
  });

  final MeetingController controller;
  final Map<HomeSection, GlobalKey> sectionKeys;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _FeatureSection(
        sectionKey: sectionKeys[HomeSection.group]!,
        eyebrow: 'STEP 1 · 그룹 만들기',
        titleBefore: '그룹을 만들고 ',
        highlight: '초대 링크',
        titleAfter: '로 모여요',
        description: '그룹 이름과 인원 수만 정하면 초대 링크가 생겨요. 친구들은 링크를 열어 같은 그룹에 바로 참여해요.',
        points: const [
          '나를 포함해 2명부터 12명까지 정할 수 있어요',
          '버튼 한 번으로 초대 링크를 복사해 단톡방에 보내요',
          '정한 인원이 다 차면 더 들어올 수 없어요',
        ],
        visual: const _GroupMock(),
      ),
      _FeatureSection(
        sectionKey: sectionKeys[HomeSection.time]!,
        alternate: true,
        eyebrow: 'STEP 2 · 시간 맞추기',
        titleBefore: '가능한 ',
        highlight: '시간',
        titleAfter: '을 쓱 칠하면 끝',
        description:
            '달력에서 가능한 날을 고르고, 시간표 위를 드래그해 칠해요. 칠한 칸 위에서 다시 드래그하면 지워져요.',
        points: const [
          '가능한 날을 여러 개 골라도 돼요',
          '30분 단위로 원하는 만큼 칠해요',
          '내가 칠한 시간은 다른 그룹원에게 보이지 않아요',
        ],
        visual: const _TimeMock(),
      ),
      _FeatureSection(
        sectionKey: sectionKeys[HomeSection.preference]!,
        eyebrow: 'STEP 3 · 취향 모으기',
        titleBefore: '출발지와 ',
        highlight: '취향',
        titleAfter: '도 한 줄씩',
        description:
            '어디서 출발하는지, 어떤 약속이 좋은지, 무엇은 피하고 싶은지 한 줄씩 적어요. 모두 입력할 때까지 만나자쿠가 기다려요.',
        points: const [
          '길게 쓰지 않아도 한 줄이면 충분해요',
          '마지막 사람이 입력하면 자동으로 결과로 넘어가요',
          '누가 무엇을 썼는지는 공개되지 않아요',
        ],
        visual: const _PreferenceMock(),
      ),
      _FeatureSection(
        sectionKey: sectionKeys[HomeSection.result]!,
        alternate: true,
        eyebrow: 'STEP 4 · 장소 추천',
        titleBefore: '날짜 순위와 ',
        highlight: '장소 추천',
        titleAfter: '을 한 번에',
        description:
            '모두가 겹치는 시간을 날짜별로 1~3순위로 보여주고, 모두의 출발지 중간 지점을 기준으로 취향에 맞는 장소를 골라 추천해요.',
        points: const [
          '날짜마다 가장 좋은 시간 하나씩 골라 순위를 매겨요',
          '추천 이유와 이동 시간을 한눈에 볼 수 있어요',
          '지도에서 추천 위치를 바로 확인해요',
        ],
        visual: const _ResultMock(),
      ),
      _CallToAction(controller: controller),
    ],
  );
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({
    required this.sectionKey,
    required this.eyebrow,
    required this.titleBefore,
    required this.highlight,
    required this.titleAfter,
    required this.description,
    required this.points,
    required this.visual,
    this.alternate = false,
  });

  final GlobalKey sectionKey;
  final String eyebrow;
  final String titleBefore;
  final String highlight;
  final String titleAfter;
  final String description;
  final List<String> points;
  final Widget visual;
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      key: sectionKey,
      width: double.infinity,
      color: alternate ? c.panel : c.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 820;
              final headingStyle = TextStyle(
                fontSize: constraints.maxWidth < 520 ? 30 : 42,
                height: 1.25,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: c.ink,
              );
              final copy = RiseIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(eyebrow),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: titleBefore),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: HighlightedText(
                              highlight,
                              style: headingStyle,
                            ),
                          ),
                          TextSpan(text: titleAfter),
                        ],
                      ),
                      style: headingStyle,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.8,
                        color: c.body,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final point in points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: JakuColors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: JakuColors.stickerInk,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: JakuColors.stickerInk,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
              final mock = RiseIn(
                delay: const Duration(milliseconds: 130),
                child: _VisualStage(alternate: alternate, child: visual),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [copy, const SizedBox(height: 40), mock],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: alternate
                    ? [
                        Expanded(child: mock),
                        const SizedBox(width: 70),
                        Expanded(child: copy),
                      ]
                    : [
                        Expanded(child: copy),
                        const SizedBox(width: 70),
                        Expanded(child: mock),
                      ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VisualStage extends StatefulWidget {
  const _VisualStage({required this.child, required this.alternate});
  final Widget child;
  final bool alternate;

  @override
  State<_VisualStage> createState() => _VisualStageState();
}

class _VisualStageState extends State<_VisualStage> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: SizedBox(
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedRotation(
              turns: hovered && !reduce
                  ? 0
                  : widget.alternate
                  ? .008
                  : -.008,
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.alternate
                      ? c.card
                      : c.arc.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            AnimatedScale(
              scale: hovered && !reduce ? 1.015 : 1,
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      SurfaceCard(padding: const EdgeInsets.all(24), radius: 30, child: child);
}

class _GroupMock extends StatelessWidget {
  const _GroupMock();
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return _MockCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Wrap(
            spacing: 8,
            children: [JakuTag('인공지능학과 스터디'), JakuTag('5명')],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = ((constraints.maxWidth - 25) / 6).clamp(34.0, 48.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: 'MZ4K7Q'
                    .split('')
                    .map(
                      (char) => Container(
                        width: width,
                        height: width * 1.2,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.ink, width: 2),
                          boxShadow: [
                            BoxShadow(color: c.ink, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(
                          char,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: width * .55,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  children: List.generate(
                    5,
                    (i) => Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i == 0 ? JakuColors.butter : JakuColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: JakuColors.stickerInk,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              JakuButton(
                '초대 링크 복사',
                small: true,
                secondary: true,
                onPressed: () => showToast(context, '초대 링크를 복사했어요.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeMock extends StatelessWidget {
  const _TimeMock();
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return _MockCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Eyebrow('내 시간 칠하기'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.soft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 13, color: c.strong),
                    const SizedBox(width: 4),
                    Text(
                      '나만 보여요',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.strong,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Table(
              border: TableBorder.all(color: c.line),
              children: [
                TableRow(
                  children: ['', '11/8', '11/9', '11/10', '11/11']
                      .map(
                        (text) => SizedBox(
                          height: 35,
                          child: Center(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                for (var row = 0; row < 7; row++)
                  TableRow(
                    children: List.generate(5, (column) {
                      final on =
                          column > 0 &&
                          ((column <= 2 && row >= 1 && row <= 5) ||
                              (column >= 3 && row >= 3));
                      return Container(
                        height: 24,
                        color: on ? JakuColors.green : c.card,
                        alignment: Alignment.center,
                        child: column == 0 && row.isEven
                            ? Text(
                                '${17 + row ~/ 2}시',
                                style: TextStyle(fontSize: 9, color: c.body),
                              )
                            : null,
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceMock extends StatelessWidget {
  const _PreferenceMock();
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final rows = [
      ('START', '경희대학교 국제캠퍼스', false),
      ('GOOD', '이동시간이 짧았으면 좋겠다', false),
      ('BAD', '시끄러운 곳은 피하고 싶다', true),
    ];
    return _MockCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  border: Border.all(color: c.line, width: 1.5),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: row.$3
                            ? const Color(0xffffc9c2)
                            : JakuColors.green,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: JakuColors.stickerInk,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: JakuColors.stickerInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.$2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              value: .8,
              minHeight: 12,
              color: JakuColors.green,
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '4 / 5명 입력 완료',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMock extends StatelessWidget {
  const _ResultMock();
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return _MockCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in const [
            (1, '11월 8일 (일)', '18:00 – 21:00 · 5명 모두 가능'),
            (2, '11월 10일 (화)', '19:00 – 21:30 · 4/5명 가능'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.$1 == 1 ? c.soft : c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: item.$1 == 1 ? c.ink : c.line,
                    width: item.$1 == 1 ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _RankBadge(rank: item.$1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            item.$3,
                            style: TextStyle(fontSize: 10, color: c.body),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.line, width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: MiniMapPainter(c))),
                const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 42,
                    color: JakuColors.green,
                    shadows: [
                      Shadow(color: JakuColors.stickerInk, blurRadius: 2),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Text(
                    '초록 테이블 파스타',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: rank == 1 ? JakuColors.green : JakuColors.butter,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: JakuColors.stickerInk, width: 2),
    ),
    child: Text(
      '$rank',
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: JakuColors.stickerInk,
      ),
    ),
  );
}

class _CallToAction extends StatelessWidget {
  const _CallToAction({required this.controller});
  final MeetingController controller;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      color: c.background,
      padding: const EdgeInsets.fromLTRB(20, 72, 20, 92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Column(
              children: [
                Text(
                  '지금 바로 약속을 잡아볼까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: c.background,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '그룹을 만들고 친구들에게 초대 링크를 보내보세요. 나머지는 만나자쿠가 모아드릴게요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: c.background.withValues(alpha: .72),
                  ),
                ),
                const SizedBox(height: 24),
                JakuButton(
                  '그룹 생성하기',
                  arrow: true,
                  onPressed: controller.startCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  const MiniMapPainter(this.colors);
  final JakuColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..color = colors.line
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = colors.card
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paths = [
      Path()
        ..moveTo(-10, size.height * .72)
        ..quadraticBezierTo(
          size.width * .35,
          0,
          size.width + 10,
          size.height * .28,
        ),
      Path()
        ..moveTo(size.width * .15, -10)
        ..quadraticBezierTo(
          size.width * .65,
          size.height * .55,
          size.width * .8,
          size.height + 10,
        ),
    ];
    for (final path in paths) {
      canvas.drawPath(path, edge);
      canvas.drawPath(path, road);
    }
  }

  @override
  bool shouldRepaint(MiniMapPainter oldDelegate) =>
      oldDelegate.colors.dark != colors.dark;
}
