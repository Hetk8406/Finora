class CurrencyModel {
  final String code;
  final String symbol;
  final String name;

  const CurrencyModel({
    required this.code,
    required this.symbol,
    required this.name,
  });

  String get displayName => "$symbol $code";

  static const List<CurrencyModel> all = [
    CurrencyModel(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyModel(code: 'USD', symbol: r'$', name: 'US Dollar'),
    CurrencyModel(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyModel(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyModel(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    CurrencyModel(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
    CurrencyModel(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar'),
    CurrencyModel(code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
    CurrencyModel(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyModel(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyModel(code: 'NZD', symbol: r'NZ$', name: 'New Zealand Dollar'),
  ];
}
