import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/update_info.dart';

/// Service for caching update information
class CacheService {
  static const String _updateInfoKey = 'app_update_info';
  static const String _lastCheckKey = 'app_update_last_check';
  static const String _userDismissedKey = 'app_update_dismissed';
  static const String _dismissedVersionKey = 'app_update_dismissed_version';
  static const String _dismissCountKey = 'app_update_dismiss_count';

  /// Cache update information
  Future<void> cacheUpdateInfo(UpdateInfo info, Duration duration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(info.toJson());
      await prefs.setString(_updateInfoKey, jsonString);
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silent fail for caching errors
    }
  }

  /// Get cached update information
  Future<UpdateInfo?> getCachedUpdateInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_updateInfoKey);
      final lastCheck = prefs.getInt(_lastCheckKey);

      if (jsonString == null || lastCheck == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
      if (DateTime.now().difference(cacheTime).inHours > 6) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UpdateInfo.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clear cached update information
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_updateInfoKey);
      await prefs.remove(_lastCheckKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Mark update as dismissed by user
  Future<void> markUpdateDismissed(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userDismissedKey, true);
      await prefs.setString(_dismissedVersionKey, version);

      // Increment dismiss count
      final currentCount = prefs.getInt(_dismissCountKey) ?? 0;
      await prefs.setInt(_dismissCountKey, currentCount + 1);
    } catch (e) {
      // Silent fail
    }
  }

  /// Check if user has dismissed this version
  Future<bool> hasUserDismissedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_userDismissedKey) ?? false;
      final dismissedVersion = prefs.getString(_dismissedVersionKey);

      return dismissed && dismissedVersion == version;
    } catch (e) {
      return false;
    }
  }

  /// Get number of times user has dismissed updates
  Future<int> getDismissCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_dismissCountKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clear dismiss status
  Future<void> clearDismissStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDismissedKey);
      await prefs.remove(_dismissedVersionKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Reset all dismiss data
  Future<void> resetDismissData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDismissedKey);
      await prefs.remove(_dismissedVersionKey);
      await prefs.remove(_dismissCountKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Get last check time
  Future<DateTime?> getLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckKey);
      if (lastCheck == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(lastCheck);
    } catch (e) {
      return null;
    }
  }

  /// Check if should check for updates based on interval
  Future<bool> shouldCheckForUpdate(int intervalHours) async {
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;

    final hoursSinceLastCheck = DateTime.now().difference(lastCheck).inHours;
    return hoursSinceLastCheck >= intervalHours;
  }
}
