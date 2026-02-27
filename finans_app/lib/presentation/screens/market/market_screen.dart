import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/presentation/screens/market/market_detail_screen.dart';
import 'package:finans_app/presentation/screens/market/alarm_dialog.dart';
import 'package:finans_app/presentation/screens/market/alarms_screen.dart';
import 'package:finans_app/presentation/widgets/main_drawer.dart';
import 'package:intl/intl.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _showSearch = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MarketData> _filter(List<MarketData> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.symbol.toLowerCase().contains(q))
        .toList();
  }

  /// 5 dakikadan yeni veri → taze (yeşil), aksi halde bayat (turuncu)
  bool _isDataFresh(DateTime lastUpdated) {
    return DateTime.now().difference(lastUpdated) < const Duration(minutes: 5);
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context);

    final allPrices = marketProvider.prices;
    final marketData = {
      'favorites': _filter(
          allPrices.where((p) => marketProvider.isFavorite(p.symbol)).toList()),
      'commodity': _filter(allPrices
          .where((p) => p.category.toLowerCase() == 'commodity')
          .toList()),
      // Borsa: BIST hisseleri + endeksler (is_index dahil)
      'stock': _filter(allPrices
          .where((p) =>
              (p.category.toLowerCase() == 'stock' ||
                  p.category.toLowerCase() == 'index'))
          .toList()),
      'currency': _filter(allPrices
          .where((p) =>
              p.category.toLowerCase() == 'currency' && p.parentSymbol == null)
          .toList()),
      'crypto': _filter(allPrices
          .where((p) => p.category.toLowerCase() == 'crypto')
          .toList()),
    };

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Piyasalar'),
        elevation: 2,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Üst Bölüm: Arama + Sekmeler ──
          Container(
            color: AppTheme.surfaceDark,
            child: Column(
              children: [
                // Arama satırı
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _showSearch ? 52 : 0,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Sembol veya isim ara…',
                              prefixIcon: const Icon(Icons.search,
                                  color: AppTheme.textDim),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: AppTheme.textDim),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Sekme çubuğu
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false, // Ensures symmetric distribution
                        indicatorColor: AppTheme.primaryColor,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textDim,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                        labelStyle: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.normal),
                        tabs: const [
                          Tab(
                              icon: Icon(Icons.star_outline, size: 20),
                              text: 'Favori'),
                          Tab(
                              icon: Icon(Icons.monetization_on_outlined,
                                  size: 20),
                              text: 'Emtia'),
                          Tab(
                              icon: Icon(Icons.business_center_outlined,
                                  size: 20),
                              text: 'Borsa'),
                          Tab(
                              icon: Icon(Icons.payments_outlined, size: 20),
                              text: 'Döviz'),
                          Tab(
                              icon: Icon(Icons.currency_bitcoin_outlined,
                                  size: 20),
                              text: 'Kripto'),
                        ],
                      ),
                    ),
                    // Arama ikonu
                    IconButton(
                      icon: Icon(
                        _showSearch ? Icons.search_off : Icons.search,
                        color: _showSearch
                            ? AppTheme.primaryColor
                            : AppTheme.textDim,
                      ),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Liste veya Yükleniyor ──
          if (marketProvider.isLoading && marketProvider.prices.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (!marketProvider.isLoading &&
              marketProvider.prices.isEmpty &&
              marketProvider.lastError != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_outlined,
                          size: 56, color: AppTheme.textDim),
                      const SizedBox(height: 16),
                      Text(
                        marketProvider.lastError!,
                        style: const TextStyle(
                            color: AppTheme.textDim, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: marketProvider.refreshManual,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMarketList(
                      context, marketData['favorites'] ?? [], marketProvider),
                  _buildMarketList(
                      context, marketData['commodity'] ?? [], marketProvider),
                  _buildMarketList(
                      context, marketData['stock'] ?? [], marketProvider),
                  _buildMarketList(
                      context, marketData['currency'] ?? [], marketProvider),
                  _buildMarketList(
                      context, marketData['crypto'] ?? [], marketProvider),
                ],
              ),
            ),

          // ── Alt bilgi çubuğu ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: AppTheme.backgroundDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (marketProvider.lastUpdated != null)
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _isDataFresh(marketProvider.lastUpdated!)
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Son güncelleme: ${DateFormat('HH:mm').format(marketProvider.lastUpdated!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isDataFresh(marketProvider.lastUpdated!)
                              ? AppTheme.textDim
                              : Colors.orange,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Veri bekleniyor…',
                    style: TextStyle(fontSize: 11, color: AppTheme.textDim),
                  ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlarmsScreen(),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.notifications_outlined,
                              size: 14, color: AppTheme.primaryColor),
                          SizedBox(width: 4),
                          Text(
                            'Alarmlarım',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: marketProvider.refreshManual,
                      child: const Row(
                        children: [
                          Icon(Icons.refresh,
                              size: 14, color: AppTheme.textDim),
                          SizedBox(width: 4),
                          Text(
                            'Yenile',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketList(
      BuildContext context, List<MarketData> prices, MarketProvider provider) {
    if (prices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 48, color: AppTheme.textDim.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? '"$_searchQuery" için sonuç bulunamadı'
                  : 'Veri bulunamadı',
              style: const TextStyle(color: AppTheme.textDim, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refreshManual,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prices.length,
        itemBuilder: (context, index) {
          final price = prices[index];
          return _MarketPriceCard(
            price: price,
            onTap: price.isIndex
                ? () {
                    final constituents = provider.prices
                        .where((p) => p.parentSymbol == price.symbol)
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarketDetailScreen(
                          index: price,
                          constituents: constituents,
                        ),
                      ),
                    );
                  }
                : () => _showAlarmDialog(context, price),
          );
        },
      ),
    );
  }

  void _showAlarmDialog(BuildContext context, MarketData price) {
    showDialog(
      context: context,
      builder: (_) => AlarmDialog(
        prefilledSymbol: price.symbol,
        prefilledPrice: price.price,
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _MarketPriceCard extends StatelessWidget {
  final MarketData price;
  final VoidCallback? onTap;

  const _MarketPriceCard({required this.price, this.onTap});

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    final isFavorite = marketProvider.isFavorite(price.symbol);
    final isPositive = price.changePercent >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    final currency = _resolveCurrency(price);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          // Uzun basınca alarm kur
          showDialog(
            context: context,
            builder: (_) => AlarmDialog(
              prefilledSymbol: price.symbol,
              prefilledPrice: price.price,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
          child: Row(
            children: [
              // Favori butonu
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : AppTheme.textDim,
                  size: 22,
                ),
                onPressed: () => marketProvider.toggleFavorite(price.symbol),
              ),
              // İkon
              _buildItemIcon(),
              const SizedBox(width: 12),
              // İsim + kategori
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCategoryLabel(price.category),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textDim),
                    ),
                  ],
                ),
              ),
              // Fiyat + değişim
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatMoney(price.price, currency: currency),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 14, color: changeColor),
                      const SizedBox(width: 2),
                      Text(
                        Formatters.formatPercent(price.changePercent),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: changeColor,
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
    );
  }

  String _resolveCurrency(MarketData p) {
    if (p.category == 'crypto') return 'USD';
    if (p.symbol.contains('TRY') ||
        p.category == 'stock' ||
        p.symbol.startsWith('GRAM') ||
        p.symbol.startsWith('CEYREK') ||
        p.symbol.startsWith('YARIM') ||
        p.symbol.startsWith('TAM') ||
        p.symbol.startsWith('CUMHURIYET') ||
        p.symbol.startsWith('22-AYAR')) {
      return 'TRY';
    }
    return 'USD';
  }

  Widget _buildItemIcon() {
    if (price.imageUrl != null) {
      return Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.network(
          price.imageUrl!,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    IconData icon;
    Color color;
    switch (price.category) {
      case 'crypto':
        icon = Icons.currency_bitcoin;
        color = Colors.orange;
        break;
      case 'commodity':
        icon = Icons.monetization_on;
        color = Colors.amber;
        break;
      case 'currency':
        icon = Icons.payments;
        color = Colors.green;
        break;
      default:
        icon = Icons.business_center;
        color = AppTheme.primaryColor;
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'commodity':
        return 'EMTİA';
      case 'stock':
      case 'index':
        return 'BORSA / ENDEKS';
      case 'currency':
        return 'DÖVİZ';
      case 'crypto':
        return 'KRİPTO';
      default:
        return category.toUpperCase();
    }
  }
}
