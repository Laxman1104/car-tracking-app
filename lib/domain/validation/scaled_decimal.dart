class ScaledDecimalParser {
  const ScaledDecimalParser._();

  /// Parses a non-negative decimal without using binary floating-point maths.
  ///
  /// Returns null for malformed values, values with too many decimal places,
  /// negative values, or values that do not fit in a Dart [int].
  static int? parse(String input, {required int fractionDigits}) {
    if (fractionDigits < 0) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'Must not be negative.',
      );
    }

    final normalized = input.trim();
    final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(normalized);
    if (match == null) return null;

    final fraction = match.group(2) ?? '';
    if (fraction.length > fractionDigits) return null;

    final paddedFraction = fraction.padRight(fractionDigits, '0');
    final combined = '${match.group(1)}$paddedFraction';
    return int.tryParse(combined);
  }
}
