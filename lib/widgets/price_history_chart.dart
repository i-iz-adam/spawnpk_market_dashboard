import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/trade.dart';
import '../utils/formatters.dart';

/// Line chart showing price history over time.
class PriceHistoryChart extends StatelessWidget {
  const PriceHistoryChart({
    super.key,
    required this.trades,
    this.height = 220,
  });

  final List<Trade> trades;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No trade data for chart',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    // Sort by timestamp ascending.
    final sorted = List<Trade>.from(trades)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].price));
    }

    final minX = 0.0;
    final maxX = (spots.length - 1).clamp(0, double.infinity).toDouble();
    final minY = ((spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) as num) * 0.95)
        .clamp(0.0, double.infinity)
        .toDouble();
    final maxY = ((spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) as num) * 1.05)
        .toDouble();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 5,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: (maxY - minY) / 5,
                  getTitlesWidget: (value, meta) => Text(
                    formatPrice(value),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (maxX - minX) / 5,
                  getTitlesWidget: (value, meta) {
                    final idx = value.round().clamp(0, sorted.length - 1);
                    if (idx >= 0 && idx < sorted.length) {
                      return Text(
                        formatDate(sorted[idx].timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: spots.length <= 20,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 1,
                    strokeColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
