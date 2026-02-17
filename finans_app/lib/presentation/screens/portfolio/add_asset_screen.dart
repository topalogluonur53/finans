import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/models/asset.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:intl/intl.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/presentation/widgets/dynamic_button.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  AssetCategory? _selectedCategory;
  AssetType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen varlık türü seçin'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      if (_quantityController.text.isEmpty || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Miktar ve Fiyat zorunludur')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final asset = Asset(
          type: _selectedType!.toString().split('.').last,
          name: _nameController.text.isEmpty ? _selectedType!.label : _nameController.text,
          symbol: _symbolController.text.isEmpty ? null : _symbolController.text,
          quantity: double.parse(_quantityController.text),
          purchasePrice: double.parse(_priceController.text),
          purchaseDate: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        final success = await Provider.of<PortfolioProvider>(context, listen: false).addAsset(asset);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Varlık başarıyla eklendi!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Varlık eklenirken hata oluştu.'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onCategoryChanged(AssetCategory? category) {
    setState(() {
      _selectedCategory = category;
      _selectedType = null; // Reset type when category changes
      _nameController.clear();
      _symbolController.clear();
    });
  }

  void _onTypeChanged(AssetType? type) {
    if (type != null) {
      setState(() {
        _selectedType = type;
        _nameController.text = type.label;
        _symbolController.text = type.symbol;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTypes = _selectedCategory != null 
        ? AssetTypeExt.byCategory(_selectedCategory!)
        : <AssetType>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Varlık Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection
              DropdownButtonFormField<AssetCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category),
                  hintText: 'Varlık kategorisi seçin',
                ),
                items: AssetCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),

              // Asset Type Selection (filtered by category)
              if (_selectedCategory != null) ...[
                DropdownButtonFormField<AssetType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Varlık Türü',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: availableTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: _onTypeChanged,
                ),
                const SizedBox(height: 16),
              ],

              // Symbol Field (auto-filled, editable)
              if (_selectedType != null) ...[
                TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(
                    labelText: 'Sembol',
                    hintText: 'Örn: BTC, USD, AAPL',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),

                // Name Field (auto-filled, editable)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Varlık Adı',
                    hintText: 'Örn: Bitcoin Yatırımım',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity & Price Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Miktar',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (value) => value!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Alış Fiyatı',
                          prefixIcon: Icon(Icons.price_change_outlined),
                        ),
                        validator: (value) => value!.isEmpty ? 'Gerekli' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker Field
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.textDim.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.textDim, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alış Tarihi',
                                style: TextStyle(color: AppTheme.textDim, fontSize: 12),
                              ),
                              Text(
                                DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textDim),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (Opsiyonel)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Dynamic Submit Button
                DynamicButton(
                  label: 'Kaydet',
                  onTap: _submit,
                  isLoading: _isLoading,
                  icon: Icons.check,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
