// lib/services/jack_tools.dart
//
// Jack Tool Engine — gives Jack real-world capabilities
// ─────────────────────────────────────────────────────────────────────────────
// Tools available to Groq via function-calling:
//   • get_weather      → real weather via wttr.in (free, no key needed)
//   • get_news         → top headlines via GNews public endpoint
//   • search_web       → DuckDuckGo instant answers (free, no key)
//   • get_time         → current time/date in user's timezone
//   • get_battery      → battery level via platform channel
//   • remember_fact    → store a fact in long-term memory
//   • recall_facts     → retrieve all stored facts
//   • forget_fact      → remove a fact by key
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_launcher_helper.dart';

class JackTools {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
  ));

  static const _memoryKey = 'jack_memory_facts';
  static const _platform  = MethodChannel('com.syncra.syncra/accessibility');

  // ── Tool schema list for Groq ──────────────────────────────────────────────

  static List<Map<String, dynamic>> get toolSchemas => [
    {
      'type': 'function',
      'function': {
        'name': 'get_weather',
        'description': 'Get current weather and forecast for any city. Call this whenever the user asks about weather, temperature, rain, etc.',
        'parameters': {
          'type': 'object',
          'properties': {
            'city': {'type': 'string', 'description': 'City name, e.g. "Mumbai" or "New York"'},
          },
          'required': ['city'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_news',
        'description': 'Get top news headlines. Call this when user asks about news, what happened today, current events.',
        'parameters': {
          'type': 'object',
          'properties': {
            'topic': {'type': 'string', 'description': 'News topic or category, e.g. "technology", "india", "sports", "business". Default: "top"'},
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_web',
        'description': 'Search the web for quick facts, answers, calculations, definitions, conversions. Use for factual questions.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': 'The search query'},
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_time',
        'description': 'Get the current date and time.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_battery',
        'description': 'Get the device battery level and charging status.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_upcoming_events',
        'description': 'Get upcoming events from the user\'s Google Calendar.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_contact',
        'description': 'Search the user\'s phone contacts for a phone number by name.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'description': 'The name of the contact to search for'},
          },
          'required': ['name'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'remember_fact',
        'description': 'Store a fact about the user in long-term memory for future conversations. Use when user shares personal info: name, preferences, schedule, family, work.',
        'parameters': {
          'type': 'object',
          'properties': {
            'key':   {'type': 'string', 'description': 'Short label, e.g. "user_name", "home_city", "wife_name"'},
            'value': {'type': 'string', 'description': 'The fact to remember'},
          },
          'required': ['key', 'value'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'recall_facts',
        'description': 'Retrieve all facts stored about the user from long-term memory.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'forget_fact',
        'description': 'Delete a stored fact by key.',
        'parameters': {
          'type': 'object',
          'properties': {
            'key': {'type': 'string', 'description': 'The key to forget'},
          },
          'required': ['key'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'send_sms',
        'description': 'Send an SMS text message to a contact or phone number. Use when user says send a message/text to someone.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name_or_number': {'type': 'string', 'description': 'Contact name or phone number'},
            'message': {'type': 'string', 'description': 'The text message to send'},
          },
          'required': ['name_or_number', 'message'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'generate_image',
        'description': 'Generate an image from a text prompt and open it on the screen. Use this when the user asks you to create, generate, or draw a picture.',
        'parameters': {
          'type': 'object',
          'properties': {
            'prompt': {'type': 'string', 'description': 'A highly detailed description of the image to generate'},
          },
          'required': ['prompt'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'set_alarm',
        'description': 'Set an alarm. Use when user says set alarm for X time.',
        'parameters': {
          'type': 'object',
          'properties': {
            'hour':   {'type': 'integer', 'description': '24-hour format hour (0-23)'},
            'minute': {'type': 'integer', 'description': 'Minute (0-59)'},
            'label':  {'type': 'string',  'description': 'Alarm label/name'},
          },
          'required': ['hour', 'minute'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'set_timer',
        'description': 'Set a countdown timer. Use when user says set timer for X minutes/seconds.',
        'parameters': {
          'type': 'object',
          'properties': {
            'seconds': {'type': 'integer', 'description': 'Timer duration in seconds'},
            'label':   {'type': 'string',  'description': 'Timer label'},
          },
          'required': ['seconds'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'set_volume',
        'description': 'Set the device media volume. Use when user says increase/decrease/mute volume.',
        'parameters': {
          'type': 'object',
          'properties': {
            'level': {'type': 'integer', 'description': 'Volume level 0-100'},
          },
          'required': ['level'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'compose_smart_reply',
        'description': 'Compose a smart, context-aware reply message for WhatsApp, SMS, or email based on context.',
        'parameters': {
          'type': 'object',
          'properties': {
            'sender':  {'type': 'string', 'description': 'Who sent the message'},
            'message': {'type': 'string', 'description': 'The message received'},
            'tone':    {'type': 'string', 'description': 'Reply tone: friendly / professional / short / detailed'},
          },
          'required': ['sender', 'message'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'launch_app',
        'description': 'Launch any installed app by name (e.g. YouTube, WhatsApp, Settings, Chrome, Spotify, Camera).',
        'parameters': {
          'type': 'object',
          'properties': {
            'app_name': {'type': 'string', 'description': 'Name of the app to launch'},
          },
          'required': ['app_name'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'click_text',
        'description': 'Tap on any screen element that contains the specified visible text using Android Accessibility.',
        'parameters': {
          'type': 'object',
          'properties': {
            'text': {'type': 'string', 'description': 'The exact text on the button or element to tap'},
          },
          'required': ['text'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'type_text',
        'description': 'Type text into the currently focused input field on the Android screen.',
        'parameters': {
          'type': 'object',
          'properties': {
            'text': {'type': 'string', 'description': 'The text to type'},
          },
          'required': ['text'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'swipe',
        'description': 'Swipe or scroll the screen in a specific direction (up, down, left, right).',
        'parameters': {
          'type': 'object',
          'properties': {
            'direction': {'type': 'string', 'description': 'Direction to scroll: "up", "down", "left", "right"'},
          },
          'required': ['direction'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'toggle_flashlight',
        'description': 'Turn device flashlight / torch ON or OFF. Use when user says turn on/off flashlight or torch.',
        'parameters': {
          'type': 'object',
          'properties': {
            'enable': {'type': 'boolean', 'description': 'True to turn on, False to turn off'},
          },
          'required': ['enable'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'take_screenshot',
        'description': 'Capture a screenshot of the current screen.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_wifi_settings',
        'description': 'Open Wi-Fi settings or toggle Wi-Fi.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'toggle_bluetooth',
        'description': 'Toggle Bluetooth ON or OFF.',
        'parameters': {
          'type': 'object',
          'properties': {
            'enable': {'type': 'boolean', 'description': 'True to turn on, False to turn off'},
          },
          'required': ['enable'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_camera',
        'description': 'Open camera to take photos or selfies.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_sound_settings',
        'description': 'Open system sound, vibration, and volume settings.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_display_settings',
        'description': 'Open display and brightness settings.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'open_battery_settings',
        'description': 'Open battery health, power usage, and battery saver settings.',
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
  ];

  // ── Tool dispatcher ────────────────────────────────────────────────────────

  static Future<String> call(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'get_weather':          return await _getWeather(args['city'] ?? 'Mumbai');
        case 'get_news':             return await _getNews(args['topic'] ?? 'top');
        case 'search_web':           return await _searchWeb(args['query'] ?? '');
        case 'get_time':             return _getTime();
        case 'get_battery':          return await _getBattery();
        case 'get_upcoming_events':  return await _getUpcomingEvents();
        case 'search_contact':       return await _searchContact(args['name'] ?? '');
        case 'remember_fact':        return await _rememberFact(args['key'] ?? '', args['value'] ?? '');
        case 'recall_facts':         return await _recallFacts();
        case 'forget_fact':          return await _forgetFact(args['key'] ?? '');
        case 'send_sms':             return await _sendSms(args['name_or_number'] ?? '', args['message'] ?? '');
        case 'set_alarm':            return await _setAlarm(args['hour'] ?? 7, args['minute'] ?? 0, args['label'] ?? 'Jack Alarm');
        case 'set_timer':            return await _setTimer(args['seconds'] ?? 60, args['label'] ?? 'Jack Timer');
        case 'set_volume':           return await _setVolume(args['level'] ?? 50);
        case 'generate_image':       return await _generateImage(args['prompt'] ?? 'beautiful landscape');
        case 'launch_app':           return await launchApp(args['app_name'] ?? '');
        case 'click_text':           return await _clickText(args['text'] ?? '');
        case 'type_text':            return await _typeText(args['text'] ?? '');
        case 'swipe':                return await _swipe(args['direction'] ?? 'up');
        case 'compose_smart_reply':  return _composeSmartReply(args['sender'] ?? '', args['message'] ?? '', args['tone'] ?? 'friendly');
        case 'toggle_flashlight':    return await toggleFlashlight(args['enable'] == true);
        case 'take_screenshot':      return await takeScreenshot();
        case 'open_wifi_settings':   return await openWifiSettings();
        case 'toggle_bluetooth':     return await toggleBluetooth(args['enable'] == true);
        case 'open_camera':          return await openCamera();
        case 'open_sound_settings':  return await openSoundSettings();
        case 'open_display_settings': return await openDisplaySettings();
        case 'open_battery_settings': return await openBatterySettings();
        default: return 'Unknown tool: $name';
      }
    } catch (e) {
      return 'Error running $name: $e';
    }
  }

  // ── Tool implementations ───────────────────────────────────────────────────

  static Future<String> _getWeather(String city) async {
    final res = await _dio.get('https://wttr.in/$city?format=j1');
    final data = res.data;
    final current = data['current_condition'][0];
    final area    = data['nearest_area'][0];

    final temp     = current['temp_C'];
    final feelsLike= current['FeelsLikeC'];
    final desc     = current['weatherDesc'][0]['value'];
    final humidity = current['humidity'];
    final windKmph = current['windspeedKmph'];
    final areaName = area['areaName'][0]['value'];

    final today    = data['weather'][0];
    final maxTemp  = today['maxtempC'];
    final minTemp  = today['mintempC'];

    return '''Weather in $areaName:
• Condition: $desc
• Temperature: $temp°C (feels like $feelsLike°C)
• Today: High $maxTemp°C / Low $minTemp°C
• Humidity: $humidity% | Wind: $windKmph km/h''';
  }

  static Future<String> _getNews(String topic) async {
    // DuckDuckGo news is not stable; use GNews free API with no key required
    // Fallback: BBC RSS feed parsed as JSON via rss2json.com
    try {
      final feedUrl = topic == 'top' || topic == 'general'
          ? 'https://feeds.bbci.co.uk/news/rss.xml'
          : 'https://feeds.bbci.co.uk/news/${topic.toLowerCase()}/rss.xml';

      final res = await _dio.get(
        'https://api.rss2json.com/v1/api.json',
        queryParameters: {'rss_url': feedUrl},
      );

      final items = (res.data['items'] as List?)?.take(5) ?? [];
      if (items.isEmpty) return 'No news found for $topic.';

      final headlines = items.map((item) {
        final title = item['title'] as String? ?? '';
        return '• $title';
      }).join('\n');

      return 'Top ${topic == "top" ? "" : "$topic "}news:\n$headlines';
    } catch (_) {
      return 'Could not fetch news right now. Please check your internet.';
    }
  }

  static Future<String> _searchWeb(String query) async {
    try {
      final res = await _dio.get(
        'https://html.duckduckgo.com/html/',
        queryParameters: {'q': query},
        options: Options(headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}),
      );

      final html = res.data as String;
      
      // Parse out the snippets
      final results = <String>[];
      final snippetRegex = RegExp(r'<a class="result__snippet[^>]*>(.*?)</a>', dotAll: true);
      final matches = snippetRegex.allMatches(html);
      
      for (final match in matches.take(3)) {
        var text = match.group(1) ?? '';
        text = text.replaceAll(RegExp(r'<[^>]*>'), ''); // strip HTML
        text = text.replaceAll('\n', ' ').trim();
        if (text.isNotEmpty) results.add('• $text');
      }
      
      if (results.isEmpty) return 'No direct search results found.';
      return 'Web Search Results for "$query":\n${results.join('\n')}';
    } catch (_) {
      return 'Web search failed. Please check internet connection.';
    }
  }

  static Future<String> _generateImage(String prompt) async {
    try {
      final encodedPrompt = Uri.encodeComponent(prompt);
      final url = Uri.parse('https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&nologo=true');
      
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return 'Successfully generated the image and opened it in the browser.';
    } catch (e) {
      return 'Failed to generate image: $e';
    }
  }

  static String _getTime() {
    return DateFormat('EEEE, MMM d, yyyy - h:mm a').format(DateTime.now());
  }

  static Future<String> _getUpcomingEvents() async {
    try {
      final res = await _platform.invokeMethod<String>('getCalendarEvents');
      return res ?? 'No events found';
    } catch (e) {
      return 'Error fetching calendar: $e';
    }
  }

  static Future<String> _searchContact(String name) async {
    try {
      final res = await _platform.invokeMethod<String>('searchContact', {'name': name});
      return res ?? 'Contact not found';
    } catch (e) {
      return 'Error searching contacts: $e';
    }
  }

  static Future<String> _getBattery() async {
    try {
      final level = await _platform.invokeMethod<int>('getBatteryLevel') ?? -1;
      if (level < 0) return 'Battery info unavailable.';
      final status = level > 20 ? 'OK' : 'LOW — please charge soon';
      return 'Battery: $level% ($status)';
    } catch (_) {
      return 'Battery: unavailable (add getBatteryLevel to MainActivity)';
    }
  }

  // ── Long-term memory ───────────────────────────────────────────────────────

  static Future<String> _sendSms(String nameOrNumber, String message) async {
    // First resolve name to number if needed
    String number = nameOrNumber;
    if (nameOrNumber.contains(RegExp(r'[a-zA-Z]'))) {
      final resolved = await _searchContact(nameOrNumber);
      if (resolved.startsWith('+') || resolved.contains(RegExp(r'^\d'))) {
        number = resolved;
      } else {
        return 'Contact "$nameOrNumber" not found.';
      }
    }
    try {
      await _platform.invokeMethod('sendSMS', {'number': number, 'message': message});
      return 'SMS sent to $nameOrNumber.';
    } catch (e) {
      return 'Failed to send SMS: $e';
    }
  }

  static Future<String> _setAlarm(int hour, int minute, String label) async {
    try {
      await _platform.invokeMethod('setAlarm', {'hour': hour, 'minute': minute, 'label': label});
      final h = hour.toString().padLeft(2, '0');
      final m = minute.toString().padLeft(2, '0');
      return 'Alarm set for $h:$m — $label.';
    } catch (e) {
      return 'Failed to set alarm: $e';
    }
  }

  static Future<String> _setTimer(int seconds, String label) async {
    try {
      await _platform.invokeMethod('setTimer', {'seconds': seconds, 'label': label});
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      final display = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
      return 'Timer set for $display.';
    } catch (e) {
      return 'Failed to set timer: $e';
    }
  }

  static Future<String> _setVolume(int level) async {
    try {
      await _platform.invokeMethod('setVolume', {'level': level.clamp(0, 100)});
      return 'Volume set to $level%.';
    } catch (e) {
      return 'Failed to set volume: $e';
    }
  }

  static String _composeSmartReply(String sender, String message, String tone) {
    // Returns a suggested reply — Jack will speak it and user can confirm before sending
    final toneNote = switch (tone) {
      'professional' => 'Keep it professional and concise.',
      'short'        => 'Keep it very short, 1 sentence.',
      'detailed'     => 'Give a detailed, thoughtful reply.',
      _              => 'Keep it warm and friendly.',
    };
    // This just returns a prompt for the LLM to generate in the main call
    return 'COMPOSE_REPLY|sender:$sender|msg:$message|tone:$toneNote';
  }

  static Future<String> _rememberFact(String key, String value) async {
    if (key.isEmpty || value.isEmpty) return 'Key and value are required.';
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_memoryKey);
    final facts = raw != null ? (jsonDecode(raw) as Map<String, dynamic>) : <String, dynamic>{};
    facts[key] = value;
    await prefs.setString(_memoryKey, jsonEncode(facts));
    return 'Remembered: $key = $value';
  }

  static Future<String> _recallFacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_memoryKey);
    if (raw == null || raw.isEmpty) return 'No facts stored yet.';
    final facts = jsonDecode(raw) as Map<String, dynamic>;
    if (facts.isEmpty) return 'No facts stored yet.';
    return facts.entries.map((e) => '• ${e.key}: ${e.value}').join('\n');
  }

  static Future<String> _forgetFact(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_memoryKey);
    if (raw == null) return 'No facts stored.';
    final facts = jsonDecode(raw) as Map<String, dynamic>;
    facts.remove(key);
    await prefs.setString(_memoryKey, jsonEncode(facts));
    return 'Forgotten: $key';
  }

  // ── App Launching ─────────────────────────────────────────────────────────

  /// Launch an installed application by resolving its common name or package.
  static Future<String> launchApp(String appNameOrPackage) async {
    try {
      final pkg = await AppLauncherHelper.resolvePackage(appNameOrPackage);
      await _platform.invokeMethod('launchApp', {'package': pkg});
      return 'Launched $appNameOrPackage ($pkg)';
    } catch (e) {
      return 'Failed to launch $appNameOrPackage: $e';
    }
  }

  // ── Helper to load all facts for injecting into system prompt ─────────────

  static Future<String> _clickText(String text) async {
    try {
      final success = await _platform.invokeMethod<bool>('clickText', {'text': text});
      return success == true ? 'Clicked on text: $text' : 'Failed to find/click text: $text';
    } catch (e) {
      return 'Accessibility error: $e';
    }
  }

  static Future<String> _typeText(String text) async {
    try {
      final success = await _platform.invokeMethod<bool>('typeText', {'text': text});
      return success == true ? 'Typed text successfully' : 'Failed to type (is an input field focused?)';
    } catch (e) {
      return 'Accessibility error: $e';
    }
  }

  static Future<String> _swipe(String dir) async {
    try {
      if (dir == 'up') { await _platform.invokeMethod('swipeUp'); }
      else if (dir == 'down') { await _platform.invokeMethod('swipeDown'); }
      else if (dir == 'left') { await _platform.invokeMethod('swipeLeft'); }
      else if (dir == 'right') { await _platform.invokeMethod('swipeRight'); }
      else { return 'Invalid direction: $dir'; }
      return 'Swiped $dir';
    } catch (e) {
      return 'Accessibility error: $e';
    }
  }

  static Future<String> loadFactsForContext() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_memoryKey);
    if (raw == null || raw.isEmpty) return '';
    final facts = jsonDecode(raw) as Map<String, dynamic>;
    if (facts.isEmpty) return '';
    return facts.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  static Future<String> toggleFlashlight(bool enable) async {
    try {
      final res = await _platform.invokeMethod<bool>('toggleFlashlight', {'enable': enable});
      if (res == true) {
        return enable ? 'Flashlight is now ON' : 'Flashlight is now OFF';
      }
      return 'Could not toggle flashlight on this device.';
    } catch (e) {
      return 'Flashlight error: $e';
    }
  }

  static Future<String> takeScreenshot() async {
    try {
      final res = await _platform.invokeMethod<bool>('takeScreenshot');
      return res == true ? 'Captured screen successfully' : 'Could not capture screen.';
    } catch (e) {
      return 'Screenshot error: $e';
    }
  }

  static Future<String> openWifiSettings() async {
    try {
      final res = await _platform.invokeMethod<bool>('openWifiSettings');
      return res == true ? 'Opened Wi-Fi settings' : 'Could not open Wi-Fi settings.';
    } catch (e) {
      return 'Wi-Fi error: $e';
    }
  }

  static Future<String> toggleBluetooth(bool enable) async {
    try {
      final res = await _platform.invokeMethod<bool>('toggleBluetooth', {'enable': enable});
      return res == true
          ? (enable ? 'Bluetooth turned ON' : 'Bluetooth turned OFF')
          : 'Opened Bluetooth settings.';
    } catch (e) {
      return 'Bluetooth error: $e';
    }
  }

  static Future<String> openCamera() async {
    try {
      final res = await _platform.invokeMethod<bool>('openCamera');
      return res == true ? 'Camera launched' : 'Could not launch camera.';
    } catch (e) {
      return 'Camera error: $e';
    }
  }

  static Future<String> openSoundSettings() async {
    try {
      final res = await _platform.invokeMethod<bool>('openSoundSettings');
      return res == true ? 'Opened sound settings' : 'Could not open sound settings.';
    } catch (e) {
      return 'Sound settings error: $e';
    }
  }

  static Future<String> openDisplaySettings() async {
    try {
      final res = await _platform.invokeMethod<bool>('openDisplaySettings');
      return res == true ? 'Opened display settings' : 'Could not open display settings.';
    } catch (e) {
      return 'Display settings error: $e';
    }
  }

  static Future<String> openBatterySettings() async {
    try {
      final res = await _platform.invokeMethod<bool>('openBatterySettings');
      return res == true ? 'Opened battery settings' : 'Could not open battery settings.';
    } catch (e) {
      return 'Battery settings error: $e';
    }
  }
}


