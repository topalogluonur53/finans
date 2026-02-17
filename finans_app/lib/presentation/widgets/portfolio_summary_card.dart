import 'package:flutter/material.dart';
import 'package:finans_app/core/utils/formatters.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final double totalValue;
  final double? profitLoss;

  const PortfolioSummaryCard({super.key, required this.totalValue, this.profitLoss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toplam Portföy Değeri',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatMoney(totalValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Profit Loss Section (if data)
          // For MVP just dummy data or passed data
          if (profitLoss != null)
          Row(
            children: [
              Icon(
                profitLoss! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: profitLoss! >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatMoney(profitLoss!),
                style: TextStyle(
                  color: profitLoss! >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
