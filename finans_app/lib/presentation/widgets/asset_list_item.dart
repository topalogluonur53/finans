import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/models/asset.dart';
import 'package:finans_app/data/providers/market_provider.dart';

class AssetListItem extends StatelessWidget {
  final Asset asset;

  const AssetListItem({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    final double currentPrice = market.getPrice(asset.symbol ?? '');
    
    // If no market price, use purchase price or unknown (0)
    final double displayPrice = currentPrice > 0 ? currentPrice : asset.purchasePrice;
    final double totalValue = asset.quantity * displayPrice;
    
    // Calculate P/L
    double profitLoss = totalValue - (asset.quantity * asset.purchasePrice);
    double profitLossPercent = (asset.quantity * asset.purchasePrice) > 0 
        ? (profitLoss / (asset.quantity * asset.purchasePrice) * 100) 
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(asset.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Miktar: ${asset.quantity} ${asset.symbol}'),
                    Text('Alış Fiyatı: ${Formatters.formatMoney(asset.purchasePrice)}'),
                    const SizedBox(height: 16),
                    if (asset.notes != null && asset.notes!.isNotEmpty)
                      Text('Notlar: ${asset.notes!}', style: const TextStyle(fontStyle: FontStyle.italic)),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _AssetIcon(type: asset.type),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${asset.quantity} ${asset.symbol ?? ''}',
                          style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatMoney(totalValue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Icon(
                          profitLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: profitLoss >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.formatPercent(profitLossPercent),
                          style: TextStyle(
                            color: profitLoss >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  final String type;

  const _AssetIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData iconData = Icons.attach_money;
    Color color = Colors.blue;

    if (type.contains('GOLD')) {
      iconData = Icons.workspaces_filled; // Gold-ish
      color = Colors.amber;
    } else if (type.contains('CRYPTO')) {
      iconData = Icons.currency_bitcoin;
      color = Colors.orange;
    } else if (type.contains('USD')) {
      iconData = Icons.attach_money;
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color),
    );
  }
}
