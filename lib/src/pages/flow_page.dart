import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../meeting_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';
import '../widgets/date_calendar.dart';
import '../widgets/feature_sections.dart';
import '../widgets/invitation_scene.dart';
import '../widgets/time_grid.dart';

class FlowPage extends StatelessWidget {
  const FlowPage({super.key, required this.controller});
  final MeetingController controller;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        right: -80,
        top: -40,
        width: 620,
        height: 400,
        child: IgnorePointer(
          child: CustomPaint(painter: ArcPainter(JakuColors.of(context).arc)),
        ),
      ),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 88),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 880;
                final card = SurfaceCard(
                  padding: EdgeInsets.all(constraints.maxWidth < 560 ? 24 : 42),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (![
                        MeetingStep.code,
                        MeetingStep.wait,
                        MeetingStep.result,
                      ].contains(controller.step)) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: controller.back,
                            style: TextButton.styleFrom(
                              foregroundColor: JakuColors.of(context).body,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                            ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              '이전',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ..._content(context),
                      if (controller.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            controller.error!,
                            style: TextStyle(
                              color: JakuColors.of(context).sun,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StepList(controller: controller, horizontal: true),
                      const SizedBox(height: 24),
                      card,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _StepList(controller: controller),
                    ),
                    const SizedBox(width: 28),
                    Expanded(child: card),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ],
  );

  List<Widget> _content(BuildContext context) {
    final model = controller;
    final c = JakuColors.of(context);
    switch (model.step!) {
      case MeetingStep.create:
        return [
          const PanelHeading(
            eyebrow: '그룹 만들기',
            title: '함께할 ',
            highlight: '그룹',
            after: '을 만들어요',
            description: '그룹 이름과 인원 수를 정하면 참여 코드가 생겨요.',
          ),
          const SizedBox(height: 28),
          _FieldLabel('그룹 이름'),
          const SizedBox(height: 9),
          TextFormField(
            key: const ValueKey('group-name'),
            initialValue: model.groupName,
            maxLength: 30,
            decoration: const InputDecoration(hintText: 'ex) 인공지능학과 스터디'),
            onChanged: (value) => model.groupName = value,
            onFieldSubmitted: (_) => model.createGroup(),
          ),
          if (model.backendEnabled) ...[
            const SizedBox(height: 20),
            _FieldLabel('방장 이름'),
            const SizedBox(height: 9),
            TextFormField(
              key: const ValueKey('host-name'),
              initialValue: model.hostName,
              maxLength: 20,
              decoration: const InputDecoration(hintText: 'ex) 승주'),
              onChanged: (value) => model.hostName = value,
              onFieldSubmitted: (_) => model.createGroup(),
            ),
          ],
          const SizedBox(height: 28),
          _FieldLabel('인원 수'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoundButton(
                      icon: Icons.remove_rounded,
                      tooltip: '한 명 줄이기',
                      onPressed: model.groupSize > 2
                          ? () => model.changeSize(-1)
                          : null,
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${model.groupSize}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                    const Text('명'),
                    const SizedBox(width: 8),
                    RoundButton(
                      icon: Icons.add_rounded,
                      tooltip: '한 명 늘리기',
                      onPressed: model.groupSize < model.maxGroupSize
                          ? () => model.changeSize(1)
                          : null,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  model.groupSize,
                  (i) => Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? JakuColors.butter : JakuColors.green,
                      border: Border.all(
                        color: JakuColors.stickerInk,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '나를 포함한 인원이에요. 2명부터 ${model.maxGroupSize}명까지 정할 수 있어요.',
            style: TextStyle(fontSize: 12, color: c.body),
          ),
          const SizedBox(height: 28),
          PanelFooter(
            hint: '모든 인원이 입력을 마치면 결과가 나와요',
            button: JakuButton(
              '그룹 만들기',
              arrow: true,
              onPressed: model.isBusy ? null : model.createGroup,
            ),
          ),
        ];
      case MeetingStep.code:
        return [
          const PanelHeading(
            eyebrow: '그룹이 만들어졌어요',
            title: '',
            highlight: '초대 링크',
            after: '를 친구들에게 보내주세요',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              JakuTag(model.group!.name),
              JakuTag('${model.group!.size}명'),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: c.accent.withValues(alpha: .4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.min(
                      50.0,
                      (constraints.maxWidth - 30) / 6,
                    );
                    return Semantics(
                      label: '그룹 코드 ${model.group!.code}',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: model.group!.code
                            .split('')
                            .map(
                              (char) => Container(
                                width: width,
                                height: width * 1.24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.ink, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.ink,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  char,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: width * .6,
                                    fontWeight: FontWeight.w800,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                JakuButton(
                  model.backendEnabled ? '초대 링크 복사' : '코드 복사',
                  secondary: true,
                  small: true,
                  icon: Icons.copy_rounded,
                  onPressed: () => _copyCode(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          InfoBox(
            model.backendEnabled
                ? '친구가 초대 링크를 열면 같은 그룹에 참여해요. 링크에는 모임 ID와 일회성 초대 정보가 포함돼요.'
                : '친구들이 첫 화면의 ‘그룹코드 입력’에 이 코드를 넣으면 같은 그룹에 참여해요.',
          ),
          const SizedBox(height: 28),
          PanelFooter(
            hint: '오른쪽 위에서도 코드를 복사할 수 있어요',
            button: JakuButton(
              '내 일정 입력하기',
              arrow: true,
              onPressed: model.isBusy ? null : model.next,
            ),
          ),
        ];
      case MeetingStep.name:
        return [
          PanelHeading(
            eyebrow: '${model.group!.name} · ${model.group!.size}명 그룹',
            title: '그룹에서 쓸 ',
            highlight: '이름',
            after: '을 알려주세요',
            description: '그룹원들에게 이 이름으로 보여요.',
          ),
          const SizedBox(height: 28),
          TextFormField(
            key: const ValueKey('my-name'),
            initialValue: model.draft.name,
            maxLength: 12,
            decoration: const InputDecoration(
              hintText: 'ex) 지윤',
              semanticCounterText: '이름',
            ),
            onChanged: (value) => model.draft.name = value,
            onFieldSubmitted: (_) => model.next(),
          ),
          const SizedBox(height: 28),
          PanelFooter(
            hint: 'Enter를 눌러도 다음으로 넘어가요',
            button: JakuButton(
              '다음',
              arrow: true,
              onPressed: model.isBusy ? null : model.next,
            ),
          ),
        ];
      case MeetingStep.date:
        return [
          const PanelHeading(
            eyebrow: 'Step 1 · 모두가 만족하는 일정을 정해볼게요',
            title: '원하는 ',
            highlight: '날짜',
            after: '를 선택해주세요',
            description: '가능한 날을 여러 개 골라도 돼요.',
          ),
          const SizedBox(height: 28),
          DateCalendar(controller: model),
          const SizedBox(height: 24),
          if (model.draft.dates.isNotEmpty) ...[
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: model.draft.sortedDates
                  .map(
                    (date) => InputChip(
                      label: Text(
                        shortDate(date),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => model.toggleDate(date),
                      deleteButtonTooltipMessage: '${dateLabel(date)} 선택 해제',
                      backgroundColor: c.soft,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      deleteIcon: const Icon(Icons.close_rounded, size: 15),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
          ],
          PanelFooter(
            hint: model.draft.dates.isEmpty
                ? '선택한 날짜 없음'
                : '${model.draft.dates.length}개의 날짜를 선택했어요',
            button: JakuButton(
              '다음',
              arrow: true,
              onPressed: model.draft.dates.isEmpty ? null : model.next,
            ),
          ),
        ];
      case MeetingStep.time:
        return [
          const PanelHeading(
            eyebrow: 'Step 1 · 모두가 만족하는 일정을 정해볼게요',
            title: '가능한 ',
            highlight: '시간',
            after: '을 칠해주세요',
            description: '드래그해서 칸을 칠하고, 칠한 칸에서 다시 드래그하면 지워져요.',
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 16,
                height: 12,
                decoration: BoxDecoration(
                  color: JakuColors.green,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: JakuColors.stickerInk, width: 1.5),
                ),
              ),
              const SizedBox(width: 7),
              const Text('내가 가능한 시간', style: TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: model.clearSlots,
                child: Text(
                  '모두 지우기',
                  style: TextStyle(
                    color: c.body,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectionContainer.disabled(
            child: TimeGrid(
              dates: model.draft.sortedDates,
              slots: model.draft.slots,
              onChanged: model.setSlots,
            ),
          ),
          const SizedBox(height: 22),
          const InfoBox(
            '내가 칠한 시간은 다른 그룹원에게 보이지 않아요. 결과에는 모두의 시간을 합친 인원 수만 나와요.',
            icon: Icons.lock_outline_rounded,
            private: true,
          ),
          if (model.draft.hasTime) ...[
            const SizedBox(height: 18),
            for (final date in model.draft.sortedDates.where(
              (d) => model.draft.slotsOn(d).isNotEmpty,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${dateLabel(date)}  ',
                        style: TextStyle(
                          color: c.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: model.draft.rangesOn(date)),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
          const SizedBox(height: 24),
          PanelFooter(
            hint: model.draft.hasTime ? '한 칸은 30분이에요' : '가능한 시간을 한 칸 이상 칠해주세요',
            button: JakuButton(
              '다음',
              arrow: true,
              onPressed: model.draft.hasTime ? model.next : null,
            ),
          ),
        ];
      case MeetingStep.place:
      case MeetingStep.good:
      case MeetingStep.bad:
        final index = model.step!.index - MeetingStep.place.index;
        final labels = ['START', 'GOOD', 'BAD'];
        final titles = ['여기서 출발해요!', '이런 약속 원해요!', '이런 약속 싫어요.'];
        final descriptions = [
          '출발하는 장소를 작성해주세요.',
          '만남에서 선호하는 것들을 작성해주세요.',
          '만남에서 피하고 싶은 것들을 작성해주세요.',
        ];
        final placeholders = [
          'ex) 경희대학교 국제캠퍼스',
          'ex) 이동시간이 최소화되었으면 좋겠다',
          'ex) 시끄러운 곳은 피하고 싶다',
        ];
        return [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: i == index ? c.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: i < index ? c.strong : c.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          PanelHeading(
            eyebrow: 'Step 2 · 장소와 취향',
            title: titles[index],
            description: descriptions[index],
          ),
          const SizedBox(height: 28),
          TextFormField(
            key: ValueKey('preference-$index'),
            initialValue: [
              model.draft.place,
              model.draft.good,
              model.draft.bad,
            ][index],
            maxLength: 60,
            decoration: InputDecoration(hintText: placeholders[index]),
            onChanged: (value) {
              switch (index) {
                case 0:
                  model.draft.place = value;
                case 1:
                  model.draft.good = value;
                case 2:
                  model.draft.bad = value;
              }
            },
            onFieldSubmitted: (_) => model.next(),
          ),
          const SizedBox(height: 28),
          PanelFooter(
            hint: 'Enter를 눌러도 다음으로 넘어가요',
            button: JakuButton('다음', arrow: true, onPressed: model.next),
          ),
        ];
      case MeetingStep.review:
        return [
          const PanelHeading(
            eyebrow: '입력 확인',
            title: '이대로 ',
            highlight: '제출',
            after: '할까요?',
            description: '제출한 뒤에도 결과가 나오기 전까지는 고칠 수 있어요.',
          ),
          const SizedBox(height: 28),
          _Summary(draft: model.draft),
          const SizedBox(height: 28),
          PanelFooter(
            button: JakuButton(
              '제출하기',
              arrow: true,
              onPressed: model.isBusy ? null : model.submit,
            ),
          ),
        ];
      case MeetingStep.wait:
        return [
          _WaitPanel(controller: model, onCopy: () => _copyCode(context)),
        ];
      case MeetingStep.result:
        return [_ResultPanel(controller: model)];
    }
  }

  Future<void> _copyCode(BuildContext context) async {
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: JakuColors.of(context).ink,
    ),
  );
}

class _StepList extends StatelessWidget {
  const _StepList({required this.controller, this.horizontal = false});
  final MeetingController controller;
  final bool horizontal;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final items = <Widget>[];
    final headings = {
      MeetingStep.create: '그룹',
      MeetingStep.name: controller.isJoiner ? '그룹' : null,
      MeetingStep.date: 'STEP 1 · 일정',
      MeetingStep.place: 'STEP 2 · 장소와 취향',
      MeetingStep.review: '마무리',
    };
    for (var i = 0; i < controller.flow.length; i++) {
      final step = controller.flow[i];
      final current = controller.step == step;
      final done = i < controller.position;
      if (!horizontal && headings[step] != null) {
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
            child: Text(
              headings[step]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: c.body,
              ),
            ),
          ),
        );
      }
      items.add(
        Semantics(
          label:
              '${i + 1}단계 ${step.label}${current
                  ? ', 현재 단계'
                  : done
                  ? ', 완료'
                  : ''}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: current ? c.soft : Colors.transparent,
              borderRadius: BorderRadius.circular(horizontal ? 99 : 14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: current
                        ? JakuColors.green
                        : done
                        ? c.soft
                        : Colors.transparent,
                    border: Border.all(
                      color: current
                          ? JakuColors.stickerInk
                          : done
                          ? Colors.transparent
                          : c.line,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded, size: 15, color: c.strong)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: current ? JakuColors.stickerInk : c.body,
                          ),
                        ),
                ),
                if (!horizontal || current) ...[
                  const SizedBox(width: 12),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                      color: current ? c.ink : c.body,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    final content = horizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: items),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: controller.position / (controller.flow.length - 1),
                  minHeight: 4,
                  color: JakuColors.green,
                  backgroundColor: c.panel,
                ),
              ),
              const SizedBox(height: 4),
              ...items,
            ],
          );
    return SurfaceCard(
      padding: EdgeInsets.all(horizontal ? 10 : 22),
      radius: horizontal ? 99 : 32,
      child: content,
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.draft});
  final ScheduleDraft draft;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final rows = [
      ('이름', draft.name.trim()),
      ('날짜', draft.sortedDates.map(dateLabel).join(', ')),
      (
        '시간',
        draft.sortedDates
            .where((d) => draft.slotsOn(d).isNotEmpty)
            .map((d) => '${shortDate(d)} ${draft.rangesOn(d)}')
            .join('\n'),
      ),
      ('출발지', draft.place.trim()),
      ('원해요', draft.good.trim()),
      ('싫어요', draft.bad.trim()),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.line, width: 1.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: List.generate(
            rows.length,
            (index) => Container(
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : Border(top: BorderSide(color: c.line)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 17,
                      ),
                      color: c.panel,
                      child: Text(
                        rows[index].$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.strong,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 17,
                        ),
                        child: Text(
                          rows[index].$2.isEmpty ? '—' : rows[index].$2,
                          style: TextStyle(fontSize: 14, color: c.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitPanel extends StatelessWidget {
  const _WaitPanel({required this.controller, required this.onCopy});
  final MeetingController controller;
  final VoidCallback onCopy;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final done = controller.completedCount;
    final total = controller.group!.size;
    final gathering = done == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 138,
                  height: 138,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.accent.withValues(alpha: .35),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: JakuColors.green,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: JakuColors.stickerInk, width: 3),
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    color: JakuColors.stickerInk,
                    size: 40,
                  ),
                ),
                for (var i = 0; i < math.min(total, 6); i++)
                  Positioned(
                    left:
                        60 +
                        66 * math.cos(i * 2 * math.pi / math.min(total, 6)),
                    top:
                        60 +
                        66 * math.sin(i * 2 * math.pi / math.min(total, 6)),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: JakuColors.avatars[i % 5],
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: JakuColors.stickerInk,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          gathering ? '그룹원들의 의견을 모으고 있어요…' : '아직 다른 그룹원을 기다리고 있어요…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: MediaQuery.sizeOf(context).width < 640 ? 25 : 32,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          gathering
              ? '모든 입력이 모였어요. 잠시 후 결과를 보여드릴게요.'
              : controller.backendEnabled
              ? '다른 그룹원이 초대 링크로 참여해 입력을 마칠 때까지 기다려주세요.'
              : '체험을 위해 예시 그룹원의 일정을 채우고 있어요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: c.body),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: done / total),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 12,
              color: JakuColors.green,
              backgroundColor: c.panel,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$done / $total명 입력 완료',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 340
                ? 1
                : constraints.maxWidth < 540
                ? 2
                : 3;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(controller.members.length, (i) {
                final member = controller.members[i];
                return Container(
                  width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: member.submitted
                        ? c.soft.withValues(alpha: .45)
                        : c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: member.submitted
                          ? c.accent.withValues(alpha: .4)
                          : c.line,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: JakuColors.avatars[i % 5],
                        child: Text(
                          member.name.substring(0, 1),
                          style: const TextStyle(
                            color: JakuColors.stickerInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${member.name}${member.isMe
                                  ? ' (나)'
                                  : member.isExample
                                  ? ' · 예시'
                                  : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                            Text(
                              member.submitted ? '입력 완료' : '입력 중…',
                              style: TextStyle(
                                fontSize: 11,
                                color: member.submitted ? c.strong : c.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (controller.backendEnabled &&
                controller.serverStatus == 'failed')
              JakuButton(
                '추천 다시 시도',
                arrow: true,
                onPressed: controller.isBusy
                    ? null
                    : controller.retryRecommendation,
              ),
            if (!gathering || controller.serverStatus == 'schedule_conflict')
              JakuButton(
                '내 입력 고치기',
                secondary: true,
                onPressed: controller.editMine,
              ),
            JakuButton(
              controller.backendEnabled ? '초대 링크 복사' : '그룹 코드 복사',
              secondary: true,
              onPressed: onCopy,
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultPanel extends StatefulWidget {
  const _ResultPanel({required this.controller});
  final MeetingController controller;
  @override
  State<_ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<_ResultPanel> {
  String inspection = '칸을 누르면 몇 명이 가능한지 보여요. 개인별 일정은 표시하지 않아요.';

  Future<void> _copyResult(BuildContext context) async {
    final code = widget.controller.group!.code;
    final uri = Uri.base.replace(
      queryParameters: {
        ...Uri.base.queryParameters,
        'group': code,
        'view': 'result',
      },
    );
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (context.mounted) showToast(context, '결과 링크를 복사했어요.');
    } catch (_) {
      if (context.mounted) showToast(context, uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.controller;
    final c = JakuColors.of(context);
    final result = model.result;
    final size = model.group!.size;
    final description = result.maximum == size
        ? '$size명 모두 가능한 시간이 있어요.'
        : result.maximum > 0
        ? '가장 많이 겹치는 ${result.maximum}명의 시간을 골랐어요.'
        : '아직 겹치는 시간이 없어요.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelHeading(
          eyebrow:
              '${model.group!.name} · $size명 · ${model.backendEnabled ? '추천 결과' : '체험 결과'}',
          title: '우리의 ',
          highlight: '약속',
          after: '을 찾았어요',
          description: description,
          trailing: JakuButton(
            '결과 링크 복사',
            icon: Icons.link_rounded,
            accent: true,
            onPressed: () => _copyResult(context),
          ),
        ),
        const SizedBox(height: 28),
        _subheading('날짜 · 시간 순위', c),
        const SizedBox(height: 14),
        if (result.candidates.isEmpty) const InfoBox('겹치는 시간이 없어요.'),
        if (result.candidates.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final count = math.min(3, result.candidates.length);
              final stacked = constraints.maxWidth < 620;
              final cards = List.generate(
                count,
                (i) => _CandidateCard(
                  candidate: result.candidates[i],
                  rank: i + 1,
                  size: size,
                ),
              );
              if (stacked) {
                return Column(
                  children: [
                    for (final card in cards)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            },
          ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _subheading('장소 추천', c),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: JakuColors.butter,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: JakuColors.stickerInk, width: 1.5),
              ),
              child: Text(
                model.recommendations.isEmpty ? '예시 추천' : '서버 추천',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff3d3410),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          model.recommendations.isEmpty
              ? '장소 추천 결과가 없어 입력값을 바탕으로 구성한 프론트엔드 예시예요.'
              : '백엔드가 공통 일정, 출발지와 취향을 계산해 반환한 추천 결과예요.',
          style: TextStyle(fontSize: 12, height: 1.6, color: c.body),
        ),
        const SizedBox(height: 14),
        _PlaceRecommendations(
          members: model.members,
          recommendations: model.recommendations,
          canConfirm: model.backendEnabled && model.isHost,
          confirmedPlaceId: model.confirmedPlaceId,
          onConfirm: model.confirmPlace,
        ),
        const SizedBox(height: 30),
        _subheading('그룹 전체 시간표', c),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('적음', style: TextStyle(fontSize: 11, color: c.body)),
            const SizedBox(width: 8),
            Container(
              width: 80,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: [c.card, JakuColors.green]),
                border: Border.all(color: c.line),
              ),
            ),
            const SizedBox(width: 8),
            Text('많음', style: TextStyle(fontSize: 11, color: c.body)),
          ],
        ),
        const SizedBox(height: 12),
        SelectionContainer.disabled(
          child: TimeGrid(
            dates: result.dates,
            countAt: result.countAt,
            groupSize: size,
            onInspect: (date, slot, count) => setState(
              () => inspection =
                  '${dateLabel(date)} ${slotLabel(slot)}–${slotLabel(slot + 1)} · $count/$size명 가능',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(inspection, style: TextStyle(fontSize: 13, color: c.ink)),
        ),
        const SizedBox(height: 28),
        _subheading('모은 의견', c),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final blocks = [
              _opinion('출발지', model.members.map((m) => m.place), c),
              _opinion('이런 약속 원해요', model.members.map((m) => m.good), c),
              _opinion(
                '이런 약속 싫어요',
                model.members.map((m) => m.bad),
                c,
                negative: true,
              ),
            ];
            if (constraints.maxWidth < 580) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final block in blocks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: block,
                    ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < blocks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: blocks[i]),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: JakuButton('처음으로', secondary: true, onPressed: model.home),
        ),
      ],
    );
  }

  Widget _subheading(String text, JakuColors c) => Text(
    text,
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
  );
  Widget _opinion(
    String heading,
    Iterable<String> values,
    JakuColors c, {
    bool negative = false,
  }) {
    final items =
        values.map((s) => s.trim()).where((s) => s.isNotEmpty).toList()..sort();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: negative ? c.sun.withValues(alpha: .08) : c.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: negative ? c.sun : c.strong,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items.isEmpty ? ['—'] : items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '· $item',
                style: TextStyle(fontSize: 12, height: 1.7, color: c.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceRecommendations extends StatelessWidget {
  const _PlaceRecommendations({
    required this.members,
    this.recommendations = const [],
    this.canConfirm = false,
    this.confirmedPlaceId,
    this.onConfirm,
  });
  final List<Member> members;
  final List<PlaceRecommendation> recommendations;
  final bool canConfirm;
  final String? confirmedPlaceId;
  final ValueChanged<String>? onConfirm;

  @override
  Widget build(BuildContext context) {
    final preferred = members
        .map((member) => member.good.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(3)
        .toList();
    final avoided = members
        .map((member) => member.bad.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(2)
        .toList();
    final starts = members
        .map((member) => member.place.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
    final fallback = [
      _PlaceData(
        id: '',
        name: '초록 테이블 파스타',
        category: '이탈리안 · 중간 지점',
        score: 94,
        reasons: preferred.isEmpty ? ['조용한 분위기', '역에서 가까워요'] : preferred,
        warnings: avoided,
        travel: [
          for (var i = 0; i < starts.length; i++) '${starts[i]} ${15 + i * 3}분',
        ],
      ),
      _PlaceData(
        id: '',
        name: '모임하기 좋은 온기 카페',
        category: '카페 · 넓은 좌석',
        score: 89,
        reasons: ['대화하기 좋은 공간', '디저트가 있어요'],
        warnings: avoided.take(1).toList(),
        travel: [
          for (var i = 0; i < starts.length; i++) '${starts[i]} ${17 + i * 2}분',
        ],
      ),
      _PlaceData(
        id: '',
        name: '저녁식사 소담 키친',
        category: '한식 · 단체석',
        score: 86,
        reasons: ['여럿이 앉기 편해요', '중간 지점과 가까워요'],
        warnings: avoided.skip(1).toList(),
        travel: [
          for (var i = 0; i < starts.length; i++) '${starts[i]} ${19 + i * 2}분',
        ],
      ),
    ];
    final data = recommendations.isEmpty
        ? fallback
        : recommendations
              .map(
                (item) => _PlaceData(
                  id: item.id,
                  name: item.name,
                  category: item.category,
                  score: item.score,
                  reasons: item.reasons,
                  warnings: item.warnings,
                  travel: item.travel,
                  url: item.url,
                  lat: item.lat,
                  lng: item.lng,
                ),
              )
              .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              for (var i = 0; i < data.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PlaceCard(
                    data: data[i],
                    rank: i + 1,
                    canConfirm: canConfirm,
                    confirmed: confirmedPlaceId == data[i].id,
                    onConfirm: onConfirm,
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            _PlaceCard(
              data: data.first,
              rank: 1,
              featured: true,
              canConfirm: canConfirm,
              confirmed: confirmedPlaceId == data.first.id,
              onConfirm: onConfirm,
            ),
            const SizedBox(height: 14),
            if (data.length > 1)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PlaceCard(
                      data: data[1],
                      rank: 2,
                      canConfirm: canConfirm,
                      confirmed: confirmedPlaceId == data[1].id,
                      onConfirm: onConfirm,
                    ),
                  ),
                  if (data.length > 2) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: _PlaceCard(
                        data: data[2],
                        rank: 3,
                        canConfirm: canConfirm,
                        confirmed: confirmedPlaceId == data[2].id,
                        onConfirm: onConfirm,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _PlaceData {
  const _PlaceData({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
    required this.reasons,
    required this.warnings,
    required this.travel,
    this.url,
    this.lat,
    this.lng,
  });
  final String id;
  final String name;
  final String category;
  final int score;
  final List<String> reasons;
  final List<String> warnings;
  final List<String> travel;
  final String? url;
  final double? lat;
  final double? lng;
}

class _PlaceCard extends StatefulWidget {
  const _PlaceCard({
    required this.data,
    required this.rank,
    this.featured = false,
    this.canConfirm = false,
    this.confirmed = false,
    this.onConfirm,
  });
  final _PlaceData data;
  final int rank;
  final bool featured;
  final bool canConfirm;
  final bool confirmed;
  final ValueChanged<String>? onConfirm;
  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final map = Container(
      height: widget.featured ? 280 : 190,
      decoration: BoxDecoration(color: c.panel),
      child: Stack(
        children: [
          Positioned.fill(
            child: PlaceMap(
              latitude: widget.data.lat,
              longitude: widget.data.lng,
              label: widget.data.name,
              fallback: CustomPaint(painter: MiniMapPainter(c)),
            ),
          ),
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              size: 52,
              color: JakuColors.green,
              shadows: [Shadow(color: JakuColors.stickerInk, blurRadius: 2)],
            ),
          ),
          Positioned(left: 14, top: 14, child: _PlaceRank(rank: widget.rank)),
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.data.score}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: '점'),
                  ],
                ),
                style: TextStyle(fontSize: 11, color: c.background),
              ),
            ),
          ),
        ],
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.name,
            style: TextStyle(
              fontSize: widget.featured ? 22 : 18,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          Text(
            widget.data.category,
            style: TextStyle(fontSize: 12, color: c.body),
          ),
          const SizedBox(height: 15),
          Text(
            '추천 이유',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.body,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: widget.data.reasons.map(JakuTag.new).toList(),
          ),
          if (widget.data.travel.isNotEmpty) ...[
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.line),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.line),
              ),
              leading: const CircleAvatar(
                radius: 13,
                backgroundColor: JakuColors.green,
                child: Icon(
                  Icons.directions_rounded,
                  size: 14,
                  color: JakuColors.stickerInk,
                ),
              ),
              title: Text(
                '출발지별 예상 이동',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.data.travel.map(JakuTag.new).toList(),
                  ),
                ),
              ],
            ),
          ],
          if (widget.data.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: c.sun.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '피하고 싶은 조건 확인: ${widget.data.warnings.join(', ')}',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: c.sun,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: JakuButton(
              '지도에서 보기',
              secondary: true,
              icon: Icons.location_on_outlined,
              onPressed: () => _openMap(context),
            ),
          ),
          if (widget.canConfirm && widget.data.id.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: JakuButton(
                widget.confirmed ? '최종 장소로 확정됨' : '이 장소로 확정',
                accent: !widget.confirmed,
                secondary: widget.confirmed,
                icon: widget.confirmed
                    ? Icons.check_circle_outline_rounded
                    : Icons.done_rounded,
                onPressed: widget.confirmed
                    ? null
                    : () => widget.onConfirm?.call(widget.data.id),
              ),
            ),
          ],
        ],
      ),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedSlide(
        offset: hovered && !reduce ? const Offset(0, -.012) : Offset.zero,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: widget.rank == 1 ? c.ink : c.line,
              width: widget.rank == 1 ? 2 : 1.5,
            ),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: c.ink.withValues(alpha: .12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : widget.rank == 1
                ? [BoxShadow(color: c.ink, offset: const Offset(0, 5))]
                : [],
          ),
          child: widget.featured
              ? LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 700
                      ? Column(children: [map, body])
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 11, child: map),
                            Expanded(flex: 10, child: body),
                          ],
                        ),
                )
              : Column(children: [map, body]),
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context) async {
    final supplied = widget.data.url?.trim();
    final target = supplied != null && supplied.isNotEmpty
        ? supplied
        : 'https://map.naver.com/p/search/'
              '${Uri.encodeComponent(widget.data.name)}';
    final uri = Uri.tryParse(target);
    if (uri == null ||
        !uri.hasScheme ||
        !await launchUrl(uri, webOnlyWindowName: '_blank')) {
      if (context.mounted) showToast(context, '지도 링크를 열지 못했어요.');
    }
  }
}

class _PlaceRank extends StatelessWidget {
  const _PlaceRank({required this.rank});
  final int rank;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: [JakuColors.green, JakuColors.butter, JakuColors.peach][rank - 1],
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: JakuColors.stickerInk, width: 2),
    ),
    child: Text(
      '$rank',
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: JakuColors.stickerInk,
      ),
    ),
  );
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.rank,
    required this.size,
  });
  final Candidate candidate;
  final int rank;
  final int size;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: rank == 1 ? Color.lerp(c.card, JakuColors.green, .2) : c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rank == 1 ? c.ink : c.line,
          width: rank == 1 ? 2 : 1.5,
        ),
        boxShadow: rank == 1
            ? [BoxShadow(color: c.ink, offset: const Offset(0, 5))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _PlaceRank(rank: rank),
          ),
          Text(
            dateLabel(candidate.date),
            style: TextStyle(
              fontSize: rank == 1 ? 25 : 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: c.line),
          const SizedBox(height: 8),
          Text(
            candidate.range.label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${durationLabel(candidate.range.length)} 동안',
            style: TextStyle(fontSize: 12, color: c.body),
          ),
          const SizedBox(height: 14),
          JakuTag(
            candidate.count == size
                ? '$size명 모두 가능'
                : '${candidate.count}/$size명 가능',
          ),
        ],
      ),
    );
  }
}
