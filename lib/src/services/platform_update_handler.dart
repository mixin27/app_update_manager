import 'dart:io';

import 'package:in_app_update/in_app_update.dart' as iap;
import 'package:url_launcher/url_launcher.dart';

import '../models/update_config.dart';
import '../models/update_info.dart';

/// Handles platform-specific update operations
class PlatformUpdateHandler {
  final UpdateConfig config;

  PlatformUpdateHandler({required this.config});

  /// Check if in-app update is available (Android only)
  Future<bool> checkInAppUpdateAvailability() async {
    if (!Platform.isAndroid) return false;

    try {
      final updateInfo = await iap.InAppUpdate.checkForUpdate();
      return updateInfo.updateAvailability ==
          iap.UpdateAvailability.updateAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Perform flexible update (Android only)
  Future<iap.AppUpdateResult> performFlexibleUpdate() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Flexible updates only available on Android');
    }

    try {
      return await iap.InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// Perform immediate update (Android only)
  Future<iap.AppUpdateResult> performImmediateUpdate() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Immediate updates only available on Android');
    }

    try {
      return await iap.InAppUpdate.performImmediateUpdate();
    } catch (e) {
      rethrow;
    }
  }

  /// Complete flexible update (Android only)
  Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await iap.InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      // Silent fail
    }
  }

  /// Open app store page
  Future<bool> openStorePage(UpdateInfo updateInfo) async {
    final url = _getStoreUrl();
    if (url == null) return false;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Download custom update
  Future<String?> downloadCustomUpdate(
    UpdateInfo updateInfo,
    Function(int received, int total)? onProgress,
  ) async {
    if (updateInfo.downloadUrl == null) return null;

    try {
      // This is a placeholder - actual implementation would require
      // proper file download handling with dio
      // For production, you'd want to:
      // 1. Download to temp directory
      // 2. Verify checksum/signature
      // 3. Move to appropriate location
      // 4. Trigger installation

      return updateInfo.downloadUrl;
    } catch (e) {
      return null;
    }
  }

  /// Install custom update (platform-specific)
  Future<bool> installCustomUpdate(String filePath) async {
    // Platform-specific installation
    // Android: Launch install intent
    // iOS: Not possible due to iOS restrictions
    // Desktop: Platform-specific installers

    if (Platform.isAndroid) {
      return await _installAndroidUpdate(filePath);
    } else if (Platform.isIOS) {
      // iOS doesn't support custom updates
      return false;
    } else {
      return await _installDesktopUpdate(filePath);
    }
  }

  Future<bool> _installAndroidUpdate(String filePath) async {
    try {
      // For Android, you would use an install intent
      // This requires android_intent_plus package or method channel
      // Placeholder implementation
      final uri = Uri.parse('content://$filePath');
      return await launchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _installDesktopUpdate(String filePath) async {
    try {
      // Desktop platforms would execute the installer
      // This is platform-specific and requires careful handling
      final uri = Uri.file(filePath);
      return await launchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  String? _getStoreUrl() {
    if (Platform.isAndroid && config.playStoreId != null) {
      return 'https://play.google.com/store/apps/details?id=${config.playStoreId}';
    } else if (Platform.isIOS && config.appStoreId != null) {
      return 'https://apps.apple.com/app/id${config.appStoreId}';
    }
    return null;
  }

  /// Get market URL for specific platform
  String? getMarketUrl() {
    if (Platform.isAndroid && config.playStoreId != null) {
      return 'market://details?id=${config.playStoreId}';
    } else if (Platform.isIOS && config.appStoreId != null) {
      return 'itms-apps://itunes.apple.com/app/id${config.appStoreId}';
    }
    return null;
  }

  /// Try to open market URL, fallback to web URL
  Future<bool> openStorePageWithFallback(UpdateInfo updateInfo) async {
    // Try market URL first (opens native store app)
    final marketUrl = getMarketUrl();
    if (marketUrl != null) {
      try {
        final uri = Uri.parse(marketUrl);
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (e) {
        // Fall through to web URL
      }
    }

    // Fallback to web URL
    return await openStorePage(updateInfo);
  }

  /// Check if platform supports in-app updates
  bool get supportsInAppUpdate => Platform.isAndroid;

  /// Check if platform supports custom updates
  bool get supportsCustomUpdate =>
      Platform.isAndroid ||
      Platform.isWindows ||
      Platform.isMacOS ||
      Platform.isLinux;
}
