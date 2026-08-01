import 'package:flutter/services.dart';

/// Formata automaticamente CNPJ no padrão: 00.000.000/0000-00
/// Aceita somente dígitos e limita em 14.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (digits.length > 14) digits = digits.substring(0, 14);

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) buffer.write('.');
      if (i == 4 && digits.length > 5) buffer.write('.');
      if (i == 7 && digits.length > 8) buffer.write('/');
      if (i == 11 && digits.length > 12) buffer.write('-');
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
