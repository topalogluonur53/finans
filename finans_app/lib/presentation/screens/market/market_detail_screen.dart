import 'package:flutter/material.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';
import 'alarm_dialog.dart';

class MarketDetailScreen extends StatelessWidget {
  final MarketData index;
  final List<MarketData> constituents;

  const MarketDetailScreen({
    super.key,
    required this.index,
    required this.constituents,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = index.changePercent >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(index.name),
        actions: [
          // Alarm kurma butonu
          IconButton(
            icon: const Icon(Icons.add_alert_outlined, color: AppTheme.primaryColor),
            tooltip: 'Bu varlık için alarm kur',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlarmDialog(
                  prefilledSymbol: index.symbol,
                  prefilledPrice: index.price,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Üst Özet Kartı ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                // Fiyat + Değişim Satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Güncel Değer',
                          style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatMoney(index.price),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _changeIndicator(index.changePercent),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Gün içi istatistikler ──
                if (index.openPrice != null ||
                    index.dayHigh != null ||
                    index.dayLow != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (index.openPrice != null)
                          _StatItem(
                            label: 'Açılış',
                            value: Formatters.formatMoney(index.openPrice!),
                            icon: Icons.open_in_new,
                            color: AppTheme.textDim,
                          ),
                        if (index.dayHigh != null)
                          _StatItem(
                            label: 'Gün Yüksek',
                            value: Formatters.formatMoney(index.dayHigh!),
                            icon: Icons.arrow_upward,
                            color: Colors.green,
                          ),
                        if (index.dayLow != null)
                          _StatItem(
                            label: 'Gün Düşük',
                            value: Formatters.formatMoney(index.dayLow!),
                            icon: Icons.arrow_downward,
                            color: Colors.red,
                          ),
                      ],
                    ),
                  ),

                // ── Gün içi bar göstergesi ──
                if (index.dayHigh != null && index.dayLow != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _DayRangeBar(
                      current: index.price,
                      low: index.dayLow!,
                      high: index.dayHigh!,
                      changeColor: changeColor,
                    ),
                  ),
              ],
            ),
          ),

          // ── Bileşen Hisseler Başlığı ──
          if (constituents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bileşen Hisseler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: constituents.length,
                itemBuilder: (context, i) =>
                    _SimpleMarketCard(price: constituents[i]),
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppTheme.textDim.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bileşen bilgisi mevcut değil',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _changeIndicator(double percent) {
    final isPositive = percent >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            Formatters.formatPercent(percent),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat İtem Widget ──
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textDim,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Gün içi aralık barı ──
class _DayRangeBar extends StatelessWidget {
  final double current;
  final double low;
  final double high;
  final Color changeColor;

  const _DayRangeBar({
    required this.current,
    required this.low,
    required this.high,
    required this.changeColor,
  });

  @override
  Widget build(BuildContext context) {
    final range = high - low;
    final position = range > 0 ? ((current - low) / range).clamp(0.0, 1.0) : 0.5;

    return Column(
      children: [
        Row(
          children: [
            Text(
              Formatters.formatMoney(low),
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.4),
                            Colors.green.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: position,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withValues(alpha: 0.6),
                              changeColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(position * 2 - 1, 0),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: changeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              Formatters.formatMoney(high),
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Gün içi aralık',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textDim.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bileşen Hisse Kartı ──
class _SimpleMarketCard extends StatelessWidget {
  final MarketData price;

  const _SimpleMarketCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final isPositive = price.changePercent >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              price.symbol.length > 4
                  ? price.symbol.substring(0, 3)
                  : price.symbol,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        title: Text(price.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(price.symbol,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatMoney(price.price),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 11,
                  color: changeColor,
                ),
                Text(
                  Formatters.formatPercent(price.changePercent),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
