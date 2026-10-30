import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_sections.dart';
import 'meeting_controller.dart';
import 'models.dart';
import 'pages/flow_page.dart';
import 'pages/home_page.dart';
import 'theme.dart';
import 'widgets/common.dart';

class MannajakuApp extends StatelessWidget {
  const MannajakuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '만나자쿠 · 맞춤형 약속 도우미',
    debugShowCheckedModeBanner: false,
    theme: jakuTheme(Brightness.light),
    darkTheme: jakuTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    home: const MeetingPage(),
  );
}

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});
  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final controller = MeetingController();
  final scroll = ScrollController();
  final sectionKeys = {
    for (final section in HomeSection.values) section: GlobalKey(),
  };
  MeetingStep? lastStep;
  HomeSection activeSection = HomeSection.intro;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onStepChanged);
    scroll.addListener(_onScroll);
  }

  void _onStepChanged() {
    if (lastStep != controller.step) {
      lastStep = controller.step;
      if (scroll.hasClients) scroll.jumpTo(0);
    }
  }

  void _onScroll() {
    if (controller.step != null) return;
    var next = HomeSection.intro;
    for (final section in HomeSection.values) {
      final render = sectionKeys[section]?.currentContext?.findRenderObject();
      if (render is RenderBox && render.localToGlobal(Offset.zero).dy <= 180) {
        next = section;
      }
    }
    if (next != activeSection && mounted) setState(() => activeSection = next);
  }

  void _navigate(HomeSection section) {
    if (controller.step != null) controller.home();
    setState(() => activeSection = section);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = sectionKeys[section]?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(target)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  @override
  void dispose() {
    controller.removeListener(_onStepChanged);
    scroll.removeListener(_onScroll);
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final c = JakuColors.of(context);
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                controller: controller,
                activeSection: activeSection,
                onNavigate: _navigate,
              ),
              Expanded(
                child: ColoredBox(
                  color: controller.step == null ? c.background : c.panel,
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      controller: scroll,
                      child: Column(
                        children: [
                          if (controller.step != null &&
                              !controller.backendEnabled)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              color: JakuColors.butter,
                              child: const Text(
                                '체험 모드예요. 다른 그룹원은 예시이며, 새로고침하면 입력이 초기화돼요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: Color(0xff3d3410),
                                ),
                              ),
                            ),
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            layoutBuilder: (currentChild, previousChildren) =>
                                currentChild ?? const SizedBox.shrink(),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, .015),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: controller.step == null
                                ? HomePage(
                                    key: const ValueKey('home'),
                                    controller: controller,
                                    sectionKeys: sectionKeys,
                                  )
                                : FlowPage(
                                    key: ValueKey(controller.step),
                                    controller: controller,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.activeSection,
    required this.onNavigate,
  });
  final MeetingController controller;
  final HomeSection activeSection;
  final ValueChanged<HomeSection> onNavigate;

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: controller.invitationLink));
      if (context.mounted) {
        showToast(
          context,
          controller.backendEnabled ? '초대 링크를 복사했어요.' : '그룹 코드를 복사했어요.',
        );
      }
    } catch (_) {
      if (context.mounted) showToast(context, '코드를 길게 눌러 직접 복사해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final group = controller.group;
    final isHome = controller.step == null;
    final mobileHome = isHome && width <= 720;
    final logo = _AnimatedLogo(onTap: () => onNavigate(HomeSection.intro));
    final nav = _SectionNav(active: activeSection, onSelected: onNavigate);
    final badge = group != null && !isHome
        ? _GroupBadge(group: group, onCopy: () => _copy(context))
        : null;
    return Container(
      height: mobileHome ? 132 : 76,
      color: c.background,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: mobileHome
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: logo),
                    const SizedBox(height: 4),
                    nav,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    logo,
                    if (isHome) Flexible(child: nav) else const Spacer(),
                    ?badge,
                  ],
                ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final compact = MediaQuery.sizeOf(context).width < 340;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Semantics(
        button: true,
        label: '만나자쿠 홈',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: hovered && !reduce ? -.035 : 0,
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  child: AnimatedScale(
                    scale: hovered && !reduce ? 1.08 : 1,
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: compact ? 34 : 42,
                      height: compact ? 34 : 42,
                      decoration: BoxDecoration(
                        color: JakuColors.green,
                        border: Border.all(
                          color: JakuColors.stickerInk,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(compact ? 12 : 15),
                      ),
                      child: Center(
                        child: Wrap(
                          spacing: compact ? 4 : 5,
                          runSpacing: compact ? 4 : 5,
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: compact ? 6 : 8,
                              height: compact ? 6 : 8,
                              decoration: BoxDecoration(
                                color: JakuColors.stickerInk.withValues(
                                  alpha: i == 3 ? .45 : 1,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 9 : 14),
                Text(
                  '만나자쿠',
                  style: TextStyle(
                    fontSize: compact ? 22 : 28,
                    letterSpacing: -1.1,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionNav extends StatelessWidget {
  const _SectionNav({required this.active, required this.onSelected});
  final HomeSection active;
  final ValueChanged<HomeSection> onSelected;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.panel.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: HomeSection.values.map((section) {
            final selected = section == active;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: TextButton(
                onPressed: () => onSelected(section),
                style: TextButton.styleFrom(
                  foregroundColor: selected ? JakuColors.stickerInk : c.body,
                  backgroundColor: selected
                      ? JakuColors.green
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: StadiumBorder(
                    side: selected
                        ? const BorderSide(
                            color: JakuColors.stickerInk,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  elevation: selected ? 2 : 0,
                ),
                child: Text(
                  section.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.group, required this.onCopy});
  final MeetingGroup group;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: c.soft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MediaQuery.sizeOf(context).width > 550) ...[
              Flexible(
                child: Text(
                  group.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.strong, fontSize: 13),
                ),
              ),
              const SizedBox(width: 9),
            ],
            Tooltip(
              message: '초대 정보 복사',
              child: InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: JakuColors.green,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: JakuColors.stickerInk,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    group.code,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: JakuColors.stickerInk,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
