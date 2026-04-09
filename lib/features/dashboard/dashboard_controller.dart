import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class DashboardController extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const int _maxHistoryPoints = 24;

  String temperature = "--";
  String humidity = "--";
  String light = "--";
  String time = "--";

  bool isConnected = false;
  bool isLoading = false;
  bool isStale = false;
  String? statusMessage;
  DateTime? lastUpdated;
  final List<double> temperatureHistory = <double>[];
  final List<double> humidityHistory = <double>[];
  final List<double> lightHistory = <double>[];

  Timer? _timer;
  String baseUrl = "";

  DashboardController() {
    baseUrl = StorageService.getBaseUrl();
    final cached = StorageService.getLatestData();
    if (cached != null) {
      update(cached, fromCache: true);
      isStale = true;
      statusMessage = 'Loaded cached data';
    }

    if (baseUrl.isNotEmpty) {
      statusMessage = 'Reconnecting to saved device';
      startPolling();
      Future<void>.microtask(fetch);
    }
  }

  void connect(String url) {
    baseUrl = formatUrl(url);
    if (baseUrl.isNotEmpty) {
      StorageService.saveBaseUrl(baseUrl);
    }
    fetch();
    startPolling();
  }

  String formatUrl(String url) {
    var value = url.trim().replaceAll(RegExp(r'/$'), '');
    if (value.isEmpty) {
      return value;
    }

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      return value;
    }

    if (parsed.hasAuthority && parsed.port == 0) {
      return parsed.replace(port: 8000).toString();
    }

    return parsed.toString();
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => fetch());
  }

  Future<void> refresh() async {
    await fetch();
  }

  Future<void> fetch() async {
    if (baseUrl.isEmpty) {
      final cached = StorageService.getLatestData();
      if (cached != null) {
        update(cached, fromCache: true);
        isStale = true;
        statusMessage = 'Waiting for device connection';
      }
      notifyListeners();
      return;
    }

    isLoading = true;
    statusMessage = 'Syncing with backend';
    notifyListeners();

    final data = await _api.fetchLatestData(baseUrl);

    if (data != null) {
      update(data);
      await StorageService.saveLatestData(data);
      isConnected = true;
      isStale = false;
      statusMessage = 'Live connection active';
    } else {
      final fallback = StorageService.getLatestData();
      if (fallback != null) {
        update(fallback, fromCache: true);
      }
      isConnected = false;
      isStale = fallback != null;
      statusMessage = fallback != null
          ? 'Showing last cached reading'
          : 'Device unavailable';
    }

    isLoading = false;
    notifyListeners();
  }

  void update(Map<String, dynamic> data, {bool fromCache = false}) {
    temperature = _formatValue(data['temperature'], suffix: '°C');
    humidity = _formatValue(data['humidity'], suffix: '%');
    light = _formatValue(data['light'], suffix: ' lux');
    time = data['timestamp']?.toString() ?? '--';
    lastUpdated = DateTime.tryParse(time);

    final tempValue = _toDouble(data['temperature']);
    final humidityValue = _toDouble(data['humidity']);
    final lightValue = _toDouble(data['light']);
    _appendHistory(temperatureHistory, tempValue);
    _appendHistory(humidityHistory, humidityValue);
    _appendHistory(lightHistory, lightValue);

    if (!fromCache) {
      statusMessage = 'Fresh sample received';
    }
  }

  String _formatValue(dynamic value, {required String suffix}) {
    if (value == null) {
      return '--';
    }

    return '$value$suffix';
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  void _appendHistory(List<double> target, double? value) {
    if (value == null) {
      return;
    }

    target.add(value);
    if (target.length > _maxHistoryPoints) {
      target.removeAt(0);
    }
  }

  Map<String, dynamic> get snapshot {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'timestamp': time,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isConnected': isConnected,
      'isStale': isStale,
      'baseUrl': baseUrl,
    };
  }

  void clear() {
    StorageService.clearLatestData();
    StorageService.clearBaseUrl();
    _timer?.cancel();
    _timer = null;
    baseUrl = "";
    temperature = "--";
    humidity = "--";
    light = "--";
    time = "--";
    isConnected = false;
    isStale = false;
    isLoading = false;
    statusMessage = 'Local cache cleared';
    lastUpdated = null;
    temperatureHistory.clear();
    humidityHistory.clear();
    lightHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
