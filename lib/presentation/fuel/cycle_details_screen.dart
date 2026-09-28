import 'package:flutter/material.dart';

import '../../domain/fuel/fuel_cycle.dart';
import '../theme/app_theme.dart';
import 'fuel_brand_assets.dart';
import 'fuel_formatters.dart';

class CycleDetailsScreen extends StatelessWidget {
  const CycleDetailsScreen({
    super.key,
    required this.cycle,
    required this.cycleNumber,
  });

  final CompletedFuelCycle cycle;
  final int cycleNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Details')),
      body: ListView(
        key: const Key('cycle-details-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusHeader(cycleNumber: cycleNumber),
          const SizedBox(height: 18),
          _CycleSummary(cycle: cycle),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fuel Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${cycle.events.length} events · CHRONOLOGICAL',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(cycle.events.length, (index) {
            final event = cycle.events[index];
            return _FuelEventTimelineRow(
              event: event,
              role: index == 0
                  ? 'Start Full'
                  : index == cycle.events.length - 1
                  ? 'End Full · Closing'
                  : 'Not Full · Partial',
              isOpeningBoundary: index == 0,
              isLast: index == cycle.events.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.cycleNumber});

  final int cycleNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.teal, size: 20),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'COMPLETED CYCLE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Cycle #$cycleNumber',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleSummary extends StatelessWidget {
  const _CycleSummary({required this.cycle});

  final CompletedFuelCycle cycle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Cycle summary. ${cycle.distanceKm} kilometres, '
          '${formatLitresFromMillilitres(cycle.fuelConsumedMillilitres)} litres, '
          '${formatEfficiency(cycle.fuelEfficiencyKmPerL)} kilometres per litre, '
          '${formatRinggitFromSen(cycle.fuelCostSen)}.',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatFuelDate(cycle.openingFull.occurredAt.toLocal())} – '
                '${formatFuelDate(cycle.closingFull.occurredAt.toLocal())}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Range: ${cycle.openingFull.odometerKm} km → '
                  '${cycle.closingFull.odometerKm} km',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'DISTANCE',
                      value: '${cycle.distanceKm}',
                      unit: 'km',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'FUEL USED',
                      value: formatLitresFromMillilitres(
                        cycle.fuelConsumedMillilitres,
                      ),
                      unit: 'L',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      key: const Key('cycle-efficiency-metric'),
                      label: 'CONSUMPTION',
                      value: formatEfficiency(cycle.fuelEfficiencyKmPerL),
                      unit: cycle.fuelEfficiencyKmPerL == null ? null : 'km/L',
                      accent: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'CYCLE COST',
                      value: formatRinggitFromSen(cycle.fuelCostSen),
                      supporting:
                          '${formatCostPerKm(cycle.costRinggitPerKm)} / km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                key: const Key('cycle-totals-explanation'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The Start Full establishes the opening fuel level. '
                        'Cycle totals include fuel added after it through the '
                        'End Full.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.supporting,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? unit;
  final String? supporting;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final valueColor = accent ? AppColors.teal : AppColors.textPrimary;
    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(color: valueColor, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          if (supporting != null) ...[
            const SizedBox(height: 4),
            Text(
              supporting!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _FuelEventTimelineRow extends StatelessWidget {
  const _FuelEventTimelineRow({
    required this.event,
    required this.role,
    required this.isOpeningBoundary,
    required this.isLast,
  });

  final FuelEventSnapshot event;
  final String role;
  final bool isOpeningBoundary;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final asset = FuelBrandAssets.forBrand(event.fuelBrand);
    return Semantics(
      container: true,
      label:
          '$role, ${event.fuelBrand}, ${event.odometerKm} kilometres, '
          '${formatLitresFromMillilitres(event.fuelVolumeMillilitres)} litres, '
          '${formatRinggitFromSen(event.costSen)}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceStrong,
                      shape: BoxShape.circle,
                    ),
                    child: asset == null
                        ? const Icon(Icons.local_gas_station_outlined, size: 18)
                        : Image.asset(asset, fit: BoxFit.contain),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppColors.border),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                key: Key('cycle-event-${event.id}'),
                margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.fuelBrand,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: role.startsWith('Not Full')
                                  ? const Color(0xFF3A3020)
                                  : const Color(0xFF1C315E),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOpeningBoundary) ...[
                                  const Icon(
                                    Icons.info_outline,
                                    key: Key('start-full-info-icon'),
                                    color: Color(0xFFAFC6FF),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  role,
                                  style: TextStyle(
                                    color: role.startsWith('Not Full')
                                        ? AppColors.warning
                                        : const Color(0xFFAFC6FF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatFuelDateTime(event.occurredAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _EventValue(
                                label: 'ODOMETER',
                                value: '${event.odometerKm} km',
                              ),
                            ),
                            Expanded(
                              child: _EventValue(
                                label: 'FUEL & COST',
                                value:
                                    '${formatLitresFromMillilitres(event.fuelVolumeMillilitres)} L · '
                                    '${formatRinggitFromSen(event.costSen)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventValue extends StatelessWidget {
  const _EventValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
