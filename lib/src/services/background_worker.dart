import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/update_config.dart';
import 'version_checker.dart';

/// Background worker for periodic update checks
class BackgroundWorker {
  static const String _taskName = 'app_update_check';
  static const String _updateAvailableKey = 'background_update_available';
  static const String _updateInfoKey = 'background_update_info';

  /// Initialize background worker
  static Future<void> initialize() async {
    if (!_isSupportedPlatform()) return;

    await Workmanager().initialize(_callbackDispatcher);
  }

  /// Register periodic update check task
  static Future<void> registerPeriodicCheck(UpdateConfig config) async {
    if (!_isSupportedPlatform() || !config.enableBackgroundCheck) return;

    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: Duration(hours: config.backgroundCheckInterval),
      constraints: Constraints(
        networkType: config.wifiOnly
            ? NetworkType.unmetered
            : NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel periodic update check
  static Future<void> cancelPeriodicCheck() async {
    if (!_isSupportedPlatform()) return;

    await Workmanager().cancelByUniqueName(_taskName);
  }

  /// Cancel all background tasks
  static Future<void> cancelAll() async {
    if (!_isSupportedPlatform()) return;

    await Workmanager().cancelAll();
  }

  /// Check if update was found in background
  static Future<bool> hasBackgroundUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_updateAvailableKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get background update info
  static Future<Map<String, dynamic>?> getBackgroundUpdateInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_updateInfoKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear background update flag
  static Future<void> clearBackgroundUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_updateAvailableKey);
      await prefs.remove(_updateInfoKey);
    } catch (e) {
      // Silent fail
    }
  }

  static bool _isSupportedPlatform() {
    return Platform.isAndroid || Platform.isIOS;
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Load config from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('app_update_config');

      if (configJson == null) {
        return Future.value(true);
      }

      final configData = jsonDecode(configJson) as Map<String, dynamic>;
      final config = _configFromJson(configData);

      // Check for updates
      final versionChecker = VersionChecker(config: config);
      final updateInfo = await versionChecker.checkForUpdate();

      if (updateInfo != null && updateInfo.isUpdateAvailable) {
        // Store update info
        await prefs.setBool('background_update_available', true);
        await prefs.setString(
          'background_update_info',
          jsonEncode(updateInfo.toJson()),
        );

        // Optionally show notification here
        // This would require flutter_local_notifications package
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

/// Helper to reconstruct UpdateConfig from JSON
UpdateConfig _configFromJson(Map<String, dynamic> json) {
  return UpdateConfig(
    playStoreId: json['play_store_id'] as String?,
    appStoreId: json['app_store_id'] as String?,
    customUpdateUrl: json['custom_update_url'] as String?,
    customHeaders: json['custom_headers'] != null
        ? Map<String, String>.from(json['custom_headers'] as Map)
        : null,
    strategy: UpdateStrategy.values[json['strategy'] as int? ?? 0],
    backgroundCheckInterval: json['background_check_interval'] as int? ?? 24,
    enableBackgroundCheck: json['enable_background_check'] as bool? ?? false,
    showDialogAutomatically: json['show_dialog_automatically'] as bool? ?? true,
    enableCaching: json['enable_caching'] as bool? ?? true,
    cacheDuration: json['cache_duration'] as int? ?? 6,
    requestTimeout: json['request_timeout'] as int? ?? 30,
    wifiOnly: json['wifi_only'] as bool? ?? false,
    customUserAgent: json['custom_user_agent'] as String?,
    regionCode: json['region_code'] as String?,
    testGroup: json['test_group'] as String?,
  );
}

/// Helper to convert UpdateConfig to JSON
Map<String, dynamic> configToJson(UpdateConfig config) {
  return {
    'play_store_id': config.playStoreId,
    'app_store_id': config.appStoreId,
    'custom_update_url': config.customUpdateUrl,
    'custom_headers': config.customHeaders,
    'strategy': config.strategy.index,
    'background_check_interval': config.backgroundCheckInterval,
    'enable_background_check': config.enableBackgroundCheck,
    'show_dialog_automatically': config.showDialogAutomatically,
    'enable_caching': config.enableCaching,
    'cache_duration': config.cacheDuration,
    'request_timeout': config.requestTimeout,
    'wifi_only': config.wifiOnly,
    'custom_user_agent': config.customUserAgent,
    'region_code': config.regionCode,
    'test_group': config.testGroup,
  };
}
