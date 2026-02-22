import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/data/providers/market_provider.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'TRY';
  String _toCurrency = 'USD';
  late TabController _tabController;

  // Supported currencies with labels and flags
  static const Map<String, Map<String, String>> _currencies = {
    'TRY': {'label': 'Türk Lirası', 'flag': '🇹🇷', 'symbol': '₺'},
    'USD': {'label': 'Amerikan Doları', 'flag': '🇺🇸', 'symbol': '\$'},
    'EUR': {'label': 'Euro', 'flag': '🇪🇺', 'symbol': '€'},
    'GBP': {'label': 'İngiliz Sterlini', 'flag': '🇬🇧', 'symbol': '£'},
    'JPY': {'label': 'Japon Yeni', 'flag': '🇯🇵', 'symbol': '¥'},
    'CHF': {'label': 'İsviçre Frangı', 'flag': '🇨🇭', 'symbol': 'Fr'},
    'GOLD': {'label': 'Gram Altın', 'flag': '🥇', 'symbol': 'g'},
    'SILVER': {'label': 'Gram Gümüş', 'flag': '⬜', 'symbol': 'g'},
    'BTC': {'label': 'Bitcoin', 'flag': '₿', 'symbol': '₿'},
    'ETH': {'label': 'Ethereum', 'flag': 'Ξ', 'symbol': 'Ξ'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  // Returns TRY value per 1 unit of currency
  double _getRate(MarketProvider market, String currency) {
    if (currency == 'TRY') return 1.0;
    // Map converter symbols to market symbols
    const symbolMap = {
      'USD': 'USDTRY=X',
      'EUR': 'EURTRY=X',
      'GBP': 'GBPTRY=X',
      'JPY': 'JPYTRY=X',
      'CHF': 'CHFTRY=X',
      'GOLD': 'GRAM-ALTIN',
      'SILVER': 'GRAM-GUMUS',
      'BTC': 'BTCUSDT',
      'ETH': 'ETHUSDT',
    };
    final marketSymbol = symbolMap[currency] ?? currency;
    double price = market.getPrice(marketSymbol);
    // BTC/ETH are in USD, convert to TRY
    if ((currency == 'BTC' || currency == 'ETH') && price > 0) {
      final usdTry = market.getPrice('USDTRY=X');
      if (usdTry > 0) price = price * usdTry;
    }
    return price > 0 ? price : 0;
  }

  double? _convert(MarketProvider market, {String? from, String? to, double? amount}) {
    final amt = amount ?? double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amt == null || amt <= 0) return null;

    final fromRate = _getRate(market, from ?? _fromCurrency);
    final toRate = _getRate(market, to ?? _toCurrency);

    if (fromRate <= 0 || toRate <= 0) return null;
    return amt * (fromRate / toRate);
  }

  String _formatResult(double value, String currency) {
    final info = _currencies[currency];
    final symbol = info?['symbol'] ?? '';
    if (value >= 1000000) {
      return '$symbol${(value / 1000000).toStringAsFixed(4)}M';
    } else if (value >= 1000) {
      return Formatters.formatMoney(value, currency: currency == 'USD' ? 'USD' : 'TRY')
          .replaceFirst('₺', symbol)
          .replaceFirst('\$', symbol);
    } else {
      return '$symbol${value.toStringAsFixed(4)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Döviz Çevirici'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textDim,
          tabs: const [
            Tab(text: 'Çevirici', icon: Icon(Icons.currency_exchange)),
            Tab(text: 'Tüm Kurlar', icon: Icon(Icons.table_chart)),
          ],
        ),
      ),
      body: Consumer<MarketProvider>(
        builder: (context, market, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildConverterTab(market),
              _buildAllRatesTab(market),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConverterTab(MarketProvider market) {
    final result = _convert(market);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // From Card
          _CurrencyCard(
            label: 'Kaynak Para Birimi',
            currency: _fromCurrency,
            currencies: _currencies,
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(
                    text: newValue.text.replaceAll('.', ','),
                    selection: TextSelection.collapsed(offset: newValue.selection.end),
                  );
                }),
              ],
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight),
              decoration: InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.transparent,
                hintText: '0',
                prefixText:
                    '${_currencies[_fromCurrency]?['flag'] ?? ''} ${_currencies[_fromCurrency]?['symbol'] ?? ''} ',
                prefixStyle: const TextStyle(
                    fontSize: 20, color: AppTheme.textDim),
              ),
              onChanged: (_) => setState(() {}),
            ),
            onCurrencyChanged: (val) {
              if (val != null) setState(() => _fromCurrency = val);
            },
          ),

          // Swap button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                GestureDetector(
                  onTap: _swap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF9C8FFF)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.swap_vert, color: Colors.white, size: 28),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
          ),

          // To Card
          _CurrencyCard(
            label: 'Hedef Para Birimi',
            currency: _toCurrency,
            currencies: _currencies,
            child: result != null
                ? Text(
                    '${_currencies[_toCurrency]?['flag'] ?? ''} ${_formatResult(result, _toCurrency)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  )
                : const Text(
                    '---',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDim),
                  ),
            onCurrencyChanged: (val) {
              if (val != null) setState(() => _toCurrency = val);
            },
            readOnly: true,
          ),

          // Rate info
          if (result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppTheme.textDim),
                  const SizedBox(width: 6),
                  Text(
                    '1 ${_currencies[_fromCurrency]?['label']} = '
                    '${_formatResult(1 / (_convert(market, amount: 1) ?? 1), _toCurrency)} ${_currencies[_toCurrency]?['label']}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textDim),
                  ),
                ],
              ),
            ),
          ],

          // Quick amounts
          const SizedBox(height: 16),
          _buildQuickAmounts(market),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts(MarketProvider market) {
    const amounts = [100.0, 500.0, 1000.0, 5000.0, 10000.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hızlı Çeviri',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDim)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: amounts.length,
          itemBuilder: (context, idx) {
            final amount = amounts[idx];
            final result = _convert(market, amount: amount);
            return GestureDetector(
              onTap: () {
                _amountController.text = amount.toStringAsFixed(0);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${amount.toStringAsFixed(0)} ${_currencies[_fromCurrency]?['symbol']}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textDim),
                    ),
                    if (result != null)
                      Text(
                        _formatResult(result, _toCurrency),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAllRatesTab(MarketProvider market) {
    final currencyKeys = _currencies.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRY Bazlı Kurlar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tüm fiyatlar TL cinsinden',
              style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
          const SizedBox(height: 12),
          ...currencyKeys.where((c) => c != 'TRY').map((currency) {
            final rate = _getRate(market, currency);
            final info = _currencies[currency]!;
            // Find change from market data
            double? changePercent;
            try {
              final marketData =
                  market.prices.firstWhere((d) => d.symbol == currency);
              changePercent = marketData.changePercent;
            } catch (_) {}

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Flag + symbol
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(info['flag']!,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currency,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textLight)),
                        Text(info['label']!,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textDim)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rate > 0 ? Formatters.formatMoney(rate) : '---',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                            fontSize: 15),
                      ),
                      if (changePercent != null)
                        Text(
                          '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: changePercent >= 0
                                ? AppTheme.secondaryColor
                                : AppTheme.errorColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final String label;
  final String currency;
  final Map<String, Map<String, String>> currencies;
  final Widget child;
  final ValueChanged<String?> onCurrencyChanged;
  final bool readOnly;

  const _CurrencyCard({
    required this.label,
    required this.currency,
    required this.currencies,
    required this.child,
    required this.onCurrencyChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textDim)),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currency,
              dropdownColor: AppTheme.surfaceDark,
              isExpanded: true,
              style: const TextStyle(
                  color: AppTheme.textLight, fontSize: 15),
              items: currencies.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                      '${e.value['flag']} ${e.value['label']} (${e.key})'),
                );
              }).toList(),
              onChanged: onCurrencyChanged,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
