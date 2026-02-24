class Price {
  final String name;
  final String buy;
  final String sell;
  final String change;
  final String buyWithMargin;
  final String sellWithMargin;

  Price({
    required this.name,
    required this.buy,
    required this.sell,
    required this.change,
    required this.buyWithMargin,
    required this.sellWithMargin,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      name: json['key'] ?? "",
      buy: json['buy'] ?? "",
      sell: json['sell'] ?? "",
      change: json['percent'] ?? "",
      buyWithMargin: json['buy_with_margin'] ?? json['buy'] ?? "",
      sellWithMargin: json['sell_with_margin'] ?? json['sell'] ?? "",
    );
  }
}