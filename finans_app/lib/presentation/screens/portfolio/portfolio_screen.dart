import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/models/asset.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/providers/binance_provider.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/presentation/widgets/asset_list_item.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';
import 'package:finans_app/presentation/widgets/main_drawer.dart';
import 'package:fl_chart/fl_chart.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTag;

  static const _tabs = [
    (label: 'Tümü', category: null),
    (label: '🪙 Emtia', category: AssetCategory.commodity),
    (label: '₿ Kripto', category: AssetCategory.crypto),
    (label: '💱 Döviz', category: AssetCategory.currency),
    (label: '📈 Borsa', category: AssetCategory.stock),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AssetCategory? get _selectedCategory => _tabs[_tabController.index].category;

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    final binance = Provider.of<BinanceProvider>(context);

    return Consumer<PortfolioProvider>(builder: (context, portfolio, child) {
      if (portfolio.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final filteredAssets = portfolio.assets.where((a) {
        if (_selectedTag != null && a.tag != _selectedTag) {
          return false;
        }
        if (_selectedCategory != null) {
          try {
            final type = AssetType.values.firstWhere((e) =>
                e.backendType == a.type ||
                e.name.toLowerCase() == a.type.toLowerCase());
            if (type.category != _selectedCategory) {
              return false;
            }
          } catch (_) {
            return false;
          }
        }
        return true;
      }).toList();

      // Extract unique tags
      final uniqueTags = portfolio.assets
          .map((a) => a.tag)
          .whereType<String>()
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();

      double binanceValue = (binance.totalUsdtBalance ?? 0) *
          (market.usdTryRate > 0 ? market.usdTryRate : 1.0);
      double binanceCost = binanceValue; // To prevent P/L distortion

      final totalValue = portfolio.getTotalValue(market) + binanceValue;
      final totalCost = portfolio.getTotalCost(market) + binanceCost;
      final totalPL = totalValue - totalCost;
      final totalPLPercent = totalCost > 0 ? (totalPL / totalCost * 100) : 0.0;
      final isPLPositive = totalPL >= 0;

      // Filtered totals
      double filteredValue = 0;
      double filteredCost = 0;
      for (final a in filteredAssets) {
        filteredValue += portfolio.getAssetCurrentValue(a, market);
        filteredCost += portfolio.getAssetCost(a, market);
      }

      if (_selectedCategory == AssetCategory.crypto ||
          _selectedCategory == null) {
        filteredValue += binanceValue;
        filteredCost += binanceCost;
      }

      final filteredPL = filteredValue - filteredCost;
      final filteredPLPercent =
          filteredCost > 0 ? (filteredPL / filteredCost * 100) : 0.0;

      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        drawer: const MainDrawer(),
        appBar: AppBar(
          title: const Text('Portfolyo'),
          elevation: 2,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_chart_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAssetScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
          // ─── Summary Card ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _PortfolioSummaryCard(
              totalValue: _selectedCategory == null ? totalValue : filteredValue,
              totalCost: _selectedCategory == null ? totalCost : filteredCost,
              totalPL: _selectedCategory == null ? totalPL : filteredPL,
              totalPLPercent: _selectedCategory == null
                  ? totalPLPercent
                  : filteredPLPercent,
              isPLPositive: _selectedCategory == null
                  ? isPLPositive
                  : filteredPL >= 0,
              isFiltered: _selectedCategory != null,
              selectedCategory: _selectedCategory,
              assets: filteredAssets,
              market: market,
              portfolio: portfolio,
            ),
          ),

          // ─── Tab Bar ─────────────────────────────────────────────────
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textDim,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _tabs
                  .map((t) => Tab(text: t.label))
                  .toList(),
            ),
          ),

          // ─── Tag Filter List ──────────────────────────────────────────
          if (uniqueTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Tüm Etiketler'),
                      selected: _selectedTag == null,
                      onSelected: (selected) {
                        setState(() => _selectedTag = null);
                      },
                      backgroundColor: AppTheme.surfaceDark,
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                          color: _selectedTag == null ? AppTheme.primaryColor : AppTheme.textDim,
                          fontWeight: _selectedTag == null ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12),
                    ),
                  ),
                  ...uniqueTags.map((tag) {
                    final isSelected = _selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedTag = selected ? tag : null);
                        },
                        backgroundColor: AppTheme.surfaceDark,
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textDim,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ─── Asset List ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (portfolio.assets.isEmpty && _selectedCategory != AssetCategory.crypto)
                  _EmptyState()
                else if (filteredAssets.isEmpty && (_selectedCategory == AssetCategory.crypto || _selectedCategory != null))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        _selectedCategory == AssetCategory.crypto 
                            ? 'Bu kategoride manuel eklenmiş varlık yok.' 
                            : 'Bu kategoride varlık yok.',
                        style: const TextStyle(color: AppTheme.textDim),
                      ),
                    ),
                  ),

                if (filteredAssets.isNotEmpty)
                  ...filteredAssets.map(
                            (asset) => Dismissible(
                              key: ValueKey('asset_${asset.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.errorColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        color: AppTheme.errorColor),
                                    SizedBox(height: 4),
                                    Text('Sil',
                                        style: TextStyle(
                                            color: AppTheme.errorColor,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppTheme.surfaceDark,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    title: const Text('Varlık Sil',
                                        style: TextStyle(
                                            color: AppTheme.textLight)),
                                    content: const Text(
                                        'Bu varlığı silmek istediğinize emin misiniz?',
                                        style: TextStyle(
                                            color: AppTheme.textDim)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('İptal',
                                              style: TextStyle(
                                                  color: AppTheme.textDim))),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Sil',
                                              style: TextStyle(
                                                  color: AppTheme.errorColor))),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                if (asset.id != null) {
                                  portfolio.deleteAsset(asset.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Varlık silindi.')),
                                  );
                                }
                              },
                              child: AssetListItem(asset: asset),
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
    });
  }
}

// ─── Portfolio Summary Card ────────────────────────────────────────────────────

class _PortfolioSummaryCard extends StatelessWidget {
  final double totalValue;
  final double totalCost;
  final double totalPL;
  final double totalPLPercent;
  final bool isPLPositive;
  final bool isFiltered;
  final AssetCategory? selectedCategory;
  final List<Asset> assets;
  final MarketProvider market;
  final PortfolioProvider portfolio;

  const _PortfolioSummaryCard({
    required this.totalValue,
    required this.totalCost,
    required this.totalPL,
    required this.totalPLPercent,
    required this.isPLPositive,
    required this.isFiltered,
    this.selectedCategory,
    required this.assets,
    required this.market,
    required this.portfolio,
  });

  static const List<Color> _chartColors = [
    Color(0xFF6C63FF),
    Color(0xFF00C853),
    Color(0xFFFF6D00),
    Color(0xFF00B0FF),
    Color(0xFFFF3D00),
    Color(0xFFFFD600),
  ];

  @override
  Widget build(BuildContext context) {
    final plColor = isPLPositive ? AppTheme.secondaryColor : AppTheme.errorColor;

    // Calculate grouping for mini pie chart
    Map<String, double> typeValues = {};
    for (var asset in assets) {
      final value = portfolio.getAssetCurrentValue(asset, market);
      if (value > 0) {
        typeValues[asset.name] = (typeValues[asset.name] ?? 0) + value;
      }
    }
    
    // Add binance to mini pie chart
    try {
      final binance = Provider.of<BinanceProvider>(context, listen: false);
      double binanceValue = (binance.totalUsdtBalance ?? 0) * (market.usdTryRate > 0 ? market.usdTryRate : 1.0);
      if (binanceValue > 0 && (selectedCategory == null || selectedCategory == AssetCategory.crypto)) {
         typeValues['Binance'] = (typeValues['Binance'] ?? 0) + binanceValue;
      }
    } catch (_) {}
    
    final entries = typeValues.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.textDim.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Values
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFiltered ? 'Kategori Değeri' : 'Portföy Değeri',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatMoney(totalValue),
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: plColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPLPositive ? Icons.trending_up : Icons.trending_down,
                            color: plColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatMoney(totalPL.abs()),
                            style: TextStyle(
                              color: plColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isPLPositive ? '+' : ''}${Formatters.formatPercent(totalPLPercent)}',
                      style: TextStyle(
                        color: plColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Maliyet: ${Formatters.formatMoney(totalCost)}',
                  style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Right Side: Mini Pie Chart
          if (entries.isNotEmpty && totalValue > 0)
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      startDegreeOffset: -90,
                      sections: entries.asMap().entries.map((mapEntry) {
                        final idx = mapEntry.key;
                        final entry = mapEntry.value;
                        return PieChartSectionData(
                          color: _chartColors[idx % _chartColors.length],
                          value: entry.value,
                          title: '',
                          radius: 10,
                        );
                      }).toList(),
                    ),
                  ),
                  Icon(
                    Icons.pie_chart_rounded,
                    color: AppTheme.textDim.withOpacity(0.3),
                    size: 24,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline,
                size: 64,
                color: AppTheme.textDim.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Portföyünüz boş',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight),
            ),
            const SizedBox(height: 8),
            const Text(
              'İlk varlığınızı ekleyerek başlayın.',
              style: TextStyle(color: AppTheme.textDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAssetScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Varlık Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
