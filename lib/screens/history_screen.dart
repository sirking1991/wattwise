import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:watt_wise/models/consumption_snapshot.dart';
import 'package:watt_wise/services/history_service.dart';
import 'package:watt_wise/services/settings_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();
  final _settingsService = SettingsService();

  List<ConsumptionSnapshot> _snapshots = [];
  String _currencySymbol = '\$';
  bool _isLoading = true;
  int _selectedDays = 30;

  static const List<int> _dayOptions = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _historyService.getRecentSnapshots(_selectedDays),
      _settingsService.getCurrencySymbol(),
    ]);
    setState(() {
      _snapshots = results[0] as List<ConsumptionSnapshot>;
      _currencySymbol = results[1] as String;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Consumption History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildFilterChips(colorScheme),
        Expanded(
          child: _snapshots.isEmpty
              ? _buildEmptyState()
              : _buildCharts(colorScheme),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _dayOptions.map((days) {
          final selected = _selectedDays == days;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$days Days'),
              selected: selected,
              onSelected: (value) {
                if (value && _selectedDays != days) {
                  _selectedDays = days;
                  _loadData();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No history data yet. Data is recorded daily as you use the app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCharts(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildKwhChart(colorScheme),
        const SizedBox(height: 12),
        _buildCostChart(colorScheme),
        const SizedBox(height: 12),
        _buildSummaryCard(colorScheme),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Bar chart: Daily Energy (kWh) ---

  Widget _buildKwhChart(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Energy (kWh)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final snapshot = _snapshots[group.x.toInt()];
                        final date = DateFormat('d/M').format(snapshot.date);
                        return BarTooltipItem(
                          '$date\n${rod.toY.toStringAsFixed(2)} kWh',
                          TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: _buildBarGroups(colorScheme),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            _bottomDateLabel(value),
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(ColorScheme colorScheme) {
    return List.generate(_snapshots.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: _snapshots[i].totalDailyKwh,
            color: colorScheme.primary,
            width: _barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  double get _barWidth {
    if (_snapshots.length <= 7) return 16;
    if (_snapshots.length <= 30) return 8;
    return 4;
  }

  // --- Line chart: Daily Cost ---

  Widget _buildCostChart(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Cost ($_currencySymbol)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final snapshot = _snapshots[spot.x.toInt()];
                          final date =
                              DateFormat('d/M').format(snapshot.date);
                          return LineTooltipItem(
                            '$date\n$_currencySymbol${spot.y.toStringAsFixed(2)}',
                            TextStyle(
                              color: colorScheme.onSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _snapshots.length,
                        (i) => FlSpot(
                          i.toDouble(),
                          _snapshots[i].totalDailyCost,
                        ),
                      ),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: colorScheme.secondary,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: _snapshots.length <= 30,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.secondary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            _bottomDateLabel(value),
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Shared axis label builder ---

  Widget _bottomDateLabel(double value) {
    final index = value.toInt();
    if (index < 0 || index >= _snapshots.length) {
      return const SizedBox.shrink();
    }
    final interval = (_snapshots.length / 6).ceil().clamp(1, _snapshots.length);
    if (index % interval != 0 && index != _snapshots.length - 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        DateFormat('d/M').format(_snapshots[index].date),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  // --- Summary card ---

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    final totalKwh =
        _snapshots.fold(0.0, (sum, s) => sum + s.totalDailyKwh);
    final totalCost =
        _snapshots.fold(0.0, (sum, s) => sum + s.totalDailyCost);
    final avgKwh =
        _snapshots.isNotEmpty ? totalKwh / _snapshots.length : 0.0;
    final avgCost =
        _snapshots.isNotEmpty ? totalCost / _snapshots.length : 0.0;

    final highest = _snapshots.isNotEmpty
        ? _snapshots.reduce((a, b) =>
            a.totalDailyKwh >= b.totalDailyKwh ? a : b)
        : null;
    final lowest = _snapshots.isNotEmpty
        ? _snapshots.reduce((a, b) =>
            a.totalDailyKwh <= b.totalDailyKwh ? a : b)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _summaryRow(
              Icons.show_chart,
              'Average daily',
              '${avgKwh.toStringAsFixed(2)} kWh  ·  $_currencySymbol${avgCost.toStringAsFixed(2)}',
              colorScheme,
            ),
            const Divider(height: 16),
            _summaryRow(
              Icons.functions,
              'Total for period',
              '${totalKwh.toStringAsFixed(2)} kWh  ·  $_currencySymbol${totalCost.toStringAsFixed(2)}',
              colorScheme,
            ),
            if (highest != null) ...[
              const Divider(height: 16),
              _summaryRow(
                Icons.arrow_upward,
                'Highest day',
                '${DateFormat('d MMM').format(highest.date)} — ${highest.totalDailyKwh.toStringAsFixed(2)} kWh',
                colorScheme,
              ),
            ],
            if (lowest != null) ...[
              const Divider(height: 16),
              _summaryRow(
                Icons.arrow_downward,
                'Lowest day',
                '${DateFormat('d MMM').format(lowest.date)} — ${lowest.totalDailyKwh.toStringAsFixed(2)} kWh',
                colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
