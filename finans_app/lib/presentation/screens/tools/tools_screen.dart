import 'package:flutter/material.dart';
import 'package:finans_app/presentation/screens/tools/notepad/notepad_screen.dart';
import 'package:finans_app/presentation/screens/tools/loan_calculator_screen.dart';
import 'package:finans_app/presentation/screens/tools/currency_converter_screen.dart';
import 'package:finans_app/presentation/screens/tools/ipo_screen.dart';
import 'package:finans_app/presentation/widgets/main_drawer.dart';
import 'package:finans_app/core/theme/app_theme.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Finansal Araçlar'),
        elevation: 2,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: [
          _ToolCard(
            title: 'Halka Arz',
            icon: Icons.trending_up,
            subtitle: 'Yaklaşan ve son arzlar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IPOScreen()),
              );
            },
          ),
          _ToolCard(
            title: 'Finansal Notlar',
            icon: Icons.analytics_outlined,
            subtitle: 'Hedef ve analiz',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotepadScreen()),
              );
            },
          ),
          _ToolCard(
            title: 'Kredi Hesaplama',
            icon: Icons.calculate,
            subtitle: 'Taksit faiz hesapla',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoanCalculatorScreen()),
              );
            },
          ),
          _ToolCard(
            title: 'Döviz Çevirici',
            icon: Icons.currency_exchange,
            subtitle: 'Anlık kur hesapla',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CurrencyConverterScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  const _ToolCard(
      {required this.title,
      required this.icon,
      required this.onTap,
      this.subtitle});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 28, color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      const Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
