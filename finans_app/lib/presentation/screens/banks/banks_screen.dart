import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class Bank {
  String id;
  String bankName;
  String accountName;
  String iban;
  double totalCash;
  double totalDebt;
  DateTime dueDate;

  Bank({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.iban,
    required this.totalCash,
    required this.totalDebt,
    required this.dueDate,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────

class BanksScreen extends StatefulWidget {
  const BanksScreen({super.key});

  @override
  State<BanksScreen> createState() => _BanksScreenState();
}

class _BanksScreenState extends State<BanksScreen> {
  // ignore: prefer_final_fields
  List<Bank> _banks = [
    Bank(
      id: '1',
      bankName: 'Is Bankasi',
      accountName: 'Vadesiz TL',
      iban: 'TR12 3456 7890 0000 0000 00',
      totalCash: 15400.0,
      totalDebt: 3200.0,
      dueDate: DateTime.now().add(const Duration(days: 12)),
    ),
    Bank(
      id: '2',
      bankName: 'Garanti BBVA',
      accountName: 'Maas Hesabi',
      iban: 'TR98 7654 3210 0000 0000 11',
      totalCash: 2450.0,
      totalDebt: 850.0,
      dueDate: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  /// Acik olan kart ID'leri
  final Set<String> _expandedIds = {'1', '2'};

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _copyIban(String iban) {
    Clipboard.setData(ClipboardData(text: iban));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IBAN kopyalandi'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareIban(Bank bank) {
    Share.share(
      'Banka: ${bank.bankName}\nAlici: ${bank.accountName}\nIBAN: ${bank.iban}',
      subject: 'IBAN Bilgisi',
    );
  }

  void _deleteBank(Bank bank) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bankayi Sil',
            style: TextStyle(color: AppTheme.textLight)),
        content: Text(
          '${bank.bankName} hesabini silmek istediginize emin misiniz?',
          style: const TextStyle(color: AppTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Iptal', style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _banks.removeWhere((b) => b.id == bank.id);
                _expandedIds.remove(bank.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${bank.bankName} silindi'),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Sil',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _openAddEditDialog({Bank? bank}) {
    showDialog(
      context: context,
      builder: (ctx) => _BankFormDialog(
        existingBank: bank,
        onSave: (newBank) {
          setState(() {
            if (bank == null) {
              _banks.add(newBank);
              _expandedIds.add(newBank.id);
            } else {
              final idx = _banks.indexWhere((b) => b.id == bank.id);
              if (idx != -1) _banks[idx] = newBank;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allExpanded =
        _banks.isNotEmpty && _expandedIds.length == _banks.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Bankalar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_banks.isNotEmpty)
            IconButton(
              tooltip: 'Tumunu Ac/Kapat',
              icon: Icon(
                allExpanded
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  if (allExpanded) {
                    _expandedIds.clear();
                  } else {
                    _expandedIds.addAll(_banks.map((b) => b.id));
                  }
                });
              },
            ),
        ],
      ),
      body: _banks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_outlined,
                      size: 64,
                      color: AppTheme.textDim.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Henuz kayitli bankaniz bulunmuyor.',
                    style: TextStyle(
                        color: AppTheme.textDim.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _openAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Banka Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _banks.length,
              itemBuilder: (context, index) {
                final bank = _banks[index];
                final isExpanded = _expandedIds.contains(bank.id);
                return _BankCard(
                  bank: bank,
                  isExpanded: isExpanded,
                  onToggle: () => _toggleExpand(bank.id),
                  onCopyIban: () => _copyIban(bank.iban),
                  onShareIban: () => _shareIban(bank),
                  onEdit: () => _openAddEditDialog(bank: bank),
                  onDelete: () => _deleteBank(bank),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Banka Ekle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Banka Karti ────────────────────────────────────────────────────────────

class _BankCard extends StatelessWidget {
  final Bank bank;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onCopyIban;
  final VoidCallback onShareIban;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BankCard({
    required this.bank,
    required this.isExpanded,
    required this.onToggle,
    required this.onCopyIban,
    required this.onShareIban,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _statusColor {
    final days = bank.dueDate.difference(DateTime.now()).inDays;
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - her zaman gorunur
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance,
                        color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.bankName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          bank.accountName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Net bakiye ozeti
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatMoney(
                            bank.totalCash - bank.totalDebt),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: (bank.totalCash - bank.totalDebt) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      Text(
                        'Net Bakiye',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textDim.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textDim.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detaylar (expand olunca)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final days = bank.dueDate.difference(DateTime.now()).inDays;

    return Column(
      children: [
        Divider(
            color: Colors.white.withValues(alpha: 0.07),
            height: 1,
            indent: 16,
            endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              // Bakiyeler
              Row(
                children: [
                  Expanded(
                    child: _BalanceChip(
                      label: 'Toplam Nakit',
                      value: Formatters.formatMoney(bank.totalCash),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceChip(
                      label: 'Toplam Borc',
                      value: Formatters.formatMoney(bank.totalDebt),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Son Odeme Tarihi
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _statusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 15, color: _statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'Son Odeme: ${bank.dueDate.day.toString().padLeft(2, '0')}/${bank.dueDate.month.toString().padLeft(2, '0')}/${bank.dueDate.year}',
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      days <= 0 ? 'Gecti!' : '$days gun kaldi',
                      style: TextStyle(
                          color: _statusColor.withValues(alpha: 0.8),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // IBAN
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        size: 15, color: AppTheme.textDim),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bank.iban,
                        style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                            letterSpacing: 1.1),
                      ),
                    ),
                    IconButton(
                      onPressed: onCopyIban,
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: AppTheme.primaryColor),
                      tooltip: 'Kopyala',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Aksiyon Butonlari
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShareIban,
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Paylas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Duzenle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.errorColor, size: 22),
                    tooltip: 'Sil',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppTheme.errorColor.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bakiye Chip ────────────────────────────────────────────────────────────

class _BalanceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Banka Ekleme / Duzenleme Dialogu ───────────────────────────────────────

class _BankFormDialog extends StatefulWidget {
  final Bank? existingBank;
  final void Function(Bank) onSave;

  const _BankFormDialog({this.existingBank, required this.onSave});

  @override
  State<_BankFormDialog> createState() => _BankFormDialogState();
}

class _BankFormDialogState extends State<_BankFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _cashCtrl;
  late final TextEditingController _debtCtrl;
  late DateTime _dueDate;

  bool get _isEdit => widget.existingBank != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBank;
    _bankNameCtrl = TextEditingController(text: b?.bankName ?? '');
    _accountNameCtrl = TextEditingController(text: b?.accountName ?? '');
    _ibanCtrl = TextEditingController(text: b?.iban ?? '');
    _cashCtrl =
        TextEditingController(text: b != null ? b.totalCash.toString() : '');
    _debtCtrl =
        TextEditingController(text: b != null ? b.totalDebt.toString() : '');
    _dueDate =
        b?.dueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _ibanCtrl.dispose();
    _cashCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            surface: AppTheme.surfaceDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final bank = Bank(
      id: widget.existingBank?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      bankName: _bankNameCtrl.text.trim(),
      accountName: _accountNameCtrl.text.trim(),
      iban: _ibanCtrl.text.trim(),
      totalCash:
          double.tryParse(_cashCtrl.text.replaceAll(',', '.')) ?? 0,
      totalDebt:
          double.tryParse(_debtCtrl.text.replaceAll(',', '.')) ?? 0,
      dueDate: _dueDate,
    );
    widget.onSave(bank);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baslik
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Bankayi Duzenle' : 'Yeni Banka Ekle',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Banka Adi
              _FormField(
                controller: _bankNameCtrl,
                label: 'Banka Adi',
                hint: 'ornek: Is Bankasi',
                icon: Icons.business_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 14),

              // Hesap Adi
              _FormField(
                controller: _accountNameCtrl,
                label: 'Hesap Adi',
                hint: 'ornek: Vadesiz TL',
                icon: Icons.label_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 14),

              // IBAN
              _FormField(
                controller: _ibanCtrl,
                label: 'IBAN',
                hint: 'TR00 0000 0000 0000 0000 00',
                icon: Icons.credit_card_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 14),

              // Nakit & Borc - yan yana
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: _cashCtrl,
                      label: 'Nakit (TL)',
                      hint: '0.00',
                      icon: Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Zorunlu';
                        }
                        if (double.tryParse(v.replaceAll(',', '.')) ==
                            null) {
                          return 'Gecersiz';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      controller: _debtCtrl,
                      label: 'Borc (TL)',
                      hint: '0.00',
                      icon: Icons.money_off_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Zorunlu';
                        }
                        if (double.tryParse(v.replaceAll(',', '.')) ==
                            null) {
                          return 'Gecersiz';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Son Odeme Tarihi
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Son Odeme Tarihi',
                              style: TextStyle(
                                  color: AppTheme.textDim, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
                            style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded,
                          color: AppTheme.textDim, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Kaydet & Iptal
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textDim,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Iptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: Icon(
                          _isEdit
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                          size: 18),
                      label: Text(_isEdit ? 'Kaydet' : 'Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form Field Yardimcisi ──────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
        labelStyle:
            const TextStyle(color: AppTheme.textDim, fontSize: 13),
        hintStyle: TextStyle(
            color: AppTheme.textDim.withValues(alpha: 0.4), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
      ),
    );
  }
}
