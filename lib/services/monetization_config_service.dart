import 'dart:convert';

import 'package:bible_decision_simulator/models/monetization_config.dart';
import 'package:flutter/services.dart';

class MonetizationConfigService {
  const MonetizationConfigService();

  static const String _configPath = 'assets/config/monetization_config.json';

  Future<MonetizationConfig> loadConfig() async {
    try {
      final raw = await rootBundle.loadString(_configPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return MonetizationConfig.fromJson(data);
    } catch (_) {
      return MonetizationConfig.defaults;
    }
  }
}
