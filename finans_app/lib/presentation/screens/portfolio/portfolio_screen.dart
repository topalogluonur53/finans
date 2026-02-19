import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/presentation/widgets/asset_list_item.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    return Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.assets.isEmpty) {
            return const Center(child: Text('Henüz varlık eklenmedi.'));
          }

          final totalValue = provider.getTotalValue(market);
          final totalCost = provider.getTotalCost();
          final totalPL = totalValue - totalCost;
          final totalPLPercent = totalCost > 0 ? (totalPL / totalCost * 100) : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.secondaryColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text('Portföy Değeri', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatMoney(totalValue),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _summaryItem(
                          'Kâr / Zarar',
                          Formatters.formatMoney(totalPL),
                          totalPL >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                        Container(width: 1, height: 30, color: AppTheme.textDim.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 20)),
                        _summaryItem(
                          'Oran',
                          Formatters.formatPercent(totalPLPercent),
                          totalPL >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Varlıklarım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...provider.assets.map((asset) => Dismissible(
                key: ValueKey('asset_${asset.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Varlık Sil'),
                      content: const Text('Bu varlığı silmek istediğinize emin misiniz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  if (asset.id != null) {
                    provider.deleteAsset(asset.id!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Varlık silindi.')));
                  }
                },
                child: AssetListItem(asset: asset),
              )),
            ],
          );
        }
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

