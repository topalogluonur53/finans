import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/models/ipo.dart';
import 'package:finans_app/data/services/ipo_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:finans_app/data/models/ipo_news.dart';

class IPOScreen extends StatefulWidget {
  const IPOScreen({super.key});

  @override
  State<IPOScreen> createState() => _IPOScreenState();
}

class _IPOScreenState extends State<IPOScreen> with SingleTickerProviderStateMixin {
  final IPOService _service = IPOService();
  late TabController _tabController;
  
  List<IPO> _upcomingIPOs = [];
  List<IPO> _recentIPOs = [];
  List<IPONews> _ipoNews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadIPOData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIPOData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchIPOCalendar(),
        _service.fetchIPONews(),
      ]);
      
      final List<IPO> allIPOs = results[0] as List<IPO>;
      final List<IPONews> news = results[1] as List<IPONews>;
      
      setState(() {
        _upcomingIPOs = allIPOs.where((ipo) => ipo.isUpcoming).toList();
        _recentIPOs = allIPOs.where((ipo) => !ipo.isUpcoming && !ipo.isWithdrawn).toList();
        _ipoNews = news;
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
            onPressed: _loadIPOData,
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
              text: 'Son 30 Gün (${_recentIPOs.length})',
            ),
            Tab(
              icon: const Icon(Icons.newspaper),
              text: 'Haberler (${_ipoNews.length})',
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
      onRefresh: _loadIPOData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ipoNews.length,
        itemBuilder: (context, index) {
          final news = _ipoNews[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          style: const TextStyle(color: AppTheme.textDim, fontSize: 10),
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
                      style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
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
                        Icon(Icons.arrow_right, color: AppTheme.primaryColor, size: 20),
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
              onPressed: _loadIPOData,
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
              isUpcoming ? 'Yaklaşan halka arz bulunamadı' : 'Son 30 günde halka arz bulunamadı',
              style: const TextStyle(color: AppTheme.textDim),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIPOData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ipos.length,
        itemBuilder: (context, index) {
          return _IPOCard(ipo: ipos[index]);
        },
      ),
    );
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
                style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Şirket adı ve sembolü', style: TextStyle(color: AppTheme.textDim)),
              Text('• Borsa (NASDAQ, NYSE, vb.)', style: TextStyle(color: AppTheme.textDim)),
              Text('• Halka arz tarihi', style: TextStyle(color: AppTheme.textDim)),
              Text('• Fiyat aralığı veya kesin fiyat', style: TextStyle(color: AppTheme.textDim)),
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
            child: const Text('Anladım', style: TextStyle(color: AppTheme.primaryColor)),
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
        onTap: () => _showIPODetails(context),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                _buildDetailRow(Icons.attach_money, 'Fiyat Aralığı', ipo.priceRange!),
              ],
              if (ipo.price != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.price_check, 'Fiyat', '\$${ipo.price!.toStringAsFixed(2)}'),
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

  void _showIPODetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ipo.company,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ipo.symbol} • ${ipo.exchange}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDim,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.calendar_today, 'Halka Arz Tarihi', ipo.displayDate),
            const SizedBox(height: 12),
            if (ipo.priceRange != null)
              _buildDetailRow(Icons.attach_money, 'Fiyat Aralığı', ipo.priceRange!),
            if (ipo.price != null)
              _buildDetailRow(Icons.price_check, 'Kesin Fiyat', '\$${ipo.price!.toStringAsFixed(2)}'),
            if (ipo.numberOfShares != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.pie_chart,
                'Toplam Hisse',
                ipo.numberOfShares!.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (ipo.url != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchURL(ipo.url!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Detaylı Bilgi'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
