import 'package:flutter/material.dart';

import '../home_sections.dart';
import '../meeting_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/feature_sections.dart';
import '../widgets/invitation_scene.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.sectionKeys,
  });

  final MeetingController controller;
  final Map<HomeSection, GlobalKey> sectionKeys;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        key: widget.sectionKeys[HomeSection.intro],
        width: double.infinity,
        color: JakuColors.of(context).background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 88),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 880;
                  final copy = RiseIn(
                    child: _HeroCopy(controller: widget.controller),
                  );
                  final scene = const RiseIn(
                    delay: Duration(milliseconds: 170),
                    child: InvitationScene(),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [copy, const SizedBox(height: 42), scene],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 56),
                      Expanded(child: scene),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      FeatureSections(
        controller: widget.controller,
        sectionKeys: widget.sectionKeys,
      ),
    ],
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.controller});

  final MeetingController controller;

  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final titleStyle = TextStyle(
      fontSize: MediaQuery.sizeOf(context).width < 560 ? 40 : 56,
      height: 1.2,
      letterSpacing: -1.8,
      fontWeight: FontWeight.w700,
      color: c.ink,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('여러분을 위한', style: titleStyle),
        const SizedBox(height: 2),
        HighlightedText('맞춤형 약속', style: titleStyle),
        const SizedBox(height: 24),
        Text(
          '안녕하세요! 만나자쿠가 약속을 잡아줄게요. 그룹을 만들고 초대 링크를 나누면, 모두의 날짜와 시간, 출발지와 취향을 모아 약속을 찾아드려요.',
          style: TextStyle(fontSize: 17, height: 1.9, color: c.body),
        ),
        const SizedBox(height: 26),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: .94, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: !controller.showChoices
              ? JakuButton(
                  key: const ValueKey('direct'),
                  '직접 약속 잡기',
                  arrow: true,
                  onPressed: controller.choose,
                )
              : JakuButton(
                  key: const ValueKey('choice'),
                  '그룹 생성하기',
                  arrow: true,
                  onPressed: controller.startCreate,
                ),
        ),
        if (controller.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              controller.error!,
              style: TextStyle(fontSize: 13, color: c.sun),
            ),
          ),
      ],
    );
  }
}
