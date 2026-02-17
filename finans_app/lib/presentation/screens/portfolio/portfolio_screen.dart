import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/presentation/widgets/asset_list_item.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portföyüm')),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.assets.isEmpty) {
            return const Center(child: Text('Henüz varlık eklenmedi.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.assets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final asset = provider.assets[index];
              return Dismissible(
                key: ValueKey('asset_${asset.id}'),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Varlık silindi')));
                  }
                },
                child: AssetListItem(asset: asset),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAssetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

