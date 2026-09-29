import 'package:flutter/material.dart';

import '../../domain/fuel/fuel_cycle.dart';
import '../theme/app_theme.dart';
import 'fuel_brand_assets.dart';
import 'fuel_formatters.dart';

typedef FuelHistoryLoader = Future<FuelCycleBuildResult> Function(
  int vehicleId,
);
typedef FuelFormBuilder = Widget Function(
  BuildContext context,
  VoidCallback saved,
);
typedef CycleDetailsBuilder = Widget Function(
  BuildContext context,
  CompletedFuelCycle cycle,
  int cycleNumber,
);
typedef FuelEventDetailsBuilder = Widget Function(
  BuildContext context,
  FuelEventSnapshot event,
);

class FuelHistoryScreen extends StatefulWidget {
  const FuelHistoryScreen({
    super.key,
    required this.vehicleId,
    required this.loadFuelHistory,
    this.fuelFormBuilder,
    this.cycleDetailsBuilder,
    this.fuelEventDetailsBuilder,
    this.readOnly = false,
  });

  final int vehicleId;
  final FuelHistoryLoader loadFuelHistory;
  final FuelFormBuilder? fuelFormBuilder;
  final CycleDetailsBuilder? cycleDetailsBuilder;
  final FuelEventDetailsBuilder? fuelEventDetailsBuilder;
  final bool readOnly;

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  late Future<FuelCycleBuildResult> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.loadFuelHistory(widget.vehicleId);
  }

  Future<void> _reload() async {
    final history = widget.loadFuelHistory(widget.vehicleId);
    setState(() {
      _history = history;
    });
    await history;
  }

  Future<void> _openFuelForm() async {
    final builder = widget.fuelFormBuilder;
    if (builder == null || widget.readOnly) return;
    var didSave = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => builder(context, () {
          didSave = true;
          Navigator.of(context).pop();
        }),
      ),
    );
    if (didSave && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel History')),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              key: const Key('add-fuel-event-fab'),
              onPressed: _openFuelForm,
              tooltip: 'Add Fuel Event',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              child: const Icon(Icons.add),
            ),
      body: FutureBuilder<FuelCycleBuildResult>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }
          return _FuelHistoryBody(
            result: snapshot.requireData,
            onRefresh: _reload,
            onCycleTap: _openCycle,
            onEventTap: _openEvent,
          );
        },
      ),
    );
  }

  Future<void> _openCycle(CompletedFuelCycle cycle, int number) async {
    final builder = widget.cycleDetailsBuilder;
    if (builder == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => builder(context, cycle, number)),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _openEvent(FuelEventSnapshot event) async {
    final builder = widget.fuelEventDetailsBuilder;
    if (builder == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => builder(context, event)),
    );
    if (changed == true && mounted) await _reload();
  }
}

class _FuelHistoryBody extends StatelessWidget {
  const _FuelHistoryBody({
    required this.result,
    required this.onRefresh,
    required this.onCycleTap,
    required this.onEventTap,
  });

  final FuelCycleBuildResult result;
  final Future<void> Function() onRefresh;
  final void Function(CompletedFuelCycle cycle, int number) onCycleTap;
  final void Function(FuelEventSnapshot event) onEventTap;

  @override
  Widget build(BuildContext context) {
    final reverseCycles = result.completedCycles.reversed.toList();
    final isEntirelyEmpty =
        result.completedCycles.isEmpty &&
        result.pendingCycle == null &&
        result.preReferenceEvents.isEmpty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('fuel-history-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (result.pendingCycle case final pending?) ...[
            _PendingCycleCard(pending: pending, onEventTap: onEventTap),
            const SizedBox(height: 28),
          ],
          if (result.preReferenceEvents.isNotEmpty &&
              result.pendingCycle == null) ...[
            _AwaitingStartingReferenceCard(
              events: result.preReferenceEvents,
              onEventTap: onEventTap,
            ),
            const SizedBox(height: 24),
          ],
          if (isEntirelyEmpty)
            const _EmptyFuelHistory()
          else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Completed cycles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                _CountChip(count: result.completedCycles.length),
              ],
            ),
            const SizedBox(height: 14),
            if (reverseCycles.isEmpty)
              const _NoCompletedCycles()
            else
              ...List.generate(reverseCycles.length, (index) {
                final cycle = reverseCycles[index];
                final cycleNumber = result.completedCycles.length - index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CompletedCycleCard(
                    cycle: cycle,
                    cycleNumber: cycleNumber,
                    onTap: () => onCycleTap(cycle, cycleNumber),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _PendingCycleCard extends StatelessWidget {
  const _PendingCycleCard({required this.pending, required this.onEventTap});

  final PendingFuelCycle pending;
  final void Function(FuelEventSnapshot event) onEventTap;

  @override
  Widget build(BuildContext context) {
    final partials = pending.replenishmentEvents.length;
    return Semantics(
      container: true,
      label: partials == 0
          ? 'Starting reference awaiting the next Full fuel event'
          : 'Pending fuel cycle with $partials partial fills',
      child: Card(
        key: const Key('pending-cycle-card'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const _FuelIconBox(),
          title: Text(
            partials == 0 ? 'Starting reference' : 'Pending cycle',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Started ${formatFuelDate(pending.openingFull.occurredAt.toLocal())}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: const _StatusChip(
            label: 'WAITING FOR FULL',
            color: Color(0xFFAFC6FF),
            background: Color(0xFF1C315E),
          ),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PendingMetric(
                    value: '${pending.openingFull.odometerKm}',
                    label: 'STARTED (KM)',
                  ),
                ),
                Expanded(
                  child: _PendingMetric(
                    value: '$partials',
                    label: 'PARTIAL FILLS',
                  ),
                ),
                const Expanded(
                  child: _PendingMetric(
                    value: 'Next Full',
                    label: 'CLOSES CYCLE',
                    accent: true,
                  ),
                ),
              ],
            ),
            if (partials > 0) ...[
              const SizedBox(height: 14),
              Text(
                '${formatLitresFromMillilitres(pending.accumulatedFuelMillilitres)} L · '
                '${formatRinggitFromSen(pending.accumulatedCostSen)} pending',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...pending.events.map(
              (event) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  event.isFullTank ? 'Start Full' : 'Not Full · Partial',
                ),
                subtitle: Text(
                  '${event.odometerKm} km · '
                  '${formatLitresFromMillilitres(event.fuelVolumeMillilitres)} L',
                ),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => onEventTap(event),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingMetric extends StatelessWidget {
  const _PendingMetric({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: accent ? const Color(0xFFAFC6FF) : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompletedCycleCard extends StatelessWidget {
  const _CompletedCycleCard({
    required this.cycle,
    required this.cycleNumber,
    required this.onTap,
  });

  final CompletedFuelCycle cycle;
  final int cycleNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = cycle.brandKind == FuelCycleBrandKind.mixed
        ? 'Mixed'
        : cycle.attributedBrand!;
    return Semantics(
      button: true,
      label:
          'Calculated fuel cycle $cycleNumber, $brand, '
          '${cycle.distanceKm} kilometres, '
          '${formatEfficiency(cycle.fuelEfficiencyKmPerL)} kilometres per litre',
      child: Card(
        key: Key('completed-cycle-$cycleNumber'),
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _BrandMark(brand: brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            formatFuelDate(
                              cycle.openingFull.occurredAt.toLocal(),
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'CYCLE COST',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatRinggitFromSen(cycle.fuelCostSen),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const _StatusChip(
                          label: 'CALCULATED',
                          color: AppColors.teal,
                          background: Color(0xFF173A3B),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CycleMetric(
                          label: 'DISTANCE',
                          value: '${cycle.distanceKm}',
                          unit: 'km',
                        ),
                      ),
                      Expanded(
                        child: _CycleMetric(
                          label: 'FUEL USED',
                          value: formatLitresFromMillilitres(
                            cycle.fuelConsumedMillilitres,
                          ),
                          unit: 'L',
                        ),
                      ),
                      Expanded(
                        child: _CycleMetric(
                          label: 'CONSUMPTION',
                          value: formatEfficiency(cycle.fuelEfficiencyKmPerL),
                          unit: cycle.fuelEfficiencyKmPerL == null
                              ? null
                              : 'km/L',
                          accent: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      cycle.replenishmentEvents.length == 1
                          ? '2 Fuel Events'
                          : '${cycle.events.length} Fuel Events merged',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleMetric extends StatelessWidget {
  const _CycleMetric({
    required this.label,
    required this.value,
    this.unit,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.teal : AppColors.textPrimary;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(color: color, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    final asset = FuelBrandAssets.forBrand(brand);
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(12),
      ),
      child: asset == null
          ? Center(
              child: Text(
                brand == 'Mixed' ? 'MX' : brand.characters.first,
                style: const TextStyle(
                  color: Color(0xFFAFC6FF),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FuelIconBox extends StatelessWidget {
  const _FuelIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.local_gas_station_outlined,
        color: AppColors.teal,
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count ${count == 1 ? 'cycle' : 'cycles'}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AwaitingStartingReferenceCard extends StatelessWidget {
  const _AwaitingStartingReferenceCard({
    required this.events,
    required this.onEventTap,
  });

  final List<FuelEventSnapshot> events;
  final void Function(FuelEventSnapshot event) onEventTap;

  @override
  Widget build(BuildContext context) {
    final eventCount = events.length;
    return Card(
      key: const Key('awaiting-starting-reference-card'),
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: const _FuelIconBox(),
        title: const Text(
          'Waiting for a Full reference',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$eventCount ${eventCount == 1 ? 'event was' : 'events were'} recorded '
          'before the first Full tank.',
        ),
        children: events
            .map(
              (event) => ListTile(
                title: Text('${event.fuelBrand} · Not Full'),
                subtitle: Text('${event.odometerKm} km'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => onEventTap(event),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyFuelHistory extends StatelessWidget {
  const _EmptyFuelHistory();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No Fuel Cycles Recorded. Add a fuel event to begin tracking.',
      child: Card(
        key: const Key('fuel-history-empty-state'),
        margin: const EdgeInsets.only(top: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceStrong,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_gas_station_outlined,
                  color: AppColors.teal,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Fuel Cycles Recorded',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add a fuel event to begin. Completed statistics appear after '
                'a Full-to-Full cycle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoCompletedCycles extends StatelessWidget {
  const _NoCompletedCycles();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('no-completed-cycles'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Your next Full fuel event will complete the first measurable cycle.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('fuel-history-loading-state'),
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('fuel-history-error-state'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: 14),
            const Text(
              'Fuel history could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your records have not been changed. Try loading them again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
