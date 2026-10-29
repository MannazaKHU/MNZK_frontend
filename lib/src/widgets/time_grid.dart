import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../theme.dart';

/// 06:00~24:00, 30분 단위. 드래그 시작 칸의 상태에 따라 사각 영역을
/// 선택/해제한다. 키보드는 Tab으로 이동하고 Space/Enter로 선택한다.
class TimeGrid extends StatefulWidget {
  const TimeGrid({
    super.key,
    required this.dates,
    this.slots = const {},
    this.onChanged,
    this.countAt,
    this.groupSize = 1,
    this.onInspect,
  });
  final List<DateTime> dates;
  final Map<String, Set<int>> slots;
  final ValueChanged<Map<String, Set<int>>>? onChanged;
  final int Function(DateTime, int)? countAt;
  final int groupSize;
  final void Function(DateTime, int, int)? onInspect;
  @override
  State<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<TimeGrid> {
  static const gutter = 66.0;
  static const rowHeight = 26.0;
  final horizontal = ScrollController();
  final vertical = ScrollController();
  final gridKey = GlobalKey();
  final viewportKey = GlobalKey();
  Map<String, Set<int>>? preview;
  Map<String, Set<int>> base = {};
  (int, int)? origin;
  (int, int)? inspected;
  bool adding = true;
  double cellWidth = 62;
  Offset? pointer;
  Timer? autoScroll;
  bool get readOnly => widget.countAt != null;

  @override
  void dispose() {
    autoScroll?.cancel();
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  (int, int)? _cellAt(Offset global) {
    final box = gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || widget.dates.isEmpty) return null;
    final point = box.globalToLocal(global);
    if (origin == null &&
        (point.dx < gutter ||
            point.dx >= box.size.width ||
            point.dy < 0 ||
            point.dy >= box.size.height)) {
      return null;
    }
    final column = ((point.dx - gutter) / cellWidth).floor().clamp(
      0,
      widget.dates.length - 1,
    );
    final slot =
        (point.dy / rowHeight).floor().clamp(0, lastSlot - firstSlot - 1) +
        firstSlot;
    return (column, slot);
  }

  void _begin(Offset global) {
    if (readOnly) return;
    final cell = _cellAt(global);
    if (cell == null) return;
    origin = cell;
    pointer = global;
    base = widget.slots.map((key, value) => MapEntry(key, {...value}));
    adding =
        !(base[dateKey(widget.dates[cell.$1])]?.contains(cell.$2) ?? false);
    _paint(cell);
    autoScroll?.cancel();
    autoScroll = Timer.periodic(
      const Duration(milliseconds: 35),
      (_) => _scrollAtEdge(),
    );
  }

  void _move(Offset global) {
    if (origin == null) return;
    pointer = global;
    final cell = _cellAt(global);
    if (cell != null) _paint(cell);
  }

  void _paint((int, int) cell) {
    final from = origin;
    if (from == null) return;
    final next = base.map((key, value) => MapEntry(key, {...value}));
    for (
      var col = math.min(from.$1, cell.$1);
      col <= math.max(from.$1, cell.$1);
      col++
    ) {
      final selected = next.putIfAbsent(dateKey(widget.dates[col]), () => {});
      for (
        var slot = math.min(from.$2, cell.$2);
        slot <= math.max(from.$2, cell.$2);
        slot++
      ) {
        adding ? selected.add(slot) : selected.remove(slot);
      }
    }
    setState(() => preview = next);
  }

  void _scrollAtEdge() {
    if (origin == null || pointer == null) return;
    final box = viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(pointer!);
    void move(ScrollController scroll, double delta) {
      if (!scroll.hasClients || delta == 0) return;
      final next = (scroll.offset + delta).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      );
      if (next != scroll.offset) scroll.jumpTo(next);
    }

    move(
      vertical,
      local.dy < 75
          ? -10
          : local.dy > box.size.height - 30
          ? 10
          : 0,
    );
    move(
      horizontal,
      local.dx < 30
          ? -10
          : local.dx > box.size.width - 30
          ? 10
          : 0,
    );
    final cell = _cellAt(pointer!);
    if (cell != null) _paint(cell);
  }

  void _finish() {
    autoScroll?.cancel();
    if (origin == null) return;
    final next = preview;
    origin = null;
    pointer = null;
    if (next != null) widget.onChanged?.call(next);
    if (mounted) setState(() => preview = null);
  }

  void _toggle(int col, int slot) {
    if (readOnly) {
      setState(() => inspected = (col, slot));
      widget.onInspect?.call(
        widget.dates[col],
        slot,
        widget.countAt!(widget.dates[col], slot),
      );
      return;
    }
    final next = widget.slots.map((key, value) => MapEntry(key, {...value}));
    final selected = next.putIfAbsent(dateKey(widget.dates[col]), () => {});
    selected.contains(slot) ? selected.remove(slot) : selected.add(slot);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = JakuColors.of(context);
    if (widget.dates.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        cellWidth = math.max(
          62,
          (constraints.maxWidth - gutter - 2) / widget.dates.length,
        );
        final width = gutter + widget.dates.length * cellWidth;
        final height = (MediaQuery.sizeOf(context).height * .55).clamp(
          280.0,
          540.0,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            key: viewportKey,
            height: height,
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.line, width: 1.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Scrollbar(
              controller: horizontal,
              thumbVisibility: width > constraints.maxWidth,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      Container(
                        height: 58,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: c.line, width: 1.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: gutter,
                              child: Text(
                                '시간',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: c.body),
                              ),
                            ),
                            for (final date in widget.dates)
                              SizedBox(
                                width: cellWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      shortDate(date),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: date.weekday == 7
                                            ? c.sun
                                            : c.ink,
                                      ),
                                    ),
                                    Text(
                                      weekdays[date.weekday - 1],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: date.weekday == 7
                                            ? c.sun
                                            : c.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: vertical,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: vertical,
                            child: GestureDetector(
                              dragStartBehavior: DragStartBehavior.down,
                              onTapDown: readOnly
                                  ? null
                                  : (details) => _begin(details.globalPosition),
                              onTapUp: readOnly ? null : (_) => _finish(),
                              onPanStart: readOnly
                                  ? null
                                  : (details) {
                                      if (origin == null) {
                                        _begin(details.globalPosition);
                                      }
                                    },
                              onPanUpdate: readOnly
                                  ? null
                                  : (details) => _move(details.globalPosition),
                              onPanEnd: readOnly ? null : (_) => _finish(),
                              onPanCancel: readOnly ? null : _finish,
                              child: SizedBox(
                                key: gridKey,
                                child: Column(
                                  children: List.generate(
                                    lastSlot - firstSlot,
                                    (row) {
                                      final slot = row + firstSlot;
                                      return SizedBox(
                                        height: rowHeight,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: gutter,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                child: Text(
                                                  slot.isEven
                                                      ? slotLabel(slot)
                                                      : '',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 11,
                                                    color: c.body,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            for (
                                              var col = 0;
                                              col < widget.dates.length;
                                              col++
                                            )
                                              _buildCell(c, col, slot),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 17),
                            child: Text(
                              '24:00',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                color: c.body,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(JakuColors c, int col, int slot) {
    final date = widget.dates[col];
    final selected =
        (preview ?? widget.slots)[dateKey(date)]?.contains(slot) ?? false;
    final count = widget.countAt?.call(date, slot) ?? 0;
    final all = readOnly && count >= widget.groupSize;
    final picked = inspected == (col, slot);
    final color = readOnly
        ? Color.lerp(c.card, JakuColors.green, count / widget.groupSize)!
        : selected
        ? JakuColors.green
        : c.card;
    final label =
        '${dateLabel(date)} ${slotLabel(slot)}–${slotLabel(slot + 1)}';
    return Semantics(
      label: readOnly ? '$label, $count/${widget.groupSize}명 가능' : label,
      button: true,
      selected: selected || picked,
      onTap: () => _toggle(col, slot),
      child: FocusableActionDetector(
        mouseCursor: readOnly
            ? SystemMouseCursors.click
            : SystemMouseCursors.precise,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle(col, slot);
              return null;
            },
          ),
        },
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: readOnly ? () => _toggle(col, slot) : null,
            child: Container(
              key: ValueKey('slot-${dateKey(date)}-$slot'),
              width: cellWidth,
              height: rowHeight,
              decoration: BoxDecoration(
                color: color,
                border: all || picked || Focus.of(context).hasFocus
                    ? Border.all(color: c.ink, width: 1.5)
                    : Border(
                        left: BorderSide(color: c.line),
                        top: BorderSide(
                          color: selected
                              ? JakuColors.stickerInk.withValues(alpha: .2)
                              : c.line,
                          width: slot.isEven ? 1 : .5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
