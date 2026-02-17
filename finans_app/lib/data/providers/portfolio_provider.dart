import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/asset.dart';

class PortfolioProvider extends ChangeNotifier {
  String? _token;
  List<Asset> _assets = [];
  bool _isLoading = false;

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;

  void updateToken(String? token) {
    _token = token;
    if (_token != null) {
      fetchAssets();
    } else {
      _assets = [];
      notifyListeners();
    }
  }

  Future<void> fetchAssets() async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.portfolioEndpoint + 'assets/'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _assets = data.map((e) => Asset.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching assets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAsset(Asset asset) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();
    
    try {
      final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.assetsEndpoint);
      print('Adding asset to: $url');
      print('Payload: ${jsonEncode(asset.toJson())}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(asset.toJson()),
      );

      if (response.statusCode == 201) {
        print('Asset added successfully');
        await fetchAssets();
        return true;
      } else {
        print('Failed to add asset: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding asset: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculation Helpers
  double getTotalValue(Map<String, double> prices) {
    double total = 0;
    for (var asset in _assets) {
      double price = prices[asset.symbol] ?? prices[asset.type] ?? 0.0;
      // Fallback: use purchase price? No, current value.
      // If price is 0 (mock), maybe use purchasePrice for demo?
      if (price == 0) price = asset.purchasePrice; 
      
      total += asset.quantity * price;
    }
    return total;
  }

  Future<bool> deleteAsset(int id) async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.portfolioEndpoint + 'assets/$id/'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _assets.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error deleting asset: $e');
    }
    return false;
  }
}
