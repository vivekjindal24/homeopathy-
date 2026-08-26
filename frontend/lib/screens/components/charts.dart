import 'dart:math' as math;
import 'package:flutter/material.dart';

// --- AREA CHART WIDGET ---
class AreaChartWidget extends StatelessWidget {
  final List<dynamic> data; // e.g. [{"day": "Mon", "value": 12000}, ...]
  final String xKey;
  final String yKey;
  final Color lineColor;
  final Color fillColor;

  const AreaChartWidget({
    super.key,
    required this.data,
    required this.xKey,
    required this.yKey,
    this.lineColor = const Color(0xFF0F766E), // Clinical Teal
    this.fillColor = const Color(0x330F766E), // Muted Teal
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    final double maxValue = data.map<double>((d) {
      final val = d[yKey];
      if (val is num) return val.toDouble();
      return 0.0;
    }).reduce(math.max);

    final double resolvedMax = maxValue == 0 ? 1000 : maxValue * 1.15; // Padding

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _AreaChartPainter(
            data: data,
            xKey: xKey,
            yKey: yKey,
            maxValue: resolvedMax,
            lineColor: lineColor,
            fillColor: fillColor,
          ),
        );
      },
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<dynamic> data;
  final String xKey;
  final String yKey;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;

  _AreaChartPainter({
    required this.data,
    required this.xKey,
    required this.yKey,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double labelAreaHeight = 24.0;
    final double labelAreaWidth = 45.0;
    final double chartHeight = size.height - labelAreaHeight;
    final double chartWidth = size.width - labelAreaWidth;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Paint areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw Grid Lines (Y-Axis splits)
    final int splits = 4;
    for (int i = 0; i <= splits; i++) {
      final double y = chartHeight * (1 - (i / splits));
      // Draw grid line
      canvas.drawLine(
        Offset(labelAreaWidth, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Draw Y labels
      final double labelVal = maxValue * (i / splits);
      final textSpan = TextSpan(
        text: labelVal >= 1000
            ? '₹${(labelVal / 1000).toStringAsFixed(1)}k'
            : '₹${labelVal.toStringAsFixed(0)}',
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(labelAreaWidth - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final double stepX = chartWidth / (data.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final double x = labelAreaWidth + (i * stepX);
      final double rawVal = (data[i][yKey] as num).toDouble();
      final double y = chartHeight * (1 - (rawVal / maxValue));
      points.add(Offset(x, y));

      // Draw X label
      final textSpan = TextSpan(
        text: data[i][xKey].toString(),
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + 6),
      );
    }

    // Path for line
    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Path for gradient area fill
    final Path areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, chartHeight);
    areaPath.lineTo(points.first.dx, chartHeight);
    areaPath.close();

    // Fill with Gradient
    areaPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [lineColor.withOpacity(0.24), lineColor.withOpacity(0.0)],
    ).createShader(Rect.fromLTWH(labelAreaWidth, 0, chartWidth, chartHeight));

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);

    // Draw data point circles
    final Paint circlePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var pt in points) {
      canvas.drawCircle(pt, 3.5, circlePaint);
      canvas.drawCircle(pt, 1.5, innerCirclePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

// --- DONUT/PIE CHART WIDGET ---
class PieChartWidget extends StatelessWidget {
  final List<dynamic> data; // e.g. [{"name": "UPI", "value": 40, "color": Colors.teal}, ...]
  final String valueKey;
  final String colorKey;

  const PieChartWidget({
    super.key,
    required this.data,
    required this.valueKey,
    required this.colorKey,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    final double total = data.map<double>((d) {
      final val = d[valueKey];
      if (val is num) return val.toDouble();
      return 0.0;
    }).reduce((sum, element) => sum + element);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double diameter = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: CustomPaint(
              painter: _PieChartPainter(
                data: data,
                valueKey: valueKey,
                colorKey: colorKey,
                total: total,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<dynamic> data;
  final String valueKey;
  final String colorKey;
  final double total;

  _PieChartPainter({
    required this.data,
    required this.valueKey,
    required this.colorKey,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 24.0;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -math.pi / 2; // Start from top 12 o'clock

    if (total == 0) {
      // Draw single grey circle if data is 0
      final Paint emptyPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, emptyPaint);
      return;
    }

    for (var item in data) {
      final double val = (item[valueKey] as num).toDouble();
      final double sweepAngle = 2 * math.pi * (val / total);
      final Color color = item[colorKey] is Color ? item[colorKey] : const Color(0xFF0F766E);

      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}

// --- BAR CHART WIDGET ---
class BarChartWidget extends StatelessWidget {
  final List<dynamic> data; // e.g. [{"day": "W1", "value": 142}, ...]
  final String xKey;
  final String yKey;
  final Color barColor;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.xKey,
    required this.yKey,
    this.barColor = const Color(0xFF0F766E),
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    final double maxValue = data.map<double>((d) {
      final val = d[yKey];
      if (val is num) return val.toDouble();
      return 0.0;
    }).reduce(math.max);

    final double resolvedMax = maxValue == 0 ? 100 : maxValue * 1.1;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map<Widget>((d) {
              final double val = (d[yKey] as num).toDouble();
              final double fraction = resolvedMax == 0 ? 0 : val / resolvedMax;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tooltip value
                      Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Rounded top bar
                      FractionallySizedBox(
                        heightFactor: fraction == 0 ? 0.02 : fraction,
                        child: Container(
                          width: 24,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // X Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map<Widget>((d) {
            return Expanded(
              child: Text(
                d[xKey].toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
