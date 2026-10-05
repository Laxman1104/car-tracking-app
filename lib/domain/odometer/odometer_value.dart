double? parseOdometerKm(String input) {
  final value = int.tryParse(input.trim());
  return value?.toDouble();
}

String formatOdometerKm(num value, {bool grouped = true}) {
  final whole = value.round().toString();
  return grouped
      ? whole.replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        )
      : whole;
}
