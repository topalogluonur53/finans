import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/providers/auth_provider.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:finans_app/data/services/market_api_service.dart';

class AlarmDialog extends StatefulWidget {
  /// Önceden seçili sembol (market detaydan açılırsa)
  final String? prefilledSymbol;
  final double? prefilledPrice;

  const AlarmDialog({super.key, this.prefilledSymbol, this.prefilledPrice});

  @override
  State<AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<AlarmDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  String _condition = '>';
  String? _selectedSymbol;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSymbol = widget.prefilledSymbol;
    _priceController = TextEditingController(
      text: widget.prefilledPrice != null
          ? widget.prefilledPrice!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _getSymbolCategory(String symbol, MarketProvider mp) {
    try {
      return mp.prices
          .firstWhere((p) => p.symbol == symbol)
          .category;
    } catch (_) {
      return 'commodity';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSymbol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir sembol seçin')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapmanız gerekiyor')),
      );
      return;
    }

    final mp = Provider.of<MarketProvider>(context, listen: false);
    final category = _getSymbolCategory(_selectedSymbol!, mp);

    setState(() => _isSaving = true);
    try {
      final ok = await MarketApiService().createAlarm(
        symbol: _selectedSymbol!,
        marketType: category,
        targetPrice: double.parse(_priceController.text.replaceAll(',', '.')),
        condition: _condition,
        token: token,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedSymbol için alarm kuruldu 🔔'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm kurulamadı. Tekrar deneyin.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mp = Provider.of<MarketProvider>(context, listen: false);
    final symbols = mp.prices.map((p) => p.symbol).toList()
      ..sort();

    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Fiyat Alarmı Kur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sembol Seçimi
              const Text('Sembol', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSymbol,
                dropdownColor: AppTheme.backgroundDark,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                hint: const Text('Sembol seçin', style: TextStyle(color: AppTheme.textDim)),
                items: symbols.map((sym) {
                  final name = mp.getMarketData(sym)?.name ?? sym;
                  return DropdownMenuItem(
                    value: sym,
                    child: Text(
                      '$sym - $name',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSymbol = val),
                validator: (v) => v == null ? 'Sembol seçin' : null,
              ),
              const SizedBox(height: 16),

              // Koşul + Fiyat
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Koşul', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
                      const SizedBox(height: 6),
                      ToggleButtons(
                        isSelected: [_condition == '>', _condition == '<'],
                        onPressed: (i) => setState(() => _condition = i == 0 ? '>' : '<'),
                        borderRadius: BorderRadius.circular(10),
                        selectedColor: Colors.white,
                        fillColor: AppTheme.primaryColor,
                        color: AppTheme.textDim,
                        borderColor: AppTheme.textDim.withValues(alpha: 0.3),
                        selectedBorderColor: AppTheme.primaryColor,
                        constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
                        children: const [
                          Text('↑ Üstünde', style: TextStyle(fontSize: 12)),
                          Text('↓ Altında', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hedef Fiyat', style: TextStyle(color: AppTheme.textDim, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              return newValue.copyWith(
                                text: newValue.text.replaceAll('.', ','),
                                selection: TextSelection.collapsed(offset: newValue.selection.end),
                              );
                            }),
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.backgroundDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Örn: 3500',
                            hintStyle: const TextStyle(color: AppTheme.textDim),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Fiyat girin';
                            if (double.tryParse(v.replaceAll(',', '.')) == null) {
                              return 'Geçersiz';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textDim,
                        side: const BorderSide(color: AppTheme.textDim),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Alarm Kur', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
