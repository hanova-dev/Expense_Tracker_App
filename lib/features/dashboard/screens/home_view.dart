import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../../../core/currency_service.dart';
import '../../../core/constants.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../settings/models/budget_model.dart';

// ── Semantic palette shared across this file ──────────────────────────────────
const _kIncome = Color(0xFF4CAF50);
const _kExpense = Color(0xFFEF5350);

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  // IDs that existed at widget init — they do NOT slide-in on first load
  final Set<String> _knownIds = {};
  // IDs playing the exit (delete) animation
  final Set<String> _removingIds = {};
  // ID of the row that should flash after an edit
  String? _pulsingId;

  @override
  void initState() {
    super.initState();
    // Seed before first build so existing items skip the enter animation
    _knownIds.addAll(ref.read(expenseProvider).map((e) => e.id));
  }

  // ── Delete flow: animate first, then remove from storage ─────────────────
  Future<void> _initiateDelete(String id) async {
    setState(() => _removingIds.add(id));
    await Future.delayed(const Duration(milliseconds: 290));
    await ref.read(expenseProvider.notifier).deleteExpense(id);
    if (mounted) setState(() => _removingIds.remove(id));
  }

  // ── Edit flow: push form screen, wait for it to pop with the edited id ────
  Future<void> _editExpense(Expense expense) async {
    final editedId =
        await context.push<String>('/add-expense', extra: expense);
    if (editedId != null && mounted) {
      setState(() => _pulsingId = editedId);
      // The pulse animation runs for ~500 ms; clear state after it finishes
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) setState(() => _pulsingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = ref.watch(expenseProvider);
    final globalCurrency = ref.watch(globalCurrencyProvider);
    final income = ref.watch(totalIncomeThisMonthProvider);
    final expensesTotal = ref.watch(totalExpensesOnlyThisMonthProvider);
    final balance = income - expensesTotal;

    final budgetBox = Hive.box<Budget>('budgets');
    final overallBudget = budgetBox.get('Total')?.amount;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header + metric cards ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page title row
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Wallet',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Balance card with income/expense mini-metrics ─────────
                  _BalanceCard(
                      balance: balance,
                      income: income,
                      expenses: expensesTotal),

                  // ── Budget progress (optional) ────────────────────────────
                  if (overallBudget != null) ...[
                    const SizedBox(height: 12),
                    _BudgetProgressCard(
                        totalThisMonth: expensesTotal,
                        budget: overallBudget),
                  ],

                  const SizedBox(height: 24),

                  // ── Section header ────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Transactions',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${expenses.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Empty state ──────────────────────────────────────────────────
          if (expenses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.18),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add your first one',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.28),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Transaction list ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = expenses[index];
                    return _AnimatedExpenseTile(
                      key: ValueKey(expense.id),
                      expense: expense,
                      globalCurrency: globalCurrency,
                      isNew: !_knownIds.contains(expense.id),
                      isRemoving: _removingIds.contains(expense.id),
                      isPulsing: _pulsingId == expense.id,
                      onEdit: () => _editExpense(expense),
                      onDelete: () => _initiateDelete(expense.id),
                    );
                  },
                  childCount: expenses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Balance · This Month',
            style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          _AnimatedCounter(
            value: balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Income',
                  value: income,
                  icon: Icons.arrow_downward_rounded,
                  color: _kIncome,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.2)),
              Expanded(
                child: _MiniMetric(
                  label: 'Expenses',
                  value: expenses,
                  icon: Icons.arrow_upward_rounded,
                  color: _kExpense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                _AnimatedCounter(
                  value: value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated counter ──────────────────────────────────────────────────────────
// Smoothly counts from the previous value to the new value on every change.

class _AnimatedCounter extends StatefulWidget {
  final double value;
  final TextStyle? style;

  const _AnimatedCounter({required this.value, this.style, super.key});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _displayed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut))
      ..addListener(() => setState(() => _displayed = _anim.value));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _displayed, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut))
        ..addListener(() => setState(() => _displayed = _anim.value));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(CurrencyService.format(_displayed), style: widget.style);
}

// ── Budget progress card ──────────────────────────────────────────────────────

class _BudgetProgressCard extends StatelessWidget {
  final double totalThisMonth;
  final double budget;

  const _BudgetProgressCard(
      {required this.totalThisMonth, required this.budget});

  @override
  Widget build(BuildContext context) {
    final progress = (totalThisMonth / budget).clamp(0.0, 1.0);
    final isOver = totalThisMonth > budget;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    color: isOver ? _kExpense : theme.colorScheme.primary,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? _kExpense : theme.colorScheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? 'Exceeded by ${CurrencyService.format(totalThisMonth - budget)}'
                : '${CurrencyService.format(budget - totalThisMonth)} remaining',
            style: TextStyle(
                color: isOver ? _kExpense : Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Animated expense tile ─────────────────────────────────────────────────────
// Handles enter slide-in, delete collapse, edit highlight pulse, and inline
// delete confirmation — all self-contained in one StatefulWidget.

class _AnimatedExpenseTile extends StatefulWidget {
  final Expense expense;
  final String globalCurrency;
  final bool isNew;
  final bool isRemoving;
  final bool isPulsing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  _AnimatedExpenseTile({
    required Key key,
    required this.expense,
    required this.globalCurrency,
    required this.isNew,
    required this.isRemoving,
    required this.isPulsing,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<_AnimatedExpenseTile> createState() => _AnimatedExpenseTileState();
}

class _AnimatedExpenseTileState extends State<_AnimatedExpenseTile>
    with TickerProviderStateMixin {
  // Enter animation (slide down + fade in)
  late AnimationController _enterCtrl;
  late Animation<Offset> _slide;
  late Animation<double> _enterFade;

  // Exit animation (fade out + height collapse)
  late AnimationController _removeCtrl;
  late Animation<double> _removeFade;
  late Animation<double> _height; // 1 → 0

  // Pulse animation (background colour flash on edit)
  late AnimationController _pulseCtrl;

  bool _confirmDelete = false;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(
            begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);

    _removeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _removeFade = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _removeCtrl, curve: Curves.easeIn));
    _height = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _removeCtrl, curve: Curves.easeIn));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    if (widget.isNew) {
      _enterCtrl.forward();
    } else {
      _enterCtrl.value = 1.0; // skip for items already present at init
    }
  }

  @override
  void didUpdateWidget(_AnimatedExpenseTile old) {
    super.didUpdateWidget(old);
    if (!old.isRemoving && widget.isRemoving) {
      _removeCtrl.forward();
    }
    if (!old.isPulsing && widget.isPulsing) {
      // Play 0 → 1 — the bell-curve formula in the builder creates a natural
      // flash that peaks at midpoint and returns to transparent by end.
      _pulseCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _removeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expense = widget.expense;
    final catColor =
        AppConstants.categoryColors[expense.category] ?? Colors.grey;
    final isConverted = expense.originalCurrency != widget.globalCurrency;

    return SizeTransition(
      sizeFactor: _height,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _removeFade,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _enterFade,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                // Bell-curve: peaks at v=0.5 → value = 0.5*0.5*4 = 1.0
                final t =
                    (_pulseCtrl.value * (1 - _pulseCtrl.value) * 4)
                        .clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      theme.cardTheme.color ??
                          theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.primary.withOpacity(0.18),
                      t,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: catColor, width: 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.045),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: _confirmDelete
                  ? _DeleteConfirmRow(
                      title: expense.title,
                      onCancel: () =>
                          setState(() => _confirmDelete = false),
                      onConfirm: () {
                        setState(() => _confirmDelete = false);
                        widget.onDelete();
                      },
                    )
                  : _TileContent(
                      expense: expense,
                      globalCurrency: widget.globalCurrency,
                      catColor: catColor,
                      isConverted: isConverted,
                      onEdit: widget.onEdit,
                      onDeleteTap: () =>
                          setState(() => _confirmDelete = true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tile content (normal state) ───────────────────────────────────────────────

class _TileContent extends StatelessWidget {
  final Expense expense;
  final String globalCurrency;
  final Color catColor;
  final bool isConverted;
  final VoidCallback onEdit;
  final VoidCallback onDeleteTap;

  const _TileContent({
    required this.expense,
    required this.globalCurrency,
    required this.catColor,
    required this.isConverted,
    required this.onEdit,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16)),
      onTap: () {}, // future: tap to expand details
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                expense.isIncome
                    ? Icons.savings_outlined
                    : (AppConstants.categoryIcons[expense.category] ??
                        Icons.receipt_outlined),
                color: expense.isIncome ? _kIncome : catColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.category} · '
                    '${DateFormat('MMM dd').format(expense.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${expense.isIncome ? '+' : '−'}'
                  '${CurrencyService.format(expense.amount, expense.originalCurrency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: expense.isIncome ? _kIncome : _kExpense,
                  ),
                ),
                if (isConverted)
                  Text(
                    '~${CurrencyService.format(CurrencyService.convert(expense.amount, expense.originalCurrency, globalCurrency))}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.38),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),

            // Edit / delete action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: theme.colorScheme.primary,
                  tooltip: 'Edit',
                  onTap: onEdit,
                ),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: _kExpense,
                  tooltip: 'Delete',
                  onTap: onDeleteTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline delete confirmation row ────────────────────────────────────────────

class _DeleteConfirmRow extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DeleteConfirmRow({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: _kExpense, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delete "$title"?',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kExpense,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Small icon action button ──────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 18, color: color.withOpacity(0.75)),
        ),
      ),
    );
  }
}
