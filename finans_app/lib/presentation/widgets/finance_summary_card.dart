import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/utils/formatters.dart';

class FinanceSummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const FinanceSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalExpense;
    final isPositive = net >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aylık Gelir / Gider',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Gelir', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatMoney(totalIncome),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white24,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('Gider', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatMoney(totalExpense),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Net balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Durum', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatMoney(net.abs()),
                      style: TextStyle(
                        color: isPositive ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
}
