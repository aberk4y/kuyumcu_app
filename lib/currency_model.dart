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
      code: json["code"],
      buy: json["buy"],
      sell: json["sell"],
    );

  }

}