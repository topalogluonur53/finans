import 'package:flutter/material.dart';
import 'dart:math';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  final _amountController = TextEditingController(text: '100000');
  final _rateController = TextEditingController(text: '3.5');
  final _termController = TextEditingController(text: '12');

  double _monthlyPayment = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;
  List<_AmortizationRow> _schedule = [];
  bool _showSchedule = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_amountController.text) ?? 0;
    final annualRate = double.tryParse(_rateController.text) ?? 0;
    final months = int.tryParse(_termController.text) ?? 1;

    if (principal <= 0 || annualRate <= 0 || months <= 0) {
      setState(() {
        _monthlyPayment = 0;
        _totalPayment = 0;
        _totalInterest = 0;
        _schedule = [];
      });
      return;
    }

    final monthlyRate = annualRate / 100;
    // Formula: M = P * r * (1+r)^n / ((1+r)^n - 1)
    final powFactor = pow(1 + monthlyRate, months).toDouble();
    final monthly = principal * monthlyRate * powFactor / (powFactor - 1);

    // Build amortization schedule
    List<_AmortizationRow> schedule = [];
    double remainingBalance = principal;

    for (int i = 1; i <= months; i++) {
      final interestPayment = remainingBalance * monthlyRate;
      final principalPayment = monthly - interestPayment;
      remainingBalance -= principalPayment;
      if (remainingBalance < 0) remainingBalance = 0;

      schedule.add(_AmortizationRow(
        month: i,
        payment: monthly,
        principalPart: principalPayment,
        interestPart: interestPayment,
        remainingBalance: remainingBalance,
      ));
    }

    setState(() {
      _monthlyPayment = monthly;
      _totalPayment = monthly * months;
      _totalInterest = (monthly * months) - principal;
      _schedule = schedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kredi Hesaplama')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Fields
            _buildInputCard(),
            const SizedBox(height: 8),

            // Calculate Button
            ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Hesapla'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_monthlyPayment > 0) ...[
              _buildResultsCard(),
              const SizedBox(height: 16),
              // Toggle schedule
              TextButton.icon(
                onPressed: () => setState(() => _showSchedule = !_showSchedule),
                icon: Icon(_showSchedule ? Icons.expand_less : Icons.expand_more),
                label: Text(_showSchedule ? 'Ödeme Planını Gizle' : 'Ödeme Planını Göster'),
              ),
              if (_showSchedule) _buildAmortizationTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kredi Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kredi Tutarı (₺)',
                prefixIcon: Icon(Icons.monetization_on),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Aylık Faiz Oranı (%)',
                prefixIcon: Icon(Icons.percent),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _termController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vade (Ay)',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              onChanged: (_) => _calculate(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Hesaplama Sonuçları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ResultRow(
              label: 'Aylık Taksit',
              value: Formatters.formatMoney(_monthlyPayment),
              valueColor: AppTheme.primaryColor,
              isLarge: true,
            ),
            const Divider(height: 24),
            _ResultRow(
              label: 'Toplam Ödeme',
              value: Formatters.formatMoney(_totalPayment),
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Toplam Faiz',
              value: Formatters.formatMoney(_totalInterest),
              valueColor: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            // Visual bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalPayment > 0 ? (_totalPayment - _totalInterest) / _totalPayment : 0,
                minHeight: 12,
                backgroundColor: AppTheme.errorColor.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    const Text('Ana Para', style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    const Text('Faiz', style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmortizationTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ödeme Planı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12),
                dataTextStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                columns: const [
                  DataColumn(label: Text('Ay')),
                  DataColumn(label: Text('Taksit')),
                  DataColumn(label: Text('Ana Para')),
                  DataColumn(label: Text('Faiz')),
                  DataColumn(label: Text('Kalan Borç')),
                ],
                rows: _schedule.map((row) {
                  return DataRow(cells: [
                    DataCell(Text('${row.month}')),
                    DataCell(Text(Formatters.formatMoney(row.payment))),
                    DataCell(Text(Formatters.formatMoney(row.principalPart))),
                    DataCell(Text(Formatters.formatMoney(row.interestPart))),
                    DataCell(Text(Formatters.formatMoney(row.remainingBalance))),
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

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLarge;

  const _ResultRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: AppTheme.textDim,
          fontSize: isLarge ? 16 : 14,
        )),
        Text(value, style: TextStyle(
          color: valueColor ?? AppTheme.textLight,
          fontWeight: FontWeight.bold,
          fontSize: isLarge ? 24 : 16,
        )),
      ],
    );
  }
}

class _AmortizationRow {
  final int month;
  final double payment;
  final double principalPart;
  final double interestPart;
  final double remainingBalance;

  _AmortizationRow({
    required this.month,
    required this.payment,
    required this.principalPart,
    required this.interestPart,
    required this.remainingBalance,
  });
}
