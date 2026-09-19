// lib/widgets/bixby_capsule_renderer.dart
//
// Jack — Dynamic Bixby Capsule Renderer
// Renders the declarative BixbyViewTemplate (result/input/confirmation views)
// into real glassmorphic Flutter components matching the tier-one design system.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../capsules/core_models.dart';
import '../theme/jack_design_tokens.dart';
import 'real_glass_card.dart';
import 'bixby_input_view_renderer.dart';

class BixbyCapsuleRenderer extends StatelessWidget {
  final CapsuleDispatchResult capsuleResult;
  final ValueChanged<String>? onDriverTapped;
  // We need a callback for when an input option is selected. We can just use a function.
  // Wait, BixbyCapsuleRenderer needs to call `resolveInputSelection`.
  // Since it's passed `onDriverTapped`, maybe we can pass `onOptionSelected` too?
  // Let's add it to the signature!
  final Function(Map<String, dynamic>)? onOptionSelected;

  const BixbyCapsuleRenderer({
    super.key,
    required this.capsuleResult,
    this.onDriverTapped,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final view = capsuleResult.viewTemplate;
    
    if (view.viewType == ViewType.inputView) {
      // Reformat the result into what BixbyInputViewRenderer expects
      final payload = {
        'render': {
          'elements': (capsuleResult.result['options'] as List?)?.map((opt) {
             return {
               'payload': opt['payload'],
               'slot1': {'text': opt['avatar']},
               'slot2': {'title': opt['title'], 'subtitle': opt['subtitle']}
             };
          }).toList() ?? []
        },
        'conversation_drivers': view.conversationDrivers.map((d) => {'template': d.template}).toList(),
      };

      return BixbyInputViewRenderer(
        viewPayload: payload,
        onOptionSelected: (data) => onOptionSelected?.call(data),
        onCancelled: () => onDriverTapped?.call('Cancel'),
      );
    }

    
    // Safety padding + max width constraint for the dashboard
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Render Main Layout Components
          for (final component in view.layout) _buildComponent(component, context),
          
          // Render Confirmation View Action Buttons if needed
          if (view.viewType == ViewType.confirmationView)
            _buildConfirmationButtons(context, view.confirmationText ?? 'Confirm'),

          // Render Conversation Drivers (Action Chips)
          if (view.conversationDrivers.isNotEmpty)
            _buildDrivers(view.conversationDrivers),
        ],
      ),
    );
  }

  Widget _buildComponent(BixbyLayoutComponent component, BuildContext context) {
    if (component is TitleAreaComponent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Column(
          crossAxisAlignment: component.halign == 'Center'
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              component.title,
              style: JackDesignTokens.highEmphasis.copyWith(fontSize: 22),
            ),
            if (component.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                component.subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ]
          ],
        ),
      );
    } 
    
    else if (component is CompoundCardComponent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RealGlassCard(
          padding: EdgeInsets.zero, // handled by children
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: component.children.map((c) => _buildComponent(c, context)).toList(),
          ),
        ),
      );
    } 
    
    else if (component is CellCardComponent) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildCellSlot(component.slot1, isLeading: true),
            const SizedBox(width: 12),
            Expanded(child: _buildCellSlot(component.slot2)),
            if (component.slot3 != null) ...[
              const SizedBox(width: 12),
              _buildCellSlot(component.slot3!),
            ],
          ],
        ),
      );
    } 
    
    else if (component is DividerComponent) {
      return Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.1),
      );
    }
    
    else if (component is SparklineComponent) {
      final color = _getSlotColor(component.color);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RealGlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(component.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  if (component.unit != null)
                    Text(component.unit!, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: component.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    else if (component is ThumbnailCardComponent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RealGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: component.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(component.imageUrl!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.music_note, color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (component.appName != null)
                      Text(
                        component.appName!.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      component.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (component.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        component.subtitle!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink(); // fallback
  }

  Widget _buildCellSlot(CellSlot slot, {bool isLeading = false}) {
    switch (slot.type) {
      case 'icon':
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIcon(slot.glyph), color: JackDesignTokens.siriCyan, size: 20),
        );
      case 'title-area':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slot.title ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            if (slot.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                slot.subtitle!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
            ],
          ],
        );
      case 'text':
        return Text(
          slot.value ?? '',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600),
        );
      case 'badge':
        final color = _getSlotColor(slot.style);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            slot.label ?? '',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildConfirmationButtons(BuildContext context, String confirmText) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onDriverTapped?.call('Cancel'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onDriverTapped?.call('Confirm $confirmText'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JackDesignTokens.siriCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrivers(List<ConversationDriver> drivers) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: drivers.map((driver) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(driver.template),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () => onDriverTapped?.call(driver.effectiveQuery),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getSlotColor(String? style) {
    switch (style) {
      case 'success':
      case 'green':
        return Colors.greenAccent;
      case 'warning':
      case 'amber':
        return Colors.orangeAccent;
      case 'error':
      case 'red':
        return Colors.redAccent;
      case 'info':
      case 'cyan':
        return JackDesignTokens.siriCyan;
      default:
        return Colors.white;
    }
  }

  IconData _getIcon(String? glyph) {
    switch (glyph) {
      case 'bolt': return Icons.bolt;
      case 'cpu': return Icons.memory;
      case 'camera': return Icons.camera_alt;
      case 'alarm': return Icons.alarm;
      case 'moon': return Icons.nightlight_round;
      case 'timer': return Icons.timer;
      case 'phone': return Icons.phone;
      case 'message': return Icons.message;
      case 'play': return Icons.play_arrow;
      case 'apps': return Icons.apps;
      case 'sun.min': return Icons.brightness_low;
      case 'bluetooth.slash': return Icons.bluetooth_disabled;
      default: return Icons.widgets;
    }
  }
}
