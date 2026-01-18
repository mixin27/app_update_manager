## 1.0.2

- Fix background worker compatibility with workmanager 0.9.0+3
- bumps: downgrade workmanager to `0.8.0` because 0.9.0+3 has an issue with periodic task on Android for 24hr frequency.

## 1.0.1

- Add github ci and inline documents
- bumps: upgrade shared_preferences to `2.5.4`
- App update now use `in_app_update` to check update in Android if `customUpdateUrl` not provide.

## 1.0.0

- Initial release of app_update_manager
- Multi-platform support (Android, iOS, custom backends)
- Three update strategies: flexible, immediate, and optional
- Beautiful, customizable UI components (dialog and bottom sheet)
- Background update checking with WorkManager
- Version caching to reduce API calls
- Release notes display
- File size information
- Force updates for critical versions
- Minimum supported version enforcement
- Regional rollouts support
- A/B testing capabilities
- Analytics integration
- Network connectivity handling
- WiFi-only update option
- Semantic versioning support
- Comprehensive error handling
- Complete documentation and examples

### Platform-Specific Features

#### Android
- Native in-app updates using Play Store API
- Flexible and immediate update flows
- Automatic Play Store page opening fallback

#### iOS
- App Store page opening
- iTunes API integration for version checking

#### All Platforms
- Custom update backend support
- Manual download and install (where supported)
- Cached update information
- User preference tracking (dismissed updates)

### Developer Features
- Type-safe configuration
- Extensive customization options
- Analytics hooks
- Testing utilities
- Comprehensive examples
- Full API documentation
