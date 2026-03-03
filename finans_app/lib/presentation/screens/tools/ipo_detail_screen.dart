import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/models/ipo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finans_app/data/models/ipo_portfolio_item.dart';
import 'package:finans_app/data/services/ipo_portfolio_service.dart';

class IPODetailScreen extends StatelessWidget {
  final IPO ipo;

  const IPODetailScreen({super.key, required this.ipo});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDim,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToPortfolio(BuildContext context) {
    int quantity = 1;
    double price = ipo.price ?? 0.0;
    
    // Parse priceRange if price is null
    if (price == 0.0 && ipo.priceRange != null) {
      try {
        final matches = RegExp(r'([\d.,]+)').firstMatch(ipo.priceRange!);
        if (matches != null) {
          price = double.parse(matches.group(1)!.replaceAll(',', '.'));
        }
      } catch (e) {
        // ignore
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Portföye Ekle', style: TextStyle(color: AppTheme.textLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                style: const TextStyle(color: AppTheme.textLight),
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Adet', labelStyle: TextStyle(color: AppTheme.textDim)),
                onChanged: (val) => quantity = int.tryParse(val) ?? 1,
              ),
              TextFormField(
                style: const TextStyle(color: AppTheme.textLight),
                initialValue: price.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Maliyet Fiyatı', labelStyle: TextStyle(color: AppTheme.textDim)),
                onChanged: (val) => price = double.tryParse(val) ?? price,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final item = IPOPortfolioItem(
                  symbol: ipo.symbol,
                  company: ipo.company,
                  quantity: quantity,
                  costPrice: price,
                  currentPrice: ipo.price ?? price, // If current price is not known, fallback to cost
                );
                final service = IPOPortfolioService();
                await service.addParticipant(item);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Portföye eklendi. Listeyi yenileyin.')));
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (ipo.isWithdrawn) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (ipo.isPriced) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ipo.symbol),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ipo.company,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ipo.exchange,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        ipo.statusLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Halka Arz Detayları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.calendar_today, 'Halka Arz Tarihi', ipo.displayDate),
                  if (ipo.priceRange != null) ...[
                    Divider(color: Colors.grey.withValues(alpha: 0.2), height: 24),
                    _buildDetailRow(Icons.sync_alt, 'Fiyat Aralığı', ipo.priceRange!),
                  ],
                  if (ipo.price != null) ...[
                    Divider(color: Colors.grey.withValues(alpha: 0.2), height: 24),
                    _buildDetailRow(
                      Icons.price_check, 
                      'Kesin Fiyat', 
                      ipo.exchange == 'BIST' 
                          ? '${ipo.price!.toStringAsFixed(2)} TL' 
                          : '\$${ipo.price!.toStringAsFixed(2)}'
                    ),
                  ],
                  if (ipo.numberOfShares != null) ...[
                    Divider(color: Colors.grey.withValues(alpha: 0.2), height: 24),
                    _buildDetailRow(
                      Icons.pie_chart,
                      'Toplam Dağıtılacak Pay',
                      ipo.numberOfShares!.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _addToPortfolio(context),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text(
                  'Portföyüme Ekle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (ipo.url != null)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(ipo.url!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text(
                    'Daha Fazla Bilgi İçin Web Sitesi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
