import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/providers/binance_provider.dart';

class BinanceBalanceCard extends StatelessWidget {
  const BinanceBalanceCard({super.key});

  void _showSetupDialog(BuildContext context) {
    final keyController = TextEditingController();
    final secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Binance Bağlantısı', style: TextStyle(color: AppTheme.textLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Binance hesabınızı bağlamak için API Key ve Secret Key giriniz. Sadece Okuma (Read-Only) yetkisi olan anahtar kullanın.',
                style: TextStyle(color: AppTheme.textDim, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  labelStyle: TextStyle(color: AppTheme.textDim),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textDim)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secretController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  labelStyle: TextStyle(color: AppTheme.textDim),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textDim)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppTheme.textDim)),
            ),
            ElevatedButton(
              onPressed: () {
                final k = keyController.text.trim();
                final s = secretController.text.trim();
                if (k.isNotEmpty && s.isNotEmpty) {
                  Navigator.pop(context);
                  context.read<BinanceProvider>().saveKeys(k, s);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD535)),
              child: const Text('Bağla', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    final binance = Provider.of<BinanceProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD535).withOpacity(0.3)),
      ),
      child: binance.isConnected
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Color(0xFFFCD535), size: 24),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Binance Cüzdanı',
                              style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: binance.fetchBalance,
                          icon: const Icon(Icons.refresh, color: AppTheme.textDim, size: 20),
                        ),
                        IconButton(
                          onPressed: binance.logout,
                          icon: const Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (binance.isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFCD535)))
                else if (binance.error != null)
                  Text(binance.error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))
                else if (binance.totalUsdtBalance != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.formatMoney(binance.totalUsdtBalance! * (market.usdTryRate > 0 ? market.usdTryRate : 1.0)),
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.formatMoney(binance.totalUsdtBalance!, currency: 'USD')} (USDT Toplam)',
                        style: const TextStyle(color: AppTheme.textDim, fontSize: 14),
                      ),
                    ],
                  ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Color(0xFFFCD535), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Binance Hesabını Bağla',
                              style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Otomatik bakiye senkronizasyonu',
                              style: TextStyle(color: AppTheme.textDim, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showSetupDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCD535),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Bağla', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }
}

