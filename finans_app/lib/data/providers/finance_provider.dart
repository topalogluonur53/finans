
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/finance.dart';

class FinanceProvider extends ChangeNotifier {
  String? _token;
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Income> get incomes => _incomes;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  double get totalIncome => _incomes.fold(0, (sum, i) => sum + i.amount);
  double get totalExpense => _expenses.fold(0, (sum, e) => sum + e.amount);
  double get netBalance => totalIncome - totalExpense;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      fetchData();
    } else {
      _incomes = [];
      _expenses = [];
      notifyListeners();
    }
  }

  Future<void> fetchData() async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    
    await Future.wait([
      fetchIncomes(),
      fetchExpenses(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchIncomes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.incomesEndpoint),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _incomes = data.map((e) => Income.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching incomes: $e');
    }
  }

  Future<void> fetchExpenses() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.expensesEndpoint),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _expenses = data.map((e) => Expense.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
  }

  Future<bool> addIncome(Income income) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.incomesEndpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(income.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchIncomes();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding income: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.expensesEndpoint),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchExpenses();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding expense: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteIncome(int id) async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.incomesEndpoint}$id/'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _incomes.removeWhere((i) => i.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error deleting income: $e');
    }
    return false;
  }

  Future<bool> deleteExpense(int id) async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.expensesEndpoint}$id/'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _expenses.removeWhere((e) => e.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error deleting expense: $e');
    }
    return false;
  }
}
