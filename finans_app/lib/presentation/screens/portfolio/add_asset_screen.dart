import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/models/asset.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/data/providers/market_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/presentation/widgets/dynamic_button.dart';

class AddAssetScreen extends StatefulWidget {
  final Asset? assetToEdit;

  const AddAssetScreen({super.key, this.assetToEdit});

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
  final _tagController = TextEditingController();

  // State
  AssetCategory? _selectedCategory;
  AssetType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.assetToEdit != null) {
      final asset = widget.assetToEdit!;
      _nameController.text = asset.name;
      _symbolController.text = asset.symbol ?? '';
      _quantityController.text = asset.quantity.toString().replaceAll('.', ',');
      _priceController.text =
          asset.purchasePrice.toString().replaceAll('.', ',');
      _notesController.text = asset.notes ?? '';
      _tagController.text = asset.tag ?? '';
      _selectedDate = asset.purchaseDate;
      try {
        _selectedType = AssetType.values.firstWhere((e) =>
            e.backendType == asset.type ||
            e.name.toLowerCase() == asset.type.toLowerCase());
        _selectedCategory = _selectedType!.category;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lütfen varlık türü seçin'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      if (_quantityController.text.isEmpty || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Miktar ve Fiyat zorunludur')),
        );
        return;
      }

      final portfolioProvider =
          Provider.of<PortfolioProvider>(context, listen: false);
      setState(() => _isLoading = true);

      try {
        final asset = Asset(
          id: widget.assetToEdit?.id,
          type: _selectedType!.backendType,
          name: _nameController.text.isEmpty
              ? _selectedType!.label
              : _nameController.text,
          symbol:
              _symbolController.text.isEmpty ? null : _symbolController.text,
          quantity: double.parse(_quantityController.text.replaceAll(',', '.')),
          purchasePrice:
              double.parse(_priceController.text.replaceAll(',', '.')),
          purchaseDate: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          tag: _tagController.text.isEmpty ? null : _tagController.text,
        );

        final success = widget.assetToEdit == null
            ? await portfolioProvider.addAsset(asset)
            : await portfolioProvider.updateAsset(asset);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(widget.assetToEdit == null
                      ? 'Varlık başarıyla eklendi!'
                      : 'Varlık başarıyla güncellendi!'),
                  backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(widget.assetToEdit == null
                      ? 'Varlık eklenirken hata oluştu.'
                      : 'Varlık güncellenirken hata oluştu.'),
                  backgroundColor: Colors.red),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onCategoryChanged(AssetCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedType = null; // Reset type when category changes
      _nameController.clear();
      _symbolController.clear();
    });
  }

  void _onTypeChanged(AssetType type) {
    setState(() {
      _selectedType = type;
      _nameController.text = type.label;
      _symbolController.text = type.symbol;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
            widget.assetToEdit == null ? 'Varlık Ekle' : 'Varlık Düzenle',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompactSectionTitle('Kategori', Icons.category_rounded),
              const SizedBox(height: 8),
              _buildCategoryScroll(),
              const SizedBox(height: 16),
              _buildCompactSectionTitle(
                  'Varlık Türü', Icons.inventory_2_rounded),
              const SizedBox(height: 8),
              _selectedCategory == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Lütfen önce bir kategori seçin.',
                          style:
                              TextStyle(color: AppTheme.textDim, fontSize: 13)),
                    )
                  : _buildTypeScroll(),
              const SizedBox(height: 20),
              _buildCompactSectionTitle('Detaylar', Icons.edit_document),
              const SizedBox(height: 8),
              _buildCompactDetailsForm(),
              const SizedBox(height: 24),
              DynamicButton(
                label: widget.assetToEdit == null ? 'Kaydet' : 'Güncelle',
                onTap: _submit,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
              fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildCategoryScroll() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AssetCategory.values.length,
        itemBuilder: (context, index) {
          final category = AssetCategory.values[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Text(category.icon, style: const TextStyle(fontSize: 14)),
              label: Text(category.label),
              selected: isSelected,
              onSelected: (_) => _onCategoryChanged(category),
              backgroundColor: AppTheme.surfaceDark,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDim,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textDim.withValues(alpha: 0.1)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeScroll() {
    final types = AssetTypeExt.byCategory(_selectedCategory!);
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (_) => _onTypeChanged(type),
              backgroundColor: AppTheme.surfaceDark,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDim,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textDim.withValues(alpha: 0.1),
                  width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textDim.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Name and Symbol
          if (_selectedType == AssetType.stock)
            _buildStockSelector()
          else
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildCompactTextField(
                    controller: _nameController,
                    label: 'Varlık Adı',
                    icon: Icons.drive_file_rename_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildCompactTextField(
                    controller: _symbolController,
                    label: 'Sembol',
                    icon: Icons.tag,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Row 2: Quantity and Price
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _quantityController,
                  label: 'Miktar',
                  icon: Icons.numbers,
                  isNumber: true,
                  validator: (val) => val!.isEmpty ? 'Boş olamaz' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactTextField(
                  controller: _priceController,
                  label: 'Alış Fiyatı',
                  icon: Icons.price_change_outlined,
                  isNumber: true,
                  validator: (val) => val!.isEmpty ? 'Boş olamaz' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Date and Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.textDim.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: AppTheme.primaryColor.withValues(alpha: 0.7),
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yyyy', 'tr_TR')
                                .format(_selectedDate),
                            style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _buildCompactTextField(
                  controller: _notesController,
                  label: 'Not',
                  icon: Icons.note_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 4: Tag
          Row(
            children: [
              Expanded(
                child: _buildCompactTextField(
                  controller: _tagController,
                  label: 'Etiket',
                  icon: Icons.label_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = newValue.text.replaceAll('.', ',');
                if (RegExp(r'^\d*\,?\d{0,2}$').hasMatch(text)) {
                  return newValue.copyWith(
                    text: text,
                    // If selection end is out of bounds after a replacement, handle it, but here lengths are the same.
                    selection:
                        TextSelection.collapsed(offset: newValue.selection.end),
                  );
                }
                return oldValue;
              }),
            ]
          : null,
      validator: validator,
      style: const TextStyle(
          fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontSize: 12,
            color: AppTheme.textDim,
            fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon,
            size: 18, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: AppTheme.backgroundDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppTheme.textDim.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        errorStyle: const TextStyle(
            height: 0, fontSize: 0), // hide error text to save vertical space
      ),
    );
  }

  Widget _buildStockSelector() {
    final marketPrices = Provider.of<MarketProvider>(context, listen: false).prices;
    final stockPrices = marketPrices
        .where((p) =>
            p.category.toLowerCase() == 'stock' ||
            p.category.toLowerCase() == 'index')
        .toList();

    return Autocomplete<MarketData>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return stockPrices.take(15);
        }
        final q = textEditingValue.text.toLowerCase();
        return stockPrices.where((option) {
          return option.name.toLowerCase().contains(q) ||
              option.symbol.toLowerCase().contains(q);
        });
      },
      displayStringForOption: (MarketData option) => '${option.name} (${option.symbol})',
      onSelected: (MarketData selection) {
        setState(() {
          _nameController.text = selection.name;
          _symbolController.text = selection.symbol;
        });
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        if (_symbolController.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
          fieldTextEditingController.text = '${_nameController.text} (${_symbolController.text})';
        }
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          style: const TextStyle(fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.bold),
          validator: (val) {
            if (_symbolController.text.isEmpty) return 'Lütfen listeden seçiniz';
            return null;
          },
          onChanged: (val) {
             _symbolController.clear();
             _nameController.clear();
          },
          decoration: InputDecoration(
            labelText: 'Hisse Senedi Seç (İsim veya Sembolü Ara)',
            labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textDim, fontWeight: FontWeight.normal),
            prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.primaryColor.withOpacity(0.7)),
            filled: true,
            fillColor: AppTheme.backgroundDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.textDim.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.surfaceDark,
            child: Container(
              height: 250,
              width: MediaQuery.of(context).size.width - 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppTheme.textDim.withOpacity(0.1),
                  height: 1,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option.name,
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      option.symbol,
                      style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
                    ),
                    trailing: Text(
                      option.price.toStringAsFixed(2),
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

