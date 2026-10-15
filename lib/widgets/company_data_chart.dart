import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/company_dataset.dart';

const dataCyan = Color(0xFF37C9FF);
const dataMint = Color(0xFF38E5B5);
const dataMuted = Color(0xFF96A7BC);
String formatDataValue(double n, {bool bytes = false}) {
  if (bytes) {
    if (n >= 1073741824) return '${(n / 1073741824).toStringAsFixed(2)} GB';
    if (n >= 1048576) return '${(n / 1048576).toStringAsFixed(1)} MB';
    if (n >= 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '${n.toInt()} B';
  }
  return NumberFormat.decimalPattern().format(n);
}

class ChartSeries {
  const ChartSeries(this.name, this.points, this.color, {this.bytes = false});
  final String name;
  final List<DataPoint> points;
  final Color color;
  final bool bytes;
}

class CompanyDataChart extends StatefulWidget {
  const CompanyDataChart({
    super.key,
    required this.series,
    this.bars = false,
    this.snapshot = false,
  });
  final List<ChartSeries> series;
  final bool bars, snapshot;
  @override
  State<CompanyDataChart> createState() => _CompanyDataChartState();
}

class _CompanyDataChartState extends State<CompanyDataChart> {
  int? _hover;
  @override
  void didUpdateWidget(covariant CompanyDataChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hover = null;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.series.isEmpty ? 0 : widget.series.first.points.length;
    final mixed = widget.series.map((s) => s.bytes).toSet().length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 22,
          runSpacing: 8,
          children: [
            for (final s in widget.series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        if (mixed)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Two scales: cyan uses the left axis; green uses the right axis.',
              style: TextStyle(color: dataMuted, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        if (count == 0)
          const SizedBox(
            height: 280,
            child: Center(
              child: Text(
                'No dated measurements are available.',
                style: TextStyle(color: dataMuted),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              void locate(Offset p) {
                final width = math.max(1.0, c.maxWidth - (mixed ? 108 : 72));
                final i = (((p.dx - 48) / width) * count).floor().clamp(
                  0,
                  count - 1,
                );
                setState(() => _hover = i);
              }

              final index = _hover;
              return Column(
                children: [
                  SizedBox(
                    height: 46,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: index == null
                          ? const Text(
                              'Hover or tap a point to inspect its values',
                              style: TextStyle(color: dataMuted, fontSize: 12),
                            )
                          : Wrap(
                              spacing: 14,
                              runSpacing: 4,
                              children: [
                                Text(
                                  widget.snapshot
                                      ? 'Current snapshot'
                                      : DateFormat.yMMMd().format(
                                          DateTime.parse(
                                            widget
                                                .series
                                                .first
                                                .points[index]
                                                .day,
                                          ),
                                        ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                for (final s in widget.series)
                                  Text(
                                    '${s.name}: ${formatDataValue(s.points[index].value, bytes: s.bytes)}',
                                    style: TextStyle(
                                      color: s.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  MouseRegion(
                    onHover: (e) => locate(e.localPosition),
                    onExit: (_) => setState(() => _hover = null),
                    child: GestureDetector(
                      onTapDown: (e) => locate(e.localPosition),
                      onHorizontalDragUpdate: (e) => locate(e.localPosition),
                      child: Semantics(
                        label: widget.series
                            .map(
                              (s) =>
                                  '${s.name}, ${s.points.length} ${widget.snapshot ? 'snapshot' : 'time'} buckets, total ${formatDataValue(s.points.fold<double>(0, (a, b) => a + b.value), bytes: s.bytes)}',
                            )
                            .join('. '),
                        child: SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(
                              '${widget.series.map((s) => '${s.name}:${s.points.map((p) => p.value).join(',')}').join('|')}:${widget.bars}',
                            ),
                            tween: Tween(begin: 0, end: 1),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 350),
                            builder: (context, progress, _) => CustomPaint(
                              painter: _DataChartPainter(
                                widget.series,
                                widget.bars || widget.snapshot,
                                widget.snapshot,
                                index,
                                progress,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _DataChartPainter extends CustomPainter {
  _DataChartPainter(
    this.series,
    this.bars,
    this.snapshot,
    this.hover,
    this.progress,
  );
  final List<ChartSeries> series;
  final bool bars, snapshot;
  final int? hover;
  final double progress;
  void text(
    Canvas canvas,
    String value,
    Offset at, {
    Color color = dataMuted,
    bool right = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, Offset(right ? at.dx - p.width : at.dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mixed = series.map((s) => s.bytes).toSet().length > 1;
    final plot = Rect.fromLTRB(
      48,
      12,
      size.width - (mixed ? 60 : 24),
      size.height - 34,
    );
    if (plot.width <= 0 || series.isEmpty || series.first.points.isEmpty) {
      return;
    }
    final n = series.first.points.length;
    double peak(ChartSeries s) =>
        s.points.fold<double>(0, (m, p) => math.max(m, p.value));
    final shared = series.fold<double>(0, (m, s) => math.max(m, peak(s)));
    double axis(double value, bool bytes) => value <= 0
        ? 4
        : bytes
        ? value * 1.15
        : math.max(4, (value / 4).ceilToDouble() * 4);
    final sharedAxis = axis(shared, series.first.bytes);
    final firstAxis = mixed
        ? axis(peak(series.first), series.first.bytes)
        : sharedAxis;
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()
          ..color = const Color(0xFF2A3545)
          ..strokeWidth = 1,
      );
      text(
        canvas,
        NumberFormat.compact().format(firstAxis * i / 4),
        Offset(plot.left - 8, y - 6),
        right: true,
      );
      if (mixed) {
        text(
          canvas,
          NumberFormat.compact().format(
            axis(peak(series.last), series.last.bytes) * i / 4,
          ),
          Offset(plot.right + 8, y - 6),
          color: series.last.color,
        );
      }
    }
    text(
      canvas,
      series.first.bytes ? 'BYTES' : 'COUNT',
      Offset(0, 0),
      color: series.first.color,
    );
    if (mixed) {
      text(
        canvas,
        series.last.bytes ? 'BYTES' : 'COUNT',
        Offset(plot.right + 5, 0),
        color: series.last.color,
      );
    }
    final slot = plot.width / n;
    double x(int i) => plot.left + slot * (i + .5);
    for (var k = 0; k < series.length; k++) {
      final s = series[k];
      final max = mixed ? axis(peak(s), s.bytes) : sharedAxis;
      double y(double v) => plot.bottom - (v / max) * plot.height * progress;
      if (bars) {
        final width = math.min(28.0, slot * .72 / series.length);
        for (var i = 0; i < n; i++) {
          final left =
              x(i) + (k - (series.length - 1) / 2) * width - width * .43;
          final rect = Rect.fromLTRB(
            left,
            y(s.points[i].value),
            left + width * .86,
            plot.bottom,
          );
          if (rect.height > 0) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(4)),
              Paint()
                ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [s.color, s.color.withValues(alpha: .35)],
                ).createShader(plot),
            );
          }
        }
      } else {
        final line = Path();
        for (var i = 0; i < n; i++) {
          if (i == 0) {
            line.moveTo(x(i), y(s.points[i].value));
          } else {
            line.lineTo(x(i), y(s.points[i].value));
          }
        }
        final area = Path.from(line)
          ..lineTo(x(n - 1), plot.bottom)
          ..lineTo(x(0), plot.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: .19),
                s.color.withValues(alpha: 0),
              ],
            ).createShader(plot),
        );
        canvas.drawPath(
          line,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round,
        );
        if (n == 1) {
          canvas.drawCircle(
            Offset(x(0), y(s.points[0].value)),
            4,
            Paint()..color = s.color,
          );
        }
      }
      if (hover != null) {
        canvas.drawCircle(
          Offset(x(hover!), y(s.points[hover!].value)),
          4,
          Paint()..color = s.color,
        );
      }
    }
    if (hover != null) {
      canvas.drawLine(
        Offset(x(hover!), plot.top),
        Offset(x(hover!), plot.bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: .22)
          ..strokeWidth = 1,
      );
    }
    final stride = math.max(1, (n / 4).ceil());
    for (var i = 0; i < n; i++) {
      if (i % stride != 0 && i != n - 1) continue;
      final label = snapshot
          ? 'Now'
          : DateFormat(
              'MMM d',
            ).format(DateTime.parse(series.first.points[i].day));
      text(
        canvas,
        label,
        Offset((x(i) - 14).clamp(plot.left, plot.right - 32), plot.bottom + 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DataChartPainter old) => true;
}
