import 'package:flutter/material.dart';
import 'dart:math';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Loan scenario data
class LoanScenario {
  final String name;
  final TextEditingController amountCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController termCtrl;

  double monthlyPayment = 0;
  double totalPayment = 0;
  double totalInterest = 0;
  List<AmortizationRow> schedule = [];

  LoanScenario({
    required this.name,
    String amount = '100000',
    String rate = '3,50',
    String term = '12',
  })  : amountCtrl = TextEditingController(text: _formatInitialAmount(amount)),
        rateCtrl = TextEditingController(text: rate),
        termCtrl = TextEditingController(text: term);

  static String _formatInitialAmount(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return '';
    return NumberFormat('#,###', 'tr_TR').format(number).replaceAll(',', '.');
  }

  void dispose() {
    amountCtrl.dispose();
    rateCtrl.dispose();
    termCtrl.dispose();
  }
}

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<LoanScenario> _scenarios;
  bool _showSchedule = false;
  bool _isMonthlyRate = true; // true = monthly, false = annual

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scenarios = [
      LoanScenario(name: 'Senaryo A'),
      LoanScenario(name: 'Senaryo B', rate: '4.0', term: '24'),
    ];
    for (final s in _scenarios) {
      _calculate(s);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final s in _scenarios) {
      s.dispose();
    }
    super.dispose();
  }

  void _calculate(LoanScenario s) {
    // Tutar stringindeki noktaları (binlik ayracı) silip ondalık ayracı olarak saklanmış virgülü noktaya çeviriyoruz
    final amountText =
        s.amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final principal = double.tryParse(amountText) ?? 0;

    // Faiz metnindeki virgülü noktaya çevir, nokta varsa bırak
    double rate = double.tryParse(s.rateCtrl.text.replaceAll(',', '.')) ?? 0;
    if (!_isMonthlyRate) rate = rate / 12; // convert annual to monthly
    final months = int.tryParse(s.termCtrl.text) ?? 1;

    if (principal <= 0 || rate <= 0 || months <= 0) {
      setState(() {
        s.monthlyPayment = 0;
        s.totalPayment = 0;
        s.totalInterest = 0;
        s.schedule = [];
      });
      return;
    }

    final monthlyRate = rate / 100;

    // Bankaların uyguladığı efektif faiz (KKDF %15 + BSMV %5 = %20 ek maliyet)
    final effectiveMonthlyRate = monthlyRate * 1.20;

    final powFactor = pow(1 + effectiveMonthlyRate, months).toDouble();
    final monthly =
        principal * effectiveMonthlyRate * powFactor / (powFactor - 1);

    List<AmortizationRow> schedule = [];
    double remainingBalance = principal;

    for (int i = 1; i <= months; i++) {
      final interestPayment = remainingBalance * effectiveMonthlyRate;
      final principalPayment = monthly - interestPayment;
      remainingBalance -= principalPayment;
      if (remainingBalance < 0) remainingBalance = 0;

      schedule.add(AmortizationRow(
        month: i,
        payment: monthly,
        principalPart: principalPayment,
        interestPart: interestPayment,
        remainingBalance: remainingBalance,
      ));
    }

    setState(() {
      s.monthlyPayment = monthly;
      s.totalPayment = monthly * months;
      s.totalInterest = (monthly * months) - principal;
      s.schedule = schedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kredi Hesaplama'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _isMonthlyRate = !_isMonthlyRate);
                for (final s in _scenarios) {
                  _calculate(s);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _isMonthlyRate ? 'Aylık %' : 'Yıllık %',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textDim,
          tabs: const [
            Tab(text: 'Hesapla', icon: Icon(Icons.calculate)),
            Tab(text: 'Karşılaştır', icon: Icon(Icons.compare_arrows)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSingleCalculator(_scenarios[0]),
          _buildCompareView(),
        ],
      ),
    );
  }

  Widget _buildSingleCalculator(LoanScenario s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputCard(s),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _calculate(s),
            icon: const Icon(Icons.calculate),
            label: const Text('Hesapla'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 20),
          if (s.monthlyPayment > 0) ...[
            _buildResultsCard(s),
            const SizedBox(height: 12),
            // Schedule toggle
            OutlinedButton.icon(
              onPressed: () => setState(() => _showSchedule = !_showSchedule),
              icon: Icon(_showSchedule ? Icons.expand_less : Icons.expand_more),
              label: Text(_showSchedule
                  ? 'Ödeme Planını Gizle'
                  : 'Ödeme Planını Göster'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4)),
              ),
            ),
            if (_showSchedule) ...[
              const SizedBox(height: 12),
              _buildAmortizationTable(s),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompareView() {
    final a = _scenarios[0];
    final b = _scenarios[1];
    final bothCalculated = a.monthlyPayment > 0 && b.monthlyPayment > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputCard(a, compact: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputCard(b, compact: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _calculate(a);
                    _calculate(b);
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Her İkisini Hesapla'),
                ),
              ),
            ],
          ),
          if (bothCalculated) ...[
            const SizedBox(height: 20),
            _buildComparisonTable(a, b),
          ],
        ],
      ),
    );
  }

  Widget _buildInputCard(LoanScenario s, {bool compact = false}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compact ? s.name : 'Kredi Bilgileri',
              style: TextStyle(
                fontSize: compact ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: s.amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Tutar',
                prefixIcon: const Icon(Icons.currency_lira, size: 18),
                isDense: compact,
              ),
              onChanged: (_) => _calculate(s),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: s.rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Kullanıcı nokta girerse onu virgüle çevir
                  return newValue.copyWith(
                    text: newValue.text.replaceAll('.', ','),
                    selection:
                        TextSelection.collapsed(offset: newValue.selection.end),
                  );
                }),
              ],
              decoration: InputDecoration(
                labelText: _isMonthlyRate
                    ? 'Aylık Faiz Oranı (%)'
                    : 'Yıllık Faiz Oranı (%)',
                prefixIcon: const Icon(Icons.percent, size: 18),
                isDense: compact,
              ),
              onChanged: (_) => _calculate(s),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: s.termCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Vade (Ay)',
                prefixIcon: const Icon(Icons.calendar_month, size: 18),
                isDense: compact,
              ),
              onChanged: (_) => _calculate(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(LoanScenario s) {
    final principalRatio = s.totalPayment > 0
        ? (s.totalPayment - s.totalInterest) / s.totalPayment
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main monthly payment
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aylık Taksit',
                            style: TextStyle(
                                color: AppTheme.textDim, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatMoney(s.monthlyPayment),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MiniStat(
                          label: 'Toplam',
                          value: Formatters.formatMoney(s.totalPayment),
                          color: AppTheme.textLight),
                      const SizedBox(height: 6),
                      _MiniStat(
                          label: 'Faiz',
                          value: Formatters.formatMoney(s.totalInterest),
                          color: AppTheme.errorColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Visual breakdown bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _LegendDot(
                        color: AppTheme.secondaryColor, label: 'Ana Para'),
                    _LegendDot(
                        color: AppTheme.errorColor.withValues(alpha: 0.7),
                        label: 'Faiz'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                      ),
                      FractionallySizedBox(
                        widthFactor: principalRatio,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.secondaryColor,
                                Color(0xFF69F0AE),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ana Para: ${(principalRatio * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textDim),
                    ),
                    Text(
                      'Faiz: ${((1 - principalRatio) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textDim),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(LoanScenario a, LoanScenario b) {
    final winner = a.totalPayment <= b.totalPayment ? 'A' : 'B';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Karşılaştırma',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Senaryo $winner daha avantajlı',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CompareRow(
              label: 'Aylık Taksit',
              valueA: Formatters.formatMoney(a.monthlyPayment),
              valueB: Formatters.formatMoney(b.monthlyPayment),
              lowerIsBetter: true,
              aVal: a.monthlyPayment,
              bVal: b.monthlyPayment,
            ),
            _CompareRow(
              label: 'Toplam Ödeme',
              valueA: Formatters.formatMoney(a.totalPayment),
              valueB: Formatters.formatMoney(b.totalPayment),
              lowerIsBetter: true,
              aVal: a.totalPayment,
              bVal: b.totalPayment,
            ),
            _CompareRow(
              label: 'Toplam Faiz',
              valueA: Formatters.formatMoney(a.totalInterest),
              valueB: Formatters.formatMoney(b.totalInterest),
              lowerIsBetter: true,
              aVal: a.totalInterest,
              bVal: b.totalInterest,
            ),
            const Divider(),
            _CompareRow(
              label: 'Fark (Toplam)',
              valueA: '',
              valueB: Formatters.formatMoney(
                  (b.totalPayment - a.totalPayment).abs()),
              lowerIsBetter: true,
              aVal: 0,
              bVal: 1,
              isInfo: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmortizationTable(LoanScenario s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ödeme Planı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 12),
                dataTextStyle:
                    const TextStyle(fontSize: 12, color: AppTheme.textLight),
                columns: const [
                  DataColumn(label: Text('Ay')),
                  DataColumn(label: Text('Taksit')),
                  DataColumn(label: Text('Ana Para')),
                  DataColumn(label: Text('Faiz')),
                  DataColumn(label: Text('Kalan')),
                ],
                rows: s.schedule.map((row) {
                  return DataRow(cells: [
                    DataCell(Text('${row.month}')),
                    DataCell(Text(Formatters.formatMoney(row.payment))),
                    DataCell(Text(Formatters.formatMoney(row.principalPart))),
                    DataCell(Text(Formatters.formatMoney(row.interestPart))),
                    DataCell(
                        Text(Formatters.formatMoney(row.remainingBalance))),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;
  final bool lowerIsBetter;
  final double aVal;
  final double bVal;
  final bool isInfo;

  const _CompareRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.lowerIsBetter,
    required this.aVal,
    required this.bVal,
    this.isInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    Color aColor = AppTheme.textLight;
    Color bColor = AppTheme.textLight;

    if (!isInfo && aVal != bVal) {
      final aWins = lowerIsBetter ? aVal < bVal : aVal > bVal;
      aColor = aWins ? AppTheme.secondaryColor : AppTheme.errorColor;
      bColor = aWins ? AppTheme.errorColor : AppTheme.secondaryColor;
    }

    if (isInfo) {
      bColor = Colors.amber;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textDim)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valueA,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: aColor),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valueB,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: bColor),
            ),
          ),
        ],
      ),
    );
  }
}

class AmortizationRow {
  final int month;
  final double payment;
  final double principalPart;
  final double interestPart;
  final double remainingBalance;

  AmortizationRow({
    required this.month,
    required this.payment,
    required this.principalPart,
    required this.interestPart,
    required this.remainingBalance,
  });
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Sadece rakamları al
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return newValue.copyWith(text: '');

    // tr_TR NumberFormat nokta ile binlik ayırır (örn: 100.000)
    final formatter = NumberFormat('#,###', 'tr_TR');
    String newText = formatter.format(int.parse(numbers)).replaceAll(',', '.');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
