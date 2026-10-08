import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';

class WeeklyBarChart extends StatefulWidget {
  final Map<int, double> weeklySpending; // 1 = T2 ... 7 = CN

  const WeeklyBarChart({super.key, required this.weeklySpending});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklySpending != widget.weeklySpending) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAmount = widget.weeklySpending.values.fold<double>(
      0.0,
      (max, val) => math.max(max, val),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedDay != null &&
            (widget.weeklySpending[_selectedDay] ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${_getDayName(_selectedDay!)}: ${CurrencyFormatter.formatVND(widget.weeklySpending[_selectedDay] ?? 0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final dayWidth = constraints.maxWidth / 7;
                  final dayIndex =
                      (details.localPosition.dx / dayWidth).floor() + 1;
                  if (dayIndex >= 1 && dayIndex <= 7) {
                    setState(() {
                      _selectedDay = dayIndex;
                    });
                  }
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, 180),
                      painter: WeeklyBarChartPainter(
                        weeklySpending: widget.weeklySpending,
                        maxAmount: maxAmount > 0 ? maxAmount : 100000,
                        progress: _animation.value,
                        selectedDay: _selectedDay,
                        primaryColor: theme.colorScheme.primary,
                        secondaryColor: theme.colorScheme.secondary,
                        isDark: theme.brightness == Brightness.dark,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = _selectedDay == day;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDayLabel(day),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (theme.brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getDayLabel(int day) {
    return switch (day) {
      1 => 'T2',
      2 => 'T3',
      3 => 'T4',
      4 => 'T5',
      5 => 'T6',
      6 => 'T7',
      7 => 'CN',
      _ => '',
    };
  }

  String _getDayName(int day) {
    return switch (day) {
      1 => 'Thứ Hai',
      2 => 'Thứ Ba',
      3 => 'Thứ Tư',
      4 => 'Thứ Năm',
      5 => 'Thứ Sáu',
      6 => 'Thứ Bảy',
      7 => 'Chủ Nhật',
      _ => '',
    };
  }
}

class WeeklyBarChartPainter extends CustomPainter {
  final Map<int, double> weeklySpending;
  final double maxAmount;
  final double progress;
  final int? selectedDay;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  WeeklyBarChartPainter({
    required this.weeklySpending,
    required this.maxAmount,
    required this.progress,
    required this.selectedDay,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bottomY = size.height - 10;
    const topY = 20.0;
    final availableHeight = bottomY - topY;

    final barSlotWidth = size.width / 7;
    final barWidth = barSlotWidth * 0.42;

    // Draw baseline
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF2E3440) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, bottomY), Offset(size.width, bottomY), linePaint);

    for (int i = 0; i < 7; i++) {
      final day = i + 1;
      final amount = weeklySpending[day] ?? 0.0;
      final ratio = maxAmount > 0 ? (amount / maxAmount) : 0.0;
      final barHeight = ratio * availableHeight * progress;

      final centerX = (i * barSlotWidth) + (barSlotWidth / 2);
      final left = centerX - (barWidth / 2);
      final right = centerX + (barWidth / 2);
      final top = bottomY - math.max(4.0, barHeight);

      final isSelected = selectedDay == day;

      // Draw background bar pill
      final bgBarPaint = Paint()
        ..color = isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, topY, right, bottomY),
          const Radius.circular(8),
        ),
        bgBarPaint,
      );

      // Draw active spending bar
      if (barHeight > 0) {
        final barPaint = Paint()
          ..color = isSelected
              ? primaryColor
              : (amount > 0
                    ? secondaryColor.withOpacity(0.85)
                    : Colors.transparent)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, right, bottomY),
            const Radius.circular(8),
          ),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.weeklySpending != weeklySpending ||
        oldDelegate.maxAmount != maxAmount;
  }
}
