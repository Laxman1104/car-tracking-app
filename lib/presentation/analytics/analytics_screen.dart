import 'package:flutter/material.dart';

import '../../domain/analytics/analytics.dart';
import '../../domain/maintenance/maintenance.dart';
import '../../domain/odometer/odometer_value.dart';
import '../fuel/fuel_formatters.dart';
import '../fuel/fuel_brand_assets.dart';
import '../maintenance/maintenance_formatters.dart';
import '../theme/app_theme.dart';

typedef AnalyticsLoader = Future<CarAnalytics> Function(int vehicleId);

enum AnalyticsSection { overview, fuel, maintenance }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.vehicleId,
    required this.loadAnalytics,
  });

  final int vehicleId;
  final AnalyticsLoader loadAnalytics;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<CarAnalytics> _analytics;
  AnalyticsSection _section = AnalyticsSection.overview;

  @override
  void initState() {
    super.initState();
    _analytics = widget.loadAnalytics(widget.vehicleId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analytics')),
    body: FutureBuilder<CarAnalytics>(
      future: _analytics,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => setState(() {
                _analytics = widget.loadAnalytics(widget.vehicleId);
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry analytics'),
            ),
          );
        }
        final data = snapshot.requireData;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SegmentedButton<AnalyticsSection>(
                key: const Key('analytics-sections'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AnalyticsSection.overview,
                    label: Text('Overview'),
                  ),
                  ButtonSegment(
                    value: AnalyticsSection.fuel,
                    label: Text('Fuel'),
                  ),
                  ButtonSegment(
                    value: AnalyticsSection.maintenance,
                    label: Text('Maintenance'),
                  ),
                ],
                selected: {_section},
                onSelectionChanged: (value) =>
                    setState(() => _section = value.single),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_section) {
                  AnalyticsSection.overview => _Overview(data: data),
                  AnalyticsSection.fuel => _Fuel(data: data),
                  AnalyticsSection.maintenance => _Maintenance(data: data),
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.data});
  final CarAnalytics data;

  @override
  Widget build(BuildContext context) => _Page(
    key: const ValueKey('overview'),
    children: [
      const _Heading('Actual logged costs'),
      _HeroMetric(
        label: 'TOTAL OWNERSHIP SPENDING',
        labelDetail: 'Fuel Logs + Maintenance (Service + Repairs)',
        value: formatRinggitFromSen(data.totalOwnershipCostSen),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _MetricGrid(
        children: [
          _Metric(
            label: 'Fuel spending',
            value: formatRinggitFromSen(data.totalFuelCostSen),
          ),
          _Metric(
            label: 'Service + repairs',
            value: formatRinggitFromSen(data.totalMaintenanceCostSen),
          ),
          _Metric(
            label: 'Latest cycle',
            value: _rate(data.latestCycle?.fuelEfficiencyKmPerL, 'km/L'),
          ),
          _Metric(
            label: 'Lifetime fuel rate',
            value: _rate(data.lifetimeKmPerL, 'km/L'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _Metric(
        label: 'Overall cost per tracked distance',
        value: _rate(data.ownershipCostPerKm, 'RM/km', prefix: 'RM'),
      ),
      const SizedBox(height: 24),
      const _Heading('Monthly spending'),
      if (data.monthlySpending.isEmpty)
        const _EmptyPanel(
          icon: Icons.bar_chart_outlined,
          title: 'No Spending Data Available',
        )
      else
        _MonthlySpendingList(values: data.monthlySpending),
      const SizedBox(height: 24),
      const _Heading('Spending by category'),
      _BreakdownRow(
        label: 'Fuel',
        value: formatRinggitFromSen(data.totalFuelCostSen),
        color: AppColors.primary,
      ),
      ...data.maintenanceCategories.map(
        (entry) => _BreakdownRow(
          label: maintenanceCategoryLabel(entry.category),
          value: formatRinggitFromSen(entry.costSen),
          color: _categoryColor(entry.category),
        ),
      ),
    ],
  );
}

class _Fuel extends StatelessWidget {
  const _Fuel({required this.data});
  final CarAnalytics data;

  @override
  Widget build(BuildContext context) {
    final latest = data.latestCycle;
    return _Page(
      key: const ValueKey('fuel'),
      children: [
        const _Heading('Fuel performance'),
        _HeroMetric(
          label: 'LATEST COMPLETED CYCLE',
          value: _rate(latest?.fuelEfficiencyKmPerL, 'km/L'),
          icon: Icons.local_gas_station_outlined,
          detail: latest == null
              ? null
              : '${latest.attributedBrand ?? 'Mixed'} · '
                    '${formatOdometerKm(latest.distanceKm)} km · '
                    '${_rate(latest.costRinggitPerKm, 'RM/km', prefix: 'RM')}',
        ),
        _MetricGrid(
          children: [
            _Metric(
              label: 'Lifetime average',
              value: _rate(data.lifetimeKmPerL, 'km/L'),
            ),
            _Metric(
              label: 'Rolling last 5',
              value: _rate(data.rollingFiveKmPerL, 'km/L'),
            ),
            _Metric(
              label: 'Completed-cycle cost',
              value: _rate(data.completedCycleCostPerKm, 'RM/km', prefix: 'RM'),
            ),
            _Metric(
              label: 'Litres purchased',
              value:
                  '${(data.totalFuelMillilitres / 1000).toStringAsFixed(2)} L',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Completed-cycle cost uses '
          '${formatRinggitFromSen(data.completedCycleFuelCostSen)} across '
          '${data.completedCycleDistanceKm} km. Opening Full purchases and '
          'pending-cycle fuel are excluded.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _Metric(
          label: 'Total fuel spending',
          value: formatRinggitFromSen(data.totalFuelCostSen),
        ),
        const SizedBox(height: 24),
        const _Heading('Monthly km/L trajectory'),
        if (data.monthlyFuelEfficiency.length < 2)
          const _EmptyPanel(
            icon: Icons.show_chart,
            title: 'Insufficient Cycle Data',
          )
        else
          _MonthlyEfficiencyChart(values: data.monthlyFuelEfficiency),
        const SizedBox(height: 24),
        const _Heading('Brand efficiency'),
        const Text(
          'Only single-brand cycles are compared. Mixed cycles remain in overall consumption.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (data.brandEfficiency.isEmpty)
          const _EmptyPanel(
            icon: Icons.compare_arrows,
            title: 'No Brand Comparisons Yet',
          )
        else
          ...data.brandEfficiency.map(
            (entry) => _BrandEfficiencyRow(entry: entry),
          ),
      ],
    );
  }
}

class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.data});
  final CarAnalytics data;

  @override
  Widget build(BuildContext context) => _Page(
    key: const ValueKey('maintenance'),
    children: [
      const _Heading('Maintenance spending'),
      _HeroMetric(
        label: 'TOTAL MAINTENANCE EXPENDITURE',
        labelDetail: 'Service + Repairs',
        value: formatRinggitFromSen(data.totalMaintenanceCostSen),
        icon: Icons.build_outlined,
        detail:
            '${data.maintenanceExpenditureRecordCount} '
            '${data.maintenanceExpenditureRecordCount == 1 ? 'record' : 'records'}',
      ),
      const SizedBox(height: 8),
      ...data.maintenanceCategories
          .where((entry) => entry.category != MaintenanceCategory.accessories)
          .map(
            (entry) => _BreakdownRow(
              label:
                  '${maintenanceCategoryLabel(entry.category)} · '
                  '${entry.recordCount}',
              value:
                  '${formatRinggitFromSen(entry.costSen)} · '
                  '${(entry.spendingShare * 100).toStringAsFixed(0)}%',
              color: _categoryColor(entry.category),
            ),
          ),
      const SizedBox(height: 8),
      const _AccessoriesHeader(),
      ...data.maintenanceCategories
          .where((entry) => entry.category == MaintenanceCategory.accessories)
          .map(
            (entry) => _BreakdownRow(
              label:
                  '${maintenanceCategoryLabel(entry.category)} · '
                  '${entry.recordCount}',
              value: formatRinggitFromSen(entry.costSen),
              color: _categoryColor(entry.category),
            ),
          ),
      const SizedBox(height: 24),
      const _Heading('Visit timeline'),
      if (data.maintenanceRecords.isEmpty)
        const _EmptyPanel(
          icon: Icons.event_busy_outlined,
          title: 'No workshop visits logged yet',
        )
      else
        ...data.maintenanceRecords.reversed.map(
          (record) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.circle,
                size: 14,
                color: _categoryColor(record.category),
              ),
              title: Text(maintenanceCategoryLabel(record.category)),
              subtitle: Text(
                '${formatMaintenanceDate(record.occurredAt.toLocal())} · '
                '${record.workshop ?? 'Workshop not recorded'}',
              ),
              trailing: Text(
                formatRinggitFromSen(record.costSen),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      const SizedBox(height: 24),
      const _Heading('Upcoming service reminders'),
      ...data.upcomingServiceReminders.map(
        (reminder) => Card(
          key: Key(
            'analytics-service-reminder-${reminder.maintenanceRecordId}',
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(reminder.title),
            subtitle: Text(_targetText(reminder)),
          ),
        ),
      ),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
    children: children,
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
  );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.labelDetail,
    this.detail,
  });
  final String label;
  final String value;
  final IconData icon;
  final String? labelDetail;
  final String? detail;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (labelDetail != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        labelDetail!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    ),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.55,
    children: children,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(
        width: 8,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _AccessoriesHeader extends StatelessWidget {
  const _AccessoriesHeader();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('accessories-separate-header'),
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      children: [
        Icon(Icons.extension_outlined, color: AppColors.textSecondary),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCESSORIES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Tracked separately from maintenance expenditure',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BrandEfficiencyRow extends StatelessWidget {
  const _BrandEfficiencyRow({required this.entry});
  final BrandEfficiencySummary entry;

  @override
  Widget build(BuildContext context) {
    final asset = FuelBrandAssets.forBrand(entry.brand);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
          ),
          child: asset == null
              ? const Icon(
                  Icons.local_gas_station_outlined,
                  color: AppColors.primary,
                )
              : Image.asset(asset, fit: BoxFit.contain),
        ),
        title: Text(entry.brand),
        subtitle: Text(
          '${entry.cycleCount} '
          '${entry.cycleCount == 1 ? 'cycle' : 'cycles'}',
        ),
        trailing: Text(
          _rate(entry.kmPerL, 'km/L'),
          style: const TextStyle(
            color: AppColors.teal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MonthlyEfficiencyChart extends StatefulWidget {
  const _MonthlyEfficiencyChart({required this.values});
  final List<MonthlyFuelEfficiency> values;

  @override
  State<_MonthlyEfficiencyChart> createState() =>
      _MonthlyEfficiencyChartState();
}

class _MonthlyEfficiencyChartState extends State<_MonthlyEfficiencyChart> {
  late int _year;

  List<int> get _years =>
      widget.values.map((entry) => entry.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _year = _years.first;
  }

  @override
  Widget build(BuildContext context) {
    final values =
        widget.values
            .where((entry) => entry.year == _year && entry.kmPerL != null)
            .toList()
          ..sort((a, b) => a.month.compareTo(b.month));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Monthly average from completed cycles',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const Key('monthly-efficiency-year'),
                    value: _year,
                    isDense: true,
                    items: _years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (year) {
                      if (year != null) setState(() => _year = year);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (values.length < 2)
              const SizedBox(
                height: 150,
                child: Center(child: Text('Insufficient Cycle Data')),
              )
            else
              SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(
                  key: const Key('monthly-efficiency-line-chart'),
                  painter: _EfficiencyChartPainter(values),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EfficiencyChartPainter extends CustomPainter {
  const _EfficiencyChartPainter(this.values);
  final List<MonthlyFuelEfficiency> values;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 28.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final rates = values.map((entry) => entry.kmPerL!).toList();
    var minimum = rates.first;
    var maximum = rates.first;
    for (final rate in rates.skip(1)) {
      if (rate < minimum) minimum = rate;
      if (rate > maximum) maximum = rate;
    }
    if (maximum == minimum) {
      maximum += 1;
      minimum -= 1;
    } else {
      final padding = (maximum - minimum) * 0.18;
      maximum += padding;
      minimum -= padding;
    }

    final grid = Paint()
      ..color = AppColors.surfaceRaised
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = top + chartHeight * index / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      _paintText(
        canvas,
        (maximum - (maximum - minimum) * index / 3).toStringAsFixed(1),
        Offset(0, y - 7),
        const TextStyle(color: AppColors.textMuted, fontSize: 9),
      );
    }

    Offset point(int index) {
      final x = left + chartWidth * index / (values.length - 1);
      final normalized = (rates[index] - minimum) / (maximum - minimum);
      return Offset(x, top + chartHeight * (1 - normalized));
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < values.length; index++) {
      path.lineTo(point(index).dx, point(index).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var index = 0; index < values.length; index++) {
      final valuePoint = point(index);
      canvas.drawCircle(valuePoint, 5, Paint()..color = AppColors.canvas);
      canvas.drawCircle(valuePoint, 3.5, Paint()..color = AppColors.primary);
      final month = const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][values[index].month - 1];
      _paintText(
        canvas,
        month,
        Offset(valuePoint.dx - 10, size.height - 18),
        const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _EfficiencyChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _MonthlySpendingList extends StatefulWidget {
  const _MonthlySpendingList({required this.values});
  final List<MonthlySpending> values;

  @override
  State<_MonthlySpendingList> createState() => _MonthlySpendingListState();
}

class _MonthlySpendingListState extends State<_MonthlySpendingList> {
  late int _year;

  List<int> get _years =>
      widget.values.map((entry) => entry.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _year = _years.first;
  }

  @override
  Widget build(BuildContext context) {
    final byMonth = {
      for (final entry in widget.values.where((entry) => entry.year == _year))
        entry.month: entry,
    };
    final months = List.generate(
      12,
      (index) =>
          byMonth[index + 1] ??
          MonthlySpending(
            year: _year,
            month: index + 1,
            fuelCostSen: 0,
            maintenanceCostSen: 0,
          ),
    );
    final maximum = months.fold<int>(
      1,
      (max, e) => e.totalCostSen > max ? e.totalCostSen : max,
    );
    var lastVisibleMonth = 6;
    for (final entry in months) {
      if (entry.totalCostSen > 0 && entry.month > lastVisibleMonth) {
        lastVisibleMonth = entry.month;
      }
    }
    final visibleMonths = months.take(lastVisibleMonth).toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fuel, service and repairs by month',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const Key('monthly-spending-year'),
                    value: _year,
                    isDense: true,
                    items: _years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (year) {
                      if (year != null) setState(() => _year = year);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _LegendDot(color: AppColors.primary, label: 'Fuel'),
                SizedBox(width: 18),
                _LegendDot(color: AppColors.teal, label: 'Service + repairs'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 172,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visibleMonths
                    .map(
                      (entry) => Expanded(
                        child: _MonthlyBar(entry: entry, maximum: maximum),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
    ],
  );
}

class _MonthlyBar extends StatelessWidget {
  const _MonthlyBar({required this.entry, required this.maximum});
  final MonthlySpending entry;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 116.0;
    final total = entry.totalCostSen;
    final totalHeight = total == 0 ? 2.0 : chartHeight * total / maximum;
    final fuelHeight = total == 0
        ? 0.0
        : totalHeight * entry.fuelCostSen / total;
    final maintenanceHeight = total == 0 ? 0.0 : totalHeight - fuelHeight;
    return Tooltip(
      message:
          '${_month(entry.year, entry.month)}\n'
          'Fuel ${formatRinggitFromSen(entry.fuelCostSen)}\n'
          'Service + repairs ${formatRinggitFromSen(entry.maintenanceCostSen)}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (total > 0)
            Text(
              'RM${(total / 100).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            )
          else
            const SizedBox(height: 11),
          const SizedBox(height: 4),
          SizedBox(
            height: chartHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  width: 26,
                  height: totalHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (maintenanceHeight > 0)
                        Container(
                          height: maintenanceHeight,
                          color: AppColors.teal,
                        ),
                      if (fuelHeight > 0)
                        Container(height: fuelHeight, color: AppColors.primary),
                      if (total == 0)
                        Container(height: 2, color: AppColors.surfaceRaised),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            const [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ][entry.month - 1],
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
    ),
  );
}

String _rate(double? value, String unit, {String prefix = ''}) {
  if (value == null) return '—';
  final start = prefix.isEmpty ? '' : '$prefix ';
  return '$start${value.toStringAsFixed(2)} $unit';
}

String _month(int year, int month) =>
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1]} $year';

Color _categoryColor(MaintenanceCategory category) => switch (category) {
  MaintenanceCategory.service => AppColors.teal,
  MaintenanceCategory.repairs => const Color(0xFF93B4FF),
  MaintenanceCategory.accessories => const Color(0xFFA855F7),
};

String _targetText(UpcomingServiceReminder target) {
  final parts = <String>[];
  if (target.targetDate case final date?) {
    parts.add(formatMaintenanceDate(date.toLocal()));
  }
  if (target.targetOdometerKm case final odometer?) {
    parts.add('${formatOdometerKm(odometer)} km');
  }
  return parts.join(' · ');
}
