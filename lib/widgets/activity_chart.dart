import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/trade.dart';
import '../utils/formatters.dart';

/// Bar chart showing activity (volume or trade count) over time.
class ActivityChart extends StatelessWidget {
  const ActivityChart({
    super.key,
    required this.trades,
    this.height = 200,
  });

  final List<Trade> trades;
  final double height;

  /// Group trades by date and sum quantity.
  Map<String, int> _groupByDate(List<Trade> trades) {
    final map = <String, int>{};
    for (final t in trades) {
      final key = formatDate(t.timestamp);
      map[key] = (map[key] ?? 0) + t.quantity;
    }
    final keys = map.keys.toList()..sort();
    return Map.fromEntries(keys.map((k) => MapEntry(k, map[k]!)));
  }

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No activity data',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    final grouped = _groupByDate(trades);
    final entries = grouped.entries.toList();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: entries.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < entries.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          entries[idx].key,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    formatQuantity(value.toInt()),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: entries.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
                showingTooltipIndicators: [],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
