import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/data/providers/auth_provider.dart';
import 'package:finans_app/presentation/widgets/ticker_widget.dart';
import 'package:finans_app/presentation/widgets/portfolio_summary_card.dart';
import 'package:finans_app/presentation/widgets/asset_list_item.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';
import 'package:finans_app/presentation/screens/finance/add_transaction_screen.dart';
import 'package:finans_app/data/providers/finance_provider.dart';
import 'package:finans_app/presentation/widgets/finance_summary_card.dart';
import 'package:finans_app/presentation/widgets/portfolio_pie_chart.dart';


class DashboardView extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardView({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    final portfolio = Provider.of<PortfolioProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context);
    
    // Create map for calculation
    Map<String, double> priceMap = {};
    for (var m in market.prices) {
      priceMap[m.symbol] = m.price;
    }
    
    double totalValue = portfolio.getTotalValue(priceMap);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finans App'),
        actions: [
          IconButton(
            onPressed: () {
              portfolio.fetchAssets();
              // market.fetchPrices();
            }, 
            icon: const Icon(Icons.refresh)
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Bildirimler'),
                  content: const Text('Henüz yeni bildiriminiz yok.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              );
            }, 
            icon: const Icon(Icons.notifications)
          ),
          IconButton(onPressed: () {
            auth.logout();
          }, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
        children: [
          // Ticker
          if (market.prices.isNotEmpty)
            TickerWidget(prices: market.prices),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await portfolio.fetchAssets();
                // await market.fetchPrices(); // Market polls automatically
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Toplam Varlık', style: TextStyle(color: AppTheme.textDim)),
                  Text(
                    Formatters.formatMoney(totalValue),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  GestureDetector(
                    onTap: () => onNavigateToTab?.call(1),
                    child: PortfolioSummaryCard(totalValue: totalValue),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Finance Summary
                  GestureDetector(
                    onTap: () => onNavigateToTab?.call(2),
                    child: FinanceSummaryCard(
                      totalIncome: finance.totalIncome,
                      totalExpense: finance.totalExpense,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Piyasa Özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => onNavigateToTab?.call(3),
                        child: const Text('Piyasaya Git'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (market.prices.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: market.prices.length,
                        itemBuilder: (context, index) {
                          final price = market.prices[index];
                          final isPositive = price.changePercent >= 0;
                          return Card(
                            margin: const EdgeInsets.only(right: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(price.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(Formatters.formatMoney(price.price), style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${isPositive ? '+' : ''}${price.changePercent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: isPositive ? Colors.green : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  const Text('Hızlı İşlemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.add, 
                        label: 'Varlık Ekle', 
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddAssetScreen()),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.arrow_upward, 
                        label: 'Gelir Ekle', 
                        color: Colors.green,
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddTransactionScreen(type: TransactionType.income)),
                          );
                        }
                      ),
                      _ActionButton(
                        icon: Icons.arrow_downward, 
                        label: 'Gider Ekle', 
                        color: Colors.red,
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddTransactionScreen(type: TransactionType.expense)),
                          );
                        }
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  // Pie Chart
                  if (portfolio.assets.isNotEmpty)
                    PortfolioPieChart(
                      assets: portfolio.assets,
                      priceMap: priceMap,
                    ),
                    
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Varlıklarım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => onNavigateToTab?.call(1), // Navigate to Portfolio Tab
                        child: const Text('Tümünü Gör'),
                      ),
                    ],
                  ),
                  if (portfolio.assets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Henüz varlık eklenmemiş.', style: TextStyle(color: AppTheme.textDim), textAlign: TextAlign.center),
                    )
                  else
                    ...portfolio.assets.take(3).map((asset) => AssetListItem(
                      asset: asset, 
                    )),
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

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.9),
          onTapUp: (_) => setState(() => _scale = 1.0),
          onTapCancel: () => setState(() => _scale = 1.0),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (widget.color ?? AppTheme.primaryColor).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: (widget.color ?? AppTheme.textDim).withOpacity(0.1),
                ),
              ),
              child: Icon(
                widget.icon, 
                color: widget.color ?? AppTheme.primaryColor, 
                size: 32
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.label, 
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          )
        ),
      ],
    );
  }
}
