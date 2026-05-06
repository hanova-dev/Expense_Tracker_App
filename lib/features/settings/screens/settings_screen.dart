import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/currency_service.dart';
import '../models/budget_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final globalCurrency = ref.watch(globalCurrencyProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          ListTile(
            title: const Text('Global Currency'),
            subtitle: Text('Current: $globalCurrency'),
            leading: const Icon(Icons.attach_money),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCurrencyPicker(context, ref);
            },
          ),
          const Divider(),
          
          ListTile(
            title: const Text('Monthly Budget'),
            subtitle: const Text('Set overall monthly limit'),
            leading: const Icon(Icons.track_changes),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showBudgetDialog(context);
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          children: CurrencyService.supportedCurrencies.map((c) {
            return ListTile(
              title: Text('${c.code} - ${c.name}'),
              trailing: Text(c.symbol),
              onTap: () async {
                await CurrencyService.setGlobalCurrency(c.code);
                ref.read(globalCurrencyProvider.notifier).state = c.code;
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final box = Hive.box<Budget>('budgets');
    final currentBudget = box.get('Total')?.amount ?? 0.0;
    final controller = TextEditingController(text: currentBudget > 0 ? currentBudget.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0.0;
                if (amount > 0) {
                  box.put('Total', Budget(category: 'Total', amount: amount));
                } else {
                  box.delete('Total');
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
