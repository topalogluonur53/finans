import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';
import 'package:finans_app/presentation/screens/finance/add_transaction_screen.dart';
import 'package:finans_app/data/providers/finance_provider.dart';
import 'package:finans_app/presentation/widgets/finance_summary_card.dart';
import 'package:finans_app/presentation/widgets/main_drawer.dart';

class DashboardView extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardView({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    final portfolio = Provider.of<PortfolioProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);

    final double totalValue = portfolio.getTotalValue(market);
    final double totalCost = portfolio.getTotalCost(market);
    final double totalPL = totalValue - totalCost;
    final double totalPLPercent =
        totalCost > 0 ? (totalPL / totalCost * 100) : 0.0;
    final bool isPLPositive = totalPL >= 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Finans Paneli'),
        elevation: 2,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await portfolio.fetchAssets();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // ─── Quick Actions (en üstte) ──────────────────────────
                      const _QuickActionsSection(),
                      const SizedBox(height: 16),

                      // ─── Hero Total Balance Card ───────────────────────────
                      _TotalBalanceCard(
                        totalValue: totalValue,
                        totalCost: totalCost,
                        totalPL: totalPL,
                        totalPLPercent: totalPLPercent,
                        isPLPositive: isPLPositive,
                      ),
                      const SizedBox(height: 20),

                      // ─── Finance Summary ───────────────────────────────────
                      GestureDetector(
                        onTap: () => onNavigateToTab?.call(2),
                        child: FinanceSummaryCard(
                          totalIncome: finance.totalIncome,
                          totalExpense: finance.totalExpense,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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

// ─── Total Balance Hero Card ───────────────────────────────────────────────────

class _TotalBalanceCard extends StatelessWidget {
  final double totalValue;
  final double totalCost;
  final double totalPL;
  final double totalPLPercent;
  final bool isPLPositive;

  const _TotalBalanceCard({
    required this.totalValue,
    required this.totalCost,
    required this.totalPL,
    required this.totalPLPercent,
    required this.isPLPositive,
  });

  @override
  Widget build(BuildContext context) {
    final plColor =
        isPLPositive ? AppTheme.secondaryColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF002F6C), // Koyu Lacivert (İşbankası Ana)
            Color(0xFF0057B8), // Orta Mavi
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'Toplam Portföy Değeri',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatMoney(totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(
                label: 'Kâr / Zarar',
                value: Formatters.formatMoney(totalPL),
                color: plColor,
                prefix: isPLPositive ? '+' : '',
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Oran',
                value: Formatters.formatPercent(totalPLPercent),
                color: plColor,
                prefix: isPLPositive ? '+' : '',
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Maliyet',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(
                    Formatters.formatMoney(totalCost),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String prefix;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            '$prefix$value',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Section ────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Hızlı İşlemler',
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle_outline,
                label: 'Varlık Ekle',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAssetScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.arrow_upward_rounded,
                label: 'Gelir Ekle',
                color: AppTheme.secondaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(
                          type: TransactionType.income)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.arrow_downward_rounded,
                label: 'Gider Ekle',
                color: AppTheme.errorColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(
                          type: TransactionType.expense)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Quick Action Button ───────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 26),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
