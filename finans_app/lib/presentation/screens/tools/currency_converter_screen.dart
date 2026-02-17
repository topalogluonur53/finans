import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/market_provider.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'TRY';
  String _toCurrency = 'USD';
  
  // Supported currencies with labels
  static const Map<String, String> _currencies = {
    'TRY': '🇹🇷 Türk Lirası',
    'USD': '🇺🇸 Amerikan Doları',
    'EUR': '🇪🇺 Euro',
    'GOLD': '🥇 Gram Altın',
    'SILVER': '⬜ Gram Gümüş',
    'BTC': '₿ Bitcoin',
    'ETH': 'Ξ Ethereum',
  };

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  double _getRate(MarketProvider market, String currency) {
    // All rates are in TRY per unit
    if (currency == 'TRY') return 1.0;
    final price = market.getPrice(currency);
    return price > 0 ? price : 0;
  }

  double? _convert(MarketProvider market) {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return null;

    final fromRate = _getRate(market, _fromCurrency);
    final toRate = _getRate(market, _toCurrency);
    
    if (fromRate <= 0 || toRate <= 0) return null;

    // Convert: amount * (fromRate / toRate)
    return amount * (fromRate / toRate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Döviz Çevirici')),
      body: Consumer<MarketProvider>(
        builder: (context, market, child) {
          final result = _convert(market);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // From Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kaynak', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _fromCurrency,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: _currencies.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _fromCurrency = val);
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Miktar girin',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),

                // Swap Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: IconButton.filled(
                    onPressed: _swap,
                    icon: const Icon(Icons.swap_vert, size: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),

                // To Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hedef', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _toCurrency,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: _currencies.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _toCurrency = val);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result != null ? Formatters.formatMoney(result) : '---',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: result != null ? AppTheme.secondaryColor : AppTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Rate Info
                if (market.prices.isNotEmpty) ...[
                  const Text('Anlık Kurlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...market.prices.map((data) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            data.symbol.length > 3 ? data.symbol.substring(0, 3) : data.symbol,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                        title: Text(data.symbol),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.formatMoney(data.price),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${data.changePercent >= 0 ? '+' : ''}${data.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: data.changePercent >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ] else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Kur verileri yükleniyor...', style: TextStyle(color: AppTheme.textDim)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
