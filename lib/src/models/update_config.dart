import 'package:flutter/material.dart';

/// Configuration for app update manager
class UpdateConfig {
  /// Play Store app ID (Android package name)
  final String? playStoreId;

  /// App Store ID (iOS app ID)
  final String? appStoreId;

  /// Custom API endpoint for version checking
  final String? customUpdateUrl;

  /// HTTP headers for custom API calls
  final Map<String, String>? customHeaders;

  /// Update check strategy
  final UpdateStrategy strategy;

  /// How often to check for updates in background (in hours)
  final int backgroundCheckInterval;

  /// Whether to enable background checking
  final bool enableBackgroundCheck;

  /// Whether to show update dialog automatically
  final bool showDialogAutomatically;

  /// Whether to cache version info
  final bool enableCaching;

  /// Cache duration in hours
  final int cacheDuration;

  /// Timeout for API requests in seconds
  final int requestTimeout;

  /// Whether to check for updates only on WiFi
  final bool wifiOnly;

  /// Custom user agent for API requests
  final String? customUserAgent;

  /// Region code for regional rollouts
  final String? regionCode;

  /// A/B test group identifier
  final String? testGroup;

  /// Whether to enable analytics tracking
  final bool enableAnalytics;

  /// Custom analytics callback
  final Function(UpdateEvent event, Map<String, dynamic>? data)?
  onAnalyticsEvent;

  /// Creates an [UpdateConfig] instance.
  const UpdateConfig({
    this.playStoreId,
    this.appStoreId,
    this.customUpdateUrl,
    this.customHeaders,
    this.strategy = UpdateStrategy.flexible,
    this.backgroundCheckInterval = 24,
    this.enableBackgroundCheck = false,
    this.showDialogAutomatically = true,
    this.enableCaching = true,
    this.cacheDuration = 6,
    this.requestTimeout = 30,
    this.wifiOnly = false,
    this.customUserAgent,
    this.regionCode,
    this.testGroup,
    this.enableAnalytics = false,
    this.onAnalyticsEvent,
  });

  /// Validate configuration
  bool validate() {
    return playStoreId != null || appStoreId != null || customUpdateUrl != null;
  }

  UpdateConfig copyWith({
    String? playStoreId,
    String? appStoreId,
    String? customUpdateUrl,
    Map<String, String>? customHeaders,
    UpdateStrategy? strategy,
    int? backgroundCheckInterval,
    bool? enableBackgroundCheck,
    bool? showDialogAutomatically,
    bool? enableCaching,
    int? cacheDuration,
    int? requestTimeout,
    bool? wifiOnly,
    String? customUserAgent,
    String? regionCode,
    String? testGroup,
    bool? enableAnalytics,
    Function(UpdateEvent, Map<String, dynamic>?)? onAnalyticsEvent,
  }) {
    return UpdateConfig(
      playStoreId: playStoreId ?? this.playStoreId,
      appStoreId: appStoreId ?? this.appStoreId,
      customUpdateUrl: customUpdateUrl ?? this.customUpdateUrl,
      customHeaders: customHeaders ?? this.customHeaders,
      strategy: strategy ?? this.strategy,
      backgroundCheckInterval:
          backgroundCheckInterval ?? this.backgroundCheckInterval,
      enableBackgroundCheck:
          enableBackgroundCheck ?? this.enableBackgroundCheck,
      showDialogAutomatically:
          showDialogAutomatically ?? this.showDialogAutomatically,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      customUserAgent: customUserAgent ?? this.customUserAgent,
      regionCode: regionCode ?? this.regionCode,
      testGroup: testGroup ?? this.testGroup,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      onAnalyticsEvent: onAnalyticsEvent ?? this.onAnalyticsEvent,
    );
  }
}

/// Update strategies
enum UpdateStrategy {
  /// Shows update dialog but allows user to dismiss
  flexible,

  /// Blocks app usage until updated
  immediate,

  /// Shows notification but allows continued use
  optional,
}

/// Analytics events
enum UpdateEvent {
  checkStarted,
  checkCompleted,
  checkFailed,
  updateAvailable,
  updateNotAvailable,
  updateDialogShown,
  updateAccepted,
  updateDismissed,
  updateDownloadStarted,
  updateDownloadProgress,
  updateDownloadCompleted,
  updateDownloadFailed,
  updateInstallStarted,
  updateInstallCompleted,
  updateInstallFailed,
}

/// UI customization for update dialogs
class UpdateUIConfig {
  final String? title;
  final String? message;
  final String? updateButtonText;
  final String? cancelButtonText;
  final String? laterButtonText;
  final Color? backgroundColor;
  final Color? primaryColor;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final bool showReleaseNotes;
  final bool showFileSize;
  final Widget? customIcon;

  const UpdateUIConfig({
    this.title,
    this.message,
    this.updateButtonText,
    this.cancelButtonText,
    this.laterButtonText,
    this.backgroundColor,
    this.primaryColor,
    this.titleStyle,
    this.messageStyle,
    this.showReleaseNotes = true,
    this.showFileSize = true,
    this.customIcon,
  });
}
