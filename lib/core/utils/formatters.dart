import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static String currency(double value) => _currency.format(value);

  static final DateFormat _dateShort = DateFormat('dd/MM/yyyy');
  static String dateShort(DateTime date) => _dateShort.format(date);
}
