import 'number_utils.dart';

class Price {
  final String name;
  final String buy;
  final String sell;
  final String change;
  final String buyWithMargin;
  final String sellWithMargin;
  final String lastUpdate;

  Price({
    required this.name,
    required this.buy,
    required this.sell,
    required this.change,
    required this.buyWithMargin,
    required this.sellWithMargin,
    required this.lastUpdate,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      name: (json['name'] ?? json['key'] ?? '').toString(),
      buy: (json['buy'] ?? '').toString(),
      sell: (json['sell'] ?? '').toString(),
      change: (json['change'] ?? json['percent'] ?? '0').toString(),
      buyWithMargin:
          (json['buy_with_margin'] ?? json['buyWithMargin'] ?? json['buy'] ?? '')
              .toString(),
      sellWithMargin:
          (json['sell_with_margin'] ?? json['sellWithMargin'] ?? json['sell'] ?? '')
              .toString(),
      lastUpdate:
          (json['lastUpdate'] ?? json['last_update'] ?? json['date'] ?? '')
              .toString(),
    );
  }

  double get buyValue => parseNumericValue(buy);

  double get sellValue => parseNumericValue(sell);

  double get buyWithMarginValue => parseNumericValue(buyWithMargin);

  double get sellWithMarginValue => parseNumericValue(sellWithMargin);

  double get changeValue => parseNumericValue(change);
}
