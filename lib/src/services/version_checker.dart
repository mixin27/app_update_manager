import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/update_config.dart';
import '../models/update_info.dart';
import '../models/version.dart';
import 'cache_service.dart';

/// Service for checking app version updates
class VersionChecker {
  final Dio _dio;

  /// Update configuration
  final UpdateConfig config;

  final CacheService _cacheService;

  /// Creates a [VersionChecker] instance.
  VersionChecker({required this.config, Dio? dio, CacheService? cacheService})
    : _dio = dio ?? Dio(),
      _cacheService = cacheService ?? CacheService() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.connectTimeout = Duration(seconds: config.requestTimeout);
    _dio.options.receiveTimeout = Duration(seconds: config.requestTimeout);

    if (config.customUserAgent != null) {
      _dio.options.headers['User-Agent'] = config.customUserAgent;
    }

    if (config.customHeaders != null) {
      _dio.options.headers.addAll(config.customHeaders!);
    }
  }

  /// Check for app updates
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Check network connectivity if WiFi only is enabled
      if (config.wifiOnly) {
        final connectivity = await Connectivity().checkConnectivity();
        if (!connectivity.contains(ConnectivityResult.wifi)) {
          throw Exception('WiFi required for update check');
        }
      }

      // Check cache first
      if (config.enableCaching) {
        final cachedUpdate = await _cacheService.getCachedUpdateInfo();
        if (cachedUpdate != null) {
          return cachedUpdate;
        }
      }

      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = AppVersion.parse(packageInfo.version);

      UpdateInfo? updateInfo;

      // Check custom backend first if available
      if (config.customUpdateUrl != null) {
        updateInfo = await _checkCustomBackend(currentVersion, packageInfo);
      }

      // If no custom backend or failed, fall back to store-specific checks
      if (updateInfo == null) {
        if (Platform.isAndroid && config.playStoreId != null) {
          updateInfo = await _checkPlayStore(currentVersion, packageInfo);
        } else if (Platform.isIOS && config.appStoreId != null) {
          updateInfo = await _checkAppStore(currentVersion, packageInfo);
        }
      }

      // Cache the result
      if (updateInfo != null && config.enableCaching) {
        await _cacheService.cacheUpdateInfo(
          updateInfo,
          Duration(hours: config.cacheDuration),
        );
      }

      return updateInfo;
    } catch (e) {
      rethrow;
    }
  }

  /// Check custom backend for updates
  Future<UpdateInfo?> _checkCustomBackend(
    AppVersion currentVersion,
    PackageInfo packageInfo,
  ) async {
    try {
      final params = {
        'platform': Platform.operatingSystem,
        'current_version': currentVersion.toString(),
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };

      // Add optional parameters
      if (config.regionCode != null) {
        params['region'] = config.regionCode!;
      }
      if (config.testGroup != null) {
        params['test_group'] = config.testGroup!;
      }

      final response = await _dio.get(
        config.customUpdateUrl!,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Add current version to response data if not present
        if (!data.containsKey('current_version')) {
          data['current_version'] = currentVersion.toString();
        }

        return UpdateInfo.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check Play Store for updates (via custom API)
  Future<UpdateInfo?> _checkPlayStore(
    AppVersion currentVersion,
    PackageInfo packageInfo,
  ) async {
    // Note: Google Play doesn't provide a public API for version checking
    // This would require a custom backend that scrapes or uses Play Store API
    // For now, we rely on in_app_update for Android which checks directly
    return null;
  }

  /// Check App Store for updates
  Future<UpdateInfo?> _checkAppStore(
    AppVersion currentVersion,
    PackageInfo packageInfo,
  ) async {
    try {
      final response = await _dio.get(
        'https://itunes.apple.com/lookup',
        queryParameters: {
          'id': config.appStoreId,
          'country': config.regionCode ?? 'us',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final appData = results[0] as Map<String, dynamic>;
          final latestVersion = AppVersion.parse(appData['version'] as String);
          final releaseNotes = appData['releaseNotes'] as String?;
          final fileSizeBytes = appData['fileSizeBytes'] as int?;

          final String? releaseDateStr =
              appData['currentVersionReleaseDate'] as String?;
          DateTime? releaseDate;
          if (releaseDateStr != null) {
            releaseDate = DateTime.tryParse(releaseDateStr);
          }

          return UpdateInfo(
            latestVersion: latestVersion,
            currentVersion: currentVersion,
            releaseNotes: releaseNotes,
            fileSizeBytes: fileSizeBytes,
            releaseDate: releaseDate,
            metadata: appData,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current app version
  Future<AppVersion> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppVersion.parse(packageInfo.version);
  }

  /// Get package info
  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
}
