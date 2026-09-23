// lib/services/app_launcher_helper.dart
//
// 3-Tier App Resolution Engine for Jack Mobile Agent
// ─────────────────────────────────────────────────────────────────────────────
// Resolves spoken app names, aliases, and abbreviations to Android package names:
//   • Tier 1: Static Normalization Dictionary (~70 common apps & aliases)
//   • Tier 2: Dynamic lookup via InstalledApps plugin (with fuzzy/partial match)
//   • Tier 3: Package Name Passthrough / Native Fallback
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppLauncherHelper {
  AppLauncherHelper._();

  static List<AppInfo>? _cachedApps;

  /// Visible for testing to inject mock installed apps.
  @visibleForTesting
  static void setCachedAppsForTesting(List<AppInfo>? apps) {
    _cachedApps = apps;
  }

  /// Clears the cached installed apps list.
  static void clearCache() {
    _cachedApps = null;
  }

  /// Tier 1: Extensive static dictionary of common app names, spoken aliases,
  /// and abbreviations mapped to standard Android package IDs.
  static const Map<String, String> _staticPackageMap = {
    // ── Google & Core System Apps ──────────────────────────────────────────
    'youtube': 'com.google.android.youtube',
    'yt': 'com.google.android.youtube',
    'ytube': 'com.google.android.youtube',
    'you tube': 'com.google.android.youtube',
    'youtube music': 'com.google.android.apps.youtube.music',
    'yt music': 'com.google.android.apps.youtube.music',
    'ytmusic': 'com.google.android.apps.youtube.music',
    'chrome': 'com.android.chrome',
    'google chrome': 'com.android.chrome',
    'browser': 'com.android.chrome',
    'settings': 'com.android.settings',
    'setting': 'com.android.settings',
    'system settings': 'com.android.settings',
    'camera': 'com.google.android.GoogleCamera',
    'cam': 'com.google.android.GoogleCamera',
    'gcam': 'com.google.android.GoogleCamera',
    'google camera': 'com.google.android.GoogleCamera',
    'maps': 'com.google.android.apps.maps',
    'google maps': 'com.google.android.apps.maps',
    'gmaps': 'com.google.android.apps.maps',
    'navigation': 'com.google.android.apps.maps',
    'gmail': 'com.google.android.gm',
    'google mail': 'com.google.android.gm',
    'mail': 'com.google.android.gm',
    'email': 'com.google.android.gm',
    'photos': 'com.google.android.apps.photos',
    'google photos': 'com.google.android.apps.photos',
    'gallery': 'com.google.android.apps.photos',
    'clock': 'com.google.android.deskclock',
    'alarm': 'com.google.android.deskclock',
    'timer': 'com.google.android.deskclock',
    'deskclock': 'com.google.android.deskclock',
    'calculator': 'com.google.android.calculator',
    'calc': 'com.google.android.calculator',
    'play store': 'com.android.vending',
    'playstore': 'com.android.vending',
    'google play': 'com.android.vending',
    'google play store': 'com.android.vending',
    'app store': 'com.android.vending',
    'market': 'com.android.vending',
    'calendar': 'com.google.android.calendar',
    'google calendar': 'com.google.android.calendar',
    'gcal': 'com.google.android.calendar',
    'drive': 'com.google.android.apps.docs',
    'google drive': 'com.google.android.apps.docs',
    'gdrive': 'com.google.android.apps.docs',
    'keep': 'com.google.android.keep',
    'google keep': 'com.google.android.keep',
    'notes': 'com.google.android.keep',
    'keep notes': 'com.google.android.keep',
    'meet': 'com.google.android.apps.meetings',
    'google meet': 'com.google.android.apps.meetings',
    'files': 'com.google.android.apps.nbu.files',
    'google files': 'com.google.android.apps.nbu.files',
    'file manager': 'com.google.android.apps.nbu.files',
    'contacts': 'com.google.android.contacts',
    'google contacts': 'com.google.android.contacts',
    'messages': 'com.google.android.apps.messaging',
    'sms': 'com.google.android.apps.messaging',
    'google messages': 'com.google.android.apps.messaging',
    'phone': 'com.google.android.dialer',
    'dialer': 'com.google.android.dialer',
    'translate': 'com.google.android.apps.translate',
    'google translate': 'com.google.android.apps.translate',
    'docs': 'com.google.android.apps.docs.editors.docs',
    'google docs': 'com.google.android.apps.docs.editors.docs',
    'sheets': 'com.google.android.apps.docs.editors.sheets',
    'google sheets': 'com.google.android.apps.docs.editors.sheets',
    'slides': 'com.google.android.apps.docs.editors.slides',
    'google slides': 'com.google.android.apps.docs.editors.slides',

    // ── Messaging & Social Media ────────────────────────────────────────────
    'whatsapp': 'com.whatsapp',
    'wa': 'com.whatsapp',
    'whats app': 'com.whatsapp',
    'wapp': 'com.whatsapp',
    'whatsapp business': 'com.whatsapp.w4b',
    'wa business': 'com.whatsapp.w4b',
    'wabi': 'com.whatsapp.w4b',
    'instagram': 'com.instagram.android',
    'insta': 'com.instagram.android',
    'ig': 'com.instagram.android',
    'threads': 'com.instagram.barcelona',
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'x twitter': 'com.twitter.android',
    'tweet': 'com.twitter.android',
    'telegram': 'org.telegram.messenger',
    'tg': 'org.telegram.messenger',
    'snapchat': 'com.snapchat.android',
    'snap': 'com.snapchat.android',
    'facebook': 'com.facebook.katana',
    'fb': 'com.facebook.katana',
    'messenger': 'com.facebook.orca',
    'fb messenger': 'com.facebook.orca',
    'linkedin': 'com.linkedin.android',
    'reddit': 'com.reddit.frontpage',
    'pinterest': 'com.pinterest',
    'discord': 'com.discord',
    'slack': 'com.Slack',
    'tiktok': 'com.zhiliaoapp.musically',
    'twitch': 'tv.twitch.android',

    // ── Music, Video & Media Streaming ──────────────────────────────────────
    'spotify': 'com.spotify.music',
    'spotify music': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
    'prime video': 'com.amazon.avod.thirdpartyclient',
    'amazon prime': 'com.amazon.avod.thirdpartyclient',
    'amazon prime video': 'com.amazon.avod.thirdpartyclient',
    'prime': 'com.amazon.avod.thirdpartyclient',
    'hotstar': 'in.startv.hotstar',
    'disney hotstar': 'in.startv.hotstar',
    'disney+': 'in.startv.hotstar',
    'disney plus': 'in.startv.hotstar',
    'disney': 'in.startv.hotstar',
    'jiocinema': 'com.jio.media.ondemand',
    'jio cinema': 'com.jio.media.ondemand',
    'zee5': 'com.graymatrix.did',
    'sonyliv': 'com.sonyliv',
    'sony liv': 'com.sonyliv',
    'apple music': 'com.apple.android.music',
    'soundcloud': 'com.soundcloud.android',
    'vlc': 'org.videolan.vlc',
    'mx player': 'com.mxtech.videoplayer.ad',
    'mxplayer': 'com.mxtech.videoplayer.ad',
    'shazam': 'com.shazam.android',

    // ── Travel, Food & Shopping ─────────────────────────────────────────────
    'uber': 'com.ubercab',
    'ubercab': 'com.ubercab',
    'ola': 'com.olacabs.customer',
    'olacabs': 'com.olacabs.customer',
    'amazon': 'in.amazon.mShop.android.shopping',
    'amazon shopping': 'in.amazon.mShop.android.shopping',
    'flipkart': 'com.flipkart.android',
    'zomato': 'com.application.zomato',
    'swiggy': 'in.swiggy.android',
    'instamart': 'in.swiggy.android',

    // ── Payments & Banking ──────────────────────────────────────────────────
    'phonepe': 'com.phonepe.app',
    'phone pe': 'com.phonepe.app',
    'paytm': 'net.one97.paytm',
    'gpay': 'com.google.android.apps.nbu.paisa.user',
    'google pay': 'com.google.android.apps.nbu.paisa.user',
    'tez': 'com.google.android.apps.nbu.paisa.user',

    // ── Productivity & Tools ────────────────────────────────────────────────
    'zoom': 'us.zoom.videomeetings',
    'teams': 'com.microsoft.teams',
    'microsoft teams': 'com.microsoft.teams',
    'outlook': 'com.microsoft.office.outlook',
    'microsoft outlook': 'com.microsoft.office.outlook',
    'word': 'com.microsoft.office.word',
    'microsoft word': 'com.microsoft.office.word',
    'excel': 'com.microsoft.office.excel',
    'microsoft excel': 'com.microsoft.office.excel',
    'powerpoint': 'com.microsoft.office.powerpoint',
    'canva': 'com.canva.editor',
    'truecaller': 'com.truecaller',
    'duolingo': 'com.duolingo',
  };

  /// Read-only access to static package mappings.
  static Map<String, String> get staticPackageMap => _staticPackageMap;

  /// Checks if a string conforms to an Android package name structure
  /// (e.g. `com.android.chrome`, `org.telegram.messenger`, `in.swiggy.android`).
  static bool isPackageName(String input) {
    final trimmed = input.trim();
    if (!trimmed.contains('.')) return false;
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$');
    return regex.hasMatch(trimmed);
  }

  /// Normalizes user/LLM input string by trimming, removing command prefixes,
  /// and standardizing lowercasing.
  static String _normalizeQuery(String rawInput) {
    var query = rawInput.trim();
    if (query.toLowerCase().startsWith('launch:')) {
      query = query.substring(7).trim();
    }
    return query;
  }

  /// Synchronous package resolver (Tier 1 & Package Passthrough).
  ///
  /// Quickly resolves:
  /// 1. Package IDs passed directly (`com.android.chrome`)
  /// 2. Known static app names & spoken aliases (`"YouTube"`, `"wa"`, `"insta"`)
  ///
  /// Returns the resolved package name, or the trimmed query if not found in static dictionary.
  static String resolvePackageSync(String query) {
    final cleanInput = _normalizeQuery(query);
    if (cleanInput.isEmpty) return cleanInput;

    // 1. Direct package name passthrough
    if (isPackageName(cleanInput)) {
      return cleanInput;
    }

    final lower = cleanInput.toLowerCase();

    // 2. Direct static dictionary lookup
    if (_staticPackageMap.containsKey(lower)) {
      return _staticPackageMap[lower]!;
    }

    // 3. Space-stripped and punctuation-stripped lookup
    final stripped = lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (_staticPackageMap.containsKey(stripped)) {
      return _staticPackageMap[stripped]!;
    }

    final spaceStripped = lower.replaceAll(' ', '');
    for (final entry in _staticPackageMap.entries) {
      if (entry.key.replaceAll(' ', '') == spaceStripped) {
        return entry.value;
      }
    }

    return cleanInput;
  }

  /// Full 3-Tier Asynchronous Package Resolver:
  ///
  /// 1. **Tier 1**: Synchronous check (Package passthrough & Static dictionary)
  /// 2. **Tier 2**: Dynamic lookup via `InstalledApps.getInstalledApps` with fuzzy/partial matching
  /// 3. **Tier 3**: Fallback to input query for native PackageManager handling
  static Future<String> resolvePackage(String rawInput) async {
    final cleanInput = _normalizeQuery(rawInput);
    if (cleanInput.isEmpty) return cleanInput;

    // Tier 1: Check synchronous resolver first
    final syncResolved = resolvePackageSync(cleanInput);
    if (isPackageName(syncResolved)) {
      return syncResolved;
    }

    // Tier 2: Dynamic lookup via installed_apps plugin (mobile only)
    if (!kIsWeb) {
      try {
        _cachedApps ??= await InstalledApps.getInstalledApps(
          excludeSystemApps: false,
          withIcon: false,
        );

      if (_cachedApps != null && _cachedApps!.isNotEmpty) {
        final queryLower = cleanInput.toLowerCase();
        final queryStripped = queryLower.replaceAll(RegExp(r'[^a-z0-9]'), '');

        // Strategy A: Exact app name match
        for (final app in _cachedApps!) {
          final appName = app.name.trim().toLowerCase();
          if (appName == queryLower) {
            if (app.packageName.isNotEmpty) return app.packageName;
          }
        }

        // Strategy B: Space/punctuation stripped match
        for (final app in _cachedApps!) {
          final appNameStripped = app.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (appNameStripped == queryStripped && queryStripped.isNotEmpty) {
            if (app.packageName.isNotEmpty) return app.packageName;
          }
        }

        // Strategy C: Substring / contains match
        for (final app in _cachedApps!) {
          final appName = app.name.trim().toLowerCase();
          if (appName.contains(queryLower) || queryLower.contains(appName)) {
            if (app.packageName.isNotEmpty) return app.packageName;
          }
        }

        // Strategy D: Package name substring match
        for (final app in _cachedApps!) {
          final pkg = app.packageName.toLowerCase();
          if (pkg.contains(queryLower)) {
            return app.packageName;
          }
        }
      }
      } catch (e) {
        debugPrint('[AppLauncherHelper] InstalledApps dynamic lookup failed: $e');
      }
    }

    // Tier 3: Return sync resolution or original cleaned query
    return syncResolved;
  }

  /// Resolves an app name and launches it on the mobile device.
  static Future<bool> launchAppByName(String appName) async {
    if (kIsWeb) return false;
    final pkg = await resolvePackage(appName);
    if (pkg.isNotEmpty && isPackageName(pkg)) {
      try {
        final started = await InstalledApps.startApp(pkg);
        return started ?? false;
      } catch (_) {}
    }
    return false;
  }
}
