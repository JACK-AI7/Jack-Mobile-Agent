// lib/services/mcp/android_mcp_server.dart
//
// Android-MCP Server — Local Model Context Protocol Bridge for Android OS
// ─────────────────────────────────────────────────────────────────────────────
// Exposes Android's system tools, UI DOM tree, gesture injection, and privileged
// shell execution as lightweight, local MCP tool definitions that any on-device
// LLM or agent workflow can invoke immediately.
// ─────────────────────────────────────────────────────────────────────────────

import '../app_launcher_helper.dart';
import '../jack_controller.dart';
import '../jack_shizuku_controller.dart';
import 'jack_mcp_client.dart';

class AndroidMcpServer {
  static final AndroidMcpServer instance = AndroidMcpServer._internal();
  AndroidMcpServer._internal();

  /// Returns the complete list of Android system tools exposed via MCP schema
  List<McpToolDefinition> getExposedTools() {
    return const [
      McpToolDefinition(
        name: 'android_inspect_screen',
        description: 'Dumps active Android screen DOM hierarchy including all buttons, labels, and coordinates.',
        parameters: [],
      ),
      McpToolDefinition(
        name: 'android_click_element',
        description: 'Taps an interactive UI element by visible text, resource-id, or (x, y) pixel coordinates.',
        parameters: [
          McpToolParameter(
            name: 'text',
            type: 'string',
            description: 'Visible label or content description of the target button.',
          ),
          McpToolParameter(
            name: 'resource_id',
            type: 'string',
            description: 'Android view ID substring (e.g. "search_button").',
          ),
          McpToolParameter(
            name: 'x',
            type: 'number',
            description: 'Exact X screen coordinate (fallback).',
          ),
          McpToolParameter(
            name: 'y',
            type: 'number',
            description: 'Exact Y screen coordinate (fallback).',
          ),
        ],
      ),
      McpToolDefinition(
        name: 'android_type_text',
        description: 'Types text into the currently focused or specified text field.',
        parameters: [
          McpToolParameter(
            name: 'data',
            type: 'string',
            description: 'The exact string to type into the field.',
            required: true,
          ),
          McpToolParameter(
            name: 'text',
            type: 'string',
            description: 'Optional placeholder or label of the field to focus first.',
          ),
        ],
      ),
      McpToolDefinition(
        name: 'android_swipe_gesture',
        description: 'Performs a touch scroll/swipe gesture across screen coordinates.',
        parameters: [
          McpToolParameter(
            name: 'direction',
            type: 'string',
            description: 'Swipe direction: "UP", "DOWN", "LEFT", "RIGHT".',
            required: true,
          ),
          McpToolParameter(
            name: 'duration_ms',
            type: 'number',
            description: 'Duration of gesture in milliseconds (default 300).',
          ),
        ],
      ),
      McpToolDefinition(
        name: 'android_global_action',
        description: 'Triggers Android system global navigation action (HOME, BACK, RECENTS, NOTIFICATIONS).',
        parameters: [
          McpToolParameter(
            name: 'action',
            type: 'string',
            description: '"HOME", "BACK", "RECENTS", or "NOTIFICATIONS".',
            required: true,
          ),
        ],
      ),
      McpToolDefinition(
        name: 'android_launch_app',
        description: 'Launches an installed Android app by common name or package.',
        parameters: [
          McpToolParameter(
            name: 'app_name',
            type: 'string',
            description: 'Name of the app (e.g., "YouTube", "Settings", "WhatsApp").',
            required: true,
          ),
        ],
      ),
      McpToolDefinition(
        name: 'android_shizuku_exec',
        description: 'Executes a privileged ADB shell command locally with UID 2000 via Shizuku.',
        parameters: [
          McpToolParameter(
            name: 'command',
            type: 'string',
            description: 'ADB shell command to run (e.g. "input tap 500 500", "am start ...").',
            required: true,
          ),
        ],
      ),
    ];
  }

  /// Dispatches an MCP tool call and returns the structured result
  Future<McpCallResult> executeTool(String toolName, Map<String, dynamic> arguments) async {
    final stopwatch = Stopwatch()..start();

    try {
      switch (toolName) {
        case 'android_inspect_screen':
          final nodes = await JackController.inspectScreen();
          stopwatch.stop();
          return McpCallResult(
            success: true,
            data: {'node_count': nodes.length, 'nodes': nodes},
            executionTime: stopwatch.elapsed,
          );

        case 'android_click_element':
          final text = arguments['text']?.toString();
          final resId = arguments['resource_id']?.toString();
          final x = (arguments['x'] as num?)?.toDouble();
          final y = (arguments['y'] as num?)?.toDouble();

          bool clicked = false;
          if (text != null || resId != null) {
            clicked = await JackController.clickElement(text: text, id: resId);
          }
          if (!clicked && x != null && y != null) {
            await JackController.tapCoordinates(x, y);
            clicked = true;
          }

          stopwatch.stop();
          return McpCallResult(
            success: clicked,
            data: {'clicked': clicked, 'target': text ?? resId ?? '($x, $y)'},
            executionTime: stopwatch.elapsed,
          );

        case 'android_type_text':
          final data = arguments['data']?.toString() ?? '';
          final text = arguments['text']?.toString();

          final typed = await JackController.typeText(text: text, data: data);
          stopwatch.stop();
          return McpCallResult(
            success: typed,
            data: {'typed': typed, 'data': data},
            executionTime: stopwatch.elapsed,
          );

        case 'android_swipe_gesture':
          final dir = arguments['direction']?.toString().toUpperCase() ?? 'DOWN';
          final dur = (arguments['duration_ms'] as num?)?.toInt() ?? 300;

          if (dir == 'UP') {
            await JackController.swipe(startX: 540, startY: 1500, endX: 540, endY: 500, durationMs: dur);
          } else if (dir == 'LEFT') {
            await JackController.swipe(startX: 900, startY: 1000, endX: 100, endY: 1000, durationMs: dur);
          } else if (dir == 'RIGHT') {
            await JackController.swipe(startX: 100, startY: 1000, endX: 900, endY: 1000, durationMs: dur);
          } else {
            await JackController.swipe(startX: 540, startY: 600, endX: 540, endY: 1500, durationMs: dur);
          }

          stopwatch.stop();
          return McpCallResult(
            success: true,
            data: {'swipe_direction': dir},
            executionTime: stopwatch.elapsed,
          );

        case 'android_global_action':
          final act = arguments['action']?.toString().toUpperCase() ?? 'BACK';
          await JackController.triggerGlobal(act);
          stopwatch.stop();
          return McpCallResult(
            success: true,
            data: {'global_action': act},
            executionTime: stopwatch.elapsed,
          );

        case 'android_launch_app':
          final app = arguments['app_name']?.toString() ?? '';
          final launched = await AppLauncherHelper.launchAppByName(app);
          stopwatch.stop();
          return McpCallResult(
            success: launched,
            data: {'app': app, 'launched': launched},
            executionTime: stopwatch.elapsed,
          );

        case 'android_shizuku_exec':
          final cmd = arguments['command']?.toString() ?? '';
          final output = await JackShizukuController.executeShell(cmd);
          stopwatch.stop();
          return McpCallResult(
            success: !output.startsWith('ERROR:'),
            data: {'command': cmd, 'output': output},
            executionTime: stopwatch.elapsed,
          );

        default:
          stopwatch.stop();
          return McpCallResult(
            success: false,
            errorMessage: 'Unknown MCP tool: $toolName',
            executionTime: stopwatch.elapsed,
          );
      }
    } catch (e) {
      stopwatch.stop();
      return McpCallResult(
        success: false,
        errorMessage: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }
}
