// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart' as iap;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/update_config.dart';
import 'models/update_info.dart';
import 'services/analytics_service.dart';
import 'services/background_worker.dart';
import 'services/cache_service.dart';
import 'services/platform_update_handler.dart';
import 'services/version_checker.dart';
import 'ui/update_bottom_sheet.dart';
import 'ui/update_dialog.dart';

/// Main entry point for app update management
class AppUpdateManager {
  static AppUpdateManager? _instance;
  late UpdateConfig _config;
  late VersionChecker _versionChecker;
  late PlatformUpdateHandler _platformHandler;
  late CacheService _cacheService;
  late AnalyticsService _analyticsService;

  AppUpdateManager._();

  /// Get singleton instance
  static AppUpdateManager get instance {
    _instance ??= AppUpdateManager._();
    return _instance!;
  }

  /// Initialize the update manager
  static Future<void> initialize({required UpdateConfig config}) async {
    final manager = AppUpdateManager.instance;
    manager._config = config;
    manager._versionChecker = VersionChecker(config: config);
    manager._platformHandler = PlatformUpdateHandler(config: config);
    manager._cacheService = CacheService();
    manager._analyticsService = AnalyticsService(config: config);

    // Validate configuration
    if (!config.validate()) {
      throw ArgumentError(
        'Invalid configuration: At least one of playStoreId, appStoreId, '
        'or customUpdateUrl must be provided',
      );
    }

    // Initialize background worker if enabled
    if (config.enableBackgroundCheck) {
      await BackgroundWorker.initialize();
      await BackgroundWorker.registerPeriodicCheck(config);

      // Save config for background worker
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'app_update_config',
        jsonEncode(_configToJson(config)),
      );
    }
  }

  /// Check for updates
  static Future<UpdateInfo?> checkForUpdate() async {
    final manager = AppUpdateManager.instance;
    manager._analyticsService.trackCheckStarted();

    try {
      final updateInfo = await manager._versionChecker.checkForUpdate();

      if (updateInfo != null) {
        manager._analyticsService.trackCheckCompleted(
          updateAvailable: updateInfo.isUpdateAvailable,
        );
      }

      return updateInfo;
    } catch (e) {
      manager._analyticsService.trackCheckFailed(e.toString());
      rethrow;
    }
  }

  /// Check and show update dialog if available
  static Future<bool> checkAndShowUpdate({
    required BuildContext context,
    UpdateUIConfig? uiConfig,
    bool useBottomSheet = false,
  }) async {
    final manager = AppUpdateManager.instance;

    try {
      final updateInfo = await checkForUpdate();

      if (updateInfo == null || !updateInfo.isUpdateAvailable) {
        return false;
      }

      // Check if user already dismissed this version
      if (!updateInfo.isForced && !updateInfo.isBelowMinimumVersion) {
        final dismissed = await manager._cacheService.hasUserDismissedVersion(
          updateInfo.latestVersion.toString(),
        );
        if (dismissed) return false;
      }

      // Show dialog or bottom sheet
      return await _showUpdateUI(
        context: context,
        updateInfo: updateInfo,
        uiConfig: uiConfig,
        useBottomSheet: useBottomSheet,
      );
    } catch (e) {
      return false;
    }
  }

  /// Show update UI
  static Future<bool> _showUpdateUI({
    required BuildContext context,
    required UpdateInfo updateInfo,
    UpdateUIConfig? uiConfig,
    bool useBottomSheet = false,
  }) async {
    final manager = AppUpdateManager.instance;
    manager._analyticsService.trackDialogShown(updateInfo);

    final result = useBottomSheet
        ? await showUpdateBottomSheet(
            context: context,
            updateInfo: updateInfo,
            uiConfig: uiConfig,
            onUpdate: () =>
                manager._analyticsService.trackUpdateAccepted(updateInfo),
            onCancel: () async {
              final count = await manager._cacheService.getDismissCount();
              manager._analyticsService.trackUpdateDismissed(
                updateInfo,
                dismissCount: count,
              );
            },
            onLater: () async {
              await manager._cacheService.markUpdateDismissed(
                updateInfo.latestVersion.toString(),
              );
              final count = await manager._cacheService.getDismissCount();
              manager._analyticsService.trackUpdateDismissed(
                updateInfo,
                dismissCount: count,
              );
            },
          )
        : await showUpdateDialog(
            context: context,
            updateInfo: updateInfo,
            uiConfig: uiConfig,
            onUpdate: () =>
                manager._analyticsService.trackUpdateAccepted(updateInfo),
            onCancel: () async {
              final count = await manager._cacheService.getDismissCount();
              manager._analyticsService.trackUpdateDismissed(
                updateInfo,
                dismissCount: count,
              );
            },
            onLater: () async {
              await manager._cacheService.markUpdateDismissed(
                updateInfo.latestVersion.toString(),
              );
              final count = await manager._cacheService.getDismissCount();
              manager._analyticsService.trackUpdateDismissed(
                updateInfo,
                dismissCount: count,
              );
            },
          );

    if (result == true) {
      await performUpdate(updateInfo);
    }

    return result ?? false;
  }

  /// Perform the update
  static Future<void> performUpdate(UpdateInfo updateInfo) async {
    final manager = AppUpdateManager.instance;

    // Android in-app update
    if (Platform.isAndroid && manager._config.playStoreId != null) {
      await _performAndroidUpdate(updateInfo);
      return;
    }

    // Open store page for iOS or when in-app update not available
    await manager._platformHandler.openStorePageWithFallback(updateInfo);
  }

  /// Perform Android in-app update
  static Future<void> _performAndroidUpdate(UpdateInfo updateInfo) async {
    final manager = AppUpdateManager.instance;

    try {
      final available = await manager._platformHandler
          .checkInAppUpdateAvailability();

      if (available) {
        manager._analyticsService.trackInstallStarted();

        iap.AppUpdateResult result;

        if (manager._config.strategy == UpdateStrategy.immediate ||
            updateInfo.isForced ||
            updateInfo.isBelowMinimumVersion) {
          result = await manager._platformHandler.performImmediateUpdate();
        } else {
          result = await manager._platformHandler.performFlexibleUpdate();

          if (result == iap.AppUpdateResult.success) {
            await manager._platformHandler.completeFlexibleUpdate();
          }
        }

        if (result == iap.AppUpdateResult.success) {
          manager._analyticsService.trackInstallCompleted();
        } else {
          manager._analyticsService.trackInstallFailed(result.toString());
        }
      } else {
        // Fallback to Play Store
        await manager._platformHandler.openStorePageWithFallback(updateInfo);
      }
    } catch (e) {
      manager._analyticsService.trackInstallFailed(e.toString());
      await manager._platformHandler.openStorePageWithFallback(updateInfo);
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    final manager = AppUpdateManager.instance;
    await manager._cacheService.clearCache();
    await manager._cacheService.resetDismissData();
  }

  /// Cancel background checks
  static Future<void> cancelBackgroundChecks() async {
    await BackgroundWorker.cancelAll();
  }

  /// Check if background update is available
  static Future<bool> hasBackgroundUpdate() async {
    return await BackgroundWorker.hasBackgroundUpdate();
  }

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    final manager = AppUpdateManager.instance;
    final version = await manager._versionChecker.getCurrentVersion();
    return version.toString();
  }

  /// Update configuration
  static void updateConfig(UpdateConfig config) {
    final manager = AppUpdateManager.instance;
    manager._config = config;
    manager._versionChecker = VersionChecker(config: config);
    manager._platformHandler = PlatformUpdateHandler(config: config);
    manager._analyticsService = AnalyticsService(config: config);
  }

  /// Get current configuration
  static UpdateConfig get config => AppUpdateManager.instance._config;

  static Map<String, dynamic> _configToJson(UpdateConfig config) {
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
}
