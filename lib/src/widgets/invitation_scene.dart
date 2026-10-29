import 'package:flutter/material.dart';
import '../theme.dart';
import 'common.dart';

class InvitationScene extends StatelessWidget {
  const InvitationScene({super.key});
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 420;
          return SizedBox(
            height: constraints.maxWidth < 320
                ? 500
                : narrow
                ? 440
                : 500,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: ColoredBox(
                      color: c.panel,
                      child: CustomPaint(painter: ArcPainter(c.arc)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 42),
                  child: SurfaceCard(
                    radius: 30,
                    padding: EdgeInsets.all(narrow ? 20 : 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Eyebrow('이번 주 약속'),
                            SizedBox(
                              width: narrow ? 70 : 87,
                              height: 32,
                              child: Stack(
                                children: List.generate(
                                  narrow ? 3 : 4,
                                  (i) => Positioned(
                                    left: i * 19,
                                    child: Container(
                                      width: 31,
                                      height: 31,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: JakuColors.avatars[i],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: c.card,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: Text(
                                        ['지', '민', '수', '+2'][i],
                                        style: const TextStyle(
                                          color: JakuColors.stickerInk,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '금요일 저녁, 다 같이 만나요',
                          style: TextStyle(
                            fontSize: narrow ? 18 : 21,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final row in [
                          ('날짜', '10월 30일 (금)'),
                          ('시간', '18:30 – 21:00'),
                          ('출발지', '5곳 모음'),
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: c.line)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  row.$1,
                                  style: TextStyle(color: c.body, fontSize: 13),
                                ),
                                Text(
                                  row.$2,
                                  style: TextStyle(
                                    color: c.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        const Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            JakuTag('이동시간 짧게'),
                            JakuTag('조용한 곳'),
                            JakuTag('시끄러운 곳 X', negative: true),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                            value: 1,
                            minHeight: 9,
                            color: JakuColors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '5명 모두 가능한 시간이에요',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.strong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 12,
                  child: _Sticker(
                    Icons.calendar_month_rounded,
                    angle: -.2,
                    size: narrow ? 51 : 67,
                  ),
                ),
                Positioned(
                  top: 26,
                  right: 14,
                  child: _Sticker(
                    Icons.schedule_rounded,
                    angle: .15,
                    size: narrow ? 48 : 59,
                    circle: true,
                  ),
                ),
                Positioned(
                  bottom: 48,
                  right: 10,
                  child: _Sticker(
                    Icons.location_on_rounded,
                    angle: -.12,
                    size: narrow ? 52 : 67,
                  ),
                ),
                if (!narrow)
                  const Positioned(
                    left: -10,
                    top: 218,
                    child: _Sticker(
                      Icons.favorite_rounded,
                      angle: .2,
                      size: 54,
                      circle: true,
                      heart: true,
                    ),
                  ),
                Positioned(
                  left: 0,
                  bottom: narrow ? 5 : 25,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    padding: const EdgeInsets.fromLTRB(11, 10, 17, 10),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
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
                            size: 19,
                            color: JakuColors.stickerInk,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '참여인원 모두의 조건을 반영해요',
                            style: TextStyle(
                              fontSize: narrow ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker(
    this.icon, {
    this.angle = 0,
    this.size = 64,
    this.circle = false,
    this.heart = false,
  });
  final IconData icon;
  final double angle;
  final double size;
  final bool circle;
  final bool heart;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: heart ? JakuColors.butter : JakuColors.green,
        borderRadius: BorderRadius.circular(circle ? 99 : 18),
        border: Border.all(color: JakuColors.stickerInk, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .09),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * .57,
        color: heart ? const Color(0xffff8a7a) : JakuColors.stickerInk,
      ),
    ),
  );
}

class ArcPainter extends CustomPainter {
  const ArcPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 520, size.height / 480);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 56
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-40, 420)
        ..cubicTo(60, 120, 300, 60, 560, 150),
      paint,
    );
    paint
      ..strokeWidth = 40
      ..color = color.withValues(alpha: .7);
    canvas.drawPath(
      Path()
        ..moveTo(120, 520)
        ..cubicTo(180, 330, 360, 290, 560, 330),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArcPainter oldDelegate) => oldDelegate.color != color;
}
