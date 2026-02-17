import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/models/finance.dart';
import 'package:finans_app/data/providers/finance_provider.dart';
import 'package:finans_app/presentation/widgets/dynamic_button.dart';

enum TransactionType { income, expense }

class AddTransactionScreen extends StatefulWidget {
  final TransactionType type;

  const AddTransactionScreen({super.key, required this.type});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController(); // acts as Category for expense
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final provider = Provider.of<FinanceProvider>(context, listen: false);
        bool success = false;

        if (widget.type == TransactionType.income) {
          final income = Income(
            amount: double.parse(_amountController.text),
            source: _sourceController.text,
            date: _selectedDate,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          );
          success = await provider.addIncome(income);
        } else {
          final expense = Expense(
            amount: double.parse(_amountController.text),
            category: _sourceController.text,
            date: _selectedDate,
            description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          );
          success = await provider.addExpense(expense);
        }

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('İşlem başarıyla eklendi!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('İşlem eklenirken hata oluştu.'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final title = isIncome ? 'Gelir Ekle' : 'Gider Ekle';
    final sourceLabel = isIncome ? 'Kaynak (Maaş, Kira vb.)' : 'Kategori (Fatura, Market vb.)';
    final accentColor = isIncome ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Source / Category
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  labelText: sourceLabel,
                  prefixIcon: Icon(isIncome ? Icons.source : Icons.category),
                ),
                validator: (value) => value!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Date Picker Field (Useful and Dynamic)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.textDim.withOpacity(0.1)),
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
                              'Tarih',
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

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Dynamic Submit Button
              DynamicButton(
                label: 'Kaydet',
                onTap: _submit,
                color: accentColor,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
