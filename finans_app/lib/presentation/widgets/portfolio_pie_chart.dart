import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/models/asset.dart';

import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';

class PortfolioPieChart extends StatefulWidget {
  final List<Asset> assets;
  final MarketProvider marketProvider;
  final PortfolioProvider portfolioProvider;

  const PortfolioPieChart({
    super.key,
    required this.assets,
    required this.marketProvider,
    required this.portfolioProvider,
  });

  @override
  State<PortfolioPieChart> createState() => _PortfolioPieChartState();
}

class _PortfolioPieChartState extends State<PortfolioPieChart> {
  int _touchedIndex = -1;

  // Unique colors for each asset type
  static const List<Color> _chartColors = [
    Color(0xFF6C63FF), // Purple
    Color(0xFF00C853), // Green
    Color(0xFFFF6D00), // Orange
    Color(0xFF00B0FF), // Light Blue
    Color(0xFFFF3D00), // Red
    Color(0xFFFFD600), // Yellow
    Color(0xFF00E5FF), // Cyan
    Color(0xFFD500F9), // Pink
    Color(0xFF76FF03), // Lime
    Color(0xFFFF9100), // Amber
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.assets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group assets by type and calculate total value per type
    Map<String, double> typeValues = {};
    double totalValue = 0;
    
    for (var asset in widget.assets) {
      final value = widget.portfolioProvider.getAssetCurrentValue(asset, widget.marketProvider);
      typeValues[asset.name] = (typeValues[asset.name] ?? 0) + value;
      totalValue += value;
    }

    if (totalValue == 0) return const SizedBox.shrink();

    final entries = typeValues.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portföy Dağılımı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: entries.asMap().entries.map((mapEntry) {
                  final idx = mapEntry.key;
                  final entry = mapEntry.value;
                  final isTouched = idx == _touchedIndex;
                  final percentage = (entry.value / totalValue) * 100;
                  
                  return PieChartSectionData(
                    color: _chartColors[idx % _chartColors.length],
                    value: entry.value,
                    title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
                    radius: isTouched ? 70 : 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.55,
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries.asMap().entries.map((mapEntry) {
              final idx = mapEntry.key;
              final entry = mapEntry.value;
              final percentage = (entry.value / totalValue) * 100;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _chartColors[idx % _chartColors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDim),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
