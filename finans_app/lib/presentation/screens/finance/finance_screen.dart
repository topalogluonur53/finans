import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/finance_provider.dart';
import 'package:finans_app/presentation/screens/finance/recurring_screen.dart';
import 'package:finans_app/presentation/widgets/main_drawer.dart';
import 'package:finans_app/presentation/screens/finance/add_transaction_screen.dart';
import 'package:finans_app/data/models/finance.dart';
import 'package:intl/intl.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Finans Yönetimi'),
        elevation: 2,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceDark,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textDim,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Gelirler'),
                Tab(text: 'Giderler'),
                Tab(text: 'Sabit'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<FinanceProvider>(
              builder: (context, finance, child) {
                if (finance.isLoading &&
                    finance.incomes.isEmpty &&
                    finance.expenses.isEmpty &&
                    _tabController.index != 2) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIncomeList(finance),
                    _buildExpenseList(finance),
                    // ── Sabit Gelir/Gider ─────────────────────────────────────
                    const RecurringScreen(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(
                        type: TransactionType.income)),
              ),
              label: const Text('Gelir Ekle', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              backgroundColor: Colors.green.shade500,
            )
          : _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen(
                            type: TransactionType.expense)),
                  ),
                  label: const Text('Gider Ekle', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white),
                  backgroundColor: Colors.red.shade500,
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddRecurringSheet(initialType: 'EXPENSE'),
                    );
                  },
                  label: const Text('Sabit İşlem Ekle', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  backgroundColor: AppTheme.primaryColor,
                ),
    );
  }

  Widget _buildIncomeList(FinanceProvider finance) {
    if (finance.incomes.isEmpty) {
      return const Center(child: Text('Henüz gelir eklenmemiş.'));
    }
    return RefreshIndicator(
      onRefresh: () => finance.fetchIncomes(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: finance.incomes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryHeader(
              'Toplam Gelir',
              finance.totalIncome,
              Colors.green,
              Icons.trending_up,
            );
          }
          final income = finance.incomes[index - 1];
          return Dismissible(
            key: ValueKey('income_${income.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Silme Onayı'),
                  content:
                      const Text('Bu işlemi silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              if (income.id != null) {
                finance.deleteIncome(income.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gelir silindi.')));
              }
            },
            child: ListTile(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(income.source,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text('Tutar: ${Formatters.formatMoney(income.amount)}'),
                        Text(
                            'Tarih: ${DateFormat('dd.MM.yyyy').format(income.date)}'),
                        if (income.description != null &&
                            income.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Açıklama: ${income.description}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic)),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              leading: const Icon(Icons.arrow_upward, color: Colors.green),
              title: Text(income.source,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(income.date)),
              trailing: Text(
                Formatters.formatMoney(income.amount),
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseList(FinanceProvider finance) {
    if (finance.expenses.isEmpty) {
      return const Center(child: Text('Henüz gider eklenmemiş.'));
    }
    return RefreshIndicator(
      onRefresh: () => finance.fetchExpenses(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: finance.expenses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryHeader(
              'Toplam Gider',
              finance.totalExpense,
              Colors.red,
              Icons.trending_down,
            );
          }
          final expense = finance.expenses[index - 1];
          return Dismissible(
            key: ValueKey('expense_${expense.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Silme Onayı'),
                  content:
                      const Text('Bu işlemi silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              if (expense.id != null) {
                finance.deleteExpense(expense.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gider silindi.')));
              }
            },
            child: ListTile(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(expense.category,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(
                            'Tutar: ${Formatters.formatMoney(expense.amount)}'),
                        Text(
                            'Tarih: ${DateFormat('dd.MM.yyyy').format(expense.date)}'),
                        if (expense.description != null &&
                            expense.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Açıklama: ${expense.description}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic)),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kapat'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              leading: const Icon(Icons.arrow_downward, color: Colors.red),
              title: Text(expense.category,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(expense.date)),
              trailing: Text(
                Formatters.formatMoney(expense.amount),
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(
      String title, double amount, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                Formatters.formatMoney(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

