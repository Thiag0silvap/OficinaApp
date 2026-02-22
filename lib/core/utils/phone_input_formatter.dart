import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // Limit to 11 digits (DDD + 9-digit number)
    if (digits.length > 11) digits = digits.substring(0, 11);

    String formatted;
    if (digits.length <= 2) {
      formatted = '($digits';
    } else if (digits.length <= 6) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.length <= 10) {
      // (xx) xxxx-xxxx
      final part1 = digits.substring(0, 2);
      final part2 = digits.substring(2, 6);
      final part3 = digits.substring(6);
      formatted = '($part1) $part2-$part3';
    } else {
      // 11 digits -> (xx) xxxxx-xxxx
      final part1 = digits.substring(0, 2);
      final part2 = digits.substring(2, 7);
      final part3 = digits.substring(7);
      formatted = '($part1) $part2-$part3';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
