import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/models/asset.dart';
import 'package:finans_app/data/providers/market_provider.dart';

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
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.portfolioEndpoint}assets/'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _assets = data.map((e) => Asset.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching assets: $e');
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

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(asset.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchAssets();
        return true;
      } else {
        debugPrint('Failed to add asset: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error adding asset: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAsset(Asset asset) async {
    if (_token == null || asset.id == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.assetsEndpoint}${asset.id}/');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(asset.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchAssets();
        return true;
      } else {
        debugPrint('Failed to update asset: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating asset: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculation Helpers
  double getTotalValue(MarketProvider market) {
    double total = 0;
    for (var asset in _assets) {
      total += getAssetCurrentValue(asset, market);
    }
    return total;
  }

  double getAssetCurrentValue(Asset asset, MarketProvider market) {
    double price = getPriceForAsset(asset, market);
    return asset.quantity * (price > 0 ? price : asset.purchasePrice);
  }

  double getPriceForAsset(Asset asset, MarketProvider market) {
    AssetType? assetType;
    try {
      assetType = AssetType.values.firstWhere((e) =>
          e.backendType == asset.type ||
          e.name.toLowerCase() == asset.type.toLowerCase());
    } catch (_) {}

    String marketSymbol = assetType?.symbol ?? '';
    if (marketSymbol.isEmpty) {
      marketSymbol = asset.symbol ?? '';
    }
    final double multiplier = assetType?.unitMultiplier ?? 1.0;
    final bool isUsdBased = assetType?.isUsdBased ?? false;

    double price = market.getPrice(marketSymbol);

    if (price > 0) {
      price *= multiplier;
      if (isUsdBased) {
        price *= market.usdTryRate;
      }
      return price;
    }

    return 0.0;
  }

  double getTotalCost(MarketProvider market) {
    double total = 0;
    for (var asset in _assets) {
      total += getAssetCost(asset, market);
    }
    return total;
  }

  double getAssetCost(Asset asset, MarketProvider market) {
    AssetType? assetType;
    try {
      assetType = AssetType.values.firstWhere((e) =>
          e.backendType == asset.type ||
          e.name.toLowerCase() == asset.type.toLowerCase());
    } catch (_) {}

    double cost = asset.purchasePrice;
    if (assetType?.isUsdBased == true && market.usdTryRate > 0) {
      cost *= market.usdTryRate;
    }
    return asset.quantity * cost;
  }

  Future<bool> deleteAsset(int id) async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.portfolioEndpoint}assets/$id/'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _assets.removeWhere((a) => a.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting asset: $e');
    }
    return false;
  }
}
