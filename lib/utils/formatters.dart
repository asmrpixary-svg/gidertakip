import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final DateFormat dateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy', 'tr_TR');
  static final DateFormat dayMonthFormat = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR');

  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
}
