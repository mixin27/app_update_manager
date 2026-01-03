import '../models/update_config.dart';
import '../models/update_info.dart';

/// Service for tracking update-related analytics
class AnalyticsService {
  /// Update configuration
  final UpdateConfig config;

  /// Creates an [AnalyticsService] instance.
  const AnalyticsService({required this.config});

  /// Track an update event
  void trackEvent(UpdateEvent event, {Map<String, dynamic>? data}) {
    if (!config.enableAnalytics) return;

    final eventData = <String, dynamic>{
      'event': event.name,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    };

    // Call custom analytics callback if provided
    config.onAnalyticsEvent?.call(event, eventData);
  }

  /// Track update check started
  void trackCheckStarted() {
    trackEvent(UpdateEvent.checkStarted);
  }

  /// Track update check completed
  void trackCheckCompleted({required bool updateAvailable}) {
    trackEvent(
      updateAvailable
          ? UpdateEvent.updateAvailable
          : UpdateEvent.updateNotAvailable,
      data: {'update_available': updateAvailable},
    );
  }

  /// Track update check failed
  void trackCheckFailed(String error) {
    trackEvent(UpdateEvent.checkFailed, data: {'error': error});
  }

  /// Track update dialog shown
  void trackDialogShown(UpdateInfo updateInfo) {
    trackEvent(
      UpdateEvent.updateDialogShown,
      data: {
        'current_version': updateInfo.currentVersion.toString(),
        'latest_version': updateInfo.latestVersion.toString(),
        'update_type': updateInfo.updateType.name,
        'is_forced': updateInfo.isForced,
      },
    );
  }

  /// Track update accepted
  void trackUpdateAccepted(UpdateInfo updateInfo) {
    trackEvent(
      UpdateEvent.updateAccepted,
      data: {
        'current_version': updateInfo.currentVersion.toString(),
        'latest_version': updateInfo.latestVersion.toString(),
        'update_type': updateInfo.updateType.name,
      },
    );
  }

  /// Track update dismissed
  void trackUpdateDismissed(UpdateInfo updateInfo, {int? dismissCount}) {
    trackEvent(
      UpdateEvent.updateDismissed,
      data: {
        'current_version': updateInfo.currentVersion.toString(),
        'latest_version': updateInfo.latestVersion.toString(),
        'dismiss_count': dismissCount,
      },
    );
  }

  /// Track download started
  void trackDownloadStarted(UpdateInfo updateInfo) {
    trackEvent(
      UpdateEvent.updateDownloadStarted,
      data: {
        'version': updateInfo.latestVersion.toString(),
        'file_size': updateInfo.fileSizeBytes,
      },
    );
  }

  /// Track download progress
  void trackDownloadProgress(int received, int total) {
    final progress = (received / total * 100).toInt();
    trackEvent(
      UpdateEvent.updateDownloadProgress,
      data: {'received': received, 'total': total, 'progress': progress},
    );
  }

  /// Track download completed
  void trackDownloadCompleted(UpdateInfo updateInfo) {
    trackEvent(
      UpdateEvent.updateDownloadCompleted,
      data: {'version': updateInfo.latestVersion.toString()},
    );
  }

  /// Track download failed
  void trackDownloadFailed(String error) {
    trackEvent(UpdateEvent.updateDownloadFailed, data: {'error': error});
  }

  /// Track install started
  void trackInstallStarted() {
    trackEvent(UpdateEvent.updateInstallStarted);
  }

  /// Track install completed
  void trackInstallCompleted() {
    trackEvent(UpdateEvent.updateInstallCompleted);
  }

  /// Track install failed
  void trackInstallFailed(String error) {
    trackEvent(UpdateEvent.updateInstallFailed, data: {'error': error});
  }
}
