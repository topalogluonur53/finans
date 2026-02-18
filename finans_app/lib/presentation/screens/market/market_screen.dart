import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/models/market_price.dart';
import 'package:finans_app/data/services/coingecko_service.dart';
import 'package:finans_app/core/utils/formatters.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  final CoinGeckoService _service = CoinGeckoService();
  late TabController _tabController;
  
  Map<String, List<MarketPrice>> _marketData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMarketData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchAllMarkets();
      setState(() {
        _marketData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Veriler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page Title Moved to HomeScreen App Bar
        Container(
          color: AppTheme.surfaceDark,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textDim,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Emtia'),
              Tab(icon: Icon(Icons.currency_bitcoin), text: 'Kripto'),
              Tab(icon: Icon(Icons.business_center_outlined), text: 'Borsa'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'Döviz'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMarketData,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMarketList(_marketData['commodity'] ?? []),
                        _buildMarketList(_marketData['crypto'] ?? []),
                        _buildMarketList(_marketData['stock'] ?? []),
                        _buildMarketList(_marketData['currency'] ?? []),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildMarketList(List<MarketPrice> prices) {
    if (prices.isEmpty) {
      return const Center(
        child: Text('Veri bulunamadı', style: TextStyle(color: AppTheme.textDim)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMarketData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prices.length,
        itemBuilder: (context, index) {
          final price = prices[index];
          return _MarketPriceCard(price: price);
        },
      ),
    );
  }
}

class _MarketPriceCard extends StatelessWidget {
  final MarketPrice price;

  const _MarketPriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final isPositive = price.isPositive;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon/Image
            if (price.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  price.image!,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                ),
              )
            else
              _buildFallbackIcon(),
            const SizedBox(width: 16),

            // Name & Symbol
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price.symbol,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDim,
                    ),
                  ),
                ],
              ),
            ),

            // Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatMoney(
                    price.currentPrice,
                    currency: price.symbol == 'XAU/XAG' 
                              ? 'NONE'
                              : (price.category == 'stock' || 
                                 price.symbol.contains('TRY') || 
                                 ['GA', 'CEYREK', 'YARIM', 'TAM', 'CUMHURIYET'].contains(price.symbol)) 
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
                      Formatters.formatPercent(price.priceChangePercentage24h),
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
