/// Represents a semantic version (major.minor.patch+build)
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? buildNumber;

  /// Creates an [AppVersion] instance.
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.buildNumber,
  });

  /// Parse version string (e.g., "1.2.3", "1.2.3+456")
  static AppVersion parse(String version) {
    final parts = version.split('+');
    final versionParts = parts[0].split('.');

    if (versionParts.isEmpty || versionParts.length > 3) {
      throw FormatException('Invalid version format: $version');
    }

    final major = int.tryParse(versionParts[0]) ?? 0;
    final minor = versionParts.length > 1
        ? (int.tryParse(versionParts[1]) ?? 0)
        : 0;
    final patch = versionParts.length > 2
        ? (int.tryParse(versionParts[2]) ?? 0)
        : 0;
    final buildNumber = parts.length > 1 ? parts[1] : null;

    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: buildNumber,
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // If version numbers are equal, compare build numbers if available
    if (buildNumber != null && other.buildNumber != null) {
      final thisBuild = int.tryParse(buildNumber!);
      final otherBuild = int.tryParse(other.buildNumber!);
      if (thisBuild != null && otherBuild != null) {
        return thisBuild.compareTo(otherBuild);
      }
    }

    return 0;
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppVersion &&
        major == other.major &&
        minor == other.minor &&
        patch == other.patch &&
        buildNumber == other.buildNumber;
  }

  @override
  int get hashCode =>
      major.hashCode ^ minor.hashCode ^ patch.hashCode ^ buildNumber.hashCode;

  @override
  String toString() {
    final version = '$major.$minor.$patch';
    return buildNumber != null ? '$version+$buildNumber' : version;
  }

  /// Get version without build number
  String toShortString() => '$major.$minor.$patch';
}
