import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/category_constants.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<String, double> categorySpending;
  final double totalAmount;

  const CategoryDonutChart({
    super.key,
    required this.categorySpending,
    required this.totalAmount,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.categorySpending != widget.categorySpending) {
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

    if (widget.totalAmount <= 0 || widget.categorySpending.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'Chưa có dữ liệu chi tiêu trong kỳ',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(240, 240),
                painter: CategoryDonutPainter(
                  categorySpending: widget.categorySpending,
                  totalAmount: widget.totalAmount,
                  progress: _animation.value,
                  isDark: theme.brightness == Brightness.dark,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tổng chi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCompact(
                          widget.totalAmount * _animation.value,
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'VND',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: widget.categorySpending.entries.map((entry) {
            final cat = ExpenseCategory.fromString(entry.key);
            final percent = widget.totalAmount > 0
                ? (entry.value / widget.totalAmount * 100).toStringAsFixed(1)
                : '0';

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${cat.vietnameseName} ($percent%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CategoryDonutPainter extends CustomPainter {
  final Map<String, double> categorySpending;
  final double totalAmount;
  final double progress;
  final bool isDark;

  CategoryDonutPainter({
    required this.categorySpending,
    required this.totalAmount,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const strokeWidth = 28.0;

    // Draw background track ring
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF282C34) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2; // Start from 12 o'clock

    for (final entry in categorySpending.entries) {
      final sweepAngle = (entry.value / totalAmount) * 2 * math.pi * progress;
      final category = ExpenseCategory.fromString(entry.key);

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(center: center, radius: radius);

      // Leave a tiny gap between slices for a sleek modern finish
      final gap = categorySpending.length > 1 ? 0.03 : 0.0;
      final adjustedSweep = math.max(0.0, sweepAngle - gap);

      canvas.drawArc(rect, startAngle + gap / 2, adjustedSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CategoryDonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.categorySpending != categorySpending;
  }
}
