import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/currency_service.dart';
import 'core/theme_provider.dart';
import 'features/expenses/models/expense_model.dart';
import 'features/settings/models/budget_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(BudgetAdapter());

  await Hive.openBox('settings');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Budget>('budgets');

  await CurrencyService.init();

  runApp(const ProviderScope(child: MyApp()));
}

// ConsumerWidget so it can reactively follow the persisted ThemeMode
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'SmartWallet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
