enum OdometerSource { fuel, maintenance }

class OdometerObservationKey implements Comparable<OdometerObservationKey> {
  const OdometerObservationKey(this.source, this.recordId);

  final OdometerSource source;
  final int recordId;

  @override
  int compareTo(OdometerObservationKey other) {
    final bySource = source.index.compareTo(other.source.index);
    return bySource != 0 ? bySource : recordId.compareTo(other.recordId);
  }

  @override
  bool operator ==(Object other) =>
      other is OdometerObservationKey &&
      source == other.source &&
      recordId == other.recordId;

  @override
  int get hashCode => Object.hash(source, recordId);
}

class OdometerObservation {
  const OdometerObservation({
    required this.key,
    required this.vehicleId,
    required this.occurredAt,
    required this.odometerKm,
  });

  final OdometerObservationKey key;
  final int vehicleId;
  final DateTime occurredAt;
  final int odometerKm;
}

enum OdometerValidationIssue {
  differentVehicle,
  belowPreviousReading,
  aboveNextReading,
}

class OdometerValidationResult {
  const OdometerValidationResult({
    required this.issues,
    required this.previous,
    required this.next,
  });

  final Set<OdometerValidationIssue> issues;
  final OdometerObservation? previous;
  final OdometerObservation? next;

  bool get isValid => issues.isEmpty;
}

class OdometerTimelineException implements Exception {
  const OdometerTimelineException(this.message);

  final String message;

  @override
  String toString() => 'OdometerTimelineException: $message';
}

class OdometerTimelineEngine {
  const OdometerTimelineEngine();

  List<OdometerObservation> chronological(
    Iterable<OdometerObservation> observations,
  ) {
    final sorted = observations.toList()..sort(_compare);
    _ensureSingleVehicle(sorted);
    return List.unmodifiable(sorted);
  }

  OdometerObservation? resolveCurrent(
    Iterable<OdometerObservation> observations,
  ) {
    final sorted = chronological(observations);
    return sorted.isEmpty ? null : sorted.last;
  }

  OdometerValidationResult validateInsert({
    required OdometerObservation candidate,
    required Iterable<OdometerObservation> existing,
  }) {
    return _validate(candidate: candidate, existing: existing);
  }

  OdometerValidationResult validateEdit({
    required OdometerObservation candidate,
    required Iterable<OdometerObservation> existing,
  }) {
    return _validate(
      candidate: candidate,
      existing: existing.where((entry) => entry.key != candidate.key),
    );
  }

  OdometerValidationResult _validate({
    required OdometerObservation candidate,
    required Iterable<OdometerObservation> existing,
  }) {
    final entries = existing.toList();
    final issues = <OdometerValidationIssue>{};
    if (entries.any((entry) => entry.vehicleId != candidate.vehicleId)) {
      issues.add(OdometerValidationIssue.differentVehicle);
      return OdometerValidationResult(
        issues: Set.unmodifiable(issues),
        previous: null,
        next: null,
      );
    }

    entries.sort(_compare);
    final insertionIndex = entries.indexWhere(
      (entry) => _compare(candidate, entry) < 0,
    );
    final resolvedIndex = insertionIndex == -1
        ? entries.length
        : insertionIndex;
    final previous = resolvedIndex == 0 ? null : entries[resolvedIndex - 1];
    final next = resolvedIndex == entries.length
        ? null
        : entries[resolvedIndex];

    if (previous != null && candidate.odometerKm < previous.odometerKm) {
      issues.add(OdometerValidationIssue.belowPreviousReading);
    }
    if (next != null && candidate.odometerKm > next.odometerKm) {
      issues.add(OdometerValidationIssue.aboveNextReading);
    }

    return OdometerValidationResult(
      issues: Set.unmodifiable(issues),
      previous: previous,
      next: next,
    );
  }

  int _compare(OdometerObservation left, OdometerObservation right) {
    final byOccurrence = left.occurredAt.compareTo(right.occurredAt);
    return byOccurrence != 0 ? byOccurrence : left.key.compareTo(right.key);
  }

  void _ensureSingleVehicle(List<OdometerObservation> observations) {
    if (observations.isEmpty) return;
    final vehicleId = observations.first.vehicleId;
    if (observations.any((entry) => entry.vehicleId != vehicleId)) {
      throw const OdometerTimelineException(
        'An odometer timeline cannot combine different vehicles.',
      );
    }
  }
}
