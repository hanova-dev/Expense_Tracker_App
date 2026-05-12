import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/currency_service.dart';
import '../../../core/theme_provider.dart';
import '../models/budget_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Track current budget value for live display in the tile
  double _currentBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _currentBudget =
        Hive.box<Budget>('budgets').get('Total')?.amount ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final globalCurrency = ref.watch(globalCurrencyProvider);
    final themeMode = ref.watch(themeModeProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Preferences & configuration',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.settings_rounded,
                        color: theme.colorScheme.primary, size: 24),
                  ),
                ],
              ),
            ),
          ),

          // ── App logo card ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _AppLogoCard(isDark: isDark, theme: theme),
            ),
          ),

          // ── Appearance section ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _SectionHeader(label: 'Appearance', isDark: isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _SettingsCard(
                isDark: isDark,
                children: [
                  // Theme mode picker row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SettingIcon(
                              icon: Icons.contrast_rounded,
                              color: const Color(0xFF9B72CF),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Theme Mode',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              theme.colorScheme.onSurface)),
                                  Text('Choose your preferred look',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.45))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Segmented selector
                        Row(
                          children: [
                            _ThemeModeBtn(
                              label: 'System',
                              icon: Icons.brightness_auto_rounded,
                              selected: themeMode == ThemeMode.system,
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(ThemeMode.system),
                              isDark: isDark,
                              accent: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            _ThemeModeBtn(
                              label: 'Light',
                              icon: Icons.light_mode_rounded,
                              selected: themeMode == ThemeMode.light,
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(ThemeMode.light),
                              isDark: isDark,
                              accent: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            _ThemeModeBtn(
                              label: 'Dark',
                              icon: Icons.dark_mode_rounded,
                              selected: themeMode == ThemeMode.dark,
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(ThemeMode.dark),
                              isDark: isDark,
                              accent: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Preferences section ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _SectionHeader(label: 'Preferences', isDark: isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _SettingsCard(
                isDark: isDark,
                children: [
                  // Currency
                  _SettingsTile(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: const Color(0xFF5B8DEF),
                    title: 'Global Currency',
                    subtitle: globalCurrency,
                    isDark: isDark,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            CurrencyService.getCurrency(globalCurrency)
                                .symbol,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                            size: 20),
                      ],
                    ),
                    onTap: () => _showCurrencyPicker(context, ref),
                  ),
                  Divider(
                      height: 1,
                      indent: 56,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.07)),
                  // Monthly budget
                  _SettingsTile(
                    icon: Icons.track_changes_rounded,
                    iconColor: const Color(0xFF00BFA5),
                    title: 'Monthly Budget',
                    subtitle: _currentBudget > 0
                        ? CurrencyService.format(_currentBudget)
                        : 'Not set',
                    isDark: isDark,
                    trailing: Icon(Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        size: 20),
                    onTap: () => _showBudgetDialog(context),
                  ),
                ],
              ),
            ),
          ),

          // ── About section ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _SectionHeader(label: 'About', isDark: isDark),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              child: _SettingsCard(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF8A9BB0),
                    title: 'Version',
                    subtitle: '1.0.0 · SmartWallet',
                    isDark: isDark,
                    trailing: null,
                    onTap: null,
                  ),
                  Divider(
                      height: 1,
                      indent: 56,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.07)),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF8A9BB0),
                    title: 'Privacy',
                    subtitle: 'All data stored locally on device',
                    isDark: isDark,
                    trailing: null,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Currency picker bottom sheet ──────────────────────────────────────────
  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text('Select Currency',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
              Divider(height: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.07)),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: CurrencyService.supportedCurrencies.map((c) {
                    final isSelected =
                        c.code == ref.read(globalCurrencyProvider);
                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(c.symbol,
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface)),
                      ),
                      title: Text('${c.code} — ${c.name}',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: theme.colorScheme.primary, size: 20)
                          : null,
                      onTap: () async {
                        await CurrencyService.setGlobalCurrency(c.code);
                        ref.read(globalCurrencyProvider.notifier).state =
                            c.code;
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Budget dialog ─────────────────────────────────────────────────────────
  void _showBudgetDialog(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box<Budget>('budgets');
    final ctrl = TextEditingController(
        text: _currentBudget > 0 ? _currentBudget.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Monthly Budget',
            style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: 'e.g. 50000',
            prefixIcon: const Icon(Icons.attach_money_rounded),
            suffixText: ref.read(globalCurrencyProvider),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final amount = double.tryParse(ctrl.text) ?? 0.0;
              if (amount > 0) {
                box.put(
                    'Total', Budget(category: 'Total', amount: amount));
                setState(() => _currentBudget = amount);
              } else {
                box.delete('Total');
                setState(() => _currentBudget = 0.0);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── App logo header card ──────────────────────────────────────────────────────

class _AppLogoCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _AppLogoCard({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SmartWallet',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4)),
              Text('Personal Finance Manager',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section header label ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── Settings card container ───────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Individual settings tile ──────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _SettingIcon(icon: icon, color: iconColor, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ── Coloured setting icon box ─────────────────────────────────────────────────

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SettingIcon(
      {required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ── Theme mode button ─────────────────────────────────────────────────────────

class _ThemeModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color accent;

  const _ThemeModeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(
                  color: accent.withValues(alpha: 0.5), width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected
                        ? accent
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4)),
                const SizedBox(height: 4),
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected
                          ? accent
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
