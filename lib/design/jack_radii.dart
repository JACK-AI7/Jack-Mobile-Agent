// lib/design/jack_radii.dart
//
// Standardized Corner Geometry Tokens for JACK Agent
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class JackRadii {
  JackRadii._();

  static const double chip = 17.0;
  static const double input = 29.0;
  static const double button = 28.0;
  static const double card = 18.0;
  static const double cardLarge = 24.0;
  static const double navPill = 34.0;
  static const double sheetTop = 28.0;

  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius cardLargeRadius = BorderRadius.all(Radius.circular(cardLarge));
  static const BorderRadius navPillRadius = BorderRadius.all(Radius.circular(navPill));
}
