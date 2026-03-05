import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/models/recurring_transaction.dart';
import 'package:finans_app/data/providers/recurring_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sabit Gelir / Gider Ekranı
// ─────────────────────────────────────────────────────────────────────────────
class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringProvider>().fetch();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecurringProvider>(
      builder: (context, prov, _) {
        return Column(
          children: [
            // ── Özet kartı ──────────────────────────────────────────────────
            _SummaryCard(prov: prov),

            // ── Tab bar ─────────────────────────────────────────────────────
            Container(
              color: AppTheme.surfaceDark,
              child: TabBar(
                controller: _tab,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textDim,
                tabs: const [
                  Tab(text: 'Sabit Gelirler'),
                  Tab(text: 'Sabit Giderler'),
                ],
              ),
            ),

            // ── İçerik ──────────────────────────────────────────────────────
            Expanded(
              child: prov.isLoading && prov.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _RecurringList(
                          items: prov.incomes,
                          type: 'INCOME',
                          onRefresh: prov.fetch,
                        ),
                        _RecurringList(
                          items: prov.expenses,
                          type: 'EXPENSE',
                          onRefresh: prov.fetch,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Özet Kartı ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final RecurringProvider prov;
  const _SummaryCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final income = prov.totalMonthlyIncome;
    final expense = prov.totalMonthlyExpense;
    final net = prov.monthlyNet;
    final isPos = net >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isPos
              ? [const Color(0xFF0A3D62), const Color(0xFF1E88E5)]
              : [const Color(0xFF4A0000), const Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPos ? Colors.blue : Colors.red).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aylık Sabit Net',
            style: TextStyle(
                color: Colors.white60, fontSize: 12, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPos ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                (isPos ? '+' : '') + Formatters.formatMoney(net),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Gelir',
                value: income,
                color: Colors.greenAccent,
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Gider',
                value: expense,
                color: Colors.redAccent.shade100,
                icon: Icons.arrow_downward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.8), fontSize: 10)),
                Text(
                  Formatters.formatMoney(value),
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Liste ───────────────────────────────────────────────────────────────────
class _RecurringList extends StatelessWidget {
  final List<RecurringTransaction> items;
  final String type;
  final Future<void> Function() onRefresh;
  const _RecurringList({
    required this.items,
    required this.type,
    required this.onRefresh,
  });

  bool get _isIncome => type == 'INCOME';
  Color get _color => _isIncome ? Colors.green.shade400 : Colors.red.shade400;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isIncome
                  ? Icons.savings_outlined
                  : Icons.credit_card_off_outlined,
              size: 64,
              color: AppTheme.textDim.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _isIncome ? 'Sabit gelir eklenmemiş.' : 'Sabit gider eklenmemiş.',
              style: const TextStyle(color: AppTheme.textDim, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '+ butonuna basarak ekleyin',
              style: TextStyle(
                  color: AppTheme.textDim.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return _RecurringCard(item: item, color: _color);
        },
      ),
    );
  }
}

// ─── Kart ────────────────────────────────────────────────────────────────────
class _RecurringCard extends StatelessWidget {
  final RecurringTransaction item;
  final Color color;
  const _RecurringCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<RecurringProvider>();
    final isIncome = item.type == 'INCOME';
    final dateFmt = DateFormat('dd MMM yyyy', 'tr_TR');

    return Dismissible(
      key: ValueKey('rec_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        if (item.id != null) {
          final ok = await prov.delete(item.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ok ? 'Silindi.' : 'Silinemedi!')),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => _showDetail(context, item),
        onLongPress: () => _openEdit(context, item),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isActive
                  ? color.withValues(alpha: 0.25)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // ── İkon ────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (item.isActive ? color : Colors.grey)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(item.category),
                  color: item.isActive ? color : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // ── Açıklama ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: item.isActive
                            ? AppTheme.textLight
                            : AppTheme.textDim,
                        decoration:
                            item.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            RecurringTransaction.periodLabel(item.period),
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Tarih aralığı göstergesi
                        if (item.endDate != null) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.event_busy_outlined,
                              size: 11, color: AppTheme.textDim),
                          const SizedBox(width: 2),
                          Text(
                            dateFmt.format(item.endDate!),
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textDim),
                          ),
                        ],
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.description!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textDim),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tutar ────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (isIncome ? '+' : '-') +
                        Formatters.formatMoney(item.amount),
                    style: TextStyle(
                      color: item.isActive ? color : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '≈ ${Formatters.formatMoney(item.monthlyAmount)}/ay',
                    style:
                        const TextStyle(fontSize: 10, color: AppTheme.textDim),
                  ),
                ],
              ),

              // ── Toggle ───────────────────────────────────────────
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => prov.toggleActive(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: item.isActive ? color : Colors.grey.shade700,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: item.isActive
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
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

  Future<bool?> _confirmDelete(BuildContext ctx) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${item.category}" kaydını silmek istiyor musunuz?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Sil', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showDetail(BuildContext ctx, RecurringTransaction item) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RecurringDetail(item: item),
    );
  }

  void _openEdit(BuildContext ctx, RecurringTransaction item) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecurringSheet(
        initialType: item.type,
        editItem: item,
      ),
    );
  }

  IconData _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('kira')) return Icons.home_outlined;
    if (c.contains('maaş') || c.contains('maas')) {
      return Icons.work_outline;
    }
    if (c.contains('elektrik')) return Icons.bolt_outlined;
    if (c.contains('fatura') || c.contains('su') || c.contains('doğalgaz')) {
      return Icons.receipt_outlined;
    }
    if (c.contains('internet') || c.contains('telefon')) {
      return Icons.wifi_outlined;
    }
    if (c.contains('abonelik') ||
        c.contains('netflix') ||
        c.contains('spotify')) {
      return Icons.subscriptions_outlined;
    }
    if (c.contains('sigorta')) return Icons.security_outlined;
    if (c.contains('kredi') || c.contains('taksit')) {
      return Icons.credit_card_outlined;
    }
    if (c.contains('yatırım') || c.contains('birikim')) {
      return Icons.savings_outlined;
    }
    return item.type == 'INCOME'
        ? Icons.arrow_circle_up_outlined
        : Icons.arrow_circle_down_outlined;
  }
}

// ─── Detay Alt Panel ─────────────────────────────────────────────────────────
class _RecurringDetail extends StatelessWidget {
  final RecurringTransaction item;
  const _RecurringDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == 'INCOME';
    final color = isIncome ? Colors.green.shade400 : Colors.red.shade400;
    final dateFmt = DateFormat('dd MMMM yyyy', 'tr_TR');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(
                    isIncome
                        ? Icons.arrow_circle_up_outlined
                        : Icons.arrow_circle_down_outlined,
                    color: color,
                    size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Text(isIncome ? 'Sabit Gelir' : 'Sabit Gider',
                        style: TextStyle(color: color, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _detailRow('Tutar', Formatters.formatMoney(item.amount)),
          _detailRow('Periyot', RecurringTransaction.periodLabel(item.period)),
          _detailRow(
              'Aylık Eşdeğer', Formatters.formatMoney(item.monthlyAmount)),
          _detailRow('Başlangıç', dateFmt.format(item.startDate)),
          if (item.endDate != null)
            _detailRow('Bitiş', dateFmt.format(item.endDate!)),
          _detailRow('Durum', item.isActive ? 'Aktif ✓' : 'Pasif ✗'),
          if (item.description != null && item.description!.isNotEmpty)
            _detailRow('Not', item.description!),
          const SizedBox(height: 20),
          // Düzenle butonu
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color.withValues(alpha: 0.6)),
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddRecurringSheet(
                        initialType: item.type,
                        editItem: item,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Ekleme / Düzenleme Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class AddRecurringSheet extends StatefulWidget {
  final String initialType; // 'INCOME' | 'EXPENSE'
  final RecurringTransaction?
      editItem; // null → yeni kayıt, non-null → düzenleme
  const AddRecurringSheet({
    super.key,
    required this.initialType,
    this.editItem,
  });

  @override
  State<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late String _type;
  String _period = 'MONTHLY';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate; // null → süresiz
  bool _saving = false;

  bool get _isEditing => widget.editItem != null;

  static const _periods = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];
  static const _incomeCategories = [
    'Maaş',
    'Serbest Meslek',
    'Kira Geliri',
    'Yatırım Getirisi',
    'Emekli Maaşı',
    'Freelance',
    'Diğer',
  ];
  static const _expenseCategories = [
    'Kira',
    'Elektrik',
    'Su',
    'Doğalgaz',
    'İnternet',
    'Telefon',
    'Kredi Taksiti',
    'Sigorta',
    'Abonelik',
    'Ulaşım',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    // Düzenleme modunda alanları önceden doldur
    if (_isEditing) {
      final e = widget.editItem!;
      _type = e.type;
      _period = e.period;
      _startDate = e.startDate;
      _endDate = e.endDate;
      _amountCtrl.text = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _categoryCtrl.text = e.category;
      _descCtrl.text = e.description ?? '';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == 'INCOME' ? _incomeCategories : _expenseCategories;
  Color get _color =>
      _type == 'INCOME' ? Colors.green.shade400 : Colors.red.shade400;

  // ── Tarih seçici ────────────────────────────────────────────────────────────
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
              primary: _color, surface: const Color(0xFF1A2332)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2040),
      helpText: 'Bitiş Tarihi Seçin',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
              primary: _color, surface: const Color(0xFF1A2332)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMMM yyyy', 'tr_TR');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2332),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),

                // Başlık
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Sabit İşlemi Düzenle'
                            : 'Sabit İşlem Ekle',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _color.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Düzenleme',
                          style: TextStyle(
                              color: _color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Tür seçici ──────────────────────────────────────────────
                Row(
                  children: [
                    _TypeBtn(
                      label: 'Gelir',
                      icon: Icons.arrow_upward_rounded,
                      selected: _type == 'INCOME',
                      color: Colors.green.shade400,
                      onTap: () => setState(() => _type = 'INCOME'),
                    ),
                    const SizedBox(width: 12),
                    _TypeBtn(
                      label: 'Gider',
                      icon: Icons.arrow_downward_rounded,
                      selected: _type == 'EXPENSE',
                      color: Colors.red.shade400,
                      onTap: () => setState(() => _type = 'EXPENSE'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Kategori ────────────────────────────────────────────────
                const Text('Kategori',
                    style: TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final sel = _categoryCtrl.text == c;
                    return GestureDetector(
                      onTap: () => setState(() => _categoryCtrl.text = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel
                              ? _color.withValues(alpha: 0.18)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? _color : Colors.transparent,
                          ),
                        ),
                        child: Text(c,
                            style: TextStyle(
                              color: sel ? _color : Colors.white70,
                              fontSize: 13,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Özel kategori yazma
                TextFormField(
                  controller: _categoryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Veya özel kategori girin', _color),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Kategori zorunlu' : null,
                ),
                const SizedBox(height: 16),

                // ── Tutar ───────────────────────────────────────────────────
                TextFormField(
                  controller: _amountCtrl,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: _inputDeco('0,00  ₺', _color),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Tutar zorunlu';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Geçerli bir tutar girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Periyot ─────────────────────────────────────────────────
                const Text('Tekrar Sıklığı',
                    style: TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: _periods.map((p) {
                    final sel = _period == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _period = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? _color.withValues(alpha: 0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? _color : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _periodEmoji(p),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                RecurringTransaction.periodLabel(p),
                                style: TextStyle(
                                  color: sel ? _color : Colors.white54,
                                  fontSize: 11,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Tarih Aralığı ────────────────────────────────────────────
                const Text('Tarih Aralığı',
                    style: TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 8),

                // Başlangıç
                GestureDetector(
                  onTap: _pickStartDate,
                  child: _DateTile(
                    label: 'Başlangıç',
                    dateText: dateFmt.format(_startDate),
                    icon: Icons.calendar_today_outlined,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 8),

                // Bitiş (isteğe bağlı)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _endDate != null ? _pickEndDate : null,
                        child: AnimatedOpacity(
                          opacity: _endDate != null ? 1 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          child: _DateTile(
                            label: 'Bitiş (isteğe bağlı)',
                            dateText: _endDate != null
                                ? dateFmt.format(_endDate!)
                                : 'Süresiz',
                            icon: Icons.event_available_outlined,
                            color: _color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Ekle / Kaldır butonu
                    GestureDetector(
                      onTap: () {
                        if (_endDate != null) {
                          setState(() => _endDate = null);
                        } else {
                          _pickEndDate();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _endDate != null
                              ? Colors.red.withValues(alpha: 0.15)
                              : _color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _endDate != null
                                ? Colors.red.withValues(alpha: 0.4)
                                : _color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          _endDate != null
                              ? Icons.close_rounded
                              : Icons.add_rounded,
                          color: _endDate != null ? Colors.redAccent : _color,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Not ─────────────────────────────────────────────────────
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _inputDeco('Not (isteğe bağlı)', _color),
                ),
                const SizedBox(height: 24),

                // ── Kaydet ──────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Güncelle' : 'Kaydet',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, Color color) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  String _periodEmoji(String p) {
    switch (p) {
      case 'DAILY':
        return '📅';
      case 'WEEKLY':
        return '📆';
      case 'MONTHLY':
        return '🗓️';
      case 'YEARLY':
        return '📊';
      default:
        return '📅';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Bitiş tarihi, başlangıçtan önce olamaz
    if (_endDate != null && !_endDate!.isAfter(_startDate)) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bitiş tarihi başlangıç tarihinden sonra olmalı.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final item = RecurringTransaction(
      id: _isEditing ? widget.editItem!.id : null,
      type: _type,
      category: _categoryCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
      period: _period,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isEditing ? widget.editItem!.isActive : true,
    );

    final prov = context.read<RecurringProvider>();
    bool ok;

    if (_isEditing) {
      ok = await prov.update(widget.editItem!.id!, item);
    } else {
      ok = await prov.add(item);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? '✅ Güncellendi.'
                : '${item.type == 'INCOME' ? '✅ Gelir' : '✅ Gider'} eklendi.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Kaydedilemedi. Bağlantıyı kontrol edin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// ─── Tarih Kutusu ─────────────────────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final String label;
  final String dateText;
  final IconData icon;
  final Color color;
  const _DateTile({
    required this.label,
    required this.dateText,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 2),
              Text(dateText,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}

// ─── Tür Butonu ──────────────────────────────────────────────────────────────
class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.white10,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Colors.white38, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Colors.white54,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
