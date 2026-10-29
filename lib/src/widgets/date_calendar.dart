import 'package:flutter/material.dart';
import '../meeting_controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class DateCalendar extends StatelessWidget {
  const DateCalendar({super.key, required this.controller});
  final MeetingController controller;
  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    final month = controller.viewMonth;
    final offset = month.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((days + offset) / 7).ceil() * 7;
    final start = month.subtract(Duration(days: offset));
    final today = dateOnly(DateTime.now());
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 640 ? 14 : 22),
      decoration: BoxDecoration(
        border: Border.all(color: c.line, width: 1.5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RoundButton(
                icon: Icons.chevron_left_rounded,
                tooltip: '이전 달',
                onPressed: () => controller.moveMonth(-1),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${month.year}년 ${month.month}월',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ),
              ),
              RoundButton(
                icon: Icons.chevron_right_rounded,
                tooltip: '다음 달',
                onPressed: () => controller.moveMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: List.generate(
                7,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      ['일', '월', '화', '수', '목', '금', '토'][i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == 0 ? c.sun : c.body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final extent = (constraints.maxWidth / 7).clamp(32.0, 58.0);
              return Column(
                children: List.generate(
                  cellCount ~/ 7,
                  (row) => Row(
                    children: List.generate(7, (column) {
                      final date = dateOnly(
                        start.add(Duration(days: row * 7 + column)),
                      );
                      final selected = controller.draft.dates.contains(date);
                      final outside = date.month != month.month;
                      return Expanded(
                        child: SizedBox(
                          height: extent,
                          child: Center(
                            child: Semantics(
                              selected: selected,
                              button: true,
                              label: '${date.year}년 ${dateLabel(date)}',
                              child: Tooltip(
                                message: '${date.year}년 ${dateLabel(date)}',
                                child: TextButton(
                                  key: ValueKey('date-${dateKey(date)}'),
                                  onPressed: () => controller.toggleDate(date),
                                  style: TextButton.styleFrom(
                                    minimumSize: Size(extent - 5, extent - 5),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: selected
                                        ? JakuColors.green
                                        : Colors.transparent,
                                    foregroundColor: selected
                                        ? JakuColors.stickerInk
                                        : column == 0
                                        ? c.sun
                                        : c.ink,
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: selected
                                            ? JakuColors.stickerInk
                                            : date == today
                                            ? c.line
                                            : Colors.transparent,
                                        width: selected ? 2 : 1.5,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Opacity(
                                    opacity: outside && !selected ? .35 : 1,
                                    child: Text('${date.day}'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
