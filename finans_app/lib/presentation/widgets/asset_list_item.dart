import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/models/asset.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';

class AssetListItem extends StatelessWidget {
  final Asset asset;

  const AssetListItem({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);

    AssetType? assetType;
    try {
      assetType = AssetType.values.firstWhere((e) =>
          e.backendType == asset.type ||
          e.name.toLowerCase() == asset.type.toLowerCase());
    } catch (_) {}

    // Get market symbol and multiplier
    final String marketSymbol = assetType?.symbol ?? asset.symbol ?? '';
    final double multiplier = assetType?.unitMultiplier ?? 1.0;
    final bool isUsdBased = assetType?.isUsdBased ?? false;

    double currentPrice = market.getPrice(marketSymbol);

    // Apply unit multiplier (e.g., PAXG ounce to gram)
    if (currentPrice > 0) {
      currentPrice *= multiplier;

      // Convert to TRY if the asset is priced in USD (Crypto/Commodities)
      if (isUsdBased) {
        currentPrice *= market.usdTryRate;
      }
    }

    // If no market price, use purchase price or unknown (0)
    final double displayPrice =
        currentPrice > 0 ? currentPrice : asset.purchasePrice;
    final double totalValue = asset.quantity * displayPrice;

    // Convert purchase price to TRY for cost if USD based
    double unitCost = asset.purchasePrice;
    if (isUsdBased && market.usdTryRate > 0) {
      unitCost *= market.usdTryRate;
    }

    final double totalCost = asset.quantity * unitCost;

    // Calculate P/L
    double profitLoss = totalValue - totalCost;
    double profitLossPercent = totalCost > 0
        ? (profitLoss / totalCost * 100)
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
                    Text(asset.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Miktar: ${asset.quantity} ${asset.symbol}'),
                    Text(
                        'Alış Fiyatı: ${Formatters.formatMoney(asset.purchasePrice)}${isUsdBased ? " (USD)" : ""}'),
                    const SizedBox(height: 16),
                    if (asset.notes != null && asset.notes!.isNotEmpty)
                      Text('Notlar: ${asset.notes!}',
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddAssetScreen(assetToEdit: asset),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Düzenle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (asset.id != null)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceDark,
                                  title: const Text('Varlığı Sil', style: TextStyle(color: Colors.white)),
                                  content: const Text('Bu varlığı silmek istediğinizden emin misiniz?', style: TextStyle(color: AppTheme.textLight)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('İptal', style: TextStyle(color: AppTheme.textDim)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true && context.mounted) {
                                final success = await Provider.of<PortfolioProvider>(context, listen: false).deleteAsset(asset.id!);
                                if (context.mounted) {
                                  Navigator.pop(context); // Close bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Varlık silindi' : 'Varlık silinirken hata oluştu'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Sil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                            ),
                          ),
                      ],
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${asset.quantity} ${asset.symbol ?? ''}',
                          style: const TextStyle(
                              color: AppTheme.textDim, fontSize: 12),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.formatMoney(profitLoss),
                          style: TextStyle(
                            color: profitLoss >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (profitLoss >= 0 ? Colors.green : Colors.red)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  (profitLoss >= 0 ? Colors.green : Colors.red)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            Formatters.formatPercent(profitLossPercent),
                            style: TextStyle(
                              color: profitLoss >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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

    final normalizedType = type.toLowerCase();
    if (normalizedType.contains('gold') ||
        normalizedType.contains('commodity')) {
      iconData = Icons.monetization_on;
      color = Colors.amber;
    } else if (normalizedType.contains('crypto')) {
      iconData = Icons.currency_bitcoin;
      color = Colors.orange;
    } else if (normalizedType.contains('usd') ||
        normalizedType.contains('currency')) {
      iconData = Icons.payments;
      color = Colors.green;
    } else if (normalizedType.contains('stock')) {
      iconData = Icons.business_center;
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color),
    );
  }
}
