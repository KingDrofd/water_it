import 'package:flutter/material.dart';

/// Design tokens from the M6 "Concept refresh" spec, one instance per theme.
///
/// Material's [ColorScheme] covers most roles; the tokens with no Material
/// equivalent (overdue, weather nudge, photo placeholder stripes, nav bar)
/// are read from here via `Theme.of(context).extension<AppPalette>()`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.card2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.primary,
    required this.deep,
    required this.accent,
    required this.onAccent,
    required this.container,
    required this.amber,
    required this.nudgeBg,
    required this.nudgeInk,
    required this.overdueBg,
    required this.overdueInk,
    required this.overdueLine,
    required this.navBg,
    required this.placeholder1,
    required this.placeholder2,
    required this.shadow,
  });

  static const light = AppPalette(
    bg: Color(0xFFF3F6EE),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFEAF1E0),
    ink: Color(0xFF1B2016),
    muted: Color(0xFF5F6753),
    line: Color(0xFFE6EBDD),
    primary: Color(0xFF8BC34A),
    deep: Color(0xFF2E7D32),
    accent: Color(0xFF2E7D32),
    onAccent: Color(0xFFFFFFFF),
    container: Color(0xFFAED581),
    amber: Color(0xFFE09600),
    nudgeBg: Color(0xFFFFF3CE),
    nudgeInk: Color(0xFF8A6400),
    overdueBg: Color(0xFFFCEBE9),
    overdueInk: Color(0xFFB00020),
    overdueLine: Color(0xFFF3C9C6),
    navBg: Color(0xFFFFFFFF),
    placeholder1: Color(0xFFDCE8CC),
    placeholder2: Color(0xFFEAF1DE),
    shadow: Color(0x1A2E4920),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0F130C),
    card: Color(0xFF1A2018),
    card2: Color(0xFF26301F),
    ink: Color(0xFFEAEEE3),
    muted: Color(0xFF99A18F),
    line: Color(0xFF2A3226),
    primary: Color(0xFFA5D66A),
    deep: Color(0xFF6DBE6E),
    accent: Color(0xFFA5D66A),
    onAccent: Color(0xFF10140C),
    container: Color(0xFF33452A),
    amber: Color(0xFFFFCA28),
    nudgeBg: Color(0xFF2C2612),
    nudgeInk: Color(0xFFFBD98A),
    overdueBg: Color(0xFF39201E),
    overdueInk: Color(0xFFF2B8B5),
    overdueLine: Color(0xFF5A2E2B),
    navBg: Color(0xFF1B2119),
    placeholder1: Color(0xFF222C1B),
    placeholder2: Color(0xFF1B2416),
    shadow: Color(0x80000000),
  );

  /// Screen background.
  final Color bg;

  /// Cards and list rows.
  final Color card;

  /// Icon tiles and secondary fills.
  final Color card2;
  final Color ink;
  final Color muted;
  final Color line;

  /// Brand green: selected nav item, active chips.
  final Color primary;

  /// Strong green for emphasis.
  final Color deep;

  /// Filled buttons: Add Plant, the due task's Mark done.
  final Color accent;
  final Color onAccent;

  /// Selected chip and nav pill backgrounds.
  final Color container;

  /// Fertilize, sun, and other warm accents.
  final Color amber;

  /// Weather nudge banner.
  final Color nudgeBg;
  final Color nudgeInk;

  /// Overdue rows and badges.
  final Color overdueBg;
  final Color overdueInk;
  final Color overdueLine;

  /// Floating bottom navigation bar.
  final Color navBg;

  /// Photo placeholder stripes.
  final Color placeholder1;
  final Color placeholder2;

  /// Card drop shadow colour.
  final Color shadow;

  /// Palette for [context], falling back to light outside a themed tree.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({
    Color? bg,
    Color? card,
    Color? card2,
    Color? ink,
    Color? muted,
    Color? line,
    Color? primary,
    Color? deep,
    Color? accent,
    Color? onAccent,
    Color? container,
    Color? amber,
    Color? nudgeBg,
    Color? nudgeInk,
    Color? overdueBg,
    Color? overdueInk,
    Color? overdueLine,
    Color? navBg,
    Color? placeholder1,
    Color? placeholder2,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      card2: card2 ?? this.card2,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      primary: primary ?? this.primary,
      deep: deep ?? this.deep,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      container: container ?? this.container,
      amber: amber ?? this.amber,
      nudgeBg: nudgeBg ?? this.nudgeBg,
      nudgeInk: nudgeInk ?? this.nudgeInk,
      overdueBg: overdueBg ?? this.overdueBg,
      overdueInk: overdueInk ?? this.overdueInk,
      overdueLine: overdueLine ?? this.overdueLine,
      navBg: navBg ?? this.navBg,
      placeholder1: placeholder1 ?? this.placeholder1,
      placeholder2: placeholder2 ?? this.placeholder2,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: mix(bg, other.bg),
      card: mix(card, other.card),
      card2: mix(card2, other.card2),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      primary: mix(primary, other.primary),
      deep: mix(deep, other.deep),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      container: mix(container, other.container),
      amber: mix(amber, other.amber),
      nudgeBg: mix(nudgeBg, other.nudgeBg),
      nudgeInk: mix(nudgeInk, other.nudgeInk),
      overdueBg: mix(overdueBg, other.overdueBg),
      overdueInk: mix(overdueInk, other.overdueInk),
      overdueLine: mix(overdueLine, other.overdueLine),
      navBg: mix(navBg, other.navBg),
      placeholder1: mix(placeholder1, other.placeholder1),
      placeholder2: mix(placeholder2, other.placeholder2),
      shadow: mix(shadow, other.shadow),
    );
  }
}
