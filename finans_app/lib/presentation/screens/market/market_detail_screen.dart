import 'package:flutter/material.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';

class MarketDetailScreen extends StatelessWidget {
  final MarketData index;
  final List<MarketData> constituents;

  const MarketDetailScreen({
    super.key, 
    required this.index,
    required this.constituents,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(index.name),
      ),
      body: Column(
        children: [
          // Index Summary Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Endeks Değeri', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatMoney(index.price),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _changeIndicator(index.changePercent),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Bileşen Hisseler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: constituents.length,
              itemBuilder: (context, index) {
                final price = constituents[index];
                return _SimpleMarketCard(price: price);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _changeIndicator(double percent) {
    final isPositive = percent >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            Formatters.formatPercent(percent),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SimpleMarketCard extends StatelessWidget {
  final MarketData price;

  const _SimpleMarketCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final isPositive = price.changePercent >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(price.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(price.symbol, style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatMoney(price.price),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              Formatters.formatPercent(price.changePercent),
              style: TextStyle(color: changeColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
