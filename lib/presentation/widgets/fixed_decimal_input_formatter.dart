import 'package:flutter/services.dart';

class FixedDecimalInputFormatter extends TextInputFormatter {
  const FixedDecimalInputFormatter({this.decimalPlaces = 2});

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';

    final padded = digits.padLeft(decimalPlaces + 1, '0');
    final split = padded.length - decimalPlaces;
    final formatted = decimalPlaces == 0
        ? padded
        : '${padded.substring(0, split)}.${padded.substring(split)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
