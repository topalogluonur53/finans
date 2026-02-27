import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';

class Receivable {
  final String id;
  final String title;
  final String contactName;
  final double amount;
  final DateTime dueDate;
  final String description;

  Receivable({
    required this.id,
    required this.title,
    required this.contactName,
    required this.amount,
    required this.dueDate,
    this.description = '',
  });
}

class ReceivablesScreen extends StatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  State<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<ReceivablesScreen> {
  // Dummy data
  final List<Receivable> _receivables = [
    Receivable(
      id: '1',
      title: 'Ahmet Araba Borcu',
      contactName: 'Ahmet Yılmaz',
      amount: 15000.0,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      description: 'Araba tamiri için verilen borç',
    ),
    Receivable(
      id: '2',
      title: 'Kira Alacağı',
      contactName: 'Veli Demir',
      amount: 8500.0,
      dueDate: DateTime.now().add(const Duration(days: 15)),
      description: 'Mart ayı ofis kirası',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Alacaklarım'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _receivables.isEmpty
          ? Center(
              child: Text(
                'Kayıtlı alacağınız bulunmuyor.',
                style: TextStyle(color: AppTheme.textDim.withOpacity(0.7)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _receivables.length,
              itemBuilder: (context, index) {
                final item = _receivables[index];
                return _buildReceivableCard(item);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alacak ekleme özelliği eklenecek')),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReceivableCard(Receivable item) {
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
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_received, color: Colors.green),
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
                        item.contactName,
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
                    color: Colors.green,
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
                    color: daysLeft <= 3 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    daysLeft < 0 ? 'Gecikti' : (daysLeft == 0 ? 'Bugün' : '$daysLeft gün kaldı'),
                    style: TextStyle(
                      color: daysLeft <= 3 ? Colors.red : Colors.green,
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
