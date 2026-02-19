import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/presentation/screens/market/market_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context);
    final marketData = {
      'commodity': marketProvider.prices.where((p) => p.category == 'commodity' && p.parentSymbol == null).toList(),
      'stock': marketProvider.prices.where((p) => (p.category == 'stock' || p.category == 'index') && p.parentSymbol == null).toList(),
      'currency': marketProvider.prices.where((p) => p.category == 'currency' && p.parentSymbol == null).toList(),
    };

    return Column(
      children: [
        Container(
          color: AppTheme.surfaceDark,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textDim,
            tabs: const [
              Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Emtia'),
              Tab(icon: Icon(Icons.business_center_outlined), text: 'Borsa'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'Döviz'),
            ],
          ),
        ),
        Expanded(
          child: marketProvider.isLoading && marketProvider.prices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMarketList(context, marketData['commodity'] ?? [], marketProvider),
                    _buildMarketList(context, marketData['stock'] ?? [], marketProvider),
                    _buildMarketList(context, marketData['currency'] ?? [], marketProvider),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMarketList(BuildContext context, List<MarketData> prices, MarketProvider provider) {
    if (prices.isEmpty) {
      return const Center(
        child: Text('Veri bulunamadı', style: TextStyle(color: AppTheme.textDim)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prices.length,
      itemBuilder: (context, index) {
        final price = prices[index];
        return _MarketPriceCard(
          price: price,
          onTap: price.isIndex ? () {
            final constituents = provider.prices.where((p) => p.parentSymbol == price.symbol).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketDetailScreen(
                  index: price,
                  constituents: constituents,
                ),
              ),
            );
          } : null,
        );
      },
    );
  }
}

class _MarketPriceCard extends StatelessWidget {
  final MarketData price;
  final VoidCallback? onTap;

  const _MarketPriceCard({required this.price, this.onTap});

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    final isFavorite = marketProvider.isFavorite(price.symbol);
    final isPositive = price.changePercent >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : AppTheme.textDim,
                ),
                onPressed: () {
                  marketProvider.toggleFavorite(price.symbol);
                },
              ),
              _buildFallbackIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.name, 
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryLabel(price.category, price.symbol),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatMoney(
                      price.price,
                      currency: price.symbol == 'AU/AG' 
                                 ? 'USD' 
                                 : (price.category == 'stock' || 
                                    price.symbol.contains('TRY') || 
                                    ['AU/TRY', 'AG/TRY', 'CEYREK', 'GA'].contains(price.symbol)) 
                                  ? 'TRY' : 'USD'
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 16, color: changeColor),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.formatPercent(price.changePercent),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    IconData icon;
    Color color;

    switch (price.category) {
      case 'crypto':
        icon = Icons.currency_bitcoin;
        color = Colors.orange;
        break;
      case 'commodity':
        icon = Icons.monetization_on;
        color = Colors.amber;
        break;
      case 'currency':
        icon = Icons.payments;
        color = Colors.green;
        break;
      default:
        icon = Icons.business_center;
        color = AppTheme.primaryColor;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getCategoryLabel(String category, String symbol) {
    if (symbol.contains('AU') || symbol.contains('AG') || symbol.contains('GOLD')) return 'EMTİA';
    switch (category.toLowerCase()) {
      case 'commodity':
        return 'EMTİA';
      case 'stock':
        return 'HİSSE SENEDİ';
      case 'currency':
        return 'DÖVİZ';
      case 'crypto':
        return 'KRİPTO';
      default:
        return category.toUpperCase();
    }
  }
}
