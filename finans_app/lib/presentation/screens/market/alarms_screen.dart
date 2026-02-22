import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/providers/auth_provider.dart';
import 'alarm_dialog.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  List<Map<String, dynamic>> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlarms();
  }

  Future<String?> _getToken() {
    return Future.value(
      Provider.of<AuthProvider>(context, listen: false).token,
    );
  }

  Future<void> _fetchAlarms() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.alarmsEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _alarms = List<Map<String, dynamic>>.from(
            data is List ? data : (data['results'] ?? []),
          );
        });
      }
    } catch (e) {
      debugPrint('Alarms fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAlarm(int id) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.alarmsEndpoint}$id/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 204 && mounted) {
        setState(() => _alarms.removeWhere((a) => a['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm silindi'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete alarm error: $e');
    }
  }

  Future<void> _toggleAlarm(int id, bool current) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.alarmsEndpoint}$id/toggle_active/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final body = json.decode(response.body);
        setState(() {
          final idx = _alarms.indexWhere((a) => a['id'] == id);
          if (idx >= 0) {
            _alarms[idx] = {..._alarms[idx], 'is_active': body['is_active']};
          }
        });
      }
    } catch (e) {
      debugPrint('Toggle alarm error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiyat Alarmları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAlarms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: AppTheme.textDim.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz alarm yok',
                        style: TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Piyasa ekranından alarm kurabilirsiniz',
                        style: TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAlarms,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = _alarms[index];
                      return _AlarmCard(
                        alarm: alarm,
                        onDelete: () => _deleteAlarm(alarm['id']),
                        onToggle: () =>
                            _toggleAlarm(alarm['id'], alarm['is_active'] ?? true),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (ctx) => const AlarmDialog(),
          );
          if (result == true) _fetchAlarms();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_alert),
        label: const Text('Alarm Kur'),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final Map<String, dynamic> alarm;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _AlarmCard({
    required this.alarm,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = alarm['is_active'] ?? true;
    final condition = alarm['condition'] ?? '>';
    final icon = condition == '>' ? Icons.trending_up : Icons.trending_down;
    final conditionColor =
        condition == '>' ? AppTheme.secondaryColor : AppTheme.errorColor;
    final conditionLabel = condition == '>' ? 'Üstüne çıkınca' : 'Altına düşünce';

    final targetPrice = double.tryParse(
          alarm['target_price']?.toString() ?? '0',
        ) ??
        0;

    return Dismissible(
      key: ValueKey(alarm['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: AppTheme.errorColor),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Alarmı Sil'),
            content: Text(
              '${alarm['symbol']} alarmını silmek istediğinizden emin misiniz?',
              style: const TextStyle(color: AppTheme.textDim),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal', style: TextStyle(color: AppTheme.textDim)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: conditionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: conditionColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm['symbol_name'] ?? alarm['symbol'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conditionLabel,
                        style: const TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      targetPrice.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: conditionColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                              : AppTheme.textDim.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppTheme.secondaryColor
                                : AppTheme.textDim,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
