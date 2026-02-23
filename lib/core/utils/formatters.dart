import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static String currency(double value) => _currency.format(value);

  /// Formato compacto para gráficos/labels (ex: R$ 1,2 mil | R$ 3,4 mi)
  static String compactCurrency(double value) => _compactCurrency.format(value);

  static final DateFormat _dateShort = DateFormat('dd/MM/yyyy');
  static String dateShort(DateTime date) => _dateShort.format(date);
}
