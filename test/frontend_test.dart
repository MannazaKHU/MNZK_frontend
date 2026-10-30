import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mannajaku/src/app.dart';
import 'package:mannajaku/src/meeting_controller.dart';
import 'package:mannajaku/src/models.dart';
import 'package:mannajaku/src/pages/flow_page.dart';
import 'package:mannajaku/src/theme.dart';
import 'package:mannajaku/src/widgets/time_grid.dart';
import 'package:mannajaku/src/widgets/common.dart';

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ElevatedButton, label).first;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('버튼은 hover에서 올라가고 눌렀을 때 작아진다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: jakuTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: JakuButton('움직임 확인', arrow: true, onPressed: () {}),
          ),
        ),
      ),
    );
    final target = find.byType(JakuButton);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 250));
    final hoveredSlides = tester
        .widgetList<AnimatedSlide>(
          find.descendant(of: target, matching: find.byType(AnimatedSlide)),
        )
        .toList();
    expect(hoveredSlides.any((slide) => slide.offset.dy < 0), isTrue);

    await mouse.down(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 250));
    final pressedScales = tester
        .widgetList<AnimatedScale>(
          find.descendant(of: target, matching: find.byType(AnimatedScale)),
        )
        .toList();
    expect(pressedScales.any((scale) => scale.scale < 1), isTrue);
    await mouse.up();
    await mouse.removePointer();
  });

  for (final width in [320.0, 360.0, 768.0, 1440.0]) {
    testWidgets('${width.toInt()}px에서 생성부터 결과까지 화면이 넘치지 않는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MannajakuApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapButton(tester, '직접 약속 잡기');
      await tapButton(tester, '그룹 생성하기');
      await tester.enterText(
        find.byKey(const ValueKey('group-name')),
        '우리 스터디',
      );
      await tapButton(tester, '그룹 만들기');
      expect(find.text('코드 복사'), findsOneWidget);
      await tapButton(tester, '내 일정 입력하기');
      await tester.enterText(find.byKey(const ValueKey('my-name')), '승주');
      await tapButton(tester, '다음');
      final controller = tester
          .widget<FlowPage>(find.byType(FlowPage))
          .controller;
      final date = dateOnly(DateTime.now());
      final day = find.byKey(ValueKey('date-${dateKey(date)}'));
      await tester.ensureVisible(day);
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(controller.draft.dates, contains(date));
      await tapButton(tester, '다음');
      expect(controller.step, MeetingStep.time);
      final first = find.byKey(ValueKey('slot-${dateKey(date)}-$firstSlot'));
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(controller.draft.hasTime, isTrue);
      await tapButton(tester, '다음');
      for (final entry in [(0, '강남역'), (1, '조용한 카페'), (2, '웨이팅')]) {
        await tester.enterText(
          find.byKey(ValueKey('preference-${entry.$1}')),
          entry.$2,
        );
        await tapButton(tester, '다음');
      }
      expect(controller.step, MeetingStep.review);
      expect(find.text('강남역'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '제출하기'));
      await tester.tap(find.widgetWithText(ElevatedButton, '제출하기'));
      await tester.pump();
      expect(controller.step, MeetingStep.wait);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(controller.step, MeetingStep.result);
      expect(find.text('날짜 · 시간 순위'), findsOneWidget);
      expect(find.text('모은 의견'), findsNothing);
      expect(find.text('장소 추천'), findsWidgets);
      expect(find.text('결과 링크 복사'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapButton(tester, '처음으로');
      expect(find.text('직접 약속 잡기'), findsOneWidget);
    });
  }

  testWidgets('시간표 드래그가 여러 날짜에 사각형으로 적용되고 다시 드래그하면 지워진다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dates = [DateTime(2026, 10, 30), DateTime(2026, 10, 31)];
    var slots = <String, Set<int>>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: jakuTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: StatefulBuilder(
                builder: (context, setState) => TimeGrid(
                  dates: dates,
                  slots: slots,
                  onChanged: (next) => setState(() => slots = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('slot-2026-10-30-12'));
    final last = find.byKey(const ValueKey('slot-2026-10-31-15'));
    for (final erase in [false, true]) {
      final gesture = await tester.startGesture(tester.getCenter(first));
      await tester.pump(const Duration(milliseconds: 120));
      await gesture.moveTo(tester.getCenter(last));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      for (final date in dates) {
        expect(
          slots[dateKey(date)],
          erase ? isEmpty : equals({12, 13, 14, 15}),
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('다크 테마와 코드 입력 오류를 표시한다', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const MannajakuApp());
    await tester.pumpAndSettle();
    await tapButton(tester, '직접 약속 잡기');
    await tapButton(tester, '그룹코드 입력');
    await tester.enterText(find.byType(TextField), '12');
    await tapButton(tester, '참여하기');
    expect(find.textContaining('그룹 코드는 영문과 숫자 6자리'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });
}
