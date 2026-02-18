import 'package:flutter/material.dart';
import 'package:finans_app/presentation/screens/tools/notepad/notepad_screen.dart';
import 'package:finans_app/presentation/screens/tools/loan_calculator_screen.dart';
import 'package:finans_app/presentation/screens/tools/currency_converter_screen.dart';
import 'package:finans_app/presentation/screens/tools/ipo_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCard(
            title: 'Halka Arz (IPO)',
            icon: Icons.trending_up,
            subtitle: 'Yaklaşan ve son halka arzlar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IPOScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _ToolCard(
            title: 'Not Defteri',
            icon: Icons.note_alt,
            subtitle: 'Notlarınızı kaydedin',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotepadScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _ToolCard(
            title: 'Kredi Hesaplama',
            icon: Icons.calculate,
            subtitle: 'Taksit ve faiz hesaplayın',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoanCalculatorScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _ToolCard(
            title: 'Döviz Çevirici',
            icon: Icons.currency_exchange,
            subtitle: 'Anlık kur ile çevirin',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyConverterScreen()),
              );
            },
          ),
          // More tools
      ],
    );
  }
}

class _ToolCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  const _ToolCard({required this.title, required this.icon, required this.onTap, this.subtitle});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D2D44),
                const Color(0xFF2D2D44).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(widget.icon, size: 32, color: primaryColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle ?? 'Kullanmak için dokunun',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
