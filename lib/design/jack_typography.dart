// lib/design/jack_typography.dart
//
// Editorial Typography System for JACK Agent
// Features Cormorant Garamond for editorial titles and Inter for crisp UI controls.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jack_colors.dart';

class JackTypography {
  JackTypography._();

  /// Grand brand display (e.g. Splash, Hero)
  static TextStyle display({Color color = JackColors.textPrimary}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: 42,
      fontWeight: FontWeight.w400,
      height: 1.10,
      letterSpacing: -0.5,
      color: color,
    );
  }

  /// Screen primary title (e.g. "Agent Autonomy", "Automations", "Tools")
  static TextStyle h1({Color color = JackColors.textPrimary}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.15,
      color: color,
    );
  }

  /// Section or card heading
  static TextStyle h2({Color color = JackColors.textPrimary}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: color,
    );
  }

  /// App bar brand title ("JACK AGENT")
  static TextStyle brandHeader({Color color = JackColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 3.0,
      color: color,
    );
  }

  /// Screen subtitle (e.g. "Set it once. Jack handles the rest.")
  static TextStyle subtitle({Color color = JackColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: color,
    );
  }

  /// Standard body text
  static TextStyle body({Color color = JackColors.textPrimary, FontWeight weight = FontWeight.w400}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: weight,
      height: 1.45,
      color: color,
    );
  }

  /// List item or card title
  static TextStyle listTitle({Color color = JackColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle cardTitle({Color color = JackColors.textPrimary}) => listTitle(color: color);

  /// List item or card subtitle
  static TextStyle listSubtitle({Color color = JackColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: color,
    );
  }

  static TextStyle cardSubtitle({Color color = JackColors.textSecondary}) => listSubtitle(color: color);

  /// Button label
  static TextStyle button({Color color = Colors.black, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: weight,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// Filter chips & tabs
  static TextStyle chip({required bool selected}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? Colors.black : JackColors.textSecondary,
    );
  }

  /// Navigation bar labels
  static TextStyle navLabel({required bool selected}) {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      color: selected ? JackColors.cyan : JackColors.textTertiary,
    );
  }

  /// Small metadata & timestamps
  static TextStyle caption({Color color = JackColors.textTertiary}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
}
