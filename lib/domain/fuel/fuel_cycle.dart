enum FuelCycleBrandKind { singleBrand, mixed }

class FuelEventSnapshot {
  const FuelEventSnapshot({
    required this.id,
    required this.vehicleId,
    required this.occurredAt,
    required this.odometerKm,
    required this.fuelBrand,
    required this.fuelVolumeMillilitres,
    required this.costSen,
    required this.isFullTank,
    this.tripDistanceMetres,
  });

  final int id;
  final int vehicleId;
  final DateTime occurredAt;
  final int odometerKm;
  final String fuelBrand;
  final int fuelVolumeMillilitres;
  final int costSen;
  final bool isFullTank;
  final int? tripDistanceMetres;
}

class CompletedFuelCycle {
  const CompletedFuelCycle({
    required this.openingFull,
    required this.closingFull,
    required this.events,
    required this.distanceKm,
    required this.fuelConsumedMillilitres,
    required this.fuelCostSen,
    required this.brandKind,
    required this.attributedBrand,
  });

  final FuelEventSnapshot openingFull;
  final FuelEventSnapshot closingFull;

  /// Includes the opening Full, intermediate Not Full events, and closing Full.
  final List<FuelEventSnapshot> events;
  final int distanceKm;
  final int fuelConsumedMillilitres;
  final int fuelCostSen;
  final FuelCycleBrandKind brandKind;
  final String? attributedBrand;

  double? get fuelEfficiencyKmPerL {
    if (distanceKm == 0) return null;
    return distanceKm * 1000 / fuelConsumedMillilitres;
  }

  double? get costRinggitPerKm {
    if (distanceKm == 0) return null;
    return fuelCostSen / 100 / distanceKm;
  }

  List<FuelEventSnapshot> get replenishmentEvents =>
      List.unmodifiable(events.skip(1));
}

class PendingFuelCycle {
  const PendingFuelCycle({required this.openingFull, required this.events});

  final FuelEventSnapshot openingFull;

  /// Includes the opening Full followed by every unresolved Not Full event.
  final List<FuelEventSnapshot> events;

  List<FuelEventSnapshot> get replenishmentEvents =>
      List.unmodifiable(events.skip(1));

  int get accumulatedFuelMillilitres => replenishmentEvents.fold(
    0,
    (total, event) => total + event.fuelVolumeMillilitres,
  );

  int get accumulatedCostSen =>
      replenishmentEvents.fold(0, (total, event) => total + event.costSen);
}

class FuelCycleBuildResult {
  const FuelCycleBuildResult({
    required this.completedCycles,
    required this.pendingCycle,
    required this.preReferenceEvents,
  });

  final List<CompletedFuelCycle> completedCycles;
  final PendingFuelCycle? pendingCycle;

  /// Events before the first Full reference are retained but not calculated.
  final List<FuelEventSnapshot> preReferenceEvents;
}

class FuelCycleException implements Exception {
  const FuelCycleException(this.message);

  final String message;

  @override
  String toString() => 'FuelCycleException: $message';
}

class FuelCycleEngine {
  const FuelCycleEngine();

  FuelCycleBuildResult build(Iterable<FuelEventSnapshot> sourceEvents) {
    final events = sourceEvents.toList()
      ..sort((left, right) {
        final byOccurrence = left.occurredAt.compareTo(right.occurredAt);
        return byOccurrence != 0 ? byOccurrence : left.id.compareTo(right.id);
      });

    _ensureSingleVehicle(events);

    final completed = <CompletedFuelCycle>[];
    final preReference = <FuelEventSnapshot>[];
    FuelEventSnapshot? openingFull;
    var activeEvents = <FuelEventSnapshot>[];

    for (final event in events) {
      if (openingFull == null) {
        if (!event.isFullTank) {
          preReference.add(event);
          continue;
        }

        openingFull = event;
        activeEvents = [event];
        continue;
      }

      activeEvents.add(event);
      if (!event.isFullTank) continue;

      completed.add(_complete(openingFull, event, activeEvents));
      openingFull = event;
      activeEvents = [event];
    }

    return FuelCycleBuildResult(
      completedCycles: List.unmodifiable(completed),
      pendingCycle: openingFull == null
          ? null
          : PendingFuelCycle(
              openingFull: openingFull,
              events: List.unmodifiable(activeEvents),
            ),
      preReferenceEvents: List.unmodifiable(preReference),
    );
  }

  CompletedFuelCycle _complete(
    FuelEventSnapshot opening,
    FuelEventSnapshot closing,
    List<FuelEventSnapshot> cycleEvents,
  ) {
    final distance = closing.odometerKm - opening.odometerKm;
    if (distance < 0) {
      throw FuelCycleException(
        'Closing Full odometer ${closing.odometerKm} km is below opening '
        'Full odometer ${opening.odometerKm} km.',
      );
    }

    final replenishments = cycleEvents.skip(1);
    final fuelVolume = replenishments.fold(
      0,
      (total, event) => total + event.fuelVolumeMillilitres,
    );
    final fuelCost = replenishments.fold(
      0,
      (total, event) => total + event.costSen,
    );
    final intermediateBrands = cycleEvents
        .skip(1)
        .take(cycleEvents.length - 2)
        .map((event) => event.fuelBrand);
    final isMixed = intermediateBrands.any(
      (brand) => brand != opening.fuelBrand,
    );

    return CompletedFuelCycle(
      openingFull: opening,
      closingFull: closing,
      events: List.unmodifiable(cycleEvents),
      distanceKm: distance,
      fuelConsumedMillilitres: fuelVolume,
      fuelCostSen: fuelCost,
      brandKind: isMixed
          ? FuelCycleBrandKind.mixed
          : FuelCycleBrandKind.singleBrand,
      attributedBrand: isMixed ? null : opening.fuelBrand,
    );
  }

  void _ensureSingleVehicle(List<FuelEventSnapshot> events) {
    if (events.isEmpty) return;
    final vehicleId = events.first.vehicleId;
    if (events.any((event) => event.vehicleId != vehicleId)) {
      throw const FuelCycleException(
        'Fuel cycles cannot combine events from different vehicles.',
      );
    }
  }
}
