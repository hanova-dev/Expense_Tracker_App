import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../core/currency_service.dart';
import '../providers/analytics_provider.dart';

// ── Semantic colours ──────────────────────────────────────────────────────────
const _kIncome = Color(0xFF4CAF50);
const _kExpense = Color(0xFFEF5350);

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryBreakdown = ref.watch(categoryBreakdownProvider);
    final dailySpending = ref.watch(dailySpendingProvider);
    final monthlySpending = ref.watch(monthlySpendingProvider);
    final totalExpenses = ref.watch(totalThisMonthProvider);
    final totalIncome = ref.watch(totalIncomeThisMonthProvider);

    // Derived stats
    final topCategory = categoryBreakdown.isEmpty
        ? null
        : categoryBreakdown.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
    final avgDaily = dailySpending.isEmpty
        ? 0.0
        : dailySpending.values.reduce((a, b) => a + b) /
            dailySpending.length;

    return FadeTransition(
      opacity: _fade,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Page header ────────────────────────────────────────────────
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
                            'Analytics',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'This month at a glance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
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
                      child: Icon(Icons.bar_chart_rounded,
                          color: theme.colorScheme.primary, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick-stat chips ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Income',
                      value: CurrencyService.format(totalIncome),
                      color: _kIncome,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Expenses',
                      value: CurrencyService.format(totalExpenses),
                      color: _kExpense,
                      icon: Icons.arrow_upward_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Avg/Day',
                      value: CurrencyService.format(avgDaily),
                      color: theme.colorScheme.primary,
                      icon: Icons.today_rounded,
                    ),
                  ],
                ),
              ),
            ),

            // ── Pie chart card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SectionCard(
                  title: 'By Category',
                  subtitle: topCategory != null
                      ? 'Top: $topCategory'
                      : 'No data',
                  icon: Icons.pie_chart_rounded,
                  isDark: isDark,
                  child: categoryBreakdown.isEmpty
                      ? _EmptyChart(
                          message: 'No expense data this month',
                          isDark: isDark,
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 56,
                                  sections: _buildPieSections(
                                      categoryBreakdown, theme),
                                  pieTouchData: PieTouchData(enabled: false),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ── Legend ────────────────────────────────
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categoryBreakdown.entries.map((e) {
                                final color =
                                    AppConstants.categoryColors[e.key] ??
                                        Colors.grey;
                                final pct = (e.value /
                                        categoryBreakdown.values
                                            .reduce((a, b) => a + b) *
                                        100)
                                    .toStringAsFixed(1);
                                return _LegendChip(
                                  label: e.key,
                                  percent: '$pct%',
                                  color: color,
                                  isDark: isDark,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // ── Bar chart card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SectionCard(
                  title: 'Daily Spending',
                  subtitle: 'Expense bars · this month',
                  icon: Icons.bar_chart_rounded,
                  isDark: isDark,
                  child: dailySpending.isEmpty
                      ? _EmptyChart(
                          message: 'No daily data this month',
                          isDark: isDark,
                        )
                      : SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (dailySpending.values.reduce(
                                          (a, b) => a > b ? a : b) *
                                      1.25)
                                  .ceilToDouble(),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) =>
                                      isDark
                                          ? const Color(0xFF2A2A3A)
                                          : const Color(0xFF1A1A2E),
                                  getTooltipItem:
                                      (group, gi, rod, ri) =>
                                          BarTooltipItem(
                                    CurrencyService.format(rod.toY),
                                    GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (val, meta) => Padding(
                                      padding:
                                          const EdgeInsets.only(top: 6),
                                      child: Text(
                                        val.toInt().toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: null,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.06),
                                  strokeWidth: 1,
                                ),
                              ),
                              barGroups: dailySpending.entries.map((e) {
                                return BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value,
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          theme.colorScheme.primary
                                              .withValues(alpha: 0.6),
                                          theme.colorScheme.primary,
                                        ],
                                      ),
                                      width: 10,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(6)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // ── Monthly trend card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: _SectionCard(
                  title: '6-Month Trend',
                  subtitle: 'Total expense per month',
                  icon: Icons.trending_up_rounded,
                  isDark: isDark,
                  child: monthlySpending.isEmpty
                      ? _EmptyChart(
                          message: 'Not enough history yet',
                          isDark: isDark,
                        )
                      : Column(
                          children: monthlySpending.map((entry) {
                            final max = monthlySpending
                                .map((e) => e.value)
                                .reduce((a, b) => a > b ? a : b);
                            final fraction =
                                max == 0 ? 0.0 : (entry.value / max);
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      entry.key,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: fraction.toDouble(),
                                        minHeight: 10,
                                        backgroundColor: theme
                                            .colorScheme.onSurface
                                            .withValues(alpha: 0.08),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      CurrencyService.format(entry.value),
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> data, ThemeData theme) {
    final total = data.values.reduce((a, b) => a + b);
    return data.entries.map((e) {
      final color = AppConstants.categoryColors[e.key] ?? Colors.grey;
      final pct = e.value / total * 100;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 58,
        titleStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        badgeWidget: pct < 8
            ? null
            : Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  AppConstants.categoryIcons[e.key] ??
                      Icons.tag_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }
}

// ── Section card wrapper ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15151E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Legend chip ───────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;
  final bool isDark;

  const _LegendChip({
    required this.label,
    required this.percent,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $percent',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick-stat chip ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF15151E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty chart placeholder ───────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyChart({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
