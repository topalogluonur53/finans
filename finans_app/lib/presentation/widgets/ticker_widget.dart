import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/market_provider.dart';

class TickerWidget extends StatelessWidget {
  final List<MarketData> prices;

  const TickerWidget({super.key, required this.prices});

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 50,
      color: AppTheme.surfaceDark.withOpacity(0.5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: prices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final data = prices[index];
          final isPositive = data.changePercent >= 0;
          return InkWell(
            onTap: () {
               ScaffoldMessenger.of(context).hideCurrentSnackBar();
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('${data.symbol} detayları yakında eklenecek.')),
               );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    data.symbol,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatMoney(data.price),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatPercent(data.changePercent),
                    style: TextStyle(
                      color: isPositive ? AppTheme.secondaryColor : AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
