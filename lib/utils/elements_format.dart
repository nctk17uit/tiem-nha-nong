import 'package:intl/intl.dart';

class PriceFormatter {
  // Caching the formatter is good for performance
  static final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");

  static String format(num value, {String suffix = " đ"}) {
    return "${_formatter.format(value)}$suffix";
  }
}
