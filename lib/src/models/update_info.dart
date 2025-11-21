import 'version.dart';

/// Information about an available update
class UpdateInfo {
  /// The latest version available
  final AppVersion latestVersion;

  /// The current installed version
  final AppVersion currentVersion;

  /// Release notes for the update
  final String? releaseNotes;

  /// Download URL for custom updates
  final String? downloadUrl;

  /// Whether this is a forced update
  final bool isForced;

  /// Whether the update is critical
  final bool isCritical;

  /// Minimum supported version (versions below this must update)
  final AppVersion? minimumSupportedVersion;

  /// Release date of the update
  final DateTime? releaseDate;

  /// File size in bytes (for custom updates)
  final int? fileSizeBytes;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Creates an [UpdateInfo] instance.
  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.isForced = false,
    this.isCritical = false,
    this.minimumSupportedVersion,
    this.releaseDate,
    this.fileSizeBytes,
    this.metadata,
  });

  /// Check if an update is available
  bool get isUpdateAvailable => latestVersion > currentVersion;

  /// Check if current version is below minimum supported
  bool get isBelowMinimumVersion {
    if (minimumSupportedVersion == null) return false;
    return currentVersion < minimumSupportedVersion!;
  }

  /// Get update type (major, minor, patch)
  UpdateType get updateType {
    if (!isUpdateAvailable) return UpdateType.none;

    if (latestVersion.major > currentVersion.major) {
      return UpdateType.major;
    } else if (latestVersion.minor > currentVersion.minor) {
      return UpdateType.minor;
    } else {
      return UpdateType.patch;
    }
  }

  /// Format file size to human readable
  String get formattedFileSize {
    if (fileSizeBytes == null) return '';

    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (fileSizeBytes! >= gb) {
      return '${(fileSizeBytes! / gb).toStringAsFixed(2)} GB';
    } else if (fileSizeBytes! >= mb) {
      return '${(fileSizeBytes! / mb).toStringAsFixed(2)} MB';
    } else if (fileSizeBytes! >= kb) {
      return '${(fileSizeBytes! / kb).toStringAsFixed(2)} KB';
    } else {
      return '$fileSizeBytes B';
    }
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: AppVersion.parse(json['latest_version'] as String),
      currentVersion: AppVersion.parse(json['current_version'] as String),
      releaseNotes: json['release_notes'] as String?,
      downloadUrl: json['download_url'] as String?,
      isForced: json['is_forced'] as bool? ?? false,
      isCritical: json['is_critical'] as bool? ?? false,
      minimumSupportedVersion: json['minimum_supported_version'] != null
          ? AppVersion.parse(json['minimum_supported_version'] as String)
          : null,
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'] as String)
          : null,
      fileSizeBytes: json['file_size_bytes'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion.toString(),
      'current_version': currentVersion.toString(),
      'release_notes': releaseNotes,
      'download_url': downloadUrl,
      'is_forced': isForced,
      'is_critical': isCritical,
      'minimum_supported_version': minimumSupportedVersion?.toString(),
      'release_date': releaseDate?.toIso8601String(),
      'file_size_bytes': fileSizeBytes,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion, '
        'available: $isUpdateAvailable, forced: $isForced)';
  }
}

/// Type of update available
enum UpdateType { none, patch, minor, major }
