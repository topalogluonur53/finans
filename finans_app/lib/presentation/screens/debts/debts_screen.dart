import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';

class Debt {
  final String id;
  final String title;
  final String creditorName;
  final double amount;
  final DateTime dueDate;
  final String description;

  Debt({
    required this.id,
    required this.title,
    required this.creditorName,
    required this.amount,
    required this.dueDate,
    this.description = '',
  });
}

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  // Dummy data
  final List<Debt> _debts = [
    Debt(
      id: '1',
      title: 'Kredi Kartı Borcu',
      creditorName: 'Garanti Bankası',
      amount: 4500.0,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      description: 'Aysonu ekstresi',
    ),
    Debt(
      id: '2',
      title: 'Mehmet Telefon Taksidi',
      creditorName: 'Mehmet Ali',
      amount: 2500.0,
      dueDate: DateTime.now().add(const Duration(days: 12)),
      description: 'iPhone 13 taksidi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Borçlarım'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _debts.isEmpty
          ? Center(
              child: Text(
                'Kayıtlı borcunuz bulunmuyor.',
                style: TextStyle(color: AppTheme.textDim.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _debts.length,
              itemBuilder: (context, index) {
                final item = _debts[index];
                return _buildDebtCard(item);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Borç ekleme özelliği eklenecek')),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDebtCard(Debt item) {
    final daysLeft = item.dueDate.difference(DateTime.now()).inDays;

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_made, color: Colors.red),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        item.creditorName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.formatMoney(item.amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (item.description.isNotEmpty) ...[
              Text(
                item.description,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(color: AppTheme.textDim, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: AppTheme.textDim),
                    const SizedBox(width: 8),
                    Text(
                      '${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                      style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysLeft <= 3 ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    daysLeft < 0 ? 'Gecikti' : (daysLeft == 0 ? 'Bugün' : '$daysLeft gün kaldı'),
                    style: TextStyle(
                      color: daysLeft <= 3 ? Colors.red : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
