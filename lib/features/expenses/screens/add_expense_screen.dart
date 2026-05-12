import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/currency_service.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? editExpense;

  const AddExpenseScreen({super.key, this.editExpense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  String _selectedCategory = AppConstants.categories.first;
  DateTime _selectedDate = DateTime.now();
  late String _selectedCurrency;
  bool _isIncome = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.editExpense != null;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = CurrencyService.globalCurrencyCode;
    if (_isEditMode) {
      final e = widget.editExpense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(
          e.amount.truncateToDouble() == e.amount ? 0 : 2);
      _noteController.text = e.note ?? '';
      _selectedCategory = e.category;
      _selectedDate = e.date;
      _selectedCurrency = e.originalCurrency;
      _isIncome = e.isIncome;
    }

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    // Brief pause so the loading spinner is perceptible before async Hive write
    await Future.delayed(const Duration(milliseconds: 280));

    final expense = Expense(
      id: _isEditMode ? widget.editExpense!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      originalCurrency: _selectedCurrency,
      isIncome: _isIncome,
    );

    if (_isEditMode) {
      await ref.read(expenseProvider.notifier).updateExpense(expense);
      // Return the edited id so home_view can trigger the pulse animation
      if (mounted) context.pop(expense.id);
    } else {
      await ref.read(expenseProvider.notifier).addExpense(expense);
      if (mounted) context.pop();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _isIncome
        ? const Color(0xFF4CAF50)
        : theme.colorScheme.primary;

    return Scaffold(
      // ── Keyboard dismissal on scroll ─────────────────────────────────────
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // ── App bar ───────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor:
                    isDark ? const Color(0xFF09090F) : const Color(0xFFF1F4F8),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  _isEditMode ? 'Edit Transaction' : 'New Transaction',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                // Live type indicator in app bar
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: accent,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isIncome ? 'Income' : 'Expense',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Type toggle ─────────────────────────────────────
                        _TypeToggle(
                          isIncome: _isIncome,
                          onChanged: (val) =>
                              setState(() => _isIncome = val),
                        ),
                        const SizedBox(height: 28),

                        // ── Section: Details ─────────────────────────────────
                        _SectionLabel(label: 'Details', accent: accent),
                        const SizedBox(height: 12),

                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: _isIncome
                                ? 'e.g. Monthly Salary'
                                : 'e.g. Lunch',
                            prefixIcon: const Icon(
                                Icons.edit_note_rounded),
                          ),
                          textCapitalization:
                              TextCapitalization.sentences,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Title is required'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        // Currency + Amount row
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 112,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCurrency,
                                decoration: const InputDecoration(
                                    labelText: 'Currency'),
                                items:
                                    CurrencyService.supportedCurrencies
                                        .map((c) => DropdownMenuItem(
                                            value: c.code,
                                            child: Text(c.code)))
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                        () => _selectedCurrency = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  prefixIcon: Icon(
                                      Icons.attach_money_rounded),
                                ),
                                validator: (val) {
                                  if (val == null ||
                                      val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final parsed =
                                      double.tryParse(val.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Enter a positive number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Section: Category & Date ─────────────────────────
                        _SectionLabel(
                            label: 'Category & Date', accent: accent),
                        const SizedBox(height: 12),

                        // Category
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon:
                                Icon(Icons.category_outlined),
                          ),
                          items: AppConstants.categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(
                                    AppConstants.categoryIcons[c],
                                    color: AppConstants
                                        .categoryColors[c],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(c),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(
                                  () => _selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Date picker
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(
                                  Icons.calendar_today_outlined),
                              suffixIcon: Icon(Icons.chevron_right),
                            ),
                            child: Text(
                              DateFormat('MMMM dd, yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Section: Note ────────────────────────────────────
                        _SectionLabel(
                            label: 'Note (optional)', accent: accent),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note',
                            hintText: 'Add a note...',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 36),

                        // ── Submit button ────────────────────────────────────
                        _SubmitButton(
                          isLoading: _isLoading,
                          isEditMode: _isEditMode,
                          isIncome: _isIncome,
                          onPressed: _save,
                        ),

                        if (_isEditMode) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color accent;

  const _SectionLabel({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ── Income / Expense segmented toggle ────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.isIncome, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFEF5350),
              isSelected: !isIncome,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF4CAF50),
              isSelected: isIncome,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: color.withValues(alpha: 0.45), width: 1.5)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected
                      ? color
                      : Colors.grey.withValues(alpha: 0.7),
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? color
                      : Colors.grey.withValues(alpha: 0.7),
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Submit button with animated loading spinner ───────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEditMode;
  final bool isIncome;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.isEditMode,
    required this.isIncome,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isIncome
        ? const Color(0xFF4CAF50)
        : Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.55),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEditMode
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isEditMode ? 'Save Changes' : 'Add Transaction',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
