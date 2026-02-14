import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class GitHubRelease {
  final String tagName;
  final String name;
  final String body;
  final String downloadUrl;
  final DateTime publishedAt;

  GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.downloadUrl,
    required this.publishedAt,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    return GitHubRelease(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      downloadUrl: _getInstallerUrl(json['assets'] ?? []),
      publishedAt: DateTime.parse(json['published_at']),
    );
  }

  static String _getInstallerUrl(List<dynamic> assets) {
    for (var asset in assets) {
      if (asset['name'] == 'SpawnPKMarketDashboardSetup.exe') {
        return asset['browser_download_url'] ?? '';
      }
    }
    return '';
  }
}

class UpdateService {
  static const String _repoOwner = 'i-iz-adam';
  static const String _repoName = 'spawnpk_market_dashboard';
  static const String _lastCheckKey = 'last_update_check';
  static const String _dismissedVersionKey = 'dismissed_update_version';

  static Future<GitHubRelease?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SpawnPK-Market-Dashboard',
        },
      );

      if (response.statusCode == 200) {
        final release = GitHubRelease.fromJson(json.decode(response.body));
        

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = 'v${packageInfo.version}';
        

        if (_isNewerVersion(release.tagName, currentVersion)) {
          return release;
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String latest, String current) {

    final latestClean = latest.startsWith('v') ? latest.substring(1) : latest;
    final currentClean = current.startsWith('v') ? current.substring(1) : current;
    
    final latestParts = latestClean.split('.').map(int.parse).toList();
    final currentParts = currentClean.split('.').map(int.parse).toList();
    

    while (latestParts.length < 3) {
      latestParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static Future<String> downloadUpdate(String downloadUrl, String savePath) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  static Future<bool> installUpdate(String installerPath) async {
    try {
      if (Platform.isWindows) {

        await Process.run(installerPath, ['/SILENT']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error installing update: $e');
      return false;
    }
  }

  static Future<void> saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastCheckKey);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  static Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  static Future<String?> getDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedVersionKey);
  }

  static Future<bool> shouldCheckForUpdates() async {
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;
    

    final now = DateTime.now();
    final difference = now.difference(lastCheck);
    return difference.inHours >= 24;
  }

  static String getInstallerDownloadPath() {
    final tempDir = Directory.systemTemp;
    return path.join(tempDir.path, 'SpawnPKMarketDashboardSetup.exe');
  }
}
