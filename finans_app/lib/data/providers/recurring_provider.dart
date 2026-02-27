import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/recurring_transaction.dart';

class RecurringProvider extends ChangeNotifier {
  String? _token;
  List<RecurringTransaction> _items = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RecurringTransaction> get incomes =>
      _items.where((t) => t.type == 'INCOME' && t.isActive).toList();
  List<RecurringTransaction> get expenses =>
      _items.where((t) => t.type == 'EXPENSE' && t.isActive).toList();

  double get totalMonthlyIncome =>
      incomes.fold(0, (s, t) => s + t.monthlyAmount);
  double get totalMonthlyExpense =>
      expenses.fold(0, (s, t) => s + t.monthlyAmount);
  double get monthlyNet => totalMonthlyIncome - totalMonthlyExpense;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      fetch();
    } else {
      _items = [];
      notifyListeners();
    }
  }

  Future<void> fetch() async {
    if (_token == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recurringEndpoint}'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        _items = list.map((e) => RecurringTransaction.fromJson(e)).toList();
      } else {
        _error = 'Sunucu hatası (${res.statusCode})';
      }
    } catch (e) {
      _error = 'Bağlantı hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(RecurringTransaction item) async {
    if (_token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recurringEndpoint}'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(item.toJson()),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 201) {
        await fetch();
        return true;
      }
      debugPrint('Recurring add error: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      debugPrint('Recurring add exception: $e');
      return false;
    }
  }

  Future<bool> update(int id, RecurringTransaction item) async {
    if (_token == null) return false;
    try {
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recurringEndpoint}$id/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(item.toJson()),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        await fetch();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Recurring update exception: $e');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    if (_token == null) return false;
    try {
      final res = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recurringEndpoint}$id/'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 204 || res.statusCode == 200) {
        _items.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Recurring delete exception: $e');
      return false;
    }
  }

  Future<bool> toggleActive(RecurringTransaction item) async {
    if (item.id == null) return false;
    final updated = RecurringTransaction(
      id: item.id, type: item.type, category: item.category,
      amount: item.amount, period: item.period,
      description: item.description, startDate: item.startDate,
      endDate: item.endDate,
      isActive: !item.isActive,
    );
    return update(item.id!, updated);
  }
}
