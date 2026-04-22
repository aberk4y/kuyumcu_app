import 'number_utils.dart';

class Currency {
  final String code;
  final String buy;
  final String sell;

  Currency({
    required this.code,
    required this.buy,
    required this.sell,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: (json['code'] ?? '').toString(),
      buy: (json['buy'] ?? '').toString(),
      sell: (json['sell'] ?? '').toString(),
    );
  }

  double get buyValue => parseNumericValue(buy);

  double get sellValue => parseNumericValue(sell);

  String get displayName {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'Amerikan Doları';
      case 'EUR':
        return 'Avrupa Birimi';
      case 'GBP':
        return 'İngiliz Sterlini';
      case 'TRY':
        return 'Türk Lirası';
      default:
        return code;
    }
  }
}
