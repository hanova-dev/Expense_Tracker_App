import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({required this.code, required this.symbol, required this.name});
}

class CurrencyService {
  static const List<Currency> supportedCurrencies = [
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    Currency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    Currency(code: 'CAD', symbol: '\$', name: 'Canadian Dollar'),
    Currency(code: 'AUD', symbol: '\$', name: 'Australian Dollar'),
    Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  ];

  // Hardcoded exchange rates relative to USD (Base) for MVP
  static const Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'PKR': 278.50,
    'EUR': 0.92,
    'GBP': 0.79,
    'AED': 3.67,
    'SAR': 3.75,
    'INR': 83.30,
    'CAD': 1.37,
    'AUD': 1.52,
    'TRY': 32.30,
    'CNY': 7.24,
    'JPY': 153.20,
    'CHF': 0.91,
    'BDT': 109.50,
    'MYR': 4.77,
  };

  static String _globalCurrencyCode = 'USD';

  static Future<void> init() async {
    final box = await Hive.openBox('settings');
    _globalCurrencyCode = box.get('globalCurrency', defaultValue: 'USD');
  }

  static Future<void> setGlobalCurrency(String code) async {
    final box = Hive.box('settings');
    await box.put('globalCurrency', code);
    _globalCurrencyCode = code;
  }

  static String get globalCurrencyCode => _globalCurrencyCode;

  static Currency get globalCurrency => supportedCurrencies.firstWhere(
        (c) => c.code == _globalCurrencyCode,
        orElse: () => supportedCurrencies.first,
      );

  static Currency getCurrency(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );
  }

  /// Converts amount from the original currency to the target currency
  static double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = _exchangeRates[fromCurrency] ?? 1.0;
    final toRate = _exchangeRates[toCurrency] ?? 1.0;

    // Convert from origin to USD, then from USD to target
    final amountInUsd = amount / fromRate;
    return amountInUsd * toRate;
  }

  /// Formats the given amount to the specified currency string (or global if null)
  static String format(double amount, [String? currencyCode]) {
    final targetCode = currencyCode ?? _globalCurrencyCode;
    final currency = getCurrency(targetCode);

    final formatter = NumberFormat.currency(
      symbol: '${currency.symbol} ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

final globalCurrencyProvider = StateProvider<String>((ref) {
  return CurrencyService.globalCurrencyCode;
});
