import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/models/ipo.dart';
import 'package:finans_app/data/services/ipo_service.dart';
import 'package:finans_app/presentation/screens/tools/ipo_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:finans_app/data/models/ipo_news.dart';
import 'package:finans_app/data/models/ipo_portfolio_item.dart';
import 'package:finans_app/data/services/ipo_portfolio_service.dart';

class IPOScreen extends StatefulWidget {
  const IPOScreen({super.key});

  @override
  State<IPOScreen> createState() => _IPOScreenState();
}

class _IPOScreenState extends State<IPOScreen>
    with SingleTickerProviderStateMixin {
  final IPOService _service = IPOService();
  late TabController _tabController;

  List<IPO> _upcomingIPOs = [];
  List<IPO> _recentIPOs = [];
  List<IPONews> _ipoNews = [];
  List<IPOPortfolioItem> _portfolioItems = [];
  final IPOPortfolioService _portfolioService = IPOPortfolioService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadIPOData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIPOData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (forceRefresh) {
      await _service.clearCache();
    }

    try {
      final results = await Future.wait([
        _service.fetchIPOCalendar(forceRefresh: forceRefresh),
        _service.fetchIPONews(forceRefresh: forceRefresh),
        _portfolioService.getPortfolio(),
      ]);

      final List<IPO> allIPOs = results[0] as List<IPO>;
      final List<IPONews> news = results[1] as List<IPONews>;
      final List<IPOPortfolioItem> portfolio =
          results[2] as List<IPOPortfolioItem>;

      setState(() {
        _upcomingIPOs = allIPOs.where((ipo) => ipo.isUpcoming).toList();
        _recentIPOs = allIPOs
            .where((ipo) => !ipo.isUpcoming && !ipo.isWithdrawn)
            .toList();
        _ipoNews = news;
        _portfolioItems = portfolio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Veriler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halka Arz (IPO)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadIPOData(forceRefresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textDim,
          tabs: [
            Tab(
              icon: const Icon(Icons.upcoming),
              text: 'Yaklaşan (${_upcomingIPOs.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Son Arzlar (${_recentIPOs.length})',
            ),
            Tab(
              icon: const Icon(Icons.account_balance_wallet),
              text: 'Portföyüm',
            ),
            Tab(
              icon: const Icon(Icons.newspaper),
              text: 'Haberler',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIPOList(_upcomingIPOs, isUpcoming: true),
                    _buildIPOList(_recentIPOs, isUpcoming: false),
                    _buildPortfolioList(),
                    _buildNewsList(),
                  ],
                ),
    );
  }

  Widget _buildNewsList() {
    if (_ipoNews.isEmpty) {
      return const Center(child: Text('Güncel haber bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadIPOData(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ipoNews.length,
        itemBuilder: (context, index) {
          final news = _ipoNews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.surfaceDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final uri = Uri.parse(news.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            news.source,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          news.displayDate,
                          style: const TextStyle(
                              color: AppTheme.textDim, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textDim, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Haberin Devamı',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.arrow_right,
                            color: AppTheme.primaryColor, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textDim),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadIPOData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIPOList(List<IPO> ipos, {required bool isUpcoming}) {
    if (ipos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_busy : Icons.history_toggle_off,
              size: 64,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? 'Yaklaşan halka arz bulunamadı'
                  : 'Son 30 günde halka arz bulunamadı',
              style: const TextStyle(color: AppTheme.textDim),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadIPOData(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ipos.length,
        itemBuilder: (context, index) {
          return _IPOCard(ipo: ipos[index]);
        },
      ),
    );
  }

  Widget _buildPortfolioList() {
    if (_portfolioItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppTheme.textDim),
            const SizedBox(height: 16),
            const Text('Portföyünüzde henüz halka arz yok',
                style: TextStyle(color: AppTheme.textDim)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0);
              },
              icon: const Icon(Icons.add),
              label: const Text('Yeni Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      );
    }

    double totalCost = 0;
    double totalValue = 0;
    for (var item in _portfolioItems) {
      totalCost += item.totalCost;
      totalValue += item.currentValue;
    }
    double totalProfit = totalValue - totalCost;
    double totalProfitPct = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Toplam Kar/Zarar',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                  Text(
                    '${totalProfit >= 0 ? '+' : ''}${totalProfit.toStringAsFixed(2)} TL',
                    style: TextStyle(
                      color: totalProfit >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Getiri Oranı',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                  Text(
                    '${totalProfitPct >= 0 ? '+' : ''}${totalProfitPct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: totalProfitPct >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _portfolioItems.length,
            itemBuilder: (context, index) {
              final item = _portfolioItems[index];
              return _PortfolioCard(
                  item: item,
                  onRemove: () => _removePortfolioItem(item.symbol));
            },
          ),
        ),
      ],
    );
  }

  void _removePortfolioItem(String symbol) async {
    await _portfolioService.removeParticipant(symbol);
    _loadIPOData();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Halka Arz Bilgilendirme',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu sayfa, yaklaşan ve son 30 gündeki halka arz (IPO) bilgilerini gösterir.',
                style: TextStyle(color: AppTheme.textDim),
              ),
              SizedBox(height: 12),
              Text(
                '📊 Gösterilen Bilgiler:',
                style: TextStyle(
                    color: AppTheme.textLight, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Şirket adı ve sembolü',
                  style: TextStyle(color: AppTheme.textDim)),
              Text('• Borsa (NASDAQ, NYSE, vb.)',
                  style: TextStyle(color: AppTheme.textDim)),
              Text('• Halka arz tarihi',
                  style: TextStyle(color: AppTheme.textDim)),
              Text('• Fiyat aralığı veya kesin fiyat',
                  style: TextStyle(color: AppTheme.textDim)),
              Text('• Hisse sayısı', style: TextStyle(color: AppTheme.textDim)),
              SizedBox(height: 12),
              Text(
                '⚠️ Not: Veriler üçüncü parti API\'lerden alınmaktadır. Yatırım kararlarınızı vermeden önce resmi kaynaklardan doğrulama yapınız.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _IPOCard extends StatelessWidget {
  final IPO ipo;

  const _IPOCard({required this.ipo});

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IPODetailScreen(ipo: ipo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Company & Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ipo.company,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ipo.symbol,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ipo.exchange,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textDim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details
              _buildDetailRow(Icons.calendar_today, 'Tarih', ipo.displayDate),
              if (ipo.priceRange != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.attach_money, 'Fiyat Aralığı', ipo.priceRange!),
              ],
              if (ipo.price != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.price_check,
                    'Fiyat',
                    ipo.exchange == 'BIST'
                        ? '${ipo.price!.toStringAsFixed(2)} TL'
                        : '\$${ipo.price!.toStringAsFixed(2)}'),
              ],
              if (ipo.numberOfShares != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.pie_chart,
                  'Hisse Sayısı',
                  '${(ipo.numberOfShares! / 1000000).toStringAsFixed(1)}M',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textDim),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDim,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final IPOPortfolioItem item;
  final VoidCallback onRemove;

  const _PortfolioCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    bool isProfit = item.profitLoss >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.company,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight)),
                      const SizedBox(height: 4),
                      Text(item.symbol,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surfaceDark,
                        title: const Text('Sil',
                            style: TextStyle(color: AppTheme.textLight)),
                        content: const Text(
                            'Bu kaydı silmek istediğinize emin misiniz?',
                            style: TextStyle(color: AppTheme.textDim)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('İptal',
                                  style: TextStyle(color: Colors.grey))),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onRemove();
                              },
                              child: const Text('Sil',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Adet', '${item.quantity}'),
                _buildStatColumn(
                    'Maliyet', '${item.costPrice.toStringAsFixed(2)} TL'),
                _buildStatColumn('Güncel',
                    '${item.isSold ? (item.soldPrice ?? 0).toStringAsFixed(2) : item.currentPrice.toStringAsFixed(2)} TL',
                    color: item.isSold ? Colors.orange : null),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isProfit ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      item.isSold
                          ? 'Gerçekleşen Kar/Zarar'
                          : 'Potansiyel Kar/Zarar',
                      style: TextStyle(
                          color: isProfit ? Colors.green : Colors.red,
                          fontSize: 12)),
                  Text(
                    '${isProfit ? '+' : ''}${item.profitLoss.toStringAsFixed(2)} TL (${isProfit ? '+' : ''}${item.profitLossPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                        color: isProfit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color ?? AppTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}
