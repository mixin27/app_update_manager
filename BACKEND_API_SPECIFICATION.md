# Backend API Specification

This document describes how to implement a custom backend for app_update_manager.

## Overview

Your backend should provide an endpoint that returns version information when queried by the app. The package will automatically include relevant query parameters with each request.

## Endpoint

```
GET https://api.yourapp.com/version/check
```

## Request

### Query Parameters

The package automatically sends these parameters:

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `platform` | string | Operating system | `android`, `ios`, `windows` |
| `current_version` | string | Current app version | `1.0.0` |
| `build_number` | string | Current build number | `42` |
| `package_name` | string | App package/bundle ID | `com.example.app` |
| `region` | string | Region code (if configured) | `US`, `JP`, `GB` |
| `test_group` | string | A/B test group (if configured) | `beta`, `alpha` |

### Headers

If you configured `customHeaders` in UpdateConfig, they will be included:

```
Authorization: Bearer YOUR_TOKEN
X-Custom-Header: value
```

## Response

### Success Response (200 OK)

#### Minimal Response

```json
{
  "latest_version": "1.2.0",
  "current_version": "1.0.0"
}
```

#### Complete Response

```json
{
  "latest_version": "1.2.0",
  "current_version": "1.0.0",
  "release_notes": "• Fixed critical bugs\n• Improved performance\n• Added new features",
  "download_url": "https://cdn.yourapp.com/app-1.2.0.apk",
  "is_forced": false,
  "is_critical": true,
  "minimum_supported_version": "1.0.0",
  "file_size_bytes": 25600000,
  "release_date": "2024-01-15T10:30:00Z",
  "metadata": {
    "changelog_url": "https://yourapp.com/changelog",
    "support_url": "https://yourapp.com/support",
    "custom_field": "custom_value"
  }
}
```

### Response Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `latest_version` | string | Yes | Latest available version (semantic versioning) |
| `current_version` | string | No | Current version (will use app version if not provided) |
| `release_notes` | string | No | What's new in this version (supports newlines) |
| `download_url` | string | No | Direct download URL for custom updates |
| `is_forced` | boolean | No | Whether update is mandatory (default: false) |
| `is_critical` | boolean | No | Whether update is critical security fix (default: false) |
| `minimum_supported_version` | string | No | Minimum version still supported |
| `file_size_bytes` | number | No | Download size in bytes |
| `release_date` | string | No | ISO 8601 date string |
| `metadata` | object | No | Additional custom data |

### Error Response (4xx, 5xx)

```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## Implementation Examples

### Node.js (Express)

```javascript
const express = require('express');
const app = express();

app.get('/version/check', async (req, res) => {
  try {
    const {
      platform,
      current_version,
      build_number,
      package_name,
      region,
      test_group
    } = req.query;

    // Your version logic here
    const latestVersion = await getLatestVersion(platform, region, test_group);

    // Compare versions
    if (compareVersions(latestVersion, current_version) > 0) {
      res.json({
        latest_version: latestVersion,
        current_version: current_version,
        release_notes: await getReleaseNotes(latestVersion),
        is_forced: await isForcedUpdate(current_version),
        is_critical: await isCriticalUpdate(latestVersion),
        minimum_supported_version: '1.0.0',
        file_size_bytes: await getFileSize(platform, latestVersion),
        release_date: new Date().toISOString()
      });
    } else {
      res.json({
        latest_version: current_version,
        current_version: current_version
      });
    }
  } catch (error) {
    res.status(500).json({
      error: error.message,
      code: 'VERSION_CHECK_FAILED'
    });
  }
});

app.listen(3000);
```

### Python (Flask)

```python
from flask import Flask, request, jsonify
from datetime import datetime
from packaging import version

app = Flask(__name__)

@app.route('/version/check')
def check_version():
    try:
        platform = request.args.get('platform')
        current_version = request.args.get('current_version')
        build_number = request.args.get('build_number')
        package_name = request.args.get('package_name')
        region = request.args.get('region')
        test_group = request.args.get('test_group')

        # Your version logic
        latest_version = get_latest_version(platform, region, test_group)

        # Compare versions
        if version.parse(latest_version) > version.parse(current_version):
            return jsonify({
                'latest_version': latest_version,
                'current_version': current_version,
                'release_notes': get_release_notes(latest_version),
                'is_forced': is_forced_update(current_version),
                'is_critical': is_critical_update(latest_version),
                'minimum_supported_version': '1.0.0',
                'file_size_bytes': get_file_size(platform, latest_version),
                'release_date': datetime.now().isoformat()
            })
        else:
            return jsonify({
                'latest_version': current_version,
                'current_version': current_version
            })
    except Exception as e:
        return jsonify({
            'error': str(e),
            'code': 'VERSION_CHECK_FAILED'
        }), 500

if __name__ == '__main__':
    app.run()
```

### PHP (Laravel)

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class VersionController extends Controller
{
    public function checkVersion(Request $request)
    {
        try {
            $platform = $request->query('platform');
            $currentVersion = $request->query('current_version');
            $buildNumber = $request->query('build_number');
            $packageName = $request->query('package_name');
            $region = $request->query('region');
            $testGroup = $request->query('test_group');

            // Your version logic
            $latestVersion = $this->getLatestVersion($platform, $region, $testGroup);

            // Compare versions
            if (version_compare($latestVersion, $currentVersion) > 0) {
                return response()->json([
                    'latest_version' => $latestVersion,
                    'current_version' => $currentVersion,
                    'release_notes' => $this->getReleaseNotes($latestVersion),
                    'is_forced' => $this->isForcedUpdate($currentVersion),
                    'is_critical' => $this->isCriticalUpdate($latestVersion),
                    'minimum_supported_version' => '1.0.0',
                    'file_size_bytes' => $this->getFileSize($platform, $latestVersion),
                    'release_date' => now()->toISOString()
                ]);
            } else {
                return response()->json([
                    'latest_version' => $currentVersion,
                    'current_version' => $currentVersion
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'error' => $e->getMessage(),
                'code' => 'VERSION_CHECK_FAILED'
            ], 500);
        }
    }
}
```

## Advanced Features

### Regional Rollouts

Roll out updates to specific regions first:

```javascript
function getLatestVersion(platform, region, testGroup) {
  const versions = {
    'US': '1.2.0',
    'EU': '1.1.0',
    'ASIA': '1.0.0'
  };
  return versions[region] || '1.0.0';
}
```

### A/B Testing

Different versions for different test groups:

```javascript
function getLatestVersion(platform, region, testGroup) {
  if (testGroup === 'beta') {
    return '1.3.0-beta';
  } else if (testGroup === 'alpha') {
    return '1.4.0-alpha';
  }
  return '1.2.0';
}
```

### Forced Updates

Force updates below certain versions:

```javascript
function isForcedUpdate(currentVersion) {
  const minimumVersion = '1.0.0';
  return compareVersions(currentVersion, minimumVersion) < 0;
}
```

### Critical Updates

Mark security updates as critical:

```javascript
function isCriticalUpdate(version) {
  const criticalVersions = ['1.2.0', '1.2.1'];
  return criticalVersions.includes(version);
}
```

## Best Practices

1. **Cache responses** - Reduce server load with CDN/caching
2. **Rate limiting** - Prevent abuse
3. **Authentication** - Use API keys or tokens
4. **Logging** - Track version checks for analytics
5. **Monitoring** - Alert on errors or unusual patterns
6. **Versioning** - Keep API versioned (/v1/version)
7. **Documentation** - Document custom fields in metadata
8. **Testing** - Test with different scenarios

## Security Considerations

1. **HTTPS only** - Always use HTTPS
2. **Authentication** - Validate API keys
3. **Input validation** - Validate all query parameters
4. **Rate limiting** - Prevent DDoS
5. **CORS** - Configure appropriate CORS headers
6. **Signed URLs** - For download_url, use signed URLs
7. **Audit logs** - Log all version checks

## Testing Your API

### Using cURL

```bash
curl "https://api.yourapp.com/version/check?platform=android&current_version=1.0.0&package_name=com.example.app"
```

### Expected Response

```json
{
  "latest_version": "1.2.0",
  "current_version": "1.0.0",
  "release_notes": "Bug fixes",
  "is_forced": false
}
```

## Troubleshooting

### No update showing

- Check version comparison logic
- Verify response format
- Check for API errors in logs
- Test with cURL

### Wrong version returned

- Check region/test group logic
- Verify database queries
- Check caching layer

### Slow responses

- Add caching
- Optimize database queries
- Use CDN
- Add monitoring

## Support

For backend integration help:
- Check example implementations
- Review API specification
- Test with provided tools
- Monitor server logs
