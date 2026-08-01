import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Keep only digits
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) digits = '0';

    // Parse cents
    double value = double.parse(digits) / 100;
    final newText = _formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
